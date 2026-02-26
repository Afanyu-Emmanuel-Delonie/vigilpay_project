﻿import logging
from functools import wraps

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.core.paginator import EmptyPage, PageNotAnInteger, Paginator
from django.db.models import CharField, Q
from django.db.models.functions import Cast
from django.http import HttpResponseRedirect, JsonResponse
from django.shortcuts import redirect, render
from django.urls import reverse

from core.models import User
from customers.ml_service import (
    get_feature_importance,
    get_model_metrics,
    get_primary_churn_driver,
    predict_churn,
)
from customers.models import Customer
from data_manager.models import UploadHistory

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _risk_level(score: float) -> str:
    if score >= 70:
        return "High"
    if score >= 40:
        return "Medium"
    return "Low"


def _to_payload(customer) -> dict:
    return {
        "credit_score": customer.credit_score,
        "geography": customer.geography,
        "gender": customer.gender,
        "age": customer.age,
        "tenure": customer.tenure,
        "balance": float(customer.balance or 0),
        "num_of_products": customer.num_of_products,
        "has_cr_card": customer.has_cr_card,
        "is_active_member": customer.is_active_member,
    }


def _safe_score(customer) -> float:
    """
    Return a 0-100 churn score. Uses the saved score if available,
    falls back to the ML model, then falls back to 0.0.
    Avoids calling predict_churn when we already have a stored value.
    """
    saved = customer.churn_risk_score
    payload = _to_payload(customer)
    if saved is not None:
        try:
            value = float(saved)
            # Legacy uploads sometimes stored labels (0/1) instead of probabilities.
            if value in (0.0, 1.0):
                return float(predict_churn(payload))
            # Normalise true probability range 0-1 to 0-100.
            if 0.0 < value < 1.0:
                value *= 100
            return max(0.0, min(100.0, value))
        except (TypeError, ValueError):
            pass
    try:
        return float(predict_churn(payload))
    except Exception:
        logger.warning("predict_churn failed for customer %s.", getattr(customer, "customer_id", "?"))
        return 0.0


def _initials(name: str) -> str:
    parts = [p for p in (name or "").strip().split() if p]
    if len(parts) >= 2:
        return (parts[0][0] + parts[1][0]).upper()
    return (name or "CU")[:2].upper()


def _compact_number(value, currency=False) -> str:
    try:
        number = float(value or 0)
    except (TypeError, ValueError):
        number = 0.0

    abs_n = abs(number)
    if abs_n >= 1_000_000_000:
        text = f"{number / 1_000_000_000:.1f}B"
    elif abs_n >= 1_000_000:
        text = f"{number / 1_000_000:.1f}M"
    elif abs_n >= 1_000:
        text = f"{number / 1_000:.1f}K"
    else:
        text = f"{number:.1f}"

    text = text.replace(".0B", "B").replace(".0M", "M").replace(".0K", "K").replace(".0", "")
    return f"${text}" if currency else text


def _score_all_customers(customers: list) -> list:
    """
    Score a list of Customer objects in one pass.
    Calls predict_churn only for customers without a stored score,
    keeping ML calls to the minimum necessary.
    """
    scored = []
    for customer in customers:
        score = round(_safe_score(customer), 2)
        scored.append({
            "customer_id": customer.customer_id,
            "surname": customer.surname,
            "initials": _initials(customer.surname),
            "credit_score": customer.credit_score,
            "geography": customer.geography,
            "gender": customer.gender,
            "age": int(customer.age or 0),
            "balance": float(customer.balance or 0),
            "num_of_products": customer.num_of_products,
            "is_active_member": int(customer.is_active_member or 0),
            "risk_score": score,
            "risk_level": _risk_level(score),
            "risk_class": _risk_level(score).lower(),
            "driver": _safe_driver(customer),
        })
    return scored


def _safe_driver(customer) -> str:
    try:
        return get_primary_churn_driver(_to_payload(customer))
    except Exception:
        return "Unavailable"


