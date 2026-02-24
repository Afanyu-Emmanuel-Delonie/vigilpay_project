def _to_float(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _to_int(value, default=0):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def predict_churn(payload: dict) -> float:
    # Lightweight heuristic fallback when the trained model is unavailable.
    credit_score = _to_float(payload.get("credit_score"), 600.0)
    age = _to_int(payload.get("age"), 35)
    balance = _to_float(payload.get("balance"), 0.0)
    num_products = _to_int(payload.get("num_of_products"), 1)
    active = _to_int(payload.get("is_active_member"), 1)
    complaint = _to_int(payload.get("has_active_complaint"), 0)

    score = 45.0
    score += max(0.0, (650.0 - credit_score) / 8.0)
    score += 8.0 if age >= 55 else 0.0
    score += 6.0 if balance < 1000 else 0.0
    score += 7.0 if num_products <= 1 else -4.0
    score += 10.0 if active == 0 else -6.0
    score += 18.0 if complaint else 0.0

    return round(max(0.0, min(100.0, score)), 2)


def get_primary_churn_driver(payload: dict) -> str:
    drivers = []
    if _to_int(payload.get("is_active_member"), 1) == 0:
        drivers.append("Low activity")
    if _to_float(payload.get("credit_score"), 700) < 600:
        drivers.append("Low credit score")
    if _to_int(payload.get("num_of_products"), 2) <= 1:
        drivers.append("Low product usage")
    if _to_int(payload.get("has_active_complaint"), 0) == 1:
        drivers.append("Active complaint")
    if _to_float(payload.get("balance"), 0) < 1000:
        drivers.append("Low balance")
    return drivers[0] if drivers else "Stable behavior"


def get_feature_importance():
    return [
        {"label": "Credit Score", "value": 25.0},
        {"label": "Activity Status", "value": 22.0},
        {"label": "Num Of Products", "value": 18.0},
        {"label": "Balance", "value": 15.0},
        {"label": "Age", "value": 12.0},
        {"label": "Tenure", "value": 8.0},
    ]

