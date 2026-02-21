# data_manager/services.py

import pandas as pd
from typing import Tuple


class DataProcessor:
    """Utility class for loading, validating and cleaning churn CSVs."""

    REQUIRED_COLUMNS = ['CreditScore', 'Age', 'Tenure', 'Balance', 'NumOfProducts']

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

        # check required columns exist
        missing = [c for c in DataProcessor.REQUIRED_COLUMNS if c not in df.columns]
        if missing:
            return pd.DataFrame(), f"missing required columns: {', '.join(missing)}"

        # fill numeric fields
        for col in df.columns:
            if pd.api.types.is_numeric_dtype(df[col]):
                median = df[col].median()
                df[col].fillna(median, inplace=True)

        # encode fields
        if 'Gender' in df.columns:
            df['Gender'] = df['Gender'].map({'Male': 1, 'Female': 0}).fillna(0).astype(int)
        if 'Geography' in df.columns:
            # simple label encoding; pandas will assign 0,1,2,...
            df['Geography'] = df['Geography'].astype('category').cat.codes

        return df, 'success'
