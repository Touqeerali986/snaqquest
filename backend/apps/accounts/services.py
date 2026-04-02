from django.conf import settings
from firebase_admin import auth, credentials
from firebase_admin import initialize_app as firebase_initialize_app
from firebase_admin import get_app as firebase_get_app
from firebase_admin.exceptions import FirebaseError
from rest_framework.exceptions import AuthenticationFailed


_firebase_initialized = False


def _initialize_firebase_once() -> None:
    global _firebase_initialized
    if _firebase_initialized:
        return

    try:
        firebase_get_app()
        _firebase_initialized = True
        return
    except ValueError:
        pass

    if settings.FIREBASE_CLIENT_EMAIL and settings.FIREBASE_PRIVATE_KEY and settings.FIREBASE_PROJECT_ID:
        cred = credentials.Certificate(
            {
                "type": "service_account",
                "project_id": settings.FIREBASE_PROJECT_ID,
                "private_key": settings.FIREBASE_PRIVATE_KEY,
                "client_email": settings.FIREBASE_CLIENT_EMAIL,
                "token_uri": "https://oauth2.googleapis.com/token",
            }
        )
        firebase_initialize_app(cred, {"projectId": settings.FIREBASE_PROJECT_ID})
    else:
        options = {"projectId": settings.FIREBASE_PROJECT_ID} if settings.FIREBASE_PROJECT_ID else None
        firebase_initialize_app(options=options)

    _firebase_initialized = True


def verify_firebase_id_token(id_token: str) -> dict:
    if not id_token:
        raise AuthenticationFailed("Google ID token is required")

    try:
        _initialize_firebase_once()
        decoded = auth.verify_id_token(id_token, check_revoked=True)
    except (ValueError, FirebaseError) as exc:
        raise AuthenticationFailed("Invalid Google token") from exc

    project_id = settings.FIREBASE_PROJECT_ID
    if project_id and decoded.get("aud") != project_id:
        raise AuthenticationFailed("Token audience mismatch")

    if not decoded.get("email"):
        raise AuthenticationFailed("Email not available in Google token")

    return decoded
