"""
core.services
-------------
Public interface for all business logic in the core app.

Import from here, not from submodules directly:

    from core.services import compute_credit_score_breakdown, resolve_complaint

Submodule layout:
    onboarding.py      →  assign_random_onboarding_profile, ensure_seed_products
    scoring.py         →  compute_credit_score_breakdown, compute_user_risk
    recommendations.py →  recommend_for_user
    complaints.py      →  run_sentiment_analysis, resolve_complaint
    export.py          →  generate_training_data
"""

from .complaints import resolve_complaint, run_sentiment_analysis
from .export import generate_training_data
from .onboarding import assign_random_onboarding_profile, ensure_seed_products
from .recommendations import recommend_for_user
from .scoring import compute_credit_score_breakdown, compute_user_risk

__all__ = [
    # onboarding
    "ensure_seed_products",
    "assign_random_onboarding_profile",
    # scoring
    "compute_credit_score_breakdown",
    "compute_user_risk",
    # recommendations
    "recommend_for_user",
    # complaints
    "run_sentiment_analysis",
    "resolve_complaint",
    # export
    "generate_training_data",
]