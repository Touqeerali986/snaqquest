import logging

from django.conf import settings
from firebase_admin import auth, credentials
from firebase_admin import initialize_app as firebase_initialize_app
from firebase_admin import get_app as firebase_get_app
from firebase_admin.exceptions import FirebaseError
from rest_framework.exceptions import AuthenticationFailed


_firebase_initialized = False
logger = logging.getLogger(__name__)


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

    if not settings.FIREBASE_PROJECT_ID:
        raise AuthenticationFailed(
            "Backend Firebase project is not configured. Contact support."
        )

    try:
        _initialize_firebase_once()
        # Revocation check requires fully configured admin credentials and an
        # extra network hop; keep login resilient in hosted environments.
        decoded = auth.verify_id_token(id_token, check_revoked=False)
    except ValueError as exc:
        message = str(exc).lower()
        if "aud" in message or "audience" in message:
            raise AuthenticationFailed("Token audience mismatch") from exc
        if "expired" in message:
            raise AuthenticationFailed("Google token expired") from exc
        logger.warning("Google token verification failed: %s", exc)
        raise AuthenticationFailed("Invalid Google token") from exc
    except FirebaseError as exc:
        logger.exception("Firebase verification error")
        raise AuthenticationFailed(
            "Google auth service misconfigured on backend. Verify Firebase env."
        ) from exc
    except Exception as exc:
        logger.exception("Unexpected error during Google token verification")
        raise AuthenticationFailed("Invalid Google token") from exc

    project_id = settings.FIREBASE_PROJECT_ID
    if project_id and decoded.get("aud") != project_id:
        raise AuthenticationFailed("Token audience mismatch")

    if not decoded.get("email"):
        raise AuthenticationFailed("Email not available in Google token")

    return decoded
