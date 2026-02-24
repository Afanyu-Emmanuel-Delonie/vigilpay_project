from django.urls import path

from core.views import health_check, landing_page, login_page, logout_page, register_page

urlpatterns = [
    path("", landing_page, name="landing"),
    path("health/", health_check, name="health_check"),
    path("login/", login_page, name="login_page"),
    path("register/", register_page, name="register_page"),
    path("logout/", logout_page, name="logout_page"),
]
