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
exports.SuperAdminController = void 0;
const common_1 = require("@nestjs/common");
const class_validator_1 = require("class-validator");
const super_admin_guard_1 = require("./super-admin.guard");
const super_admin_service_1 = require("./super-admin.service");
class CreateUserDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    (0, class_validator_1.MaxLength)(120),
    __metadata("design:type", String)
], CreateUserDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    (0, class_validator_1.MaxLength)(40),
    __metadata("design:type", String)
], CreateUserDto.prototype, "phone", void 0);
__decorate([
    (0, class_validator_1.IsEmail)(),
    __metadata("design:type", String)
], CreateUserDto.prototype, "email", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(4),
    __metadata("design:type", String)
], CreateUserDto.prototype, "password", void 0);
__decorate([
    (0, class_validator_1.IsIn)(['online', 'offline', 'ONLINE', 'OFFLINE']),
    __metadata("design:type", String)
], CreateUserDto.prototype, "type", void 0);
class UpdateUserDto {
}
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    (0, class_validator_1.MaxLength)(120),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    (0, class_validator_1.MaxLength)(40),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "phone", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEmail)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "email", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsIn)(['online', 'offline', 'ONLINE', 'OFFLINE']),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "type", void 0);
class ResetPasswordDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(4),
    __metadata("design:type", String)
], ResetPasswordDto.prototype, "password", void 0);
class StatusDto {
}
__decorate([
    (0, class_validator_1.IsIn)(['active', 'temporarily_inactive', 'ACTIVE', 'TEMPORARILY_INACTIVE']),
    __metadata("design:type", String)
], StatusDto.prototype, "status", void 0);
class SubscriptionDto {
}
__decorate([
    (0, class_validator_1.IsIn)(['monthly', 'quarterly', 'yearly']),
    __metadata("design:type", String)
], SubscriptionDto.prototype, "planType", void 0);
let SuperAdminController = class SuperAdminController {
    constructor(s) {
        this.s = s;
    }
    create(d) { return this.s.createUser(d); }
    users() { return this.s.users(); }
    update(id, d) { return this.s.updateUser(id, d); }
    resetPassword(id, d) { return this.s.resetPassword(id, d.password); }
    status(id, d) { return this.s.setStatus(id, d.status); }
    subscription(id, d) { return this.s.assignOrRenew(id, d.planType); }
    renew(id, d) { return this.s.assignOrRenew(id, d.planType); }
};
exports.SuperAdminController = SuperAdminController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateUserDto]),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "users", null);
__decorate([
    (0, common_1.Patch)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, UpdateUserDto]),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "update", null);
__decorate([
    (0, common_1.Post)(':id/reset-password'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, ResetPasswordDto]),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "resetPassword", null);
__decorate([
    (0, common_1.Patch)(':id/status'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, StatusDto]),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "status", null);
__decorate([
    (0, common_1.Post)(':id/subscription'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, SubscriptionDto]),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "subscription", null);
__decorate([
    (0, common_1.Post)(':id/subscription/renew'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, SubscriptionDto]),
    __metadata("design:returntype", void 0)
], SuperAdminController.prototype, "renew", null);
exports.SuperAdminController = SuperAdminController = __decorate([
    (0, common_1.UseGuards)(super_admin_guard_1.SuperAdminGuard),
    (0, common_1.Controller)('super-admin/users'),
    __metadata("design:paramtypes", [super_admin_service_1.SuperAdminService])
], SuperAdminController);
//# sourceMappingURL=super-admin.controller.js.map