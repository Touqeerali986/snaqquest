# Render Deployment Guide (Backend)

This guide deploys the Django backend to Render in production mode.

## 1) Push code to GitHub
1. Create GitHub repository.
2. Push full project.

## 2) Create Render web service
1. Open Render dashboard.
2. New -> Blueprint and select this repository.
3. Render will read [render.yaml](render.yaml).

## 3) Set required secrets in Render
In Render service environment variables, set these values:
- `DJANGO_SECRET_KEY`
- `DATABASE_URL` (from Render Postgres)
- `CORS_ALLOWED_ORIGINS`
- `CSRF_TRUSTED_ORIGINS`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (one line with escaped `\\n`)

Optional but recommended:
- `DJANGO_ALLOWED_HOSTS=.onrender.com`
- `LOG_LEVEL=INFO`

## 4) Persistent media for profile pictures
If you need profile images to persist:
1. Add Render persistent disk to backend service.
2. Mount path: `/var/data/media`
3. Keep env values:
   - `SERVE_MEDIA_FILES=True`
   - `DJANGO_MEDIA_ROOT=/var/data/media`

## 5) Verify deployment
1. Open health endpoint:
   - `https://YOUR_RENDER_BACKEND/health/`
2. Verify API base:
   - `https://YOUR_RENDER_BACKEND/api/v1/`

## 6) Frontend production API
Use Render backend URL in Flutter builds:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR_RENDER_BACKEND/api/v1 --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

## 7) Client handover
Share these files with client:
- [README.md](README.md)
- [MANUAL_STEPS.md](MANUAL_STEPS.md)
- [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md)
- [scripts/run-client-local.ps1](scripts/run-client-local.ps1)

Client can run local full stack with one command:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-client-local.ps1 -DeviceId "ANDROID_DEVICE_ID" -HostIp "CLIENT_LAN_IP" -GoogleWebClientId "YOUR_WEB_CLIENT_ID"
```