def _paginate(queryset, page_number, per_page=20):
    paginator = Paginator(queryset, per_page)
    try:
        page_obj = paginator.page(page_number)
    except PageNotAnInteger:
        page_obj = paginator.page(1)
    except EmptyPage:
        page_obj = paginator.page(paginator.num_pages)
    return paginator, page_obj


def _page_numbers(paginator, current_page):
    """Build a smart page number list with ellipses."""
    total = paginator.num_pages
    if total <= 7:
        return list(paginator.page_range)

    numbers = [1]
    if current_page > 4:
        numbers.append("...")
    for n in range(max(2, current_page - 2), min(total - 1, current_page + 2) + 1):
        numbers.append(n)
    if current_page < total - 3:
        numbers.append("...")
    numbers.append(total)
    return numbers


def _safe_dashboard_context() -> dict:
    """Fallback context used when the dashboard crashes."""
    return {
        "total_customers": 0,
        "total_customers_compact": "0",
        "churn_rate": 0.0,
        "high_risk_count": 0,
        "at_risk_balance": 0.0,
        "at_risk_balance_compact": "$0",
        "active_members": 0,
        "active_members_compact": "0",
        "avg_score": 0.0,
        "top_customers": [],
        "highest_geo": "N/A",
        "highest_geo_count": 0,
        "inactive_low_balance": 0,
        "multi_product_stable": 0,
        "feature_importance": [],
        "dashboard_data": {
            "bar": {"labels": ["Low Risk", "Medium Risk", "High Risk"], "values": [0, 0, 0]},
            "donut": {"labels": [], "values": []},
            "scatter": {"high": [], "low": []},
            "line": {"labels": [f"{i}Y" for i in range(11)], "values": [0] * 11},
        },
    }


# ---------------------------------------------------------------------------
# Decorator
# ---------------------------------------------------------------------------

