from django.conf import settings
from rest_framework import serializers

from .models import User


class UserSerializer(serializers.ModelSerializer):
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "email", "full_name", "auth_provider", "avatar_url", "date_joined"]

    def get_avatar_url(self, obj: User) -> str | None:
        if not obj.avatar:
            return None

        version = int(obj.updated_at.timestamp())
        # Return relative media URL so clients can safely bind it to their
        # configured API host in all environments.
        return f"{obj.avatar.url}?v={version}"


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ["email", "full_name", "password"]

    def validate_email(self, value: str) -> str:
        return value.lower().strip()

    def create(self, validated_data):
        return User.objects.create_user(
            email=validated_data["email"],
            full_name=validated_data["full_name"],
            password=validated_data["password"],
            auth_provider=User.AuthProvider.EMAIL,
        )


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class GoogleLoginSerializer(serializers.Serializer):
    id_token = serializers.CharField(write_only=True)


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField(write_only=True)


class ProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["full_name", "avatar"]

    def validate_avatar(self, value):
        if value is None:
            return value

        if value.size > settings.MAX_AVATAR_UPLOAD_SIZE:
            raise serializers.ValidationError("Avatar size exceeds allowed limit")

        if value.content_type not in settings.ALLOWED_AVATAR_MIME_TYPES:
            raise serializers.ValidationError("Unsupported avatar file type")

        return value
