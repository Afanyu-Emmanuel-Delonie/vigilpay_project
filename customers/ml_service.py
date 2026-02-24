import logging
from pathlib import Path

logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parents[1]
DATASET_DIR = BASE_DIR / "customers" / "dataset"
ARTIFACT_DIR = BASE_DIR / "customers" / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "churn_model.joblib"
_MODEL_CACHE = None
_MODEL_CACHE_MTIME = None

FEATURE_COLUMNS = [
    "credit_score",
    "geography",
    "gender",
    "age",
    "tenure",
    "balance",
    "num_of_products",
    "has_cr_card",
    "is_active_member",
    "has_active_complaint",
]
NUMERIC_COLUMNS = [
    "credit_score",
    "age",
    "tenure",
    "balance",
    "num_of_products",
    "has_cr_card",
    "is_active_member",
    "has_active_complaint",
]
CATEGORICAL_COLUMNS = ["geography", "gender"]


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


def _payload_to_row(payload: dict) -> dict:
    return {
        "credit_score": _to_float(payload.get("credit_score"), 600.0),
        "geography": str(payload.get("geography") or "Unknown"),
        "gender": str(payload.get("gender") or "Unknown"),
        "age": _to_int(payload.get("age"), 35),
        "tenure": _to_int(payload.get("tenure"), 0),
        "balance": _to_float(payload.get("balance"), 0.0),
        "num_of_products": _to_int(payload.get("num_of_products"), 1),
        "has_cr_card": _to_int(payload.get("has_cr_card"), 1),
        "is_active_member": _to_int(payload.get("is_active_member"), 1),
        "has_active_complaint": _to_int(payload.get("has_active_complaint"), 0),
    }


def _fallback_predict(payload: dict) -> float:
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


def _load_model_bundle():
    global _MODEL_CACHE, _MODEL_CACHE_MTIME
    if not MODEL_PATH.exists():
        _MODEL_CACHE = None
        _MODEL_CACHE_MTIME = None
        return None
    try:
        current_mtime = MODEL_PATH.stat().st_mtime
        if _MODEL_CACHE is not None and _MODEL_CACHE_MTIME == current_mtime:
            return _MODEL_CACHE

        import joblib

        _MODEL_CACHE = joblib.load(MODEL_PATH)
        _MODEL_CACHE_MTIME = current_mtime
        return _MODEL_CACHE
    except Exception:
        logger.exception("Failed to load churn model artifact: %s", MODEL_PATH)
        return None


def _normalize_geo(value):
    text = str(value or "").strip()
    mapping = {"FRA": "France", "DEU": "Germany", "ESP": "Spain"}
    return mapping.get(text.upper(), text or "Unknown")


def _load_bank_churn_dataframe(dataset_dir: Path):
    import pandas as pd

    csv_path = dataset_dir / "Bank_Churn.csv"
    if not csv_path.exists():
        raise FileNotFoundError(f"Missing dataset file: {csv_path}")

    base = pd.read_csv(csv_path)
    base = base.rename(
        columns={
            "CustomerId": "customer_id",
            "Surname": "surname",
            "CreditScore": "credit_score",
            "Geography": "geography",
            "Gender": "gender",
            "Age": "age",
            "Tenure": "tenure",
            "Balance": "balance",
            "NumOfProducts": "num_of_products",
            "HasCrCard": "has_cr_card",
            "IsActiveMember": "is_active_member",
            "Exited": "label",
        }
    )

    required = [
        "customer_id",
        "surname",
        "credit_score",
        "geography",
        "gender",
        "age",
        "tenure",
        "balance",
        "num_of_products",
        "has_cr_card",
        "is_active_member",
        "label",
    ]
    missing = [c for c in required if c not in base.columns]
    if missing:
        raise ValueError(f"Bank_Churn.csv missing required columns: {missing}")

    messy_path = dataset_dir / "Bank_Churn_Messy.xlsx"
    if messy_path.exists():
        try:
            messy = pd.read_excel(messy_path)
            messy = messy.rename(
                columns={
                    "CustomerId": "customer_id",
                    "Surname": "surname",
                    "CreditScore": "credit_score",
                    "Geography": "geography",
                    "Gender": "gender",
                    "Age": "age",
                    "Tenure": "tenure",
                }
            )
            if "customer_id" in messy.columns:
                # Use messy file to enrich/override sparse textual fields by id.
                keep_cols = [c for c in ["customer_id", "surname", "geography", "gender"] if c in messy.columns]
                messy = messy[keep_cols].dropna(subset=["customer_id"]).drop_duplicates("customer_id")
                base = base.merge(
                    messy,
                    on="customer_id",
                    how="left",
                    suffixes=("", "_messy"),
                )
                for col in ["surname", "geography", "gender"]:
                    mixed = f"{col}_messy"
                    if mixed in base.columns:
                        base[col] = base[mixed].fillna(base[col])
                        base = base.drop(columns=[mixed])
        except Exception:
            logger.warning("Could not parse Bank_Churn_Messy.xlsx; continuing with Bank_Churn.csv only.")

    base["credit_score"] = base["credit_score"].apply(lambda v: _to_int(v, 600))
    base["age"] = base["age"].apply(lambda v: _to_int(v, 35))
    base["tenure"] = base["tenure"].apply(lambda v: _to_int(v, 0))
    base["balance"] = base["balance"].apply(lambda v: _to_float(v, 0.0))
    base["num_of_products"] = base["num_of_products"].apply(lambda v: _to_int(v, 1))
    base["has_cr_card"] = base["has_cr_card"].apply(lambda v: _to_int(v, 1))
    base["is_active_member"] = base["is_active_member"].apply(lambda v: _to_int(v, 1))
    base["label"] = base["label"].apply(lambda v: _to_int(v, -1))
    base["geography"] = base["geography"].apply(_normalize_geo)
    base["gender"] = base["gender"].astype(str).replace({"nan": "Unknown"}).fillna("Unknown")
    base["has_active_complaint"] = 0
    base = base[base["label"].isin([0, 1])]
    base = base.dropna(subset=["credit_score", "age", "tenure", "balance", "num_of_products"])
    base = base.drop_duplicates(subset=["customer_id"])
    return base


