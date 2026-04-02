# SnaqQuest Manual Steps (Easy + Detailed)

This file explains only what must be done manually by you.

## A) One-command deployment run
1. Open PowerShell in project root.
2. Run this command:
   powershell -ExecutionPolicy Bypass -File scripts/client-one-command-deploy.ps1 -ApiBaseUrl "https://YOUR_BACKEND_DOMAIN/api/v1" -GoogleWebClientId "YOUR_WEB_CLIENT_ID"
3. After completion, release APK will be at:
   frontend/build/app/outputs/flutter-apk/app-release.apk

## A.1) If Android build fails with NDK error
If you see an error like source.properties missing in NDK folder, do this:
1. Open Android Studio.
2. Go to SDK Manager -> SDK Tools.
3. Enable and install:
   - NDK (Side by side)
   - Android SDK Command-line Tools
4. Remove broken folder inside:
   C:\Users\YOUR_USER\AppData\Local\Android\sdk\ndk\
5. Re-run one-command deployment script.

## B) Android release signing (manual secret inputs required)
1. Run:
   powershell -ExecutionPolicy Bypass -File scripts/setup-android-signing.ps1 -StorePassword "YOUR_STORE_PASS" -KeyPassword "YOUR_KEY_PASS"
2. This creates:
   - frontend/android/upload-keystore.jks
   - frontend/android/key.properties
3. Keep both files private and never share in git.
4. Build signed release APK:
   flutter build apk --release --dart-define=API_BASE_URL="https://YOUR_BACKEND_DOMAIN/api/v1" --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID"

## C) Firebase manual setup (required)
1. Create/open Firebase project.
2. Add Android app package name exactly:
   com.snaqquest.app.snaqquest_frontend
3. Add SHA-1 and SHA-256 fingerprints from your signing key.
4. Enable Authentication -> Sign-in method -> Google.
5. Download google-services.json and place at:
   frontend/android/app/google-services.json
6. Copy Firebase service account credentials values to backend/.env:
   - FIREBASE_PROJECT_ID
   - FIREBASE_CLIENT_EMAIL
   - FIREBASE_PRIVATE_KEY (single line with escaped \n)

## D) Firebase configuration verification
1. Run:
   powershell -ExecutionPolicy Bypass -File scripts/verify-firebase-config.ps1
2. If it fails, fix shown issues and run again.

## E) End-to-end Google auth verification (manual test)
1. Start backend:
   cd backend
   .venv\Scripts\python manage.py runserver
2. Start app with defines:
   cd frontend
   flutter run --dart-define=API_BASE_URL="http://10.0.2.2:8000/api/v1" --dart-define=GOOGLE_WEB_CLIENT_ID="YOUR_WEB_CLIENT_ID"
3. Tap Login with Google.
4. Expected result:
   - Login succeeds
   - Profile screen opens
   - Backend logs show successful POST /api/v1/auth/google/

## F) Full debug command
Run this to debug all checks/tests:
powershell -ExecutionPolicy Bypass -File scripts/debug-all.ps1

## G) Render production deploy (backend)
1. Push project to GitHub.
2. In Render, create Blueprint from repository.
3. Render will use render.yaml from root.
4. Set these required env vars in Render:
   - DJANGO_SECRET_KEY
   - DATABASE_URL
   - CORS_ALLOWED_ORIGINS
   - CSRF_TRUSTED_ORIGINS
   - FIREBASE_PROJECT_ID
   - FIREBASE_CLIENT_EMAIL
   - FIREBASE_PRIVATE_KEY
5. Open health URL after deploy:
   https://YOUR_RENDER_BACKEND/health/

## H) Client machine local run (same as your machine)
1. Install prerequisites on client machine:
   - Python 3.12
   - Flutter SDK
   - Android Studio + SDK
2. Give project folder to client.
3. Client runs one command from root:
   powershell -ExecutionPolicy Bypass -File scripts/run-client-local.ps1 -DeviceId "ANDROID_DEVICE_ID" -HostIp "CLIENT_LAN_IP" -GoogleWebClientId "YOUR_WEB_CLIENT_ID"
4. This opens two terminals and runs:
   - Backend server on 0.0.0.0:8000
   - Flutter app on provided device
