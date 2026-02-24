from django.urls import path

from core.http_views import engagement_hub_page
from data_manager.views import UploadDataView
from dashboard.views import (
    clear_dataset,
    dashboard_page,
    dashboard_search,
    data_management_page,
    model_insight_page,
    risk_level_page,
    settings_page,
)

urlpatterns = [
    path("", dashboard_page, name="dashboard_page"),
    path("engagement-hub/", engagement_hub_page, name="engagement_hub_page"),
    path("risk-level/", risk_level_page, name="risk_level_page"),
    path("data-management/", data_management_page, name="data_management_page"),
    path("model-insight/", model_insight_page, name="model_insight_page"),
    path("profile/", settings_page, name="profile_page"),
    path("settings/", settings_page, name="settings_page"),
    path("data-management/upload/", UploadDataView.as_view(), name="data_management_upload"),
    path("search/", dashboard_search, name="dashboard_search"),
    path("clear-dataset/", clear_dataset, name="clear_dataset"),
]
