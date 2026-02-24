import re

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from django.urls import reverse
from django.shortcuts import redirect, render


def landing_page(request):
    return render(request, "core/index.html")


def login_page(request):
    if request.method == "POST":
        identifier = (
            request.POST.get("username")
            or request.POST.get("email")
            or request.POST.get("identifier")
            or ""
        ).strip()
        password = request.POST.get("password") or ""
        if not identifier or not password:
            messages.error(request, "Username/email and password are required.")
            return render(request, "core/login.html")
        if "@" in identifier:
            try:
                validate_email(identifier)
            except ValidationError:
                messages.error(request, "Enter a valid email address.")
                return render(request, "core/login.html")
        elif not re.fullmatch(r"[A-Za-z0-9_]{3,150}", identifier):
            messages.error(request, "Enter a valid username.")
            return render(request, "core/login.html")
        try:
            user = authenticate(request, username=identifier, password=password)
            if user is None and "@" in identifier:
                matched_user = get_user_model().objects.filter(email__iexact=identifier).first()
                if matched_user is not None:
                    user = authenticate(request, username=matched_user.username, password=password)
        except Exception:
            # CHANGE: Prevent hard 500s when auth backend/database throws unexpectedly.
            messages.error(request, "Authentication failed due to a server error.")
            return render(request, "core/login.html")
        # if user is not None:
        #     login(request, user)
        #     try:
        #         return redirect("dashboard_page")
        #     except NoReverseMatch:
        #         # Fallback keeps login functional even if dashboard routing is unavailable.
        #         return redirect(reverse("landing"))
        if user is not None:
            try:
                login(request, user)
            except Exception:
                # CHANGE: Prevent hard 500s if session write/login internals fail.
                messages.error(request, "Login failed due to a server/session error.")
                return render(request, "core/login.html")
            # CHANGE: Redirect to a lighter post-login page to avoid dashboard-heavy failures.
            try:
                return redirect("engagement_hub_page")
            except Exception:
                # CHANGE: Guaranteed safe fallback route if engagement URL is unavailable.
                return redirect(reverse("landing"))

        # CHANGE: Keep invalid credentials as a handled response, not a crash.
        messages.error(request, "Invalid credentials.")
    return render(request, "core/login.html")


def register_page(request):
    return render(request, "core/register.html")


def forgot_password_page(request):
    return render(request, "core/forgot_password.html")


def reset_password_page(request):
    return render(request, "core/reset_password.html")


def verify_otp_page(request):
    return render(request, "core/verify_otp.html")


@login_required(login_url="login_page")
def logout_page(request):
    if request.method == "POST":
        logout(request)
        return redirect("login_page")
    return redirect("dashboard_page")
