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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SettingsController = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const jwt_guard_1 = require("../auth/jwt.guard");
let SettingsController = class SettingsController {
    constructor(p) {
        this.p = p;
    }
    async get(r) {
        const [admin, plans] = await Promise.all([
            this.p.admin.findUniqueOrThrow({ where: { id: r.user.id } }),
            this.p.plan.findMany({
                where: { adminId: r.user.id },
                orderBy: [{ durationUnit: 'asc' }, { durationValue: 'asc' }],
            }),
        ]);
        return {
            revenue_goal: Number(admin.revenueGoal),
            plans: plans.map((plan) => ({
                duration_value: plan.durationValue,
                duration_unit: plan.durationUnit,
                fee: Number(plan.fee),
            })),
        };
    }
    async goal(r, body) {
        await this.p.admin.update({
            where: { id: r.user.id },
            data: { revenueGoal: body.value },
        });
        return { success: true };
    }
    async plans(r, body) {
        await this.p.$transaction(async (tx) => {
            await tx.plan.deleteMany({ where: { adminId: r.user.id } });
            if (body.plans?.length) {
                await tx.plan.createMany({
                    data: body.plans.map((plan) => ({
                        adminId: r.user.id,
                        durationValue: Number(plan.duration_value),
                        durationUnit: String(plan.duration_unit).toUpperCase(),
                        fee: plan.fee,
                    })),
                });
            }
        });
        return { success: true };
    }
};
exports.SettingsController = SettingsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "get", null);
__decorate([
    (0, common_1.Put)('goal'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "goal", null);
__decorate([
    (0, common_1.Put)('plans'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "plans", null);
exports.SettingsController = SettingsController = __decorate([
    (0, common_1.UseGuards)(jwt_guard_1.JwtGuard),
    (0, common_1.Controller)('settings'),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SettingsController);
//# sourceMappingURL=settings.controller.js.map