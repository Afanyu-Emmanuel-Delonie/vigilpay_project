# data_manager/services.py

import pandas as pd
from typing import Tuple


class DataProcessor:
    """Utility class for loading, validating and cleaning churn CSVs."""

    REQUIRED_COLUMNS = ["CreditScore", "Age", "Tenure", "Balance", "NumOfProducts"]
    CANONICAL_ALIASES = {
        "CustomerId": ["CustomerId", "customer_id", "customerid"],
        "Surname": ["Surname", "surname", "last_name", "lastname", "name"],
        "CreditScore": ["CreditScore", "credit_score", "creditscore"],
        "Geography": ["Geography", "geography", "country", "region"],
        "Gender": ["Gender", "gender", "sex"],
        "Age": ["Age", "age"],
        "Tenure": ["Tenure", "tenure"],
        "Balance": ["Balance", "balance"],
        "NumOfProducts": ["NumOfProducts", "num_of_products", "numofproducts", "products"],
        "HasCrCard": ["HasCrCard", "has_cr_card", "hascrcard", "credit_card"],
        "IsActiveMember": ["IsActiveMember", "is_active_member", "isactivemember", "active_member"],
        "ChurnRiskScore": ["ChurnRiskScore", "churn_risk_score", "churn", "target"],
    }

    @staticmethod
    def _norm_col(name: str) -> str:
        return "".join(ch for ch in str(name).lower() if ch.isalnum())

    @classmethod
    def _normalize_columns(cls, df: pd.DataFrame) -> pd.DataFrame:
        normalized_map = {}
        existing_norm = {cls._norm_col(c): c for c in df.columns}

        for canonical, aliases in cls.CANONICAL_ALIASES.items():
            for alias in aliases:
                match = existing_norm.get(cls._norm_col(alias))
                if match:
                    normalized_map[match] = canonical
                    break

        return df.rename(columns=normalized_map)

    @staticmethod
    def validate_and_clean(file_path: str) -> Tuple[pd.DataFrame, str]:
        """Load a CSV from *file_path* and make sure it is usable.

        The method performs the following:
        * Reads the file into a :class:`pandas.DataFrame`.
        * Verifies that every column in ``REQUIRED_COLUMNS`` is present.
        * Fills missing numeric values with the column median.
        * Encodes ``Gender`` (Male=1/Female=0) and ``Geography`` (categories to codes).

        Returns a tuple ``(cleaned_df, message)``.  If the DataFrame is empty the
        message will contain an error description.
        """
        try:
            df = pd.read_csv(file_path)
        except Exception as exc:  # e.g. parsing error or file not found
            return pd.DataFrame(), f"failed to read csv: {exc}"

        df = DataProcessor._normalize_columns(df)

        # check required columns exist
        missing = [c for c in DataProcessor.REQUIRED_COLUMNS if c not in df.columns]
        if missing:
            return pd.DataFrame(), f"missing required columns: {', '.join(missing)}"

        numeric_like = [
            "CustomerId",
            "CreditScore",
            "Age",
            "Tenure",
            "Balance",
            "NumOfProducts",
            "HasCrCard",
            "IsActiveMember",
            "ChurnRiskScore",
        ]
        for col in numeric_like:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors="coerce")

        numeric_cols = [c for c in numeric_like if c in df.columns]
        if numeric_cols:
            df[numeric_cols] = df[numeric_cols].fillna(df[numeric_cols].median(numeric_only=True))

        if "Gender" in df.columns:
            df["Gender"] = (
                df["Gender"]
                .astype(str)
                .str.strip()
                .str.lower()
                .replace({"m": "male", "f": "female"})
                .str.title()
            )
        if "Geography" in df.columns:
            df["Geography"] = df["Geography"].astype(str).str.strip().str.title()
        if "Surname" in df.columns:
            df["Surname"] = df["Surname"].fillna("").astype(str).str.strip()

        return df, "success"
