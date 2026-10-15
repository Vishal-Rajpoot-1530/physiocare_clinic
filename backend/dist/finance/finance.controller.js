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
exports.FinanceController = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const jwt_guard_1 = require("../auth/jwt.guard");
let FinanceController = class FinanceController {
    constructor(p) {
        this.p = p;
    }
    async all(r, m) { const rows = await this.p.finance.findMany({ where: { adminId: r.user.id, ...(m ? { memberId: BigInt(m) } : {}) }, orderBy: { paidAt: 'desc' } }); return rows.map(x => ({ id: Number(x.id), admin_id: Number(x.adminId), member_id: x.memberId == null ? null : Number(x.memberId), member_name: x.memberName, amount: Number(x.amount), type: x.type, plan: x.plan, description: x.description, paid_at: x.paidAt.toISOString(), method: x.method })); }
};
exports.FinanceController = FinanceController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('member_id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], FinanceController.prototype, "all", null);
exports.FinanceController = FinanceController = __decorate([
    (0, common_1.UseGuards)(jwt_guard_1.JwtGuard),
    (0, common_1.Controller)('finance'),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], FinanceController);
//# sourceMappingURL=finance.controller.js.map