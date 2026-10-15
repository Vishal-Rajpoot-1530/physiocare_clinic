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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MembersController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const multer_1 = require("multer");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const jwt_guard_1 = require("../auth/jwt.guard");
const members_service_1 = require("./members.service");
const serialize_1 = require("../common/serialize");
fs_1.default.mkdirSync(serialize_1.uploadsDir, { recursive: true });
let MembersController = class MembersController {
    constructor(s) {
        this.s = s;
    }
    all(r) { return this.s.all(r.user.id); }
    key(r, c, e) { return this.s.key(r.user.id, c, e); }
    clean(r) { return this.s.clean(r.user.id); }
    one(r, id) { return this.s.one(r.user.id, id); }
    add(r, b) { return this.s.add(r.user.id, b); }
    update(r, id, b) { return this.s.update(r.user.id, id, b); }
    renew(r, id, b) { return this.s.renew(r.user.id, id, b); }
    adjustment(r, id, b) { return this.s.adjustment(r.user.id, id, b); }
    status(r, id, b) { return this.s.status(r.user.id, id, b.active); }
    pr(r, id, b) { return this.s.pr(r.user.id, id, b.kg); }
    photo(r, id, f) { return this.s.photo(r.user.id, id, f); }
    del(r, id) { return this.s.del(r.user.id, id); }
    notes(r, id) { return this.s.notes(r.user.id, id); }
    addNote(r, id, b) { return this.s.addNote(r.user.id, id, b); }
};
exports.MembersController = MembersController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "all", null);
__decorate([
    (0, common_1.Get)('keycard/check'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Query)('code')),
    __param(2, (0, common_1.Query)('except')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "key", null);
__decorate([
    (0, common_1.Delete)('inactive/clean'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "clean", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "one", null);
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "add", null);
__decorate([
    (0, common_1.Put)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "update", null);
__decorate([
    (0, common_1.Post)(':id/renew'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "renew", null);
__decorate([
    (0, common_1.Post)(':id/adjustment'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "adjustment", null);
__decorate([
    (0, common_1.Patch)(':id/status'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "status", null);
__decorate([
    (0, common_1.Patch)(':id/pr'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "pr", null);
__decorate([
    (0, common_1.Post)(':id/photo'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('photo', { storage: (0, multer_1.diskStorage)({ destination: serialize_1.uploadsDir, filename: (req, f, cb) => cb(null, `${req.user.id}-${Date.now()}${path_1.default.extname(f.originalname) || '.jpg'}`) }), limits: { fileSize: 5 * 1024 * 1024 } })),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.UploadedFile)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "photo", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "del", null);
__decorate([
    (0, common_1.Get)(':id/notes'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "notes", null);
__decorate([
    (0, common_1.Post)(':id/notes'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", void 0)
], MembersController.prototype, "addNote", null);
exports.MembersController = MembersController = __decorate([
    (0, common_1.UseGuards)(jwt_guard_1.JwtGuard),
    (0, common_1.Controller)('members'),
    __metadata("design:paramtypes", [members_service_1.MembersService])
], MembersController);
//# sourceMappingURL=members.controller.js.map