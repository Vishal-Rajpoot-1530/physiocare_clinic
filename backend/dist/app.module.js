"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const prisma_module_1 = require("./prisma/prisma.module");
const auth_module_1 = require("./auth/auth.module");
const members_module_1 = require("./members/members.module");
const finance_module_1 = require("./finance/finance.module");
const settings_module_1 = require("./settings/settings.module");
const checkins_module_1 = require("./checkins/checkins.module");
const health_controller_1 = require("./health.controller");
const request_logger_middleware_1 = require("./common/request-logger.middleware");
const super_admin_module_1 = require("./super-admin/super-admin.module");
let AppModule = class AppModule {
    configure(consumer) { consumer.apply(request_logger_middleware_1.RequestLoggerMiddleware).forRoutes('*'); }
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({ imports: [config_1.ConfigModule.forRoot({ isGlobal: true }), prisma_module_1.PrismaModule, auth_module_1.AuthModule, members_module_1.MembersModule, finance_module_1.FinanceModule, settings_module_1.SettingsModule, checkins_module_1.CheckinsModule, super_admin_module_1.SuperAdminModule], controllers: [health_controller_1.HealthController] })
], AppModule);
//# sourceMappingURL=app.module.js.map