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
Object.defineProperty(exports, "__esModule", { value: true });
exports.JwtGuard = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const prisma_service_1 = require("../prisma/prisma.service");
let JwtGuard = class JwtGuard {
    constructor(jwt, p) {
        this.jwt = jwt;
        this.p = p;
    }
    async canActivate(c) {
        const r = c.switchToHttp().getRequest();
        const h = r.headers.authorization || '';
        if (!h.startsWith('Bearer '))
            throw new common_1.UnauthorizedException();
        try {
            const x = await this.jwt.verifyAsync(h.slice(7), { secret: process.env.JWT_SECRET });
            const id = BigInt(x.sub);
            const admin = await this.p.admin.findUnique({ where: { id } });
            if (!admin || admin.accountStatus !== 'ACTIVE') {
                throw new common_1.UnauthorizedException('Account is inactive');
            }
            if (admin.type === 'ONLINE') {
                const now = new Date();
                const subscription = await this.p.appSubscription.findFirst({
                    where: { adminId: id, status: 'ACTIVE', expiryDate: { gt: now } },
                    orderBy: { expiryDate: 'desc' },
                });
                if (!subscription)
                    throw new common_1.UnauthorizedException('Subscription expired or not assigned');
            }
            r.user = { id, email: admin.email, type: admin.type };
            return true;
        }
        catch (e) {
            if (e instanceof common_1.UnauthorizedException)
                throw e;
            throw new common_1.UnauthorizedException();
        }
    }
};
exports.JwtGuard = JwtGuard;
exports.JwtGuard = JwtGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [jwt_1.JwtService, prisma_service_1.PrismaService])
], JwtGuard);
//# sourceMappingURL=jwt.guard.js.map