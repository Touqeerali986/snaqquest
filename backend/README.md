# Backend (Django API)

## Features
- `POST /api/v1/auth/signup/`
- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/google/`
- `POST /api/v1/auth/logout/`
- `GET /api/v1/profile/me/`
- `PATCH /api/v1/profile/me/` (supports avatar upload)

## Setup
```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python manage.py migrate
python manage.py runserver
```

## Environment
Use `.env.example` as template. Important production vars:
- `DJANGO_SECRET_KEY`
- `DJANGO_DEBUG=False`
- `DATABASE_URL=postgres://...`
- `DJANGO_ALLOWED_HOSTS`
- `CORS_ALLOWED_ORIGINS`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

## Run Tests
```bash
python manage.py test
```
