from django.contrib import admin
from django.urls import include, path

urlpatterns = [
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
