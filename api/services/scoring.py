"""
core.services.scoring
---------------------
Credit score computation and churn risk prediction for customer profiles.

Both functions read from UserProfile, persist their results back to it,
and return structured dicts consumed by the API serializers and the
admin dashboard — keeping the views and serializers thin.
"""

import logging

from ..model import User, UserProfile

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Internal constants
# ---------------------------------------------------------------------------

# Score band boundaries
_SCORE_MIN = 300
_SCORE_MAX = 850

# ML payload defaults for fields we do not yet collect from the user.
# Centralised here so they are easy to replace when real data is available.
_ML_DEFAULTS = {
    "geography": "France",
    "gender": "Male",
    "age": 35,
    "tenure": 5,
    "has_cr_card": 1,
}

# Churn probability tier thresholds
_TIER_HIGH = 70
_TIER_MEDIUM = 40


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(maximum, value))


def _get_profile(user: User) -> UserProfile:
    """
    Fetch the user's profile, creating a blank one if it does not exist.
    Avoids RelatedObjectDoesNotExist exceptions across the scoring layer.
    """
    profile, _ = UserProfile.objects.get_or_create(user=user)
    return profile


def _ml_payload(profile: UserProfile, user: User) -> dict:
    """
    Build the payload sent to the external ML churn model.
    Real user data is merged with _ML_DEFAULTS for fields not yet collected.
    """
    return {
        **_ML_DEFAULTS,
        "credit_score": profile.credit_score,
        "balance": profile.balance,
        "num_of_products": 1 if profile.activity_rate < 0.6 else 2,
        "is_active_member": 1 if profile.activity_rate >= 0.2 else 0,
        "has_active_complaint": 1 if user.has_active_complaint else 0,
    }


def _call_churn_model(payload: dict) -> float:
    """
    Call the ML service and return a probability (0–100).
    Falls back to 50.0 if the service is unavailable so the rest of the
    system keeps working even when the ML service is down.
    """
    try:
        from customers.ml_service import predict_churn
        return float(predict_churn(payload))
    except Exception:
        logger.warning("Churn model unavailable — using fallback probability of 50.0.")
        return 50.0


def _call_driver_model(profile: UserProfile) -> str:
    """
    Fetch the primary churn driver label from the ML service.
    Returns an empty string on failure.
    """
    try:
        from customers.ml_service import get_primary_churn_driver
        return get_primary_churn_driver({
            "credit_score": profile.credit_score,
            "balance": profile.balance,
            "is_active_member": 1 if profile.activity_rate >= 0.2 else 0,
            "num_of_products": 1 if profile.activity_rate < 0.6 else 2,
            "age": _ML_DEFAULTS["age"],
        })
    except Exception:
        logger.warning("Churn driver model unavailable.")
        return ""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def compute_credit_score_breakdown(user: User) -> dict:
    """
    Compute a detailed credit score breakdown for the given user.

    Persists the new score to UserProfile.credit_score and returns
    a structured dict with the score, range, summary, and factor breakdown
    ready for the mobile app to render.
    """
    profile = _get_profile(user)

    activity_rate = _clamp(profile.activity_rate, 0.0, 1.0)
    loyalty_score = _clamp(profile.loyalty_score, 0.0, 100.0)
    balance = max(profile.balance, 0.0)

    # ------------------------------------------------------------------
    # Score components
    # ------------------------------------------------------------------
    base_points = 300
    loyalty_points = round((loyalty_score / 100.0) * 180.0, 2)
    activity_points = round(activity_rate * 170.0, 2)
    balance_points = round(_clamp(balance / 20_000.0, 0.0, 1.0) * 120.0, 2)

    if not user.has_active_complaint and activity_rate >= 0.7:
        consistency_points = 80
    elif not user.has_active_complaint and activity_rate >= 0.4:
        consistency_points = 45
    elif not user.has_active_complaint:
        consistency_points = 20
    else:
        consistency_points = 0

    complaint_penalty = -70 if user.has_active_complaint else 0

    raw_score = (
        base_points
        + loyalty_points
        + activity_points
        + balance_points
        + consistency_points
        + complaint_penalty
    )
    score = int(round(_clamp(raw_score, _SCORE_MIN, _SCORE_MAX)))

    # Persist the updated score
    profile.credit_score = float(score)
    profile.save(update_fields=["credit_score", "updated_at"])

    # ------------------------------------------------------------------
    # Summary narrative
    # ------------------------------------------------------------------
    if score >= 760:
        summary = "Excellent score driven by strong consistency and engagement."
    elif score >= 690:
        summary = "Good score. Maintain activity and balance growth for faster improvement."
    elif score >= 620:
        summary = "Fair score. Increase consistent activity to move into the good band."
    else:
        summary = "Developing score. Focus on regular account usage and complaint resolution."

    return {
        "score": score,
        "range": {"min": _SCORE_MIN, "max": _SCORE_MAX},
        "summary": summary,
        "factors": [
            {
                "name": "Base score",
                "points": base_points,
                "max_points": 300,
                "description": "Baseline starting point applied to all users.",
            },
            {
                "name": "Loyalty contribution",
                "points": loyalty_points,
                "max_points": 180,
                "description": "Higher loyalty score increases this component.",
            },
            {
                "name": "Activity contribution",
                "points": activity_points,
                "max_points": 170,
                "description": "Frequent, healthy usage improves this component.",
            },
            {
                "name": "Balance contribution",
                "points": balance_points,
                "max_points": 120,
                "description": "Sustained balance levels improve this component.",
            },
            {
                "name": "Consistency bonus",
                "points": consistency_points,
                "max_points": 80,
                "description": "Given for steady activity with no active complaints.",
            },
            {
                "name": "Complaint penalty",
                "points": complaint_penalty,
                "max_points": 0,
                "description": "Applied when a complaint is still unresolved.",
            },
        ],
    }


def compute_user_risk(user: User) -> dict:
    """
    Run the churn model and return a structured risk assessment.

    Persists the churn probability to UserProfile.churn_probability and
    returns a dict with probability, tier, and contributing factors.
    """
    profile = _get_profile(user)
    payload = _ml_payload(profile, user)

    probability = round(_call_churn_model(payload), 2)
    factors = []

    driver = _call_driver_model(profile)
    if driver:
        factors.append(driver)

    if user.has_active_complaint:
        factors.append("Active complaint spike")

    tier = (
        "high" if probability >= _TIER_HIGH
        else "medium" if probability >= _TIER_MEDIUM
        else "low"
    )

    # Persist
    profile.churn_probability = probability
    profile.save(update_fields=["churn_probability", "updated_at"])

    return {
        "probability": probability,
        "tier": tier,
        "factors": factors,
    }