from django.conf import settings
from django.db import models


class Complaint(models.Model):
    """
    A complaint raised by a CUSTOMER via the mobile app.

    Lifecycle:
        open  →  resolved

    Sentiment scoring and category classification happen automatically
    via core.signals when a complaint is first created.
    The resolution flow is handled by core.services.resolve_complaint.
    """

    # ------------------------------------------------------------------
    # Category choices
    # ------------------------------------------------------------------
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

    # ------------------------------------------------------------------
    # Status choices
    # ------------------------------------------------------------------
    STATUS_OPEN = "open"
    STATUS_RESOLVED = "resolved"
    STATUS_CHOICES = [
        (STATUS_OPEN, "Open"),
        (STATUS_RESOLVED, "Resolved"),
    ]

    # ------------------------------------------------------------------
    # Fields
    # ------------------------------------------------------------------
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="complaints",
    )
    text = models.TextField(
        help_text="The complaint message submitted by the user."
    )
    category = models.CharField(
        max_length=32,
        choices=CATEGORY_CHOICES,
        default=CATEGORY_SUPPORT,
        db_index=True,
        help_text="Auto-classified from text by the sentiment engine.",
    )
    status = models.CharField(
        max_length=16,
        choices=STATUS_CHOICES,
        default=STATUS_OPEN,
        db_index=True,
    )
    sentiment_score = models.FloatField(
        default=0.0,
        help_text="Computed score: positive > 0, negative < 0.",
    )
    resolution_note = models.TextField(
        blank=True,
        default="",
        help_text="Populated by a stakeholder when the complaint is resolved.",
    )

    # ------------------------------------------------------------------
    # Timestamps
    # ------------------------------------------------------------------
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "complaints"
        ordering = ["-created_at"]
        verbose_name = "Complaint"
        verbose_name_plural = "Complaints"
        indexes = [
            models.Index(fields=["user", "status"], name="complaint_user_status_idx"),
        ]

    def __str__(self) -> str:
        return f"Complaint #{self.pk} by {self.user} [{self.status}]"

    # ------------------------------------------------------------------
    # Convenience
    # ------------------------------------------------------------------

    @property
    def is_open(self) -> bool:
        return self.status == self.STATUS_OPEN

    @property
    def is_resolved(self) -> bool:
        return self.status == self.STATUS_RESOLVED