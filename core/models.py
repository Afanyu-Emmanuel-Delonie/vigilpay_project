import uuid

from django.conf import settings
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


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class UserOTP(models.Model):
    PURPOSE_REGISTRATION = "registration"
    PURPOSE_PASSWORD_RESET = "password_reset"
    PURPOSE_CHOICES = (
        (PURPOSE_REGISTRATION, "Registration"),
        (PURPOSE_PASSWORD_RESET, "Password Reset"),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="otps")
    purpose = models.CharField(max_length=32, choices=PURPOSE_CHOICES)
    code = models.CharField(max_length=6)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_otps"


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class Complaint(models.Model):
    CATEGORY_BILLING = "billing"
    CATEGORY_SUPPORT = "support"
    CATEGORY_TECHNICAL = "technical"
    CATEGORY_SERVICE = "service"
    CATEGORY_CHOICES = (
        (CATEGORY_BILLING, "Billing"),
        (CATEGORY_SUPPORT, "Support"),
        (CATEGORY_TECHNICAL, "Technical"),
        (CATEGORY_SERVICE, "Service"),
    )

    STATUS_OPEN = "open"
    STATUS_RESOLVED = "resolved"
    STATUS_CHOICES = (
        (STATUS_OPEN, "Open"),
        (STATUS_RESOLVED, "Resolved"),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="complaints")
    text = models.TextField()
    sentiment_score = models.FloatField(default=0.0)
    category = models.CharField(max_length=32, choices=CATEGORY_CHOICES, default=CATEGORY_SUPPORT)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_OPEN)
    resolution_note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "complaints"
        ordering = ["-created_at"]


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class Product(models.Model):
    TYPE_LOAN = "loan"
    TYPE_CARD = "card"
    TYPE_BONUS = "bonus"
    TYPE_RESOLUTION = "resolution"
    TYPE_CHOICES = (
        (TYPE_LOAN, "Loan"),
        (TYPE_CARD, "Card"),
        (TYPE_BONUS, "Bonus"),
        (TYPE_RESOLUTION, "Resolution"),
    )

    name = models.CharField(max_length=120, unique=True)
    type = models.CharField(max_length=16, choices=TYPE_CHOICES)
    min_score_required = models.FloatField(default=0.0)
    min_balance_required = models.FloatField(default=0.0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "products"
        ordering = ["name"]


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class SurveyResponse(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="survey_responses")
    rating = models.IntegerField(default=3)
    feedback = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "survey_responses"
        ordering = ["-created_at"]


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class UserGoal(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="goals")
    title = models.CharField(max_length=150)
    target_amount = models.FloatField(default=0.0)
    current_amount = models.FloatField(default=0.0)
    is_completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_goals"
        ordering = ["-created_at"]


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class AppNotification(models.Model):
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_notifications",
    )
    target_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="notifications",
    )
    title = models.CharField(max_length=150)
    message = models.TextField()
    is_reviewed = models.BooleanField(default=False)
    is_confirmed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "app_notifications"
        ordering = ["-created_at"]


# CHANGE: Restored missing domain models referenced by API/views to prevent import/runtime failures.
class InteractionLog(models.Model):
    EVENT_PRODUCT_ACCEPTED = "product_accepted"
    EVENT_PRODUCT_REJECTED = "product_rejected"
    EVENT_RESOLUTION_SENT = "resolution_sent"
    EVENT_RESOLUTION_SUCCESS = "resolution_success"
    EVENT_TYPE_CHOICES = (
        (EVENT_PRODUCT_ACCEPTED, "Product Accepted"),
        (EVENT_PRODUCT_REJECTED, "Product Rejected"),
        (EVENT_RESOLUTION_SENT, "Resolution Sent"),
        (EVENT_RESOLUTION_SUCCESS, "Resolution Success"),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="interactions")
    complaint = models.ForeignKey(
        "core.Complaint",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="interactions",
    )
    product = models.ForeignKey(
        "core.Product",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="interactions",
    )
    event_type = models.CharField(max_length=32, choices=EVENT_TYPE_CHOICES)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "interaction_logs"
        ordering = ["-created_at"]
