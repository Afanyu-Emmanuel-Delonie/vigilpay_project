from django.urls import path
from .views import (
    RegisterView, LoginView, LogoutView,
    MeView, DashboardView,
    ComplaintListCreateView, ComplaintDetailView,
    ProductListView, ProductDetailView,
    NotificationListView, NotificationMarkReadView,
    GoalListCreateView, GoalDetailView,
    SurveySubmitView,
)

urlpatterns = [
    # Auth
    path("auth/register/",  RegisterView.as_view(),  name="api_register"),
    path("auth/login/",     LoginView.as_view(),      name="api_login"),
    path("auth/logout/",    LogoutView.as_view(),     name="api_logout"),

    # User
    path("users/me/",        MeView.as_view(),        name="api_me"),
    path("users/dashboard/", DashboardView.as_view(), name="api_dashboard"),

    # Complaints
    path("complaints/",          ComplaintListCreateView.as_view(), name="api_complaints"),
    path("complaints/<int:pk>/", ComplaintDetailView.as_view(),     name="api_complaint_detail"),

    # Products
    path("products/",            ProductListView.as_view(),   name="api_products"),
    path("products/<int:pk>/",   ProductDetailView.as_view(), name="api_product_detail"),

    # Notifications
    path("notifications/",                NotificationListView.as_view(),     name="api_notifications"),
    path("notifications/<int:pk>/read/",  NotificationMarkReadView.as_view(), name="api_notification_read"),

    # Goals
    path("goals/",          GoalListCreateView.as_view(), name="api_goals"),
    path("goals/<int:pk>/", GoalDetailView.as_view(),     name="api_goal_detail"),

    # Surveys
    path("surveys/", SurveySubmitView.as_view(), name="api_survey_submit"),
]