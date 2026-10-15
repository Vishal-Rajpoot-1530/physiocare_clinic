"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SuperAdminService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const bcrypt = __importStar(require("bcryptjs"));
const PLAN = {
    monthly: { months: 1, price: 150 },
    quarterly: { months: 3, price: 300 },
    yearly: { months: 12, price: 1000 },
};
let SuperAdminService = class SuperAdminService {
    constructor(p) {
        this.p = p;
    }
    jsonUser(u, subscription) {
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
    async createUser(d) {
        const email = d.email.trim().toLowerCase();
        if (await this.p.admin.findUnique({ where: { email } }))
            throw new common_1.ConflictException('Email already registered');
        const type = d.type.toUpperCase();
        const passwordHash = await bcrypt.hash(d.password, 12);
        const u = await this.p.$transaction(async (tx) => {
            const admin = await tx.admin.create({ data: { name: d.name.trim(), phone: d.phone.trim(), email, passwordHash, type, accountStatus: 'ACTIVE' } });
            await tx.plan.createMany({ data: [[1, 'DAY', 400], [1, 'WEEK', 2500], [1, 'MONTH', 10000], [3, 'MONTH', 25000]].map(([durationValue, durationUnit, fee]) => ({ adminId: admin.id, durationValue, durationUnit, fee })) });
            return admin;
        });
        return this.jsonUser(u);
    }
    async users() {
        const users = await this.p.admin.findMany({ orderBy: { createdAt: 'desc' }, include: { appSubscriptions: { orderBy: { expiryDate: 'desc' }, take: 1 } } });
        return users.map(u => this.jsonUser(u, u.appSubscriptions[0]));
    }
    async updateUser(id, d) {
        const adminId = BigInt(id);
        const current = await this.p.admin.findUnique({ where: { id: adminId } });
        if (!current)
            throw new common_1.NotFoundException('User not found');
        const data = {};
        if (d.name !== undefined)
            data.name = d.name.trim();
        if (d.phone !== undefined)
            data.phone = d.phone.trim();
        if (d.email !== undefined) {
            const email = d.email.trim().toLowerCase();
            const duplicate = await this.p.admin.findFirst({ where: { email, NOT: { id: adminId } } });
            if (duplicate)
                throw new common_1.ConflictException('Email already registered');
            data.email = email;
        }
        if (d.type !== undefined)
            data.type = d.type.toUpperCase();
        if (!Object.keys(data).length)
            throw new common_1.BadRequestException('No editable fields supplied');
        const u = await this.p.admin.update({ where: { id: adminId }, data });
        const subscription = await this.p.appSubscription.findFirst({ where: { adminId }, orderBy: { expiryDate: 'desc' } });
        return this.jsonUser(u, subscription);
    }
    async resetPassword(id, password) {
        const adminId = BigInt(id);
        const current = await this.p.admin.findUnique({ where: { id: adminId } });
        if (!current)
            throw new common_1.NotFoundException('User not found');
        const passwordHash = await bcrypt.hash(password, 12);
        await this.p.admin.update({ where: { id: adminId }, data: { passwordHash } });
        return { success: true, message: 'Password reset successfully' };
    }
    async setStatus(id, status) {
        const u = await this.p.admin.update({ where: { id: BigInt(id) }, data: { accountStatus: status.toUpperCase() } }).catch(() => { throw new common_1.NotFoundException('User not found'); });
        return this.jsonUser(u);
    }
    async assignOrRenew(id, planType) {
        const adminId = BigInt(id);
        const u = await this.p.admin.findUnique({ where: { id: adminId } });
        if (!u)
            throw new common_1.NotFoundException('User not found');
        if (u.type !== 'ONLINE')
            throw new common_1.BadRequestException('Subscriptions apply only to online users');
        const cfg = PLAN[planType];
        if (!cfg)
            throw new common_1.BadRequestException('Invalid plan type');
        const now = new Date();
        const latest = await this.p.appSubscription.findFirst({ where: { adminId, status: 'ACTIVE' }, orderBy: { expiryDate: 'desc' } });
        const start = now;
        const expiry = latest && latest.expiryDate > now ? new Date(latest.expiryDate) : new Date(now);
        expiry.setMonth(expiry.getMonth() + cfg.months);
        const sub = await this.p.$transaction(async (tx) => {
            await tx.appSubscription.updateMany({ where: { adminId, status: 'ACTIVE' }, data: { status: 'RENEWED' } });
            return tx.appSubscription.create({ data: { adminId, planType: planType.toUpperCase(), price: cfg.price, startDate: start, expiryDate: expiry, status: 'ACTIVE' } });
        });
        return this.jsonUser(u, sub);
    }
};
exports.SuperAdminService = SuperAdminService;
exports.SuperAdminService = SuperAdminService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SuperAdminService);
//# sourceMappingURL=super-admin.service.js.map