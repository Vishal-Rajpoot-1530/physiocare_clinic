"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SuperAdminGuard = void 0;
const common_1 = require("@nestjs/common");
const crypto_1 = require("crypto");
let SuperAdminGuard = class SuperAdminGuard {
    canActivate(context) {
        const expected = process.env.SUPER_ADMIN_KEY || '';
        const supplied = String(context.switchToHttp().getRequest().headers['x-super-admin-key'] || '');
        if (!expected || !supplied)
            throw new common_1.UnauthorizedException('Super admin authorization required');
        const a = Buffer.from(expected), b = Buffer.from(supplied);
        if (a.length !== b.length || !(0, crypto_1.timingSafeEqual)(a, b))
            throw new common_1.UnauthorizedException('Invalid super admin authorization');
        return true;
    }
};
exports.SuperAdminGuard = SuperAdminGuard;
exports.SuperAdminGuard = SuperAdminGuard = __decorate([
    (0, common_1.Injectable)()
], SuperAdminGuard);
//# sourceMappingURL=super-admin.guard.js.map