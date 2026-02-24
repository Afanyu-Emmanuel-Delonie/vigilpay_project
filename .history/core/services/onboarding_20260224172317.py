"""
core.services.onboarding
------------------------
Handles first-time setup for new customer accounts:
  - Seeding the default product catalogue
  - Assigning a randomised financial snapshot to new users
    so the scoring and risk engines have data to work with immediately
"""

import random

from ..m import Product, User, UserProfile


def ensure_seed_products() -> None:
    """
    Idempotently create the default product catalogue.
    Safe to call multiple times — uses get_or_create under the hood.
    Called at startup and before any recommendation run.
    """
    defaults = [
        {
            "name": "Gold Card Upgrade",
            "type": Product.TYPE_CARD,
            "min_score_required": 650,
            "min_balance_required": 6_000,
            "description": "Upgrade to our premium Gold Card with exclusive rewards.",
        },
        {
            "name": "VIP Savings Bonus",
            "type": Product.TYPE_BONUS,
            "min_score_required": 620,
            "min_balance_required": 8_000,
            "description": "Earn bonus interest on your savings with VIP status.",
        },
        {
            "name": "Personal Loan",
            "type": Product.TYPE_LOAN,
            "min_score_required": 700,
            "min_balance_required": 3_000,
            "description": "Flexible personal loan with competitive rates.",
        },
        {
            "name": "Investment Portfolio",
            "type": Product.TYPE_BONUS,
            "min_score_required": 720,
            "min_balance_required": 10_000,
            "description": "Diversified investment options managed by our advisors.",
        },
        {
            "name": "Resolution Offer - Fee Waiver",
            "type": Product.TYPE_RESOLUTION,
            "min_score_required": 0,
            "min_balance_required": 0,
            "description": "We are waiving your fees as a goodwill gesture.",
        },
    ]

    for row in defaults:
        Product.objects.get_or_create(name=row["name"], defaults=row)


def assign_random_onboarding_profile(user: User) -> UserProfile:
    """
    Assign a randomised financial snapshot to a newly registered customer.

    Creates the UserProfile if it does not exist yet, then populates it
    with plausible random values so scoring and risk APIs are immediately
    functional. Should only be called once — skips silently if a balance
    already exists.

    Returns the UserProfile instance (created or existing).
    """
    if user.user_type != User.USER_TYPE_CUSTOMER:
        # Stakeholder accounts do not have financial profiles.
        profile, _ = UserProfile.objects.get_or_create(user=user)
        return profile

    profile, created = UserProfile.objects.get_or_create(user=user)

    if not created and profile.balance > 0:
        # Already initialised — do not overwrite.
        return profile

    profile.credit_score = float(random.randint(480, 820))
    profile.balance = round(random.uniform(500.0, 25_000.0), 2)
    profile.loyalty_score = round(random.uniform(0.0, 100.0), 2)
    profile.activity_rate = round(random.uniform(0.05, 1.0), 3)
    profile.save(update_fields=["credit_score", "balance", "loyalty_score", "activity_rate", "updated_at"])

    return profile