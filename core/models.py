import uuid

from django.contrib.auth.models import AbstractUser, Group, Permission
from django.db import models
from django.utils import timezone


def _user_id():
    return uuid.uuid4().hex


class User(AbstractUser):
    USER_TYPE_PRO = "PRO"
    USER_TYPE_CUSTOMER = "CUSTOMER"
    USER_TYPE_CHOICES = (
        (USER_TYPE_PRO, "Web User"),
        (USER_TYPE_CUSTOMER, "Mobile User"),
    )

    id = models.CharField(max_length=32, primary_key=True, default=_user_id, editable=False)
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    profile_picture = models.CharField(max_length=100, blank=True, null=True)
    company_name = models.CharField(max_length=255, blank=True, default="")
    job_title = models.CharField(max_length=100, blank=True, default="")
    is_verified = models.BooleanField(default=False)
    two_factor_enabled = models.BooleanField(default=False)
    last_login_ip = models.GenericIPAddressField(blank=True, null=True)
    last_activity = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    has_complain = models.BooleanField(default=False)
    loyalty_score = models.FloatField(default=0.0)
    user_type = models.CharField(max_length=16, choices=USER_TYPE_CHOICES, default=USER_TYPE_CUSTOMER)
    calculated_credit_score = models.FloatField(default=600.0)
    has_active_complaint = models.BooleanField(default=False)
    onboarding_activity_rate = models.FloatField(default=0.0)
    onboarding_balance = models.FloatField(default=0.0)
    onboarding_prediction = models.FloatField(default=0.0)

    # Match existing M2M table names in the current database.
    groups = models.ManyToManyField(
        Group,
        blank=True,
        related_name="users_set",
        related_query_name="user",
        db_table="users_groups",
    )
    user_permissions = models.ManyToManyField(
        Permission,
        blank=True,
        related_name="users_set",
        related_query_name="user",
        db_table="users_user_permissions",
    )

    class Meta:
        db_table = "users"

