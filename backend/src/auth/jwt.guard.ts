import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class JwtGuard implements CanActivate {
  constructor(private jwt: JwtService, private p: PrismaService) {}

  async canActivate(c: ExecutionContext) {
    const r = c.switchToHttp().getRequest();
    const h = r.headers.authorization || '';
    if (!h.startsWith('Bearer ')) throw new UnauthorizedException();
    try {
      const x = await this.jwt.verifyAsync(h.slice(7), { secret: process.env.JWT_SECRET });
      const id = BigInt(x.sub);
      const admin = await this.p.admin.findUnique({ where: { id } });
      if (!admin || admin.accountStatus !== 'ACTIVE') {
        throw new UnauthorizedException('Account is inactive');
      }
      if (admin.type === 'ONLINE') {
        const now = new Date();
        const subscription = await this.p.appSubscription.findFirst({
          where: { adminId: id, status: 'ACTIVE', expiryDate: { gt: now } },
          orderBy: { expiryDate: 'desc' },
        });
        if (!subscription) throw new UnauthorizedException('Subscription expired or not assigned');
      }
      r.user = { id, email: admin.email, type: admin.type };
      return true;
    } catch (e) {
      if (e instanceof UnauthorizedException) throw e;
      throw new UnauthorizedException();
    }
  }
}
