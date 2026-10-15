"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MembersService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const serialize_1 = require("../common/serialize");
const fs_1 = require("fs");
const path_1 = __importDefault(require("path"));
function durationFrom(body) {
    const value = Number(body.duration_value ?? body.duration_months);
    const unit = String(body.duration_unit ?? 'MONTH').toUpperCase();
    if (!Number.isInteger(value) || value < 1 || value > 1200) {
        throw new common_1.BadRequestException('Duration must be a whole number from 1 to 1200.');
    }
    if (unit !== 'DAY' && unit !== 'WEEK' && unit !== 'MONTH') {
        throw new common_1.BadRequestException('Duration unit must be DAY, WEEK, or MONTH.');
    }
    return { value, unit };
}
function addDuration(date, value, unit) {
    const result = new Date(date);
    if (unit === 'DAY') {
        result.setDate(result.getDate() + value);
    }
    else if (unit === 'WEEK') {
        result.setDate(result.getDate() + value * 7);
    }
    else {
        const day = result.getDate();
        result.setDate(1);
        result.setMonth(result.getMonth() + value);
        const lastDay = new Date(result.getFullYear(), result.getMonth() + 1, 0).getDate();
        result.setDate(Math.min(day, lastDay));
    }
    return result;
}
function durationLabel(value, unit) {
    const name = unit.toLowerCase();
    return `${value} ${name}${value === 1 ? '' : 's'}`;
}
let MembersService = class MembersService {
    constructor(p) {
        this.p = p;
    }
    async all(adminId) {
        return Promise.all((await this.p.member.findMany({
            where: { adminId },
            orderBy: { name: 'asc' },
        })).map(serialize_1.memberJson));
    }
    async one(adminId, id) {
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member)
            throw new common_1.NotFoundException('Member not found');
        return (0, serialize_1.memberJson)(member);
    }
    async key(adminId, code = '', exceptId) {
        if (!code.trim())
            return { taken: false };
        const count = await this.p.member.count({
            where: {
                adminId,
                keycard: { equals: code.trim() },
                ...(exceptId ? { NOT: { id: BigInt(exceptId) } } : {}),
            },
        });
        return { taken: count > 0 };
    }
    body(adminId, body) {
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
    async add(adminId, body) {
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
        }
        catch (error) {
            if (error.code === 'P2002') {
                throw new common_1.ConflictException('Keycard already in use');
            }
            throw error;
        }
    }
    async update(adminId, id, body) {
        const existing = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!existing)
            throw new common_1.NotFoundException('Member not found');
        const data = this.body(adminId, body);
        delete data.adminId;
        delete data.createdAt;
        try {
            await this.p.member.update({ where: { id: existing.id }, data });
            return { success: true };
        }
        catch (error) {
            if (error.code === 'P2002') {
                throw new common_1.ConflictException('Keycard already in use');
            }
            throw error;
        }
    }
    async renew(adminId, id, body) {
        const duration = durationFrom(body);
        return this.p.$transaction(async (tx) => {
            const member = await tx.member.findFirst({
                where: { id: BigInt(id), adminId },
            });
            if (!member)
                throw new common_1.NotFoundException('Member not found');
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
    async adjustment(adminId, id, body) {
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member)
            throw new common_1.NotFoundException('Member not found');
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
    async status(adminId, id, active) {
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member)
            throw new common_1.NotFoundException('Member not found');
        await this.p.member.update({
            where: { id: member.id },
            data: { status: active ? 'active' : 'inactive' },
        });
        return { success: true };
    }
    async pr(adminId, id, kg) {
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member)
            throw new common_1.NotFoundException('Member not found');
        await this.p.member.update({
            where: { id: member.id },
            data: { prKg: kg },
        });
        return { success: true };
    }
    async photo(adminId, id, file) {
        if (!file)
            throw new common_1.BadRequestException('Photo required');
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member) {
            await fs_1.promises.unlink(file.path).catch(() => { });
            throw new common_1.NotFoundException('Member not found');
        }
        await this.p.member.update({
            where: { id: member.id },
            data: { photoPath: file.filename },
        });
        if (member.photoPath) {
            await fs_1.promises
                .unlink(path_1.default.join(serialize_1.uploadsDir, path_1.default.basename(member.photoPath)))
                .catch(() => { });
        }
        return { success: true };
    }
    async del(adminId, id) {
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member)
            return { deleted: 0 };
        await this.p.member.delete({ where: { id: member.id } });
        if (member.photoPath) {
            await fs_1.promises
                .unlink(path_1.default.join(serialize_1.uploadsDir, path_1.default.basename(member.photoPath)))
                .catch(() => { });
        }
        return { deleted: 1 };
    }
    async clean(adminId) {
        const photos = await this.p.member.findMany({
            where: { adminId, status: 'inactive' },
            select: { photoPath: true },
        });
        const result = await this.p.member.deleteMany({
            where: { adminId, status: 'inactive' },
        });
        for (const member of photos) {
            if (member.photoPath) {
                await fs_1.promises
                    .unlink(path_1.default.join(serialize_1.uploadsDir, path_1.default.basename(member.photoPath)))
                    .catch(() => { });
            }
        }
        return { deleted: result.count };
    }
    async notes(adminId, id) {
        return (await this.p.note.findMany({
            where: { adminId, memberId: BigInt(id) },
            orderBy: { createdAt: 'desc' },
        })).map((note) => ({
            id: Number(note.id),
            member_id: Number(note.memberId),
            title: note.title,
            body: note.body || '',
            tags: note.tags || '',
            created_at: note.createdAt.toISOString(),
        }));
    }
    async addNote(adminId, id, body) {
        const member = await this.p.member.findFirst({
            where: { id: BigInt(id), adminId },
        });
        if (!member)
            throw new common_1.NotFoundException('Member not found');
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
};
exports.MembersService = MembersService;
exports.MembersService = MembersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MembersService);
//# sourceMappingURL=members.service.js.map