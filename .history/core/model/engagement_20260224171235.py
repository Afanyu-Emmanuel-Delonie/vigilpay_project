from django.conf import settings
from django.db import models


# ---------------------------------------------------------------------------
# UserGoal
# ---------------------------------------------------------------------------

class UserGoal(models.Model):
    """
    A savings or financial goal set by the customer on the mobile app.
    Progress is tracked via current_amount relative to target_amount.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="goals",
    )
    title = models.CharField(max_length=150)
    target_amount = models.FloatField(default=0.0)
    current_amount = models.FloatField(default=0.0)
    is_completed = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "user_goals"
        ordering = ["-created_at"]
        verbose_name = "User Goal"
        verbose_name_plural = "User Goals"

    def __str__(self) -> str:
        return f"'{self.title}' — {self.user}"

    @property
    def progress_percentage(self) -> float:
        """Returns completion percentage, capped at 100."""
        if not self.target_amount:
            return 0.0
        return min(round((self.current_amount / self.target_amount) * 100, 1), 100.0)


# ---------------------------------------------------------------------------
# SurveyResponse
# ---------------------------------------------------------------------------

class SurveyResponse(models.Model):
    """
    A star rating + optional feedback submitted by a customer.
    Rating is constrained to 1–5.
    """

    RATING_MIN = 1
    RATING_MAX = 5

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="survey_responses",
    )
    rating = models.PositiveSmallIntegerField(
        default=3,
        help_text="1 (very poor) to 5 (excellent).",
    )
    feedback = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "survey_responses"
        ordering = ["-created_at"]
        verbose_name = "Survey Response"
        verbose_name_plural = "Survey Responses"

    def __str__(self) -> str:
        return f"Survey by {self.user} — {self.rating}/5"

    def clean(self):
        from django.core.exceptions import ValidationError
        if not (self.RATING_MIN <= self.rating <= self.RATING_MAX):
            raise ValidationError(
                {"rating": f"Rating must be between {self.RATING_MIN} and {self.RATING_MAX}."}
            )


# ---------------------------------------------------------------------------
# AppNotification
# ---------------------------------------------------------------------------

class AppNotification(models.Model):
    """
    An in-app notification sent to a customer.

    created_by  →  the stakeholder or system that created the notification
    target_user →  the customer who receives it (null = broadcast to all)

    is_reviewed  →  the customer opened / read the notification
    is_confirmed →  the customer acknowledged / acted on it
    """

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="sent_notifications",
    )
    target_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="notifications",
        help_text="Leave blank to broadcast to all customers.",
    )
    title = models.CharField(max_length=150)
    message = models.TextField()
    is_reviewed = models.BooleanField(default=False, db_index=True)
    is_confirmed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "app_notifications"
        ordering = ["-created_at"]
        verbose_name = "App Notification"
        verbose_name_plural = "App Notifications"

    def __str__(self) -> str:
        target = str(self.target_user) if self.target_user else "All customers"
        return f"Notification → {target}: {self.title}"


# ---------------------------------------------------------------------------
# InteractionLog
# ---------------------------------------------------------------------------

class InteractionLog(models.Model):
    """
    Immutable audit trail of significant events in a customer's journey.

    Never updated after creation — new events create new rows.
    Used by the ML training data export and the admin analytics dashboard.
    """

    EVENT_PRODUCT_ACCEPTED = "product_accepted"
    EVENT_PRODUCT_REJECTED = "product_rejected"
    EVENT_RESOLUTION_SENT = "resolution_sent"
    EVENT_RESOLUTION_SUCCESS = "resolution_success"
    EVENT_TYPE_CHOICES = [
        (EVENT_PRODUCT_ACCEPTED, "Product Accepted"),
        (EVENT_PRODUCT_REJECTED, "Product Rejected"),
        (EVENT_RESOLUTION_SENT, "Resolution Sent"),
        (EVENT_RESOLUTION_SUCCESS, "Resolution Success"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="interactions",
    )
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
    event_type = models.CharField(
        max_length=32,
        choices=EVENT_TYPE_CHOICES,
        db_index=True,
    )
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text="Arbitrary context data for this event (e.g. resolution note, product details).",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "interaction_logs"
        ordering = ["-created_at"]
        verbose_name = "Interaction Log"
        verbose_name_plural = "Interaction Logs"
        indexes = [
            models.Index(fields=["user", "event_type"], name="interaction_user_event_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.get_event_type_display()} — {self.user} at {self.created_at:%Y-%m-%d %H:%M}"