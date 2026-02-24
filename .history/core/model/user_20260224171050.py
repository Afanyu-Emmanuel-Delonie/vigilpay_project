import uuid

from django.contrib.auth.models import AbstractUser, Group, Permission
from django.db import models
from django.utils import timezone


def _generate_user_id() -> str:
    """Generate a compact, URL-safe UUID as the user's primary key."""
    return uuid.uuid4().hex


# ---------------------------------------------------------------------------
# User
# ---------------------------------------------------------------------------

class User(AbstractUser):
    """
    The single user model for the entire system.

    USER_TYPE_CUSTOMER  →  mobile app users (customers)
    USER_TYPE_PRO       →  web portal users (stakeholders / staff)

    Analytics and ML fields are intentionally kept off this model.
    See UserProfile for those. The rule of thumb: if a field describes
    WHO the user is, it lives here. If it describes how the system
    SCORES or ANALYSES them, it lives on UserProfile.
    """

    USER_TYPE_PRO = "PRO"
    USER_TYPE_CUSTOMER = "CUSTOMER"
    USER_TYPE_CHOICES = [
        (USER_TYPE_PRO, "Stakeholder (Web)"),
        (USER_TYPE_CUSTOMER, "Customer (Mobile)"),
    ]

    id = models.CharField(
        max_length=32,
        primary_key=True,
        default=_generate_user_id,
        editable=False,
    )

    # ------------------------------------------------------------------
    # Contact & identity
    # ------------------------------------------------------------------
    phone_number = models.CharField(max_length=20, blank=True, default="")
    profile_picture = models.URLField(max_length=500, blank=True, default="")
    company_name = models.CharField(max_length=255, blank=True, default="")
    job_title = models.CharField(max_length=100, blank=True, default="")

    # ------------------------------------------------------------------
    # Account status
    # ------------------------------------------------------------------
    user_type = models.CharField(
        max_length=16,
        choices=USER_TYPE_CHOICES,
        default=USER_TYPE_CUSTOMER,
        db_index=True,
    )
    is_verified = models.BooleanField(default=False)
    two_factor_enabled = models.BooleanField(default=False)

    # ------------------------------------------------------------------
    # Activity tracking
    # ------------------------------------------------------------------
    last_login_ip = models.GenericIPAddressField(blank=True, null=True)
    last_activity = models.DateTimeField(default=timezone.now)

    # ------------------------------------------------------------------
    # Complaint flag — single source of truth
    # has_active_complaint is set by signals and re-checked after
    # each complaint status change. We only need one flag.
    # ------------------------------------------------------------------
    has_active_complaint = models.BooleanField(default=False, db_index=True)

    # ------------------------------------------------------------------
    # Timestamps
    # ------------------------------------------------------------------
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # ------------------------------------------------------------------
    # M2M overrides to match existing DB table names
    # ------------------------------------------------------------------
    groups = models.ManyToManyField(
        Group,
        blank=True,
        related_name="custom_users",
        db_table="users_groups",
    )
    user_permissions = models.ManyToManyField(
        Permission,
        blank=True,
        related_name="custom_users",
        db_table="users_user_permissions",
    )

    class Meta:
        db_table = "users"
        verbose_name = "User"
        verbose_name_plural = "Users"

    def __str__(self) -> str:
        return f"{self.get_full_name() or self.username} ({self.user_type})"

    # ------------------------------------------------------------------
    # Convenience properties
    # ------------------------------------------------------------------

    @property
    def is_customer(self) -> bool:
        return self.user_type == self.USER_TYPE_CUSTOMER

    @property
    def is_stakeholder(self) -> bool:
        return self.user_type == self.USER_TYPE_PRO

    def update_complaint_flag(self) -> None:
        """
        Recompute has_active_complaint from the complaints table.
        Call this after any complaint status change instead of
        setting the flag manually.
        """
        from core.models.complaint import Complaint  # local import avoids circular

        self.has_active_complaint = self.complaints.filter(
            status=Complaint.STATUS_OPEN
        ).exists()
        self.save(update_fields=["has_active_complaint", "updated_at"])


# ---------------------------------------------------------------------------
# UserProfile  —  analytics & ML fields
# ---------------------------------------------------------------------------

class UserProfile(models.Model):
    """
    Extends User with analytics, ML predictions, and scoring data.

    Kept separate from User so that:
    - The User model stays clean and auth-focused
    - ML fields can evolve independently without touching auth migrations
    - Admin and API serializers can include/exclude this data cleanly
    """

    user = models.OneToOneField(
        "core.User",
        on_delete=models.CASCADE,
        related_name="profile",
        primary_key=True,
    )

    # ------------------------------------------------------------------
    # Onboarding / financial snapshot
    # Populated once during registration via assign_random_onboarding_profile
    # and refreshed when the user's financial picture changes.
    # ------------------------------------------------------------------
    balance = models.FloatField(default=0.0)
    activity_rate = models.FloatField(
        default=0.0,
        help_text="Normalised value between 0.0 and 1.0.",
    )
    loyalty_score = models.FloatField(
        default=0.0,
        help_text="0–100 score derived from engagement history.",
    )

    # ------------------------------------------------------------------
    # Scoring & predictions
    # Updated by core.services on demand; never written directly by views.
    # ------------------------------------------------------------------
    credit_score = models.FloatField(default=600.0)
    churn_probability = models.FloatField(
        default=0.0,
        help_text="Latest churn probability (0–100) from the ML model.",
    )

    # ------------------------------------------------------------------
    # Timestamps
    # ------------------------------------------------------------------
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "user_profiles"
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"

    def __str__(self) -> str:
        return f"Profile of {self.user}"

    @property
    def churn_tier(self) -> str:
        """Human-readable risk tier derived from churn_probability."""
        if self.churn_probability >= 70:
            return "high"
        if self.churn_probability >= 40:
            return "medium"
        return "low"


# ---------------------------------------------------------------------------
# UserOTP  —  one-time passwords for future verification flows
# ---------------------------------------------------------------------------

class UserOTP(models.Model):
    """
    Stores time-limited OTP codes.
    Not used in the current auth flow but kept for the upcoming
    verification and password-reset features.
    """

    PURPOSE_REGISTRATION = "registration"
    PURPOSE_PASSWORD_RESET = "password_reset"
    PURPOSE_CHOICES = [
        (PURPOSE_REGISTRATION, "Registration"),
        (PURPOSE_PASSWORD_RESET, "Password Reset"),
    ]

    user = models.ForeignKey(
        "core.User",
        on_delete=models.CASCADE,
        related_name="otps",
    )
    purpose = models.CharField(max_length=32, choices=PURPOSE_CHOICES)
    code = models.CharField(max_length=6)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_otps"
        verbose_name = "User OTP"
        verbose_name_plural = "User OTPs"
        indexes = [
            models.Index(fields=["user", "purpose", "is_used"], name="otp_lookup_idx"),
        ]

    def __str__(self) -> str:
        return f"OTP({self.purpose}) for {self.user}"