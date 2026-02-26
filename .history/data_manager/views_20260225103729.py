import csv
from io import StringIO

from django.contrib.auth.decorators import login_required
from django.db import transaction
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views import View

from customers.ml_service import predict_churn, train_churn_model
from customers.models import Customer
from data_manager.models import UploadHistory

MAX_UPLOAD_SIZE_BYTES = 10 * 1024 * 1024
REQUIRED_COLUMN_ALIASES = {
    # Optional: auto-generated when absent.
    "CustomerId": ("customerid", "customer_id"),
    "Surname": ("surname",),
    # Required columns (accept common snake_case aliases too).
    "CreditScore": ("creditscore", "credit_score"),
    "Geography": ("geography",),
    "Gender": ("gender",),
    "Age": ("age",),
    "Tenure": ("tenure",),
    "Balance": ("balance",),
    "NumOfProducts": ("numofproducts", "num_of_products"),
    "HasCrCard": ("hascrcard", "has_cr_card"),
    "IsActiveMember": ("isactivemember", "is_active_member"),
}
OPTIONAL_AUTOFILL_COLUMNS = {"CustomerId", "Surname"}


def _pick(row, *keys, default=None):
    for key in keys:
        if key in row and str(row[key]).strip() != "":
            return row[key]
    return default


def _has_any_column(normalized_headers, aliases):
    return any(alias in normalized_headers for alias in aliases)


def _to_int(value, default=0):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def _to_float(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _validate_row(row, idx):
    errors = []

    credit_score = _to_int(_pick(row, "CreditScore", "credit_score"), -1)
    if credit_score < 0 or credit_score > 1000:
        errors.append(f"row {idx}: CreditScore must be between 0 and 1000")

    age = _to_int(_pick(row, "Age", "age"), -1)
    if age < 0 or age > 120:
        errors.append(f"row {idx}: Age must be between 0 and 120")

    tenure = _to_int(_pick(row, "Tenure", "tenure"), -1)
    if tenure < 0 or tenure > 100:
        errors.append(f"row {idx}: Tenure must be between 0 and 100")

    balance = _to_float(_pick(row, "Balance", "balance"), -1.0)
    if balance < 0:
        errors.append(f"row {idx}: Balance must be non-negative")

    num_products = _to_int(_pick(row, "NumOfProducts", "num_of_products"), -1)
    if num_products < 1 or num_products > 10:
        errors.append(f"row {idx}: NumOfProducts must be between 1 and 10")

    has_card = _to_int(_pick(row, "HasCrCard", "has_cr_card"), -1)
    if has_card not in (0, 1):
        errors.append(f"row {idx}: HasCrCard must be 0 or 1")

    active_member = _to_int(_pick(row, "IsActiveMember", "is_active_member"), -1)
    if active_member not in (0, 1):
        errors.append(f"row {idx}: IsActiveMember must be 0 or 1")

    return errors


@method_decorator(login_required(login_url="login_page"), name="dispatch")
class UploadDataView(View):
    def post(self, request, *args, **kwargs):
        uploaded = request.FILES.get("file")
        if not uploaded:
            return JsonResponse({"error": "No file uploaded."}, status=400)

        if not uploaded.name.lower().endswith(".csv"):
            return JsonResponse({"error": "Only CSV files are accepted."}, status=400)
        if uploaded.size > MAX_UPLOAD_SIZE_BYTES:
            return JsonResponse({"error": "File too large. Maximum allowed size is 10MB."}, status=400)

        try:
            content = uploaded.read().decode("utf-8-sig", errors="ignore")
            reader = csv.DictReader(StringIO(content))
            if not reader.fieldnames:
                return JsonResponse({"error": "CSV appears empty or missing headers."}, status=400)

            normalized = {name.strip().lower() for name in reader.fieldnames if name}
            missing = []
            for canonical, aliases in REQUIRED_COLUMN_ALIASES.items():
                if canonical in OPTIONAL_AUTOFILL_COLUMNS:
                    continue
                if not _has_any_column(normalized, aliases):
                    missing.append(canonical)
            if missing:
                return JsonResponse(
                    {"error": f"Missing required columns: {', '.join(missing)}"},
                    status=400,
                )

            rows = list(reader)
        except Exception:
            return JsonResponse({"error": "Could not read CSV file."}, status=400)

        if not rows:
            return JsonResponse({"error": "CSV has no data rows."}, status=400)

        validation_errors = []
        for idx, row in enumerate(rows, start=2):
            validation_errors.extend(_validate_row(row, idx))
            if len(validation_errors) >= 10:
                break

        if validation_errors:
            return JsonResponse(
                {
                    "error": "CSV validation failed.",
                    "details": validation_errors,
                },
                status=400,
            )

        training_samples = []
        training_labels = []
        prepared_rows = []
        for idx, row in enumerate(rows, start=1):
            payload = {
                "credit_score": _to_int(_pick(row, "CreditScore", "credit_score"), 600),
                "geography": str(_pick(row, "Geography", "geography", default="Unknown")),
                "gender": str(_pick(row, "Gender", "gender", default="Unknown")),
                "age": _to_int(_pick(row, "Age", "age"), 35),
                "tenure": _to_int(_pick(row, "Tenure", "tenure"), 0),
                "balance": _to_float(_pick(row, "Balance", "balance"), 0.0),
                "num_of_products": _to_int(_pick(row, "NumOfProducts", "num_of_products"), 1),
                "has_cr_card": _to_int(_pick(row, "HasCrCard", "has_cr_card"), 1),
                "is_active_member": _to_int(_pick(row, "IsActiveMember", "is_active_member"), 1),
                "has_active_complaint": 0,
            }
            prepared_rows.append((idx, row, payload))

            label_raw = _pick(row, "Exited", "exited", "churn_risk_score")
            if label_raw is None:
                continue
            label = _to_int(label_raw, -1)
            if label in (0, 1):
                training_samples.append(payload)
                training_labels.append(label)

        model_result = {"trained": False, "reason": "no labels found in upload"}
        if training_labels:
            model_result = train_churn_model(training_samples, training_labels)

        created = 0
        with transaction.atomic():
            Customer.objects.all().delete()
            for idx, row, payload in prepared_rows:
                customer_id = _to_int(_pick(row, "CustomerId", "customer_id", "customerid"), idx)
                predicted_score = predict_churn(payload)
                Customer.objects.create(
                    customer_id=customer_id,
                    surname=str(_pick(row, "Surname", "surname", default=f"Customer {idx}")),
                    credit_score=payload["credit_score"],
                    geography=payload["geography"],
                    gender=payload["gender"],
                    age=payload["age"],
                    tenure=payload["tenure"],
                    balance=payload["balance"],
                    num_of_products=payload["num_of_products"],
                    has_cr_card=payload["has_cr_card"],
                    is_active_member=payload["is_active_member"],
                    churn_risk_score=predicted_score,
                )
                created += 1

            UploadHistory.objects.create(
                file_name=uploaded.name,
                processed=True,
                row_count=created,
                uploaded_by=request.user,
            )

        return JsonResponse(
            {
                "rows_prepared": created,
                "ml_model": model_result,
            },
            status=200,
        )
