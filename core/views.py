from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.http import JsonResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_POST

from core.models import User


def landing_page(request):
    return render(request, "core/index.html")


def health_check(request):
    return JsonResponse({"status": "ok"})


def login_page(request):
    if request.method == "POST":
        email = request.POST.get("email", "").strip().lower()
        password = request.POST.get("password", "")
        user = authenticate(request, username=email, password=password)

        if user is not None:
            login(request, user)
            return redirect("dashboard_page")

        messages.error(request, "Invalid email or password.")

    return render(request, "core/login.html")


def register_page(request):
    if request.method == "POST":
        first_name = request.POST.get("first_name", "").strip()
        last_name = request.POST.get("last_name", "").strip()
        username = request.POST.get("username", "").strip()
        email = request.POST.get("email", "").strip().lower()
        password = request.POST.get("password", "")
        confirm_password = request.POST.get("confirm_password", "")

        if not all([first_name, last_name, username, email, password, confirm_password]):
            messages.error(request, "All fields are required.")
            return render(request, "core/register.html")

        if password != confirm_password:
            messages.error(request, "Passwords do not match.")
            return render(request, "core/register.html")

        if User.objects.filter(email=email).exists():
            messages.error(request, "Email already exists.")
            return render(request, "core/register.html")

        if User.objects.filter(username=username).exists():
            messages.error(request, "Username already exists.")
            return render(request, "core/register.html")

        user = User.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            password=password,
        )
        login(request, user)
        return redirect("dashboard_page")

    return render(request, "core/register.html")


@require_POST
def logout_page(request):
    logout(request)
    messages.success(request, "You have been logged out.")
    return redirect("landing")
