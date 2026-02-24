from django.contrib import admin
from django.http import HttpResponse
from django.urls import include, path


def home(_request):
    return HttpResponse("VigilPay", content_type="text/plain")


def health(_request):
    return HttpResponse("ok", content_type="text/plain")

urlpatterns = [
    path("", include("core.urls")),
    path("healthz/", health, name="healthz"),
    path("admin/", admin.site.urls),
    # CHANGE: Include API routes directly to fail fast on import issues.
    path("api/", include("api.urls")),
    # CHANGE: Include dashboard routes directly to avoid hidden runtime failures.
    path("dashboard/", include("dashboard.urls")),
]
