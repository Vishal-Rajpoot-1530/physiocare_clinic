import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { memberJson, uploadsDir } from '../common/serialize';
import { promises as fs } from 'fs';
import path from 'path';

type DurationUnit = 'DAY' | 'WEEK' | 'MONTH';

function durationFrom(body: any): { value: number; unit: DurationUnit } {
  const value = Number(body.duration_value ?? body.duration_months);
  const unit = String(body.duration_unit ?? 'MONTH').toUpperCase();
  if (!Number.isInteger(value) || value < 1 || value > 1200) {
    throw new BadRequestException('Duration must be a whole number from 1 to 1200.');
  }
  if (unit !== 'DAY' && unit !== 'WEEK' && unit !== 'MONTH') {
    throw new BadRequestException('Duration unit must be DAY, WEEK, or MONTH.');
  }
  return { value, unit };
}

function addDuration(date: Date, value: number, unit: DurationUnit): Date {
  const result = new Date(date);
  if (unit === 'DAY') {
    result.setDate(result.getDate() + value);
  } else if (unit === 'WEEK') {
    result.setDate(result.getDate() + value * 7);
  } else {
    const day = result.getDate();
    result.setDate(1);
    result.setMonth(result.getMonth() + value);
    const lastDay = new Date(
      result.getFullYear(),
      result.getMonth() + 1,
      0,
    ).getDate();
    result.setDate(Math.min(day, lastDay));
  }
  return result;
}

function durationLabel(value: number, unit: DurationUnit): string {
  const name = unit.toLowerCase();
  return `${value} ${name}${value === 1 ? '' : 's'}`;
}

@Injectable()
export class MembersService {
  constructor(private p: PrismaService) {}

  async all(adminId: bigint) {
    return Promise.all(
      (
        await this.p.member.findMany({
          where: { adminId },
          orderBy: { name: 'asc' },
        })
      ).map(memberJson),
    );
  }

