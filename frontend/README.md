# SnaqQuest Frontend (Flutter)

## Implemented Prototype Features
- Email/password login
- Email/password signup
- Google login via Firebase Authentication
- Profile screen with avatar upload
- Logout

## Run Locally
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Use these runtime defines as needed:
- `API_BASE_URL`
- `GOOGLE_WEB_CLIENT_ID`

Example:
```bash
flutter run \
	--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
	--dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

## Firebase Setup
1. Create Firebase project.
2. Enable Authentication -> Google provider.
3. Android: add `android/app/google-services.json`.
4. iOS: add `ios/Runner/GoogleService-Info.plist`.
5. Ensure SHA-1/SHA-256 for Android app are added in Firebase.

## Build Release (Android)
```bash
flutter build apk --release \
	--dart-define=API_BASE_URL=https://your-api-domain/api/v1 \
	--dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

## Android Signing Setup
1. Generate keystore and key.properties:
```powershell
powershell -ExecutionPolicy Bypass -File ..\scripts\setup-android-signing.ps1 -StorePassword "YOUR_STORE_PASS" -KeyPassword "YOUR_KEY_PASS"
```
2. Keep these files private:
- `android/upload-keystore.jks`
- `android/key.properties`

Reference template:
- `android/key.properties.example`

## Notes
- Tokens are stored in secure storage.
- API errors are surfaced to the UI with user-friendly messages.
- Google login requires both frontend Firebase setup and backend Firebase Admin env configuration.
