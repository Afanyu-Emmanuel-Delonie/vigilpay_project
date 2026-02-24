from django.db import models


class Product(models.Model):
    """
    A financial product or offer that can be recommended to customers.

    Products are seeded via core.services.ensure_seed_products and
    matched to users by the recommendation engine in core.services.
    TYPE_RESOLUTION products are special — they are only surfaced
    to users who have an active complaint.
    """

    # ------------------------------------------------------------------
    # Type choices
    # ------------------------------------------------------------------
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

    # ------------------------------------------------------------------
    # Fields
    # ------------------------------------------------------------------
    name = models.CharField(max_length=120, unique=True)
    type = models.CharField(max_length=16, choices=TYPE_CHOICES, db_index=True)
    description = models.TextField(
        blank=True,
        default="",
        help_text="Optional description shown to the customer on the mobile app.",
    )

    # Eligibility thresholds — enforced by the recommendation engine,
    # not at the DB level, so staff can configure them freely.
    min_score_required = models.FloatField(
        default=0.0,
        help_text="Minimum credit score needed to be eligible for this product.",
    )
    min_balance_required = models.FloatField(
        default=0.0,
        help_text="Minimum account balance needed to be eligible for this product.",
    )

    is_active = models.BooleanField(
        default=True,
        db_index=True,
        help_text="Inactive products are excluded from all recommendations.",
    )

    # ------------------------------------------------------------------
    # Timestamps
    # ------------------------------------------------------------------
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "products"
        ordering = ["name"]
        verbose_name = "Product"
        verbose_name_plural = "Products"

    def __str__(self) -> str:
        return f"{self.name} ({self.get_type_display()})"

    # ------------------------------------------------------------------
    # Convenience
    # ------------------------------------------------------------------

    @property
    def is_resolution_offer(self) -> bool:
        return self.type == self.TYPE_RESOLUTION