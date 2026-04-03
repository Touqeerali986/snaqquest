# SnaqQuest - Production Ready Prototype

This repository contains a production-oriented implementation of your client prototype:
- Email/password signup and login
- Google login via Firebase token verification
- Profile picture upload
- Secure logout with JWT refresh token blacklist

## Tech Stack
- Frontend: Flutter
- Backend: Django + DRF + SimpleJWT
- Google Auth: Firebase Authentication + Firebase Admin token verification
- Database: PostgreSQL (production), SQLite (local fallback)

## Project Structure
- `backend/` Django REST API
- `frontend/` Flutter mobile/web app
- `planning.md` Deep implementation plan used for build
- `scripts/` Deployment, signing, Firebase verification, and debug automation
- `MANUAL_STEPS.md` Easy manual checklist for client handover
- `RENDER_DEPLOYMENT.md` Render production backend deployment guide
- `render.yaml` Render blueprint config

## One-Command Client Deploy
Run from project root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/client-one-command-deploy.ps1 -ApiBaseUrl "https://YOUR_BACKEND_DOMAIN/api/v1" -GoogleWebClientId "YOUR_WEB_CLIENT_ID"
```

This command:
- Installs backend/frontend dependencies
- Runs backend migrations/checks/tests
- Runs frontend analyze/tests
- Builds release APK

## Production Architecture Summary
1. Flutter authenticates user via email/password or Google.
2. For Google sign-in, Flutter retrieves Firebase ID token.
3. Django backend verifies Firebase token and issues JWT tokens.
4. Flutter stores JWT in secure storage and uses API for profile operations.
5. Logout blacklists refresh token server-side and clears local tokens.

## Quick Start (Local)
### 1) Backend
```bash
cd backend
python -m venv .venv
# Windows
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
python manage.py runserver
```

Backend runs on `http://127.0.0.1:8000`.

### 2) Frontend
```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

For Android emulator, use `http://10.0.2.2:8000/api/v1` instead.

## Google Login Setup (Required)
### Flutter side
1. Add Firebase app in Firebase console.
2. Place `google-services.json` in `frontend/android/app/`.
3. Place `GoogleService-Info.plist` in iOS runner.
4. Enable Google provider in Firebase Authentication.
5. Run app with web client id:
```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

### Backend side
Set these env values in `backend/.env`:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (escaped with `\n` in one line)

## Docker (Backend + Postgres)
```bash
docker compose up --build
```

Backend service will be available at `http://localhost:8000`.

## Render Deployment
Use Render blueprint from [render.yaml](render.yaml) and follow [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md).

## Client Local Run (Backend + Frontend)
Client can run full stack locally with one command:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-client-local.ps1 -DeviceId "ANDROID_DEVICE_ID" -HostIp "CLIENT_LAN_IP" -GoogleWebClientId "YOUR_WEB_CLIENT_ID"
```

## Production Checklist Before Client Handover
- Set `DJANGO_DEBUG=False`
- Set strong `DJANGO_SECRET_KEY`
- Configure proper `DJANGO_ALLOWED_HOSTS`
- Configure strict `CORS_ALLOWED_ORIGINS`
- Use PostgreSQL `DATABASE_URL`
- Configure Firebase credentials in backend env
- Set `SERVE_MEDIA_FILES=True` and `DJANGO_MEDIA_ROOT=/var/data/media` on Render
- Upload release signing configs for Android/iOS builds
- Run tests and smoke flow checks

## Release Snapshot
- Stable baseline verified on 2026-04-03
- Backend checks: `python manage.py check`, `python manage.py test`
- Frontend checks: `flutter analyze`, `flutter test`
- Production smoke verified:
  - Google login flow
  - Profile avatar upload and fetch
  - Render health endpoint

## Fast Production Verification
1. Open `https://YOUR_RENDER_BACKEND/health/` and confirm `{"status":"ok","database":"ok"}`.
2. Login with Google from app using `API_BASE_URL=https://YOUR_RENDER_BACKEND/api/v1`.
3. Upload a profile image and confirm it appears on profile reload.
4. If Google login fails, re-check `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.
5. If avatar fails, confirm `SERVE_MEDIA_FILES=True`, `DJANGO_MEDIA_ROOT=/var/data/media`, and persistent disk is mounted.

## Debug Command
Run full debug checks anytime:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/debug-all.ps1
```

## Verified Commands Run
- Backend:
  - `python manage.py check`
  - `python manage.py migrate`
  - `python manage.py test`
- Frontend:
  - `flutter analyze`
  - `flutter test`
