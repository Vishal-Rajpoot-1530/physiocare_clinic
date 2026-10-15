import { BadRequestException, ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService {
  constructor(private p: PrismaService, private jwt: JwtService) {}

  async register(d: any) {
    const email = d.email.trim().toLowerCase();
    if (await this.p.admin.findUnique({ where: { email } })) {
      throw new ConflictException('Email already registered');
    }
    const hash = await bcrypt.hash(d.password, 12);
    await this.p.$transaction(async (tx) => {
      const a = await tx.admin.create({ data: { name: d.name, email, phone: (d.phone || '').trim(), type: (d.type || 'OFFLINE').toUpperCase(), accountStatus: 'ACTIVE', passwordHash: hash } });
      await tx.plan.createMany({
        data: ([[1, 'DAY', 400], [1, 'WEEK', 2500], [1, 'MONTH', 10000], [3, 'MONTH', 25000]] as const).map(([durationValue, durationUnit, fee]) => ({
          adminId: a.id,
          durationValue,
          durationUnit,
          fee,
        })),
      });
    });
    return { success: true };
  }

  async login(d: any) {
    const email = d.email.trim().toLowerCase();
    const u = await this.p.admin.findUnique({ where: { email } });
    if (!u || !await bcrypt.compare(d.password, u.passwordHash)) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (u.accountStatus !== 'ACTIVE') throw new UnauthorizedException('Account is inactive');
    let subscription: any = null;
    if (u.type === 'ONLINE') {
      subscription = await this.p.appSubscription.findFirst({
        where: { adminId: u.id, status: 'ACTIVE', expiryDate: { gt: new Date() } },
        orderBy: { expiryDate: 'desc' },
      });
      if (!subscription) throw new UnauthorizedException('Subscription expired or not assigned');
    }
    const token = await this.jwt.signAsync(
      { sub: u.id.toString(), email: u.email },
      { secret: process.env.JWT_SECRET, expiresIn: (process.env.JWT_EXPIRES_IN || '30d') as any },
    );
    return { token, user: { id: Number(u.id), name: u.name, email: u.email, phone: u.phone, type: u.type.toLowerCase(), status: u.accountStatus.toLowerCase(), ...(subscription ? { subscription: { plan_type: subscription.planType.toLowerCase(), start_date: subscription.startDate.toISOString(), expiry_date: subscription.expiryDate.toISOString(), status: subscription.status.toLowerCase() } } : {}) } };
  }

  async getProfile(adminId: bigint) {
    const admin = await this.p.admin.findUniqueOrThrow({
      where: { id: adminId },
      select: { id: true, name: true, email: true, phone: true, type: true, accountStatus: true, createdAt: true },
    });
    return {
      id: Number(admin.id),
      name: admin.name,
      email: admin.email,
      phone: admin.phone,
      type: admin.type.toLowerCase(),
      status: admin.accountStatus.toLowerCase(),
      created_at: admin.createdAt.toISOString(),
    };
  }

  async updateProfile(adminId: bigint, name: string) {
    const trimmedName = name.trim();
    if (!trimmedName) {
      throw new BadRequestException('Name cannot be empty.');
    }
    const admin = await this.p.admin.update({
      where: { id: adminId },
      data: { name: trimmedName },
      select: { id: true, name: true, email: true, phone: true, type: true, accountStatus: true, createdAt: true },
    });
    return {
      id: Number(admin.id),
      name: admin.name,
      email: admin.email,
      phone: admin.phone,
      type: admin.type.toLowerCase(),
      status: admin.accountStatus.toLowerCase(),
      created_at: admin.createdAt.toISOString(),
    };
  }

  async changePassword(adminId: bigint, currentPassword: string, newPassword: string) {
    const admin = await this.p.admin.findUniqueOrThrow({ where: { id: adminId } });
    if (!await bcrypt.compare(currentPassword, admin.passwordHash)) {
      throw new UnauthorizedException('Current password is incorrect.');
    }
    const passwordHash = await bcrypt.hash(newPassword, 12);
    await this.p.admin.update({ where: { id: adminId }, data: { passwordHash } });
    return { success: true };
  }
}