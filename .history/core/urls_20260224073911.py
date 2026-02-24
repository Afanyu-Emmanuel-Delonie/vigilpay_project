from django.urls import path

from core.views import (
    forgot_password_page,
    landing_page,
    login_page,
    logout_page,
    register_page,
    reset_password_page,
    verify_otp_page,
)

urlpatterns = [
    path("", landing_page, name="landing"),
    path("login/", login_page, name="login_page"),
    path("register/", register_page, name="register_page"),
    path("forgot-password/", forgot_password_page, name="forgot_password_page"),
    path("reset-password/", reset_password_page, name="reset_password_page"),
    path("verify-otp/", verify_otp_page, name="verify_otp_page"),
    path("logout/", logout_page, name="logout_page"),
]
