from django.contrib import admin
from django.http import HttpResponse
from django.urls import include, path


urlpatterns = [
    path("", include("core.urls")),
    path("healthz/", health, name="healthz"),
    path("admin/", admin.site.urls),
    path("api/", include("api.urls")),
    path("dashboard/", include("dashboard.urls")),
]
