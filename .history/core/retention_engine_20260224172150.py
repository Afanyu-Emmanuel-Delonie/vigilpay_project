import csv
import random
from pathlib import Path

from customers.ml_service import get_primary_churn_driver, predict_churn
from mod import Complaint, InteractionLog, Product, User


def _clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(maximum, value))


def ensure_seed_products():
    defaults = [
        {"name": "Gold Card Upgrade", "type": Product.TYPE_CARD, "min_score_required": 650, "min_balance_required": 6000},
        {"name": "VIP Savings Bonus", "type": Product.TYPE_BONUS, "min_score_required": 620, "min_balance_required": 8000},
        {"name": "Personal Loan", "type": Product.TYPE_LOAN, "min_score_required": 700, "min_balance_required": 3000},
        {"name": "Investment Portfolio", "type": Product.TYPE_BONUS, "min_score_required": 720, "min_balance_required": 10000},
        {"name": "Resolution Offer - Fee Waiver", "type": Product.TYPE_RESOLUTION, "min_score_required": 0, "min_balance_required": 0},
    ]
    for row in defaults:
        Product.objects.get_or_create(name=row["name"], defaults=row)


def assign_random_onboarding_profile(user: User):
    if user.user_type != User.USER_TYPE_CUSTOMER:
        return
    if user.onboarding_balance > 0:
        return
    user.calculated_credit_score = float(random.randint(480, 820))
    user.onboarding_balance = round(random.uniform(500.0, 25000.0), 2)
    user.loyalty_score = round(random.uniform(0.0, 100.0), 2)
    user.onboarding_activity_rate = round(random.uniform(0.05, 1.0), 3)
    user.save(
        update_fields=[
            "calculated_credit_score",
            "onboarding_balance",
            "loyalty_score",
            "onboarding_activity_rate",
        ]
    )


def _predict_base_risk(user: User) -> float:
    payload = {
        "credit_score": user.calculated_credit_score,
        "geography": "France",
        "gender": "Male",
        "age": 35,
        "tenure": 5,
        "balance": user.onboarding_balance,
        "num_of_products": 1 if user.onboarding_activity_rate < 0.6 else 2,
        "has_cr_card": 1,
        "is_active_member": 1 if user.onboarding_activity_rate >= 0.2 else 0,
        "has_active_complaint": 1 if user.has_active_complaint else 0,
    }
    try:
        return float(predict_churn(payload))
    except Exception:
        return 50.0


def compute_user_risk(user: User) -> dict:
    probability = _predict_base_risk(user)
    factors = [get_primary_churn_driver(
        {
            "credit_score": user.calculated_credit_score,
            "balance": user.onboarding_balance,
            "is_active_member": 1 if user.onboarding_activity_rate >= 0.2 else 0,
            "num_of_products": 1 if user.onboarding_activity_rate < 0.6 else 2,
            "age": 35,
        }
    )]

    probability = round(probability, 2)
    if user.has_active_complaint:
        factors.append("Active complaint spike")

    if probability >= 70:
        tier = "high"
    elif probability >= 40:
        tier = "medium"
    else:
        tier = "low"

    user.onboarding_prediction = probability
    user.save(update_fields=["onboarding_prediction"])
    return {"probability": probability, "tier": tier, "factors": factors}


def compute_credit_score_breakdown(user: User) -> dict:
    activity_rate = _clamp(float(user.onboarding_activity_rate or 0.0), 0.0, 1.0)
    loyalty_score = _clamp(float(user.loyalty_score or 0.0), 0.0, 100.0)
    balance = max(float(user.onboarding_balance or 0.0), 0.0)

    base_points = 300
    loyalty_points = round((loyalty_score / 100.0) * 180.0, 2)
    activity_points = round(activity_rate * 170.0, 2)
    balance_points = round(_clamp(balance / 20000.0, 0.0, 1.0) * 120.0, 2)

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
    score = int(round(_clamp(raw_score, 300.0, 850.0)))

    user.calculated_credit_score = float(score)
    user.save(update_fields=["calculated_credit_score"])

    if score >= 760:
        summary = "Excellent score driven by strong consistency and engagement."
    elif score >= 690:
        summary = "Good score. Maintain activity and balance growth for faster improvement."
    elif score >= 620:
        summary = "Fair score. Increase consistent activity to move into the good band."
    else:
        summary = "Developing score. Focus on regular account usage and complaint resolution."

    factors = [
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
    ]

    return {
        "score": score,
        "range": {"min": 300, "max": 850},
        "summary": summary,
        "factors": factors,
    }


