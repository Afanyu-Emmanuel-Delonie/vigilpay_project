"""
core.services.export
---------------------
Generates CSV exports of interaction data for ML model retraining.
Called from the admin dashboard or a management command — never from the API.
"""

import csv
import logging
from pathlib import Path

from .. import InteractionLog

logger = logging.getLogger(__name__)

_DEFAULT_EXPORT_FILENAME = "ml_training_export.csv"

_CSV_HEADERS = [
    "user_id",
    "user_type",
    "loyalty_score",
    "credit_score",
    "has_active_complaint",
    "event_type",
    "product_name",
    "complaint_category",
    "timestamp",
]


def generate_training_data(output_path: str | None = None) -> str:
    """
    Export all InteractionLog rows to a CSV file for ML retraining.

    Args:
        output_path: Absolute path for the output file.
                     Defaults to <services_dir>/ml_training_export.csv.

    Returns:
        The absolute path of the written file as a string.
    """
    base_dir = Path(__file__).resolve().parent
    export_path = Path(output_path) if output_path else (base_dir / _DEFAULT_EXPORT_FILENAME)

    rows = (
        InteractionLog.objects
        .select_related("user", "user__profile", "product", "complaint")
        .all()
    )

    with export_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(_CSV_HEADERS)

        for row in rows:
            profile = getattr(row.user, "profile", None)
            writer.writerow([
                row.user_id,
                row.user.user_type,
                profile.loyalty_score if profile else "",
                profile.credit_score if profile else "",
                int(row.user.has_active_complaint),
                row.event_type,
                row.product.name if row.product else "",
                row.complaint.category if row.complaint else "",
                row.created_at.isoformat(),
            ])

    logger.info("Training data exported to %s (%d rows).", export_path, rows.count())
    return str(export_path)