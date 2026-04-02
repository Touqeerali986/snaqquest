from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import User


class AuthFlowTests(APITestCase):
    def test_signup_and_login(self):
        signup_payload = {
            "email": "user@example.com",
            "full_name": "Test User",
            "password": "StrongPass123!",
        }
        signup_response = self.client.post(reverse("auth-signup"), signup_payload, format="json")
        self.assertEqual(signup_response.status_code, status.HTTP_201_CREATED)
        self.assertIn("tokens", signup_response.data)

        login_payload = {"email": "user@example.com", "password": "StrongPass123!"}
        login_response = self.client.post(reverse("auth-login"), login_payload, format="json")
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
        self.assertIn("tokens", login_response.data)

    def test_profile_requires_auth(self):
        response = self.client.get(reverse("profile-me"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class ProfileFlowTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="profile@example.com",
            full_name="Profile User",
            password="StrongPass123!",
        )

    def test_get_profile(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get(reverse("profile-me"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["email"], self.user.email)