def _build_expanded_training_pool(df, target_rows: int, random_state: int):
    import numpy as np
    import pandas as pd

    pool = df.copy()
    if len(pool) >= target_rows:
        return pool

    rng = np.random.default_rng(random_state)
    needed = target_rows - len(pool)

    # Bootstrap rows and apply small numeric jitter for variability while
    # preserving realistic ranges.
    boot = pool.sample(n=needed, replace=True, random_state=random_state).reset_index(drop=True)

    boot["credit_score"] = (
        boot["credit_score"]
        + rng.integers(-20, 21, size=len(boot))
    ).clip(300, 900).astype(int)
    boot["age"] = (
        boot["age"]
        + rng.integers(-3, 4, size=len(boot))
    ).clip(18, 95).astype(int)
    boot["tenure"] = (
        boot["tenure"]
        + rng.integers(-1, 2, size=len(boot))
    ).clip(0, 20).astype(int)
    boot["balance"] = (
        boot["balance"]
        * (1.0 + rng.uniform(-0.12, 0.12, size=len(boot)))
    ).clip(0.0, 300000.0)

    # Keep binary/categorical features valid while injecting mild diversity.
    flip_active = rng.uniform(0, 1, size=len(boot)) < 0.08
    boot.loc[flip_active, "is_active_member"] = 1 - boot.loc[flip_active, "is_active_member"]

    flip_card = rng.uniform(0, 1, size=len(boot)) < 0.05
    boot.loc[flip_card, "has_cr_card"] = 1 - boot.loc[flip_card, "has_cr_card"]

    pool = pd.concat([pool, boot], ignore_index=True)
    return pool


def train_churn_model_from_datasets(min_rows=5000, random_state=42, tune=True):
    df = _load_bank_churn_dataframe(DATASET_DIR)
    expanded = _build_expanded_training_pool(df, target_rows=min_rows, random_state=random_state)
    sampled = expanded.sample(
        n=min_rows,
        random_state=random_state,
        replace=len(expanded) < min_rows,
    )
    samples = sampled[FEATURE_COLUMNS].to_dict(orient="records")
    labels = sampled["label"].astype(int).tolist()
    source = f"customers/dataset base={len(df)} expanded={len(expanded)} used={min_rows}"
    return train_churn_model(samples, labels, source=source, random_state=random_state, tune=tune)


