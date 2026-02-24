from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render


def landing_page(request):
    return render(request, "core/index.html")


def login_page(request):
    if request.method == "POST":
        username = (
            request.POST.get("username")
            or request.POST.get("email")
            or request.POST.get("identifier")
            or ""
        ).strip()
        password = request.POST.get("password") or ""
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return redirect("dashboard_page")
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
