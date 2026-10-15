import { promises as fs } from 'fs';
import path from 'path';

export const uploadsDir = path.join(process.cwd(), 'uploads');
export const iso = (value: any) => (value ? new Date(value).toISOString() : null);

export async function memberJson(row: any) {
  let photo: string | null = null;
  if (row.photoPath) {
    try {
      photo = (
        await fs.readFile(path.join(uploadsDir, path.basename(row.photoPath)))
      ).toString('base64');
    } catch {
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
    joining_date: iso(row.joiningDate),
    expiry_date: iso(row.expiryDate),
    status: row.status,
    notes: row.notesText || '',
    keycard: row.keycard || '',
    pr_kg: Number(row.prKg || 0),
    photo,
    created_at: iso(row.createdAt),
  };
}
