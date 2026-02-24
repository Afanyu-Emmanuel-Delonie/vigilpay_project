from django.urls import path

from core import views

urlpatterns = [
    path("",          views.landing_page,  name="landing"),
    path("login/",    views.login_page,    name="login_page"),
    path("register/", views.register_page, name="register_page"),
    path("logout/",   views.logout_page,   name="logout_page"),
]