def no_500_dashboard(view_func):
    """
    Catches unhandled exceptions in dashboard views and renders a safe
    fallback instead of a 500. Always logs the full traceback so the
    error is still visible in the server logs.
    """
    @wraps(view_func)
    def _wrapped(request, *args, **kwargs):
        try:
            return view_func(request, *args, **kwargs)
        except Exception:
            logger.exception("Dashboard view '%s' raised an unhandled exception.", view_func.__name__)
            messages.error(request, "Dashboard data is temporarily unavailable.")
            return render(request, "core/dashboard.html", _safe_dashboard_context())
    return _wrapped


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
@no_500_dashboard
def dashboard_page(request):
    try:
        customers = list(Customer.objects.all())
    except Exception:
        logger.exception("Failed to load customers from database.")
        messages.error(request, "Customer dataset is unavailable. Upload a dataset to continue.")
        customers = []

    # Score all customers in one pass — avoids repeated ML calls per page
    scored = _score_all_customers(customers)
    scored.sort(key=lambda c: c["risk_score"], reverse=True)

    total = len(scored)
    high   = sum(1 for c in scored if c["risk_score"] >= 70)
    medium = sum(1 for c in scored if 40 <= c["risk_score"] < 70)
    low    = total - high - medium

    avg_score      = round(sum(c["risk_score"] for c in scored) / total, 2) if total else 0.0
    churn_rate     = round((high / total) * 100, 2) if total else 0.0
    at_risk_balance = sum(c["balance"] for c in scored if c["risk_score"] >= 80)
    active_members = sum(1 for c in scored if c["is_active_member"] == 1)

    # Geography breakdown
    geo_count = {}
    for c in scored:
        geo_count[c["geography"]] = geo_count.get(c["geography"], 0) + 1
    sorted_geo = sorted(geo_count.items(), key=lambda x: x[1], reverse=True)
    geo_labels = [g[0] for g in sorted_geo[:6]]
    geo_values = [g[1] for g in sorted_geo[:6]]

    # Tenure risk trend
    tenure_sum   = {str(i): 0.0 for i in range(11)}
    tenure_count = {str(i): 0   for i in range(11)}
    for customer, row in zip(customers, scored):
        key = str(max(0, min(10, int(customer.tenure or 0))))
        tenure_sum[key]   += row["risk_score"]
        tenure_count[key] += 1

    tenure_values = [
        round(tenure_sum[str(i)] / tenure_count[str(i)], 2) if tenure_count[str(i)] else 0
        for i in range(11)
    ]

    # Scatter data (capped for performance)
    high_points = [{"x": c["age"], "y": c["balance"]} for c in scored if c["risk_score"] >= 50][:250]
    low_points  = [{"x": c["age"], "y": c["balance"]} for c in scored if c["risk_score"] < 50][:250]

    try:
        feature_importance = get_feature_importance()
    except Exception:
        logger.warning("Feature importance unavailable.")
        feature_importance = []

    context = {
        "total_customers": total,
        "total_customers_compact": _compact_number(total),
        "churn_rate": churn_rate,
        "high_risk_count": high,
        "at_risk_balance": at_risk_balance,
        "at_risk_balance_compact": _compact_number(at_risk_balance, currency=True),
        "active_members": active_members,
        "active_members_compact": _compact_number(active_members),
        "avg_score": avg_score,
        "top_customers": scored[:5],
        "highest_geo": geo_labels[0] if geo_labels else "N/A",
        "highest_geo_count": geo_values[0] if geo_values else 0,
        "inactive_low_balance": sum(1 for c in scored if c["is_active_member"] == 0 and c["balance"] < 10000),
        "multi_product_stable": sum(1 for c in scored if c["num_of_products"] >= 2 and c["risk_score"] < 40),
        "feature_importance": feature_importance,
        "dashboard_data": {
            "bar":    {"labels": ["Low Risk", "Medium Risk", "High Risk"], "values": [low, medium, high]},
            "donut":  {"labels": geo_labels, "values": geo_values},
            "scatter": {"high": high_points, "low": low_points},
            "line":   {"labels": [f"{i}Y" for i in range(11)], "values": tenure_values},
        },
    }
    return render(request, "core/dashboard.html", context)


# ---------------------------------------------------------------------------
# Risk Level
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def risk_level_page(request):
    customers = list(Customer.objects.all())

    # Score once upfront — no per-row ML calls inside the filter loop
    scored = _score_all_customers(customers)

    # Filters
    selected_risk   = request.GET.get("risk_level", "").strip().lower()
    selected_geo    = request.GET.get("geography", "").strip()
    selected_active = request.GET.get("is_active", "").strip()
    query           = request.GET.get("q", "").strip().lower()

    rows = [
        c for c in scored
        if (not selected_risk   or c["risk_class"] == selected_risk)
        and (not selected_geo   or c["geography"] == selected_geo)
        and (selected_active not in {"0", "1"} or str(c["is_active_member"]) == selected_active)
        and (not query or query in str(c["customer_id"]).lower() or query in c["surname"].lower())
    ]

    rows.sort(key=lambda c: c["risk_score"], reverse=True)

    total  = len(rows)
    high   = sum(1 for c in rows if c["risk_score"] >= 70)
    medium = sum(1 for c in rows if 40 <= c["risk_score"] < 70)
    low    = total - high - medium

    geographies = sorted({c["geography"] for c in scored if c["geography"]})

    paginator, page_obj = _paginate(rows, request.GET.get("page", 1))

    querydict = request.GET.copy()
    querydict.pop("page", None)

    context = {
        "customers": page_obj.object_list,
        "total_customers": total,
        "high_risk_count": high,
        "medium_risk_count": medium,
        "low_risk_count": low,
        "geographies": geographies,
        "page_obj": page_obj,
        "paginator": paginator,
        "page_numbers": _page_numbers(paginator, page_obj.number),
        "base_query": querydict.urlencode(),
    }
    return render(request, "dashboard/risk_level.html", context)


