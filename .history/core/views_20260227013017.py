import logging

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from django.shortcuts import redirect, render

from core.models import User

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Landing
# ---------------------------------------------------------------------------

def landing_page(request):
    return render(request, "core/index.html")


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

def login_page(request):
    if request.user.is_authenticated:
        return redirect("dashboard_page")

    if request.method == "POST":
        # Keep backward compatibility with existing templates/forms.
        identifier = (
            request.POST.get("identifier", "").strip()
            or request.POST.get("email", "").strip()
            or request.POST.get("username", "").strip()
        )
        password = request.POST.get("password", "").strip()

        if not identifier or not password:
            messages.error(request, "Please enter your username/email and password.")
            return render(request, "core/login.html")

        # Resolve identifier to a username for authenticate()
        username = _resolve_username(identifier)
        if username is None:
            messages.error(request, "Invalid credentials.")
            return render(request, "core/login.html")

        user = authenticate(request, username=username, password=password)

        if user is None:
            messages.error(request, "Invalid credentials.")
            return render(request, "core/login.html")

        if not user.is_active:
            messages.error(request, "This account has been deactivated.")
            return render(request, "core/login.html")

        # Only PRO (stakeholder) accounts can access the web portal
        if user.user_type != User.USER_TYPE_PRO:
            messages.error(request, "Customer accounts must use the mobile app.")
            return render(request, "core/login.html")

        login(request, user)
        return redirect("dashboard_page")

    return render(request, "core/login.html")


def _resolve_username(identifier: str) -> str | None:
    """
    Return the username to pass to authenticate().
    If the identifier looks like an email, look up the matching username.
    Returns None if an email was provided but no matching user exists.
    """
    if "@" in identifier:
        try:
            validate_email(identifier)
        except ValidationError:
            return None
        user = User.objects.filter(email__iexact=identifier).first()
        return user.username if user else None
    return identifier


# ---------------------------------------------------------------------------
# Register
# ---------------------------------------------------------------------------

def register_page(request):
    if request.user.is_authenticated:
        return redirect("dashboard_page")

    if request.method == "POST":
        first_name = request.POST.get("first_name", "").strip()
        last_name = request.POST.get("last_name", "").strip()
        username = request.POST.get("username", "").strip()
        email = request.POST.get("email", "").strip().lower()
        password = request.POST.get("password", "")
        confirm_password = request.POST.get("confirm_password", "")

        # ------------------------------------------------------------------
        # Validation
        # ------------------------------------------------------------------
        if not all([first_name, last_name, username, email, password, confirm_password]):
            messages.error(request, "All fields are required.")
            return render(request, "core/register.html")

        if len(username) < 3:
            messages.error(request, "Username must be at least 3 characters.")
            return render(request, "core/register.html")

        if User.objects.filter(username__iexact=username).exists():
            messages.error(request, "That username is already taken.")
            return render(request, "core/register.html")

        try:
            validate_email(email)
        except ValidationError:
            messages.error(request, "Enter a valid email address.")
            return render(request, "core/register.html")

        if User.objects.filter(email__iexact=email).exists():
            messages.error(request, "An account with that email already exists.")
            return render(request, "core/register.html")

        if password != confirm_password:
            messages.error(request, "Passwords do not match.")
            return render(request, "core/register.html")

        try:
            validate_password(password)
        except ValidationError as e:
            for error in e.messages:
                messages.error(request, error)
            return render(request, "core/register.html")

        # ------------------------------------------------------------------
        # Create stakeholder account
        # ------------------------------------------------------------------
        user = User(
            first_name=first_name,
            last_name=last_name,
            username=username,
            email=email,
            user_type=User.USER_TYPE_PRO,
            is_verified=True,
        )
        user.set_password(password)
        user.save()

        logger.info("New stakeholder account created: %s", username)
        messages.success(request, "Account created. Please log in.")
        return redirect("login_page")

    return render(request, "core/register.html")


# ---------------------------------------------------------------------------
# Logout
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def logout_page(request):
    if request.method == "POST":
        logout(request)
        return redirect("login_page")
    # GET requests just redirect back — no logout without a form POST
    return redirect("dashboard_page")


# ---------------------------------------------------------------------------
# Health Check / Ping (for keeping app active)
# ---------------------------------------------------------------------------

def health_check(request):
    """
    Simple health check endpoint that returns a JSON response.
    Use this with external services like cron-job.org to keep the app active.
    
    Example cronjob URL: https://your-app.onrender.com/api/ping/
    """
    from django.http import JsonResponse
    from django.utils import timezone
    import random
    
    # Optionally trigger a small database query to keep the connection active
    user_count = User.objects.count() if request.method == "POST" else None
    
    return JsonResponse({
        "status": "active",
        "message": "VigilPay is running",
        "timestamp": timezone.now().isoformat(),
    })
