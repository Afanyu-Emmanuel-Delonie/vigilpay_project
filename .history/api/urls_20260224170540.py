from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from api.views import DashboardView, LoginView, LogoutView, MeView, RegisterView

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
    
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]