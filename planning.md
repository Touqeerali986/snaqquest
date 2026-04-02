# SnaqQuest Production Plan (Flutter + Django + Firebase Google Auth)

## 1) Project Objective
Build a production-ready app prototype with:
- Login and signup using email + password
- Login using Google (Firebase-based)
- User profile picture upload/update
- Secure logout
- Clean client handover so app can run on client machine with minimal setup

This project will use:
- Frontend: Flutter
- Backend: Django + Django REST Framework
- Google auth broker: Firebase Authentication + Firebase Admin SDK verification on backend

## 2) Scope Clarification
### In Scope
- User registration and authentication APIs
- JWT-based session handling (access + refresh)
- Google sign-in endpoint that verifies Firebase ID token
- Profile endpoint (read/update) including avatar upload
- Logout endpoint (refresh token blacklist)
- Flutter UI screens for login, signup, profile
- Flutter state management + secure token storage
- Production env configuration and deployment docs

### Out of Scope (for this phase)
- Password reset email flow
- Multi-factor auth
- Social providers other than Google
- Complex role/permission systems

## 3) High-Level Architecture
- Flutter app authenticates user via:
  - Email/password endpoints OR
  - Firebase Google Sign-In to obtain Firebase ID token
- Flutter sends credentials/token to Django API
- Django issues JWT access/refresh tokens
- Flutter stores tokens securely and uses access token for authenticated calls
- Profile image uploaded via multipart/form-data endpoint
- Logout blacklists refresh token

## 4) Security & Production Requirements
### Backend security
- Use environment variables for all secrets
- `DEBUG=False` in production
- Strict CORS allowlist
- Secure cookie/token policy (token transport in Authorization header)
- JWT refresh token blacklisting enabled
- File upload validation (type + size)
- Rate limiting on auth endpoints
- Proper logging with no sensitive data leaks

### Client security
- Use `flutter_secure_storage` for tokens
- Never hardcode API secrets
- Firebase config from platform files and env where needed

## 5) Data Model Plan
### Custom User
- `email` (unique)
- `full_name`
- `avatar` (optional ImageField)
- `is_active`, `is_staff`, timestamps
- `auth_provider` (`email`, `google`)

## 6) API Contract (v1)
Base path: `/api/v1/`

### Auth
- `POST /auth/signup/`
  - Input: `email`, `password`, `full_name`
  - Output: user object + JWT tokens
- `POST /auth/login/`
  - Input: `email`, `password`
  - Output: user object + JWT tokens
- `POST /auth/google/`
  - Input: `id_token` (Firebase ID token)
  - Output: user object + JWT tokens
- `POST /auth/logout/`
  - Input: `refresh`
  - Output: success message

### Profile
- `GET /profile/me/`
  - Output: current user profile
- `PATCH /profile/me/`
  - Input: `full_name`, optional `avatar` multipart file
  - Output: updated profile

## 7) Flutter App UX Plan
### Screens
- Splash / auth gate
- Login screen:
  - Email/password form
  - Login with Google button
  - Link to signup
- Signup screen:
  - Full name, email, password, confirm password
- Profile screen:
  - Avatar preview
  - Upload/replace photo
  - Basic profile details
  - Logout button

### UX and reliability
- Form validation
- Loading states and disabled buttons
- API error mapping to user-friendly messages
- Retry-friendly networking layer

## 8) Folder Structure Plan
```
SnaqQuest/
  backend/
    manage.py
    requirements.txt
    .env.example
    config/
    apps/
      accounts/
    media/
    static/
  frontend/
    pubspec.yaml
    lib/
      core/
      features/auth/
      features/profile/
      app.dart
      main.dart
```

## 9) Environment & Secrets Plan
### Backend .env variables
- `DJANGO_SECRET_KEY`
- `DJANGO_DEBUG`
- `DJANGO_ALLOWED_HOSTS`
- `DATABASE_URL`
- `CORS_ALLOWED_ORIGINS`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `JWT_ACCESS_MINUTES`
- `JWT_REFRESH_DAYS`

### Frontend runtime config
- `API_BASE_URL`
- `GOOGLE_WEB_CLIENT_ID` (for Android/iOS sign-in alignment)

## 10) Deployment Plan (Production-Ready)
### Backend
- Gunicorn app server
- WhiteNoise for static serving
- PostgreSQL in production
- `collectstatic` and migrations as deployment steps
- Health endpoint

### Frontend
- Flutter Android/iOS production build configuration
- Optional Flutter web build for admin/demo

### Client handover
- README with exact run/deploy commands
- `.env.example` and configuration checklist
- Known troubleshooting section (Google Sign-In SHA, Firebase config, CORS)

## 11) Testing & Validation Plan
- Backend unit/API tests for auth and profile endpoints
- Smoke test checklist:
  - Signup works
  - Email login works
  - Google login works
  - Avatar upload works
  - Logout invalidates refresh token
- Manual cross-platform Flutter flow verification

## 12) Implementation Order
1. Create backend project scaffold and settings
2. Implement custom user model and auth/profile APIs
3. Integrate Firebase token verification endpoint
4. Add production hardening configs
5. Create Flutter project structure + service layer
6. Build auth/profile UI screens and logic
7. Wire Google sign-in in Flutter + backend endpoint
8. Add docs for local + production deployment
9. Run sanity checks and finalize handover

## 13) Acceptance Criteria
- User can sign up and login via email/password
- User can login with Google
- User can upload and view profile picture
- User can logout reliably
- App/API can be configured for production and run on client machine
- Codebase contains clear setup and deployment documentation