def train_churn_model(samples: list[dict], labels: list[int], source="upload", random_state=42, tune=True) -> dict:
    if not samples or not labels or len(samples) != len(labels):
        return {"trained": False, "reason": "invalid training payload"}

    clean_labels = []
    clean_samples = []
    for sample, label in zip(samples, labels):
        try:
            y = int(float(label))
        except (TypeError, ValueError):
            continue
        if y not in (0, 1):
            continue
        clean_samples.append(_payload_to_row(sample))
        clean_labels.append(y)

    if len(clean_labels) < 200:
        return {"trained": False, "reason": "insufficient labeled rows"}
    if len(set(clean_labels)) < 2:
        return {"trained": False, "reason": "training requires both classes (0 and 1)"}

    try:
        import joblib
        import pandas as pd
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.metrics import accuracy_score, precision_score, recall_score, roc_auc_score
        from sklearn.model_selection import RandomizedSearchCV, StratifiedKFold, train_test_split
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import OneHotEncoder

        X = pd.DataFrame(clean_samples, columns=FEATURE_COLUMNS)
        y = clean_labels

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=random_state, stratify=y
        )

        preprocessor = ColumnTransformer(
            transformers=[
                ("num", "passthrough", NUMERIC_COLUMNS),
                ("cat", OneHotEncoder(handle_unknown="ignore"), CATEGORICAL_COLUMNS),
            ],
            remainder="drop",
        )

        # Explicit depth cap to reduce overfitting.
        base_model = RandomForestClassifier(
            n_estimators=500,
            max_depth=5,
            random_state=random_state,
            class_weight="balanced_subsample",
            min_samples_leaf=8,
            max_features="sqrt",
        )
        pipeline = Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                ("model", base_model),
            ]
        )
        best_params = {}
        if tune:
            search = RandomizedSearchCV(
                estimator=pipeline,
                param_distributions={
                    "model__n_estimators": [300, 500, 700, 900],
                    "model__min_samples_leaf": [4, 8, 12, 16],
                    "model__min_samples_split": [2, 6, 10, 14],
                    "model__max_features": ["sqrt", "log2", None],
                    "model__class_weight": ["balanced", "balanced_subsample", None],
                },
                n_iter=12,
                scoring="roc_auc",
                cv=StratifiedKFold(n_splits=3, shuffle=True, random_state=random_state),
                random_state=random_state,
                n_jobs=-1,
                refit=True,
                verbose=0,
            )
            search.fit(X_train, y_train)
            pipeline = search.best_estimator_
            best_params = search.best_params_
        else:
            pipeline.fit(X_train, y_train)

        train_pred = pipeline.predict(X_train)
        test_pred = pipeline.predict(X_test)
        test_prob = pipeline.predict_proba(X_test)[:, 1]

        metrics = {
            "accuracy": round(float(accuracy_score(y_test, test_pred)) * 100.0, 2),
            "precision": round(float(precision_score(y_test, test_pred, zero_division=0)) * 100.0, 2),
            "recall": round(float(recall_score(y_test, test_pred, zero_division=0)) * 100.0, 2),
            "auc": round(float(roc_auc_score(y_test, test_prob)) * 100.0, 2),
            "train_accuracy": round(float(accuracy_score(y_train, train_pred)) * 100.0, 2),
            "generalization_gap": round(
                float(accuracy_score(y_train, train_pred) - accuracy_score(y_test, test_pred)) * 100.0,
                2,
            ),
            "test_samples": int(len(y_test)),
            "source": source,
            "tuned": bool(tune),
        }
        if best_params:
            metrics["best_params"] = best_params

        ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
        joblib.dump({"pipeline": pipeline, "metrics": metrics}, MODEL_PATH)
        _load_model_bundle()

        return {
            "trained": True,
            "samples": len(clean_labels),
            "path": str(MODEL_PATH),
            "metrics": metrics,
        }
    except Exception:
        logger.exception("Failed to train churn model.")
        return {"trained": False, "reason": "training error"}


def get_model_metrics():
    bundle = _load_model_bundle()
    if bundle:
        return bundle.get("metrics")
    return None


def predict_churn(payload: dict) -> float:
    bundle = _load_model_bundle()
    if bundle and "pipeline" in bundle:
        try:
            import pandas as pd

            row = _payload_to_row(payload)
            X = pd.DataFrame([row], columns=FEATURE_COLUMNS)
            proba = float(bundle["pipeline"].predict_proba(X)[0][1]) * 100.0
            return round(max(0.0, min(100.0, proba)), 2)
        except Exception:
            logger.warning("Model prediction failed. Falling back to heuristic scoring.")

    return _fallback_predict(payload)


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
    bundle = _load_model_bundle()
    if bundle and "pipeline" in bundle:
        try:
            pipeline = bundle["pipeline"]
            preprocessor = pipeline.named_steps["preprocessor"]
            model = pipeline.named_steps["model"]
            raw_names = preprocessor.get_feature_names_out()
            importances = model.feature_importances_

            grouped = {
                "Credit Score": 0.0,
                "Activity Status": 0.0,
                "Num Of Products": 0.0,
                "Balance": 0.0,
                "Age": 0.0,
                "Tenure": 0.0,
                "Has Card": 0.0,
                "Geography": 0.0,
                "Gender": 0.0,
                "Active Complaint": 0.0,
            }

            for name, value in zip(raw_names, importances):
                n = name.lower()
                if "credit_score" in n:
                    grouped["Credit Score"] += float(value)
                elif "is_active_member" in n:
                    grouped["Activity Status"] += float(value)
                elif "num_of_products" in n:
                    grouped["Num Of Products"] += float(value)
                elif "balance" in n:
                    grouped["Balance"] += float(value)
                elif "age" in n:
                    grouped["Age"] += float(value)
                elif "tenure" in n:
                    grouped["Tenure"] += float(value)
                elif "has_cr_card" in n:
                    grouped["Has Card"] += float(value)
                elif "geography" in n:
                    grouped["Geography"] += float(value)
                elif "gender" in n:
                    grouped["Gender"] += float(value)
                elif "has_active_complaint" in n:
                    grouped["Active Complaint"] += float(value)

            total = sum(grouped.values()) or 1.0
            ranked = sorted(grouped.items(), key=lambda item: item[1], reverse=True)
            return [
                {"label": label, "value": round((val / total) * 100, 1)}
                for label, val in ranked
                if val > 0
            ][:8]
        except Exception:
            logger.warning("Could not compute model feature importance.")

    return [
        {"label": "Credit Score", "value": 25.0},
        {"label": "Activity Status", "value": 22.0},
        {"label": "Num Of Products", "value": 18.0},
        {"label": "Balance", "value": 15.0},
        {"label": "Age", "value": 12.0},
        {"label": "Tenure", "value": 8.0},
    ]