# ---------------------------------------------------------------------------
# Data Management
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def data_management_page(request):
    upload_history = (
        UploadHistory.objects.select_related("uploaded_by")
        .order_by("-uploaded_at")[:100]
    )
    return render(request, "dashboard/data_management.html", {
        "upload_history": upload_history,
        "can_manage_dataset": True,
    })


@login_required(login_url="login_page")
def clear_dataset(request):
    if request.method != "POST":
        messages.error(request, "Invalid request.")
        return redirect("data_management_page")

    customer_count = Customer.objects.count()
    uploads = list(UploadHistory.objects.all())

    for upload in uploads:
        if upload.file_name:
            upload.file_name.delete(save=False)

    UploadHistory.objects.all().delete()
    Customer.objects.all().delete()

    messages.success(
        request,
        f"Dataset cleared: {customer_count} customers and {len(uploads)} upload records removed.",
    )
    return redirect("data_management_page")


# ---------------------------------------------------------------------------
# Model Insights
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def model_insight_page(request):
    customers = list(Customer.objects.all())
    latest_upload = UploadHistory.objects.filter(processed=True).order_by("-uploaded_at").first()

    has_data = len(customers) > 0 and latest_upload is not None

    scored = []
    high_points, low_points = [], []
    region_totals, region_high = {}, {}
    truth_pairs = []

    for customer in customers:
        score = round(_safe_score(customer), 2)
        geo = customer.geography or "Unknown"

        scored.append({"risk_score": score, "geography": geo})

        point = {"x": int(customer.age or 0), "y": round(float(customer.balance or 0), 2)}
        (high_points if score >= 50 else low_points).append(point)

        region_totals[geo] = region_totals.get(geo, 0) + 1
        if score >= 70:
            region_high[geo] = region_high.get(geo, 0) + 1

        raw = customer.churn_risk_score
        if raw is not None:
            try:
                raw_float = float(raw)
                if raw_float in (0.0, 1.0):
                    truth_pairs.append((int(raw_float), 1 if score >= 50 else 0))
            except (TypeError, ValueError):
                pass

    # Feature importance
    feature_rows = []
    if has_data:
        try:
            for item in get_feature_importance()[:8]:
                feature_rows.append({
                    "name": item["label"],
                    "pct": round(float(item["value"]), 1),
                    "tip": f"{item['label']} contributes {round(float(item['value']), 1)}% to model decisions.",
                })
        except Exception:
            logger.warning("Feature importance unavailable for model insights.")

    # Regional concentration
    total_high = sum(region_high.values())
    region_data = [
        {
            "name": geo,
            "pct": round((count / total_high) * 100, 1) if total_high else 0.0,
            "high_count": count,
        }
        for geo, count in sorted(region_high.items(), key=lambda x: x[1], reverse=True)
    ]
    if not region_data:
        grand = sum(region_totals.values())
        region_data = [
            {"name": geo, "pct": round((n / grand) * 100, 1) if grand else 0.0, "high_count": 0}
            for geo, n in sorted(region_totals.items(), key=lambda x: x[1], reverse=True)
        ]

    # Model health metrics
    accuracy = precision = recall = None
    metrics_available = False
    labeled_count = 0
    if truth_pairs:
        tp = sum(1 for y, p in truth_pairs if y == 1 and p == 1)
        tn = sum(1 for y, p in truth_pairs if y == 0 and p == 0)
        fp = sum(1 for y, p in truth_pairs if y == 0 and p == 1)
        fn = sum(1 for y, p in truth_pairs if y == 1 and p == 0)
        total = len(truth_pairs)
        accuracy  = round(((tp + tn) / total) * 100, 1) if total else 0.0
        precision = round((tp / (tp + fp)) * 100, 1) if (tp + fp) else 0.0
        recall    = round((tp / (tp + fn)) * 100, 1) if (tp + fn) else 0.0
        metrics_available = True
        labeled_count = len(truth_pairs)
    else:
        persisted = get_model_metrics() or {}
        if persisted:
            accuracy = persisted.get("accuracy")
            precision = persisted.get("precision")
            recall = persisted.get("recall")
            labeled_count = persisted.get("test_samples", 0)
            metrics_available = all(v is not None for v in (accuracy, precision, recall))

    context = {
        "feature_rows": feature_rows,
        "region_data": region_data[:3],
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "metrics_available": metrics_available,
        "labeled_count": labeled_count,
        "training_last_text": (
            latest_upload.uploaded_at.strftime("%b %d, %Y") if latest_upload else "No dataset uploaded"
        ),
        "insight_data": {
            "donut":   {"labels": [r["name"] for r in region_data[:6]], "values": [r["pct"] for r in region_data[:6]]},
            "scatter": {"high": high_points[:300], "retained": low_points[:300]},
        },
    }
    return render(request, "dashboard/model_insights.html", context)


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def settings_page(request):
    can_view_all = request.user.is_staff
    members = User.objects.all().order_by("-created_at") if can_view_all else User.objects.filter(pk=request.user.pk)
    return render(request, "dashboard/settings.html", {
        "members": members,
        "member_count": members.count(),
        "can_manage_dataset": True,
        "can_view_all_users": can_view_all,
    })



