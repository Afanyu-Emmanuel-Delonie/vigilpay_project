from __future__ import annotations

import csv
from functools import lru_cache
from pathlib import Path
from typing import Mapping

import joblib


BASE_DIR = Path(__file__).resolve().parent
ML_ASSETS_DIR = BASE_DIR / "ml_assets"
MODEL_PATH = ML_ASSETS_DIR / "model.pkl"
DATASET_PATH = ML_ASSETS_DIR / "customer_dataset.csv"
FEATURE_NAMES = [
    "Credit Score",
    "Geography",
    "Gender",
    "Age",
    "Tenure",
    "Balance",
    "Number of Products",
    "Has Credit Card",
    "Is Active Member",
]


@lru_cache(maxsize=1)
def _load_model():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"ML model not found at {MODEL_PATH}")
    return joblib.load(MODEL_PATH)


@lru_cache(maxsize=1)
def _load_encoders():
    if not DATASET_PATH.exists():
        return {"geography": {}, "gender": {}}

    geo_set = set()
    gender_set = set()

    with DATASET_PATH.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            geo = (row.get("geography") or "").strip()
            gender = (row.get("gender") or "").strip()
            if geo:
                geo_set.add(geo)
            if gender:
                gender_set.add(gender)

    geo_values = sorted(geo_set)
    gender_values = sorted(gender_set)

    return {
        "geography": {name: idx for idx, name in enumerate(geo_values)},
        "gender": {name: idx for idx, name in enumerate(gender_values)},
    }


def _encode(mapping: Mapping[str, int], value: object) -> int:
    if value is None:
        return 0
    as_text = str(value).strip()
    if not as_text:
        return 0
    return int(mapping.get(as_text, 0))


def predict_churn(customer_data: Mapping[str, object]) -> float:
    """Return churn risk probability in percentage (0-100)."""
    model = _load_model()
    encoders = _load_encoders()

    feature_vector = [
        [
            float(customer_data.get("credit_score", 0) or 0),
            float(_encode(encoders["geography"], customer_data.get("geography"))),
            float(_encode(encoders["gender"], customer_data.get("gender"))),
            float(customer_data.get("age", 0) or 0),
            float(customer_data.get("tenure", 0) or 0),
            float(customer_data.get("balance", 0) or 0),
            float(customer_data.get("num_of_products", 0) or 0),
            float(customer_data.get("has_cr_card", 0) or 0),
            float(customer_data.get("is_active_member", 0) or 0),
        ]
    ]

    probability = float(model.predict_proba(feature_vector)[0][1])
    return round(probability * 100, 2)


def get_primary_churn_driver(customer_data: Mapping[str, object]) -> str:
    credit_score = int(customer_data.get("credit_score", 0) or 0)
    balance = float(customer_data.get("balance", 0) or 0)
    is_active_member = int(customer_data.get("is_active_member", 0) or 0)
    num_of_products = int(customer_data.get("num_of_products", 0) or 0)
    age = int(customer_data.get("age", 0) or 0)

    if is_active_member == 0:
        return "Inactive account behaviour"
    if credit_score < 520:
        return "Low credit profile"
    if balance < 10000:
        return "Low balance exposure"
    if num_of_products <= 1:
        return "Single-product relationship"
    if age >= 60:
        return "Senior segment volatility"
    return "Multi-factor behavioural pattern"


def get_feature_importance() -> list[dict[str, float | str]]:
    """Return model feature importance percentages (0-100)."""
    model = _load_model()
    values = getattr(model, "feature_importances_", None)
    if values is None:
        return []

    rows = []
    for idx, raw in enumerate(values):
        label = FEATURE_NAMES[idx] if idx < len(FEATURE_NAMES) else f"Feature {idx + 1}"
        rows.append({"label": label, "value": round(float(raw) * 100, 2)})

    rows.sort(key=lambda item: item["value"], reverse=True)
    return rows
