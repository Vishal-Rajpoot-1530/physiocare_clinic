"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.iso = exports.uploadsDir = void 0;
exports.memberJson = memberJson;
const fs_1 = require("fs");
const path_1 = __importDefault(require("path"));
exports.uploadsDir = path_1.default.join(process.cwd(), 'uploads');
const iso = (value) => (value ? new Date(value).toISOString() : null);
exports.iso = iso;
async function memberJson(row) {
    let photo = null;
    if (row.photoPath) {
        try {
            photo = (await fs_1.promises.readFile(path_1.default.join(exports.uploadsDir, path_1.default.basename(row.photoPath)))).toString('base64');
        }
        catch {
            photo = null;
        }
    }
    return {
        id: Number(row.id),
        name: row.name,
        email: row.email || '',
        phone: row.phone || '',
        gender: row.gender,
        age: row.age,
        plan: row.plan,
        duration_value: row.durationValue,
        duration_unit: row.durationUnit,
        fee: Number(row.fee),
        joining_date: (0, exports.iso)(row.joiningDate),
        expiry_date: (0, exports.iso)(row.expiryDate),
        status: row.status,
        notes: row.notesText || '',
        keycard: row.keycard || '',
        pr_kg: Number(row.prKg || 0),
        photo,
        created_at: (0, exports.iso)(row.createdAt),
    };
}
//# sourceMappingURL=serialize.js.map