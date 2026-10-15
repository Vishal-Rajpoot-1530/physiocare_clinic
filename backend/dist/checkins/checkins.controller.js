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
exports.CheckinsController = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const jwt_guard_1 = require("../auth/jwt.guard");
const serialize_1 = require("../common/serialize");
let CheckinsController = class CheckinsController {
    constructor(p) {
        this.p = p;
    }
    async find(r, raw = '') { const s = raw.trim(); let m = await this.p.member.findFirst({ where: { adminId: r.user.id, keycard: s } }); if (!m) {
        const mt = /^(?:mv-?)?0*(\d+)$/i.exec(s);
        if (mt)
            m = await this.p.member.findFirst({ where: { adminId: r.user.id, id: BigInt(mt[1]) } });
    } if (!m)
        m = await this.p.member.findFirst({ where: { adminId: r.user.id, phone: s } }); return m ? (0, serialize_1.memberJson)(m) : null; }
    async add(r, id) { const memberId = BigInt(id), m = await this.p.member.findFirst({ where: { id: memberId, adminId: r.user.id } }); if (!m)
        return { created: false }; const start = new Date(); start.setHours(0, 0, 0, 0); const end = new Date(start); end.setDate(end.getDate() + 1); if (await this.p.checkin.count({ where: { adminId: r.user.id, memberId, checkedAt: { gte: start, lt: end } } }))
        return { created: false }; await this.p.checkin.create({ data: { adminId: r.user.id, memberId } }); return { created: true }; }
    async today(r) { const start = new Date(); start.setHours(0, 0, 0, 0); const end = new Date(start); end.setDate(end.getDate() + 1); const rows = await this.p.checkin.findMany({ where: { adminId: r.user.id, checkedAt: { gte: start, lt: end } }, include: { member: true }, orderBy: { checkedAt: 'desc' } }); return rows.map(x => ({ at: x.checkedAt.toISOString(), name: x.member.name, id: Number(x.memberId) })); }
    async stats(r, id) { const rows = await this.p.checkin.findMany({ where: { adminId: r.user.id, memberId: BigInt(id) }, select: { checkedAt: true } }); const days = new Set(rows.map(x => { const d = new Date(x.checkedAt); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`; })); let cur = new Date(); const key = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`; if (!days.has(key(cur)))
        cur.setDate(cur.getDate() - 1); let streak = 0; while (days.has(key(cur))) {
        streak++;
        cur.setDate(cur.getDate() - 1);
    } return { total: rows.length, streak }; }
};
exports.CheckinsController = CheckinsController;
__decorate([
    (0, common_1.Get)('find'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('code')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], CheckinsController.prototype, "find", null);
__decorate([
    (0, common_1.Post)(':memberId'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('memberId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CheckinsController.prototype, "add", null);
__decorate([
    (0, common_1.Get)('today/list'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CheckinsController.prototype, "today", null);
__decorate([
    (0, common_1.Get)(':memberId/stats'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('memberId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CheckinsController.prototype, "stats", null);
exports.CheckinsController = CheckinsController = __decorate([
    (0, common_1.UseGuards)(jwt_guard_1.JwtGuard),
    (0, common_1.Controller)('checkins'),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CheckinsController);
//# sourceMappingURL=checkins.controller.js.map