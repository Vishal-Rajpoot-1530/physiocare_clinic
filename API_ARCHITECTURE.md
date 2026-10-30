# Physio API Architecture

## Flutter
- `lib/api/api_config.dart` - base URL and timeout
- `lib/api/api_endpoints.dart` - centralized endpoint definitions
- `lib/api/api_exception.dart` - normalized API/network errors
- `lib/api/api_client.dart` - HTTP/JWT/multipart/logging layer
- `lib/db/app_db.dart` - mode-aware data facade used by existing UI
- `lib/db/local_db.dart` - SQLite database for offline accounts and clinic data

Signup and sign-in require an Online or Offline mode:
- Online accounts use the server API for authentication and all business data.
- Offline accounts use SQLite only; API access is guarded off for the active offline session.
- Offline SQLite is available on Android, iOS, macOS, Windows and Linux. Web accounts use Online mode.
- Offline account passwords are stored as salted PBKDF2-HMAC-SHA256 hashes.
- The UI never silently switches between storage modes when a request fails.

### Request logs
Run Flutter with `flutter run`. Every request prints:
`[API] --> GET http://.../api/v1/members`
`[API] <-- GET /members [200] 42ms`

## NestJS
- Feature modules: `auth`, `members`, `finance`, `settings`, `checkins`
- `prisma` - MySQL access to the `rts_physioclinic` database
- `common/request-logger.middleware.ts` - incoming API logs
- Membership plans use `duration_value` and `duration_unit` (`DAY`, `WEEK`, or `MONTH`). Before deploying the updated API, run `npx prisma migrate deploy` from `backend`; the migration preserves existing plans and memberships as month-based durations.

From `physio_backend`, run `npm run start:dev`; each hit prints method, URL, HTTP status and duration.

## Empty member behavior
Either store returning an empty member list renders the Members empty state: `No members yet...`. It never injects demo members.
