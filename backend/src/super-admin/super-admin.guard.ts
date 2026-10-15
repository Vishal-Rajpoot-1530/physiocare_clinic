import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { timingSafeEqual } from 'crypto';

@Injectable()
export class SuperAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const expected = process.env.SUPER_ADMIN_KEY || '';
    const supplied = String(context.switchToHttp().getRequest().headers['x-super-admin-key'] || '');
    if (!expected || !supplied) throw new UnauthorizedException('Super admin authorization required');
    const a = Buffer.from(expected), b = Buffer.from(supplied);
    if (a.length !== b.length || !timingSafeEqual(a, b)) throw new UnauthorizedException('Invalid super admin authorization');
    return true;
  }
}
