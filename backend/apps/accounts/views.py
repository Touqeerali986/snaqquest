from django.contrib.auth import authenticate
from django.db import transaction
from django.utils.crypto import get_random_string
from rest_framework import permissions, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken, TokenError

from .models import User
from .serializers import (
    GoogleLoginSerializer,
    LoginSerializer,
    LogoutSerializer,
    ProfileUpdateSerializer,
    SignupSerializer,
    UserSerializer,
)
from .services import verify_firebase_id_token


def _auth_response(user: User, request) -> dict:
    refresh = RefreshToken.for_user(user)
    return {
        "user": UserSerializer(user, context={"request": request}).data,
        "tokens": {
            "access": str(refresh.access_token),
            "refresh": str(refresh),
        },
    }


class SignupView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    @transaction.atomic
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(_auth_response(user, request), status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"].lower().strip()
        password = serializer.validated_data["password"]
        user = authenticate(request=request, username=email, password=password)

        if not user:
            return Response({"detail": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

        return Response(_auth_response(user, request), status=status.HTTP_200_OK)


class GoogleLoginView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    @transaction.atomic
    def post(self, request):
        serializer = GoogleLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payload = verify_firebase_id_token(serializer.validated_data["id_token"])
        email = payload["email"].lower().strip()
        name = payload.get("name", "Google User")

        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                "full_name": name[:120],
                "auth_provider": User.AuthProvider.GOOGLE,
            },
        )

        if created:
            user.set_password(get_random_string(32))
            user.save(update_fields=["password"])

        if user.auth_provider != User.AuthProvider.GOOGLE:
            user.auth_provider = User.AuthProvider.GOOGLE
            user.save(update_fields=["auth_provider", "updated_at"])

        return Response(_auth_response(user, request), status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        refresh_token = serializer.validated_data["refresh"]
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError:
            return Response({"detail": "Invalid refresh token"}, status=status.HTTP_400_BAD_REQUEST)

        return Response({"detail": "Logout successful"}, status=status.HTTP_205_RESET_CONTENT)


class ProfileMeView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        serializer = UserSerializer(request.user, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        serializer = ProfileUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        updated_user = serializer.save()
        updated_user.refresh_from_db()
        return Response(UserSerializer(updated_user, context={"request": request}).data, status=status.HTTP_200_OK)