def recommend_for_user(user: User, risk: dict) -> dict:
    ensure_seed_products()
    active_resolutions = []
    suggested_products = []

    if user.has_active_complaint:
        resolution = Product.objects.filter(
            name__iexact="Resolution Offer - Fee Waiver",
            is_active=True,
        ).first()
        if resolution:
            active_resolutions.append(resolution.name)
        return {
            "active_resolutions": active_resolutions,
            "suggested_products": suggested_products,
        }

    high_balance = user.onboarding_balance >= 7000
    high_credit = user.calculated_credit_score >= 700

    if risk["probability"] > 70 and high_balance:
        choices = ["Gold Card Upgrade", "VIP Savings Bonus"]
        suggested_products.extend(
            list(Product.objects.filter(name__in=choices, is_active=True).values_list("name", flat=True))
        )
    elif risk["probability"] < 30 and high_credit:
        choices = ["Personal Loan", "Investment Portfolio"]
        suggested_products.extend(
            list(Product.objects.filter(name__in=choices, is_active=True).values_list("name", flat=True))
        )
    else:
        suggested_products.extend(
            list(
                Product.objects.filter(
                    is_active=True,
                    min_score_required__lte=user.calculated_credit_score,
                    min_balance_required__lte=user.onboarding_balance,
                )
                .exclude(type=Product.TYPE_RESOLUTION)
                .values_list("name", flat=True)[:2]
            )
        )

    return {
        "active_resolutions": active_resolutions,
        "suggested_products": suggested_products,
    }


def profile_payload(user: User) -> dict:
    credit_analysis = compute_credit_score_breakdown(user)
    risk = compute_user_risk(user)
    actionable = recommend_for_user(user, risk)
    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.get_full_name(),
        "phone_number": user.phone_number or "",
        "member_since": user.created_at.date().isoformat(),
        "credit_analysis": credit_analysis,
        "user_info": {
            "username": user.username,
            "type": user.user_type,
            "loyalty_score": user.loyalty_score,
        },
        "risk_analysis": risk,
        "actionable_items": actionable,
    }


def resolve_complaint(complaint: Complaint, note: str):
    complaint.status = Complaint.STATUS_RESOLVED
    complaint.resolution_note = note
    complaint.save(update_fields=["status", "resolution_note", "updated_at"])
    user = complaint.user
    user.has_active_complaint = user.complaints.filter(status=Complaint.STATUS_OPEN).exists()
    user.save(update_fields=["has_active_complaint"])
    InteractionLog.objects.create(
        user=user,
        complaint=complaint,
        event_type=InteractionLog.EVENT_RESOLUTION_SUCCESS,
        metadata={"resolution_note": note},
    )


def generate_training_data(output_path: str | None = None) -> str:
    base_dir = Path(__file__).resolve().parent
    export_path = Path(output_path) if output_path else (base_dir / "ml_training_export.csv")

    rows = InteractionLog.objects.select_related("user", "product", "complaint").all()
    with export_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(
            [
                "user_id",
                "user_type",
                "loyalty_score",
                "calculated_credit_score",
                "has_active_complaint",
                "event_type",
                "product_name",
                "complaint_category",
                "timestamp",
            ]
        )
        for row in rows:
            writer.writerow(
                [
                    row.user_id,
                    row.user.user_type,
                    row.user.loyalty_score,
                    row.user.calculated_credit_score,
                    int(row.user.has_active_complaint),
                    row.event_type,
                    row.product.name if row.product else "",
                    row.complaint.category if row.complaint else "",
                    row.created_at.isoformat(),
                ]
            )
    return str(export_path)
