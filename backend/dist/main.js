"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const helmet_1 = __importDefault(require("helmet"));
const app_module_1 = require("./app.module");
async function bootstrap() { const app = await core_1.NestFactory.create(app_module_1.AppModule); app.setGlobalPrefix('api/v1'); app.use((0, helmet_1.default)({ crossOriginResourcePolicy: false })); app.enableCors({ origin: true, credentials: true }); app.useGlobalPipes(new common_1.ValidationPipe({ whitelist: true, transform: true })); await app.listen(Number(process.env.PORT || 3000), '0.0.0.0'); console.log(`Power Cave NestJS API running on ${process.env.PORT || 3000}`); }
bootstrap();
//# sourceMappingURL=main.js.map