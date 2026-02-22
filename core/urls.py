from django.urls import path

from core.views import landing_page, login_page, logout_page, register_page

urlpatterns = [
    path("", landing_page, name="landing"),
    path("login/", login_page, name="login_page"),
    path("register/", register_page, name="register_page"),
    path("logout/", logout_page, name="logout_page"),
]
