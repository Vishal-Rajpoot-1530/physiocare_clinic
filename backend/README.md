# Power Cave API — NestJS + Prisma + MySQL

Backend stack: NestJS, Prisma ORM, MySQL, JWT, bcrypt, Multer.

## Start
1. Copy `.env.example` to `.env` and set `DATABASE_URL` + `JWT_SECRET`.
2. `npm install`
3. `npx prisma generate`
4. `npx prisma migrate dev --name init` (local development)
5. `npm run start:dev`

Flutter API contract remains `/api/v1`. Configure with:
- Android emulator (also the app's default): `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`
- Physical device via USB: `adb reverse tcp:3000 tcp:3000` then `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1`
- Wi‑Fi/LAN: `flutter run --dart-define=API_BASE_URL=http://YOUR_HOST:3000/api/v1`

Do not use `127.0.0.1` on a real phone unless you have configured `adb reverse`.

For production use HTTPS, run `npx prisma migrate deploy`, build with `npm run build`, and start `node dist/main.js`.


## Online / Offline account licensing

Existing `POST /api/v1/auth/register` remains backward-compatible; omitted `type` defaults to `OFFLINE`. Super-admin management endpoints use the `x-super-admin-key` header matching `SUPER_ADMIN_KEY`.

- `POST /api/v1/super-admin/users` creates an online/offline user.
- `GET /api/v1/super-admin/users` lists users and latest app subscription.
- `PATCH /api/v1/super-admin/users/:id/status` sets `active` or `temporarily_inactive`.
- `POST /api/v1/super-admin/users/:id/subscription` assigns a monthly/quarterly/yearly online subscription.
- `POST /api/v1/super-admin/users/:id/subscription/renew` renews it without discarding remaining active time.

Run the included Prisma migration before deploying. Offline users bypass subscription checks. Online users are checked both at login and on every JWT-protected request, so expiry/deactivation also invalidates continued API access with an old token. Existing gym `Plan` records and APIs are unchanged.
