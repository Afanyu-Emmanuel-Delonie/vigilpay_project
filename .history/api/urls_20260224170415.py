from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
urlpatterns = [
    # ------------------------------------------------------------------
    # Auth  —  no authentication required
    # ------------------------------------------------------------------
    path("auth/register/", RegisterView.as_view(), name="api_register"),
    path("auth/login/", LoginView.as_view(), name="api_login"),
    path("auth/logout/", LogoutView.as_view(), name="api_logout"),

    # ------------------------------------------------------------------
    # User  —  requires IsCustomer + IsVerified
    # ------------------------------------------------------------------
    path("users/me/", MeView.as_view(), name="api_me"),
    path("users/dashboard/", DashboardView.as_view(), name="api_dashboard"),
]