from django.http import HttpResponse
from django.shortcuts import render


def home(request):
    base = request.build_absolute_uri("/").rstrip("/")
    html = f"""
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>VigilPay Routes</title>
    </head>
    <body>
      <h1>VigilPay</h1>
      <h2>HTTP Routes</h2>
      <ul>
        <li><a href="{base}/forgot-password/">/forgot-password/</a></li>
        <li><a href="{base}/reset-password/">/reset-password/</a></li>
        <li><a href="{base}/verify-otp/">/verify-otp/</a></li>
        <li><a href="{base}/dashboard/engagement-hub/">/dashboard/engagement-hub/</a></li>
      </ul>
      <h2>API Routes</h2>
      <ul>
        <li><a href="{base}/api/register/web/">/api/register/web/</a></li>
        <li><a href="{base}/api/register/mobile/">/api/register/mobile/</a></li>
        <li><a href="{base}/api/auth/mobile/login/">/api/auth/mobile/login/</a></li>
        <li><a href="{base}/api/products/">/api/products/</a></li>
      </ul>
      <p>Health: <a href="{base}/healthz/">/healthz/</a></p>
    </body>
    </html>
    """
    return HttpResponse(html)


def forgot_password_page(request):
    return render(request, "core/forgot_password.html")


def reset_password_page(request):
    return render(request, "core/reset_password.html")


def verify_otp_page(request):
    return render(request, "core/verify_otp.html")


def engagement_hub_page(request):
    return render(request, "dashboard/engagement_hub.html")
