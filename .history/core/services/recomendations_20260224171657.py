"""
core.services.recommendations
------------------------------
Matches active Products to a customer based on their financial profile
and current risk tier.

Rules (in priority order):
  1. If the user has an active complaint → show the resolution offer only.
  2. High churn probability + high balance → retention-focused products.
  3. Low churn probability + high credit → growth-focused products.
  4. Otherwise → any eligible product that meets score/balance thresholds.
"""

from core.models import Product, User, UserProfile
from core.services.onboarding import ensure_seed_products


def recommend_for_user(user: User, risk: dict) -> dict:
    """
    Return product recommendations for the given user.

    Args:
        user:  The customer to generate recommendations for.
        risk:  The output of compute_user_risk(user) — must contain
               'probability' (float) and 'tier' (str).

    Returns:
        {
            "active_resolutions": [...product names...],
            "suggested_products": [...product names...],
        }
    """
    ensure_seed_products()

    active_resolutions: list[str] = []
    suggested_products: list[str] = []

    # ------------------------------------------------------------------
    # Rule 1 — complaint resolution takes priority over everything else
    # ------------------------------------------------------------------
    if user.has_active_complaint:
        resolution = (
            Product.objects.filter(type=Product.TYPE_RESOLUTION, is_active=True).first()
        )
        if resolution:
            active_resolutions.append(resolution.name)
        return {
            "active_resolutions": active_resolutions,
            "suggested_products": suggested_products,
        }

    profile = _get_profile(user)
    probability = risk.get("probability", 0.0)
    high_balance = profile.balance >= 7_000
    high_credit = profile.credit_score >= 700

    # ------------------------------------------------------------------
    # Rule 2 — high churn risk + high balance → retention products
    # ------------------------------------------------------------------
    if probability > 70 and high_balance:
        names = ["Gold Card Upgrade", "VIP Savings Bonus"]
        suggested_products.extend(_fetch_by_names(names))

    # ------------------------------------------------------------------
    # Rule 3 — low churn risk + high credit → growth products
    # ------------------------------------------------------------------
    elif probability < 30 and high_credit:
        names = ["Personal Loan", "Investment Portfolio"]
        suggested_products.extend(_fetch_by_names(names))

    # ------------------------------------------------------------------
    # Rule 4 — general eligibility match
    # ------------------------------------------------------------------
    else:
        suggested_products.extend(
            list(
                Product.objects.filter(
                    is_active=True,
                    min_score_required__lte=profile.credit_score,
                    min_balance_required__lte=profile.balance,
                )
                .exclude(type=Product.TYPE_RESOLUTION)
                .values_list("name", flat=True)[:2]
            )
        )

    return {
        "active_resolutions": active_resolutions,
        "suggested_products": suggested_products,
    }


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _get_profile(user: User) -> UserProfile:
    profile, _ = UserProfile.objects.get_or_create(user=user)
    return profile


def _fetch_by_names(names: list[str]) -> list[str]:
    """Return active product names from a priority list, preserving order."""
    products = (
        Product.objects.filter(name__in=names, is_active=True)
        .values_list("name", flat=True)
    )
    # Preserve the priority order defined in names
    found = set(products)
    return [n for n in names if n in found]