  async one(adminId: bigint, id: string) {
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) throw new NotFoundException('Member not found');
    return memberJson(member);
  }

  async key(adminId: bigint, code = '', exceptId?: string) {
    if (!code.trim()) return { taken: false };
    const count = await this.p.member.count({
      where: {
        adminId,
        keycard: { equals: code.trim() },
        ...(exceptId ? { NOT: { id: BigInt(exceptId) } } : {}),
      },
    });
    return { taken: count > 0 };
  }

  private body(adminId: bigint, body: any) {
    const duration = durationFrom(body);
    return {
      adminId,
      name: body.name,
      email: body.email || '',
      phone: body.phone || '',
      gender: body.gender,
      age: Number(body.age),
      plan: body.plan,
      durationValue: duration.value,
      durationUnit: duration.unit,
      fee: body.fee,
      joiningDate: new Date(body.joining_date),
      expiryDate: new Date(body.expiry_date),
      status: body.status || 'active',
      notesText: body.notes || '',
      keycard: (body.keycard || '').trim() || null,
      prKg: body.pr_kg || 0,
      createdAt: body.created_at ? new Date(body.created_at) : new Date(),
    };
  }

  async add(adminId: bigint, body: any) {
    try {
      return await this.p.$transaction(async (tx) => {
        const member = await tx.member.create({
          data: this.body(adminId, body),
        });
        await tx.finance.create({
          data: {
            adminId,
            memberId: member.id,
            memberName: member.name,
            amount: body.fee,
            type: 'joining',
            plan: body.plan,
            description: 'Initial membership payment',
            method: body.method || 'Cash',
          },
        });
        return { id: Number(member.id) };
      });
    } catch (error: any) {
      if (error.code === 'P2002') {
        throw new ConflictException('Keycard already in use');
      }
      throw error;
    }
  }

  async update(adminId: bigint, id: string, body: any) {
    const existing = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!existing) throw new NotFoundException('Member not found');
    const data = this.body(adminId, body);
    delete (data as { adminId?: bigint }).adminId;
    delete (data as { createdAt?: Date }).createdAt;
    try {
      await this.p.member.update({ where: { id: existing.id }, data });
      return { success: true };
    } catch (error: any) {
      if (error.code === 'P2002') {
        throw new ConflictException('Keycard already in use');
      }
      throw error;
    }
  }

  async renew(adminId: bigint, id: string, body: any) {
    const duration = durationFrom(body);
    return this.p.$transaction(async (tx) => {
      const member = await tx.member.findFirst({
        where: { id: BigInt(id), adminId },
      });
      if (!member) throw new NotFoundException('Member not found');
      const now = new Date();
      const start = member.expiryDate > now ? member.expiryDate : now;
      const expiryDate = addDuration(start, duration.value, duration.unit);
      await tx.member.update({
        where: { id: member.id },
        data: {
          plan: body.plan,
          durationValue: duration.value,
          durationUnit: duration.unit,
          fee: body.amount,
          expiryDate,
          status: 'active',
        },
      });
      await tx.finance.create({
        data: {
          adminId,
          memberId: member.id,
          memberName: member.name,
          amount: body.amount,
          type: 'renewal',
          plan: body.plan,
          description: `Membership renewal (${durationLabel(duration.value, duration.unit)})`,
          method: body.method || 'Cash',
        },
      });
      return { success: true };
    });
  }

  async adjustment(adminId: bigint, id: string, body: any) {
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) throw new NotFoundException('Member not found');
    await this.p.finance.create({
      data: {
        adminId,
        memberId: member.id,
        memberName: member.name,
        amount: body.amount,
        type: 'adjustment',
        plan: member.plan,
        description: body.note || 'Payment adjustment',
        method: body.method || 'Cash',
      },
    });
    return { success: true };
  }

  async status(adminId: bigint, id: string, active: boolean) {
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) throw new NotFoundException('Member not found');
    await this.p.member.update({
      where: { id: member.id },
      data: { status: active ? 'active' : 'inactive' },
    });
    return { success: true };
  }

  async pr(adminId: bigint, id: string, kg: any) {
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) throw new NotFoundException('Member not found');
    await this.p.member.update({
      where: { id: member.id },
      data: { prKg: kg },
    });
    return { success: true };
  }

  async photo(adminId: bigint, id: string, file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Photo required');
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) {
      await fs.unlink(file.path).catch(() => {});
      throw new NotFoundException('Member not found');
    }
    await this.p.member.update({
      where: { id: member.id },
      data: { photoPath: file.filename },
    });
    if (member.photoPath) {
      await fs
        .unlink(path.join(uploadsDir, path.basename(member.photoPath)))
        .catch(() => {});
    }
    return { success: true };
  }

  async del(adminId: bigint, id: string) {
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) return { deleted: 0 };
    await this.p.member.delete({ where: { id: member.id } });
    if (member.photoPath) {
      await fs
        .unlink(path.join(uploadsDir, path.basename(member.photoPath)))
        .catch(() => {});
    }
    return { deleted: 1 };
  }

  async clean(adminId: bigint) {
    const photos = await this.p.member.findMany({
      where: { adminId, status: 'inactive' },
      select: { photoPath: true },
    });
    const result = await this.p.member.deleteMany({
      where: { adminId, status: 'inactive' },
    });
    for (const member of photos) {
      if (member.photoPath) {
        await fs
          .unlink(path.join(uploadsDir, path.basename(member.photoPath)))
          .catch(() => {});
      }
    }
    return { deleted: result.count };
  }

  async notes(adminId: bigint, id: string) {
    return (
      await this.p.note.findMany({
        where: { adminId, memberId: BigInt(id) },
        orderBy: { createdAt: 'desc' },
      })
    ).map((note) => ({
      id: Number(note.id),
      member_id: Number(note.memberId),
      title: note.title,
      body: note.body || '',
      tags: note.tags || '',
      created_at: note.createdAt.toISOString(),
    }));
  }

  async addNote(adminId: bigint, id: string, body: any) {
    const member = await this.p.member.findFirst({
      where: { id: BigInt(id), adminId },
    });
    if (!member) throw new NotFoundException('Member not found');
    await this.p.note.create({
      data: {
        adminId,
        memberId: member.id,
        title: body.title,
        body: body.body || '',
        tags: body.tags || '',
      },
    });
    return { success: true };
  }
}
