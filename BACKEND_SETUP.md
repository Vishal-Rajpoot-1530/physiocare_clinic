# Power Cave — NestJS + Prisma + MySQL Setup

## 1. MySQL
Create an empty database:
```sql
CREATE DATABASE rts_physioclinic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 2. Backend
```bash
cd ..\physio_backend
npm install
copy .env.example .env   # Windows
# cp .env.example .env  # macOS/Linux
```
Edit `.env` and set your MySQL password and a strong JWT secret. Then:
```bash
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```
API base: `http://localhost:3002/api/v1`

## 3. Flutter
The default API URL targets the backend on port 3002 from an Android emulator
(`10.0.2.2` maps to the host computer). You can also set it explicitly:
```bash
flutter run --dart-define=PHYSIO_API_BASE_URL=http://10.0.2.2:3002/api/v1
```
For physical Android devices over USB, use adb reverse so the device points to your computer:
```bash
adb reverse tcp:3002 tcp:3002
flutter run --dart-define=PHYSIO_API_BASE_URL=http://127.0.0.1:3002/api/v1
```
For Wi‑Fi/device-server access, replace `127.0.0.1` with your PC's LAN IP, example: `http://192.168.1.25:3002/api/v1`.

Important: `127.0.0.1` points to the phone itself, not the backend server running on your laptop/desktop.

The Physio Flutter web app uses port `5502`:
```bash
flutter run -d web-server --web-port 5502
```
Open `http://localhost:5502`. In VS Code, select **Physio Web (5502)** in Run
and Debug. The Physio backend allows local web origins (`localhost`,
`127.0.0.1`, and `[::1]`) on any port, so changing development ports does not
require a `CORS_ORIGIN` update. Non-local web origins must be listed explicitly
in the backend's `CORS_ORIGIN`.

## Production
Use HTTPS and a production `DATABASE_URL`. Run `npx prisma migrate deploy`, `npm run build`, then `node dist/main.js` (or PM2). Keep `.env` out of Git. Back up MySQL and the `physio_backend/uploads/` directory.

## Data safety
Business data is stored in MySQL. SharedPreferences only stores the JWT session token. Member image files live in `backend/uploads/`; their paths are stored in MySQL. Uninstalling the mobile app no longer deletes server business data.
