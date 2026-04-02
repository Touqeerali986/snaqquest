from django.urls import path

from .views import GoogleLoginView, LoginView, LogoutView, ProfileMeView, SignupView

urlpatterns = [
    path("auth/signup/", SignupView.as_view(), name="auth-signup"),
    path("auth/login/", LoginView.as_view(), name="auth-login"),
    path("auth/google/", GoogleLoginView.as_view(), name="auth-google"),
    path("auth/logout/", LogoutView.as_view(), name="auth-logout"),
    path("profile/me/", ProfileMeView.as_view(), name="profile-me"),
]
