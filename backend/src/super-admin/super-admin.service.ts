import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';

const PLAN = {
  monthly: { months: 1, price: 150 },
  quarterly: { months: 3, price: 300 },
  yearly: { months: 12, price: 1000 },
} as const;

type PlanType = keyof typeof PLAN;

@Injectable()
export class SuperAdminService {
  constructor(private p: PrismaService) {}

  private jsonUser(u: any, subscription?: any) {
    return {
      id: Number(u.id), name: u.name, phone: u.phone, email: u.email,
      type: u.type.toLowerCase(), status: u.accountStatus.toLowerCase(),
      created_at: u.createdAt.toISOString(),
      subscription: subscription ? {
        id: Number(subscription.id), plan_type: subscription.planType.toLowerCase(),
        price: Number(subscription.price), start_date: subscription.startDate.toISOString(),
        expiry_date: subscription.expiryDate.toISOString(), status: (subscription.status === 'ACTIVE' && new Date(subscription.expiryDate) <= new Date() ? 'expired' : subscription.status.toLowerCase()),
      } : null,
    };
  }

  async createUser(d: any) {
    const email = d.email.trim().toLowerCase();
    if (await this.p.admin.findUnique({ where: { email } })) throw new ConflictException('Email already registered');
    const type = d.type.toUpperCase();
    const passwordHash = await bcrypt.hash(d.password, 12);
    const u = await this.p.$transaction(async tx => {
      const admin = await tx.admin.create({ data: { name: d.name.trim(), phone: d.phone.trim(), email, passwordHash, type, accountStatus: 'ACTIVE' } });
      await tx.plan.createMany({ data: ([[1, 'DAY', 400], [1, 'WEEK', 2500], [1, 'MONTH', 10000], [3, 'MONTH', 25000]] as const).map(([durationValue, durationUnit, fee]) => ({ adminId: admin.id, durationValue, durationUnit, fee })) });
      return admin;
    });
    return this.jsonUser(u);
  }

  async users() {
    const users = await this.p.admin.findMany({ orderBy: { createdAt: 'desc' }, include: { appSubscriptions: { orderBy: { expiryDate: 'desc' }, take: 1 } } });
    return users.map(u => this.jsonUser(u, u.appSubscriptions[0]));
  }

  async updateUser(id: string, d: any) {
    const adminId = BigInt(id);
    const current = await this.p.admin.findUnique({ where: { id: adminId } });
    if (!current) throw new NotFoundException('User not found');

    const data: any = {};
    if (d.name !== undefined) data.name = d.name.trim();
    if (d.phone !== undefined) data.phone = d.phone.trim();
    if (d.email !== undefined) {
      const email = d.email.trim().toLowerCase();
      const duplicate = await this.p.admin.findFirst({ where: { email, NOT: { id: adminId } } });
      if (duplicate) throw new ConflictException('Email already registered');
      data.email = email;
    }
    if (d.type !== undefined) data.type = d.type.toUpperCase();
    if (!Object.keys(data).length) throw new BadRequestException('No editable fields supplied');

    const u = await this.p.admin.update({ where: { id: adminId }, data });
    const subscription = await this.p.appSubscription.findFirst({ where: { adminId }, orderBy: { expiryDate: 'desc' } });
    return this.jsonUser(u, subscription);
  }

  async resetPassword(id: string, password: string) {
    const adminId = BigInt(id);
    const current = await this.p.admin.findUnique({ where: { id: adminId } });
    if (!current) throw new NotFoundException('User not found');
    const passwordHash = await bcrypt.hash(password, 12);
    await this.p.admin.update({ where: { id: adminId }, data: { passwordHash } });
    return { success: true, message: 'Password reset successfully' };
  }

  async setStatus(id: string, status: string) {
    const u = await this.p.admin.update({ where: { id: BigInt(id) }, data: { accountStatus: status.toUpperCase() } }).catch(() => { throw new NotFoundException('User not found'); });
    return this.jsonUser(u);
  }

  async assignOrRenew(id: string, planType: PlanType) {
    const adminId = BigInt(id);
    const u = await this.p.admin.findUnique({ where: { id: adminId } });
    if (!u) throw new NotFoundException('User not found');
    if (u.type !== 'ONLINE') throw new BadRequestException('Subscriptions apply only to online users');
    const cfg = PLAN[planType];
    if (!cfg) throw new BadRequestException('Invalid plan type');
    const now = new Date();
    const latest = await this.p.appSubscription.findFirst({ where: { adminId, status: 'ACTIVE' }, orderBy: { expiryDate: 'desc' } });
    const start = now;
    const expiry = latest && latest.expiryDate > now ? new Date(latest.expiryDate) : new Date(now);
    expiry.setMonth(expiry.getMonth() + cfg.months);
    const sub = await this.p.$transaction(async tx => {
      await tx.appSubscription.updateMany({ where: { adminId, status: 'ACTIVE' }, data: { status: 'RENEWED' } });
      return tx.appSubscription.create({ data: { adminId, planType: planType.toUpperCase(), price: cfg.price, startDate: start, expiryDate: expiry, status: 'ACTIVE' } });
    });
    return this.jsonUser(u, sub);
  }
}
