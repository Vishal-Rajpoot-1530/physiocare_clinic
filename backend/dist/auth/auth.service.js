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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const prisma_service_1 = require("../prisma/prisma.service");
const bcrypt = __importStar(require("bcryptjs"));
let AuthService = class AuthService {
    constructor(p, jwt) {
        this.p = p;
        this.jwt = jwt;
    }
    async register(d) {
        const email = d.email.trim().toLowerCase();
        if (await this.p.admin.findUnique({ where: { email } })) {
            throw new common_1.ConflictException('Email already registered');
        }
        const hash = await bcrypt.hash(d.password, 12);
        await this.p.$transaction(async (tx) => {
            const a = await tx.admin.create({ data: { name: d.name, email, phone: (d.phone || '').trim(), type: (d.type || 'OFFLINE').toUpperCase(), accountStatus: 'ACTIVE', passwordHash: hash } });
            await tx.plan.createMany({
                data: [[1, 'DAY', 400], [1, 'WEEK', 2500], [1, 'MONTH', 10000], [3, 'MONTH', 25000]].map(([durationValue, durationUnit, fee]) => ({
                    adminId: a.id,
                    durationValue,
                    durationUnit,
                    fee,
                })),
            });
        });
        return { success: true };
    }
    async login(d) {
        const email = d.email.trim().toLowerCase();
        const u = await this.p.admin.findUnique({ where: { email } });
        if (!u || !await bcrypt.compare(d.password, u.passwordHash)) {
            throw new common_1.UnauthorizedException('Invalid email or password');
        }
        if (u.accountStatus !== 'ACTIVE')
            throw new common_1.UnauthorizedException('Account is inactive');
        let subscription = null;
        if (u.type === 'ONLINE') {
            subscription = await this.p.appSubscription.findFirst({
                where: { adminId: u.id, status: 'ACTIVE', expiryDate: { gt: new Date() } },
                orderBy: { expiryDate: 'desc' },
            });
            if (!subscription)
                throw new common_1.UnauthorizedException('Subscription expired or not assigned');
        }
        const token = await this.jwt.signAsync({ sub: u.id.toString(), email: u.email }, { secret: process.env.JWT_SECRET, expiresIn: (process.env.JWT_EXPIRES_IN || '30d') });
        return { token, user: { id: Number(u.id), name: u.name, email: u.email, phone: u.phone, type: u.type.toLowerCase(), status: u.accountStatus.toLowerCase(), ...(subscription ? { subscription: { plan_type: subscription.planType.toLowerCase(), start_date: subscription.startDate.toISOString(), expiry_date: subscription.expiryDate.toISOString(), status: subscription.status.toLowerCase() } } : {}) } };
    }
    async getProfile(adminId) {
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
    async updateProfile(adminId, name) {
        const trimmedName = name.trim();
        if (!trimmedName) {
            throw new common_1.BadRequestException('Name cannot be empty.');
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
    async changePassword(adminId, currentPassword, newPassword) {
        const admin = await this.p.admin.findUniqueOrThrow({ where: { id: adminId } });
        if (!await bcrypt.compare(currentPassword, admin.passwordHash)) {
            throw new common_1.UnauthorizedException('Current password is incorrect.');
        }
        const passwordHash = await bcrypt.hash(newPassword, 12);
        await this.p.admin.update({ where: { id: adminId }, data: { passwordHash } });
        return { success: true };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService, jwt_1.JwtService])
], AuthService);
//# sourceMappingURL=auth.service.js.map