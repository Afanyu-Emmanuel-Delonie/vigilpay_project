import uuid
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    USER_TYPE_PRO = "PRO"
    USER_TYPE_CUSTOMER = "CUSTOMER"
    USER_TYPE_CHOICES = [
        (USER_TYPE_PRO, "Stakeholder (Web)"),
        (USER_TYPE_CUSTOMER, "Customer (Mobile)"),
    ]

    id = models.CharField(max_length=32, primary_key=True, default=_generate_user_id, editable=False)
    phone_number = models.CharField(max_length=20, blank=True, default="")
    profile_picture = models.URLField(max_length=500, blank=True, default="")
    user_type = models.CharField(max_length=16, choices=USER_TYPE_CHOICES, default=USER_TYPE_CUSTOMER)
    is_verified = models.BooleanField(default=False)
    has_active_complaint = models.BooleanField(default=False)

    # Financial / ML fields
    balance = models.FloatField(default=0.0)
    loyalty_score = models.FloatField(default=0.0)
    activity_rate = models.FloatField(default=0.0)
    credit_score = models.FloatField(default=600.0)
    churn_probability = models.FloatField(default=0.0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    groups = models.ManyToManyField(Group, blank=True, related_name="custom_users", db_table="users_groups")
    user_permissions = models.ManyToManyField(Permission, blank=True, related_name="custom_users", db_table="users_user_permissions")

    class Meta:
        db_table = "users"

    def __str__(self):
        return f"{self.username} ({self.user_type})"

    @property
    def is_customer(self):
        return self.user_type == self.USER_TYPE_CUSTOMER


class Complaint(models.Model):
    CATEGORY_BILLING = "billing"
    CATEGORY_TECHNICAL = "technical"
    CATEGORY_SERVICE = "service"
    CATEGORY_SUPPORT = "support"
    CATEGORY_CHOICES = [
        (CATEGORY_BILLING, "Billing"),
        (CATEGORY_TECHNICAL, "Technical"),
        (CATEGORY_SERVICE, "Service"),
        (CATEGORY_SUPPORT, "Support"),
    ]

    STATUS_OPEN = "open"
    STATUS_RESOLVED = "resolved"
    STATUS_CHOICES = [
        (STATUS_OPEN, "Open"),
        (STATUS_RESOLVED, "Resolved"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="complaints")
    text = models.TextField()
    category = models.CharField(max_length=32, choices=CATEGORY_CHOICES, default=CATEGORY_SUPPORT)
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default=STATUS_OPEN)
    sentiment_score = models.FloatField(default=0.0)
    resolution_note = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "complaints"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Complaint #{self.pk} by {self.user} [{self.status}]"


class Product(models.Model):
    TYPE_LOAN = "loan"
    TYPE_CARD = "card"
    TYPE_BONUS = "bonus"
    TYPE_RESOLUTION = "resolution"
    TYPE_CHOICES = [
        (TYPE_LOAN, "Loan"),
        (TYPE_CARD, "Card"),
        (TYPE_BONUS, "Bonus"),
        (TYPE_RESOLUTION, "Resolution"),
    ]

    name = models.CharField(max_length=120, unique=True)
    type = models.CharField(max_length=16, choices=TYPE_CHOICES)
    description = models.TextField(blank=True, default="")
    min_score_required = models.FloatField(default=0.0)
    min_balance_required = models.FloatField(default=0.0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "products"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.get_type_display()})"


class Notification(models.Model):
    target_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=150)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Notification → {self.target_user}: {self.title}"


class Goal(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="goals")
    title = models.CharField(max_length=150)
    target_amount = models.FloatField(default=0.0)
    current_amount = models.FloatField(default=0.0)
    is_completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "goals"
        ordering = ["-created_at"]

    def __str__(self):
        return f"'{self.title}' — {self.user}"

    @property
    def progress(self):
        if not self.target_amount:
            return 0.0
        return min(round((self.current_amount / self.target_amount) * 100, 1), 100.0)


class Survey(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="surveys")
    rating = models.PositiveSmallIntegerField(default=3)
    feedback = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "surveys"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Survey by {self.user} — {self.rating}/5"