# ---------------------------------------------------------------------------
# Engagement Hub
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def engagement_hub_page(request):
    """
    Central engagement hub for stakeholders.
    Shows complaints, notifications, goals and surveys across all customers.
    """
    from core.models import Complaint, Goal, Notification, Survey

    recent_complaints = (
        Complaint.objects.select_related("user")
        .order_by("-created_at")[:10]
    )
    recent_notifications = (
        Notification.objects.select_related("target_user")
        .order_by("-created_at")[:10]
    )
    recent_goals = (
        Goal.objects.select_related("user")
        .order_by("-created_at")[:10]
    )
    recent_surveys = (
        Survey.objects.select_related("user")
        .order_by("-created_at")[:10]
    )

    open_complaints = Complaint.objects.filter(status=Complaint.STATUS_OPEN).count()
    unread_notifications = Notification.objects.filter(is_read=False).count()

    context = {
        "recent_complaints": recent_complaints,
        "recent_notifications": recent_notifications,
        "recent_goals": recent_goals,
        "recent_surveys": recent_surveys,
        "open_complaints": open_complaints,
        "unread_notifications": unread_notifications,
    }
    return render(request, "dashboard/engagement_hub.html", context)

# ---------------------------------------------------------------------------
# Search (JSON)
# ---------------------------------------------------------------------------

@login_required(login_url="login_page")
def dashboard_search(request):
    query = request.GET.get("q", "").strip()

    if len(query) < 2:
        return JsonResponse({"query": query, "count": 0, "results": []})

    customers = (
        Customer.objects
        .annotate(customer_id_str=Cast("customer_id", CharField()))
        .filter(
            Q(customer_id_str__icontains=query)
            | Q(surname__icontains=query)
            | Q(geography__icontains=query)
            | Q(gender__icontains=query)
        )
        .order_by("-churn_risk_score", "surname")[:8]
    )

    risk_level_url = reverse("risk_level_page")
    results = []
    for customer in customers:
        score = round(_safe_score(customer), 2)
        results.append({
            "customer_id": customer.customer_id,
            "surname": customer.surname,
            "geography": customer.geography,
            "gender": customer.gender,
            "risk_score": score,
            "risk_level": _risk_level(score),
            "driver": _safe_driver(customer),
            "risk_url": risk_level_url,
        })

    return JsonResponse({"query": query, "count": len(results), "results": results})
