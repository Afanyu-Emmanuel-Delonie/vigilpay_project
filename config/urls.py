from django.contrib import admin
from django.http import HttpResponse
from django.urls import include, path


def home(_request):
    return HttpResponse("VigilPay is live.", content_type="text/plain")


def health(_request):
    return HttpResponse("ok", content_type="text/plain")

urlpatterns = [
    path("", home, name="home"),
    path("healthz/", health, name="healthz"),
    path("admin/", admin.site.urls),
]

# Best-effort route wiring so project can start even if optional apps are absent.
try:
    urlpatterns.append(path("", include("core.api_urls")))
except Exception:
    pass

try:
    urlpatterns.append(path("dashboard/", include("dashboard.urls")))
except Exception:
    pass
