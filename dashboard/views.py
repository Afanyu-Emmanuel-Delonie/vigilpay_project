from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.contrib.auth import get_user_model
from django.core.paginator import EmptyPage, PageNotAnInteger, Paginator
from django.db.models import CharField, Q
from django.db.models.functions import Cast
from django.http import HttpResponseRedirect, JsonResponse
from django.shortcuts import render
from django.urls import reverse

from data_manager.models import UploadHistory
from customers.ml_service import (
    get_feature_importance,
    get_primary_churn_driver,
    predict_churn,
)
from customers.models import Customer


def _normalize_score(raw_score):
    if raw_score is None:
        return None
    try:
        value = float(raw_score)
    except (TypeError, ValueError):
        return None
    if value <= 1:
        value *= 100
    return max(0.0, min(100.0, value))


def _to_payload(customer):
    return {
        "credit_score": customer.credit_score,
        "geography": customer.geography,
        "gender": customer.gender,
        "age": customer.age,
        "tenure": customer.tenure,
        "balance": customer.balance,
        "num_of_products": customer.num_of_products,
        "has_cr_card": customer.has_cr_card,
        "is_active_member": customer.is_active_member,
    }


def _safe_score(customer):
    saved_score = _normalize_score(customer.churn_risk_score)
    if saved_score is not None:
        return saved_score
    try:
        return float(predict_churn(_to_payload(customer)))
    except Exception:
        return 0.0


def _initials(name: str):
    cleaned = (name or "").strip()
    if not cleaned:
        return "CU"
    parts = [p for p in cleaned.split(" ") if p]
    if len(parts) >= 2:
        return (parts[0][0] + parts[1][0]).upper()
    return cleaned[:2].upper()


def _compact_number(value, currency=False):
    try:
        number = float(value or 0)
    except (TypeError, ValueError):
        number = 0.0

    abs_number = abs(number)
    suffix = ""
    scaled = number

    if abs_number >= 1_000_000_000:
        scaled = number / 1_000_000_000
        suffix = "B"
    elif abs_number >= 1_000_000:
        scaled = number / 1_000_000
        suffix = "M"
    elif abs_number >= 1_000:
        scaled = number / 1_000
        suffix = "K"

    text = f"{scaled:.1f}"
    if text.endswith(".0"):
        text = text[:-2]
    if currency:
        return f"${text}{suffix}"
    return f"{text}{suffix}"


@login_required(login_url="login_page")
def dashboard_page(request):
    customers = list(Customer.objects.all())

    scored_customers = []
    geo_count = {}
    tenure_risk_sum = {str(i): 0.0 for i in range(0, 11)}
    tenure_count = {str(i): 0 for i in range(0, 11)}
    high_points = []
    low_points = []

    for customer in customers:
        score = _safe_score(customer)
        level = _risk_level(score)
        driver = get_primary_churn_driver(_to_payload(customer))

        scored = {
            "customer_id": customer.customer_id,
            "surname": customer.surname,
            "credit_score": customer.credit_score,
            "geography": customer.geography,
            "gender": customer.gender,
            "age": customer.age,
            "balance": float(customer.balance),
            "num_of_products": customer.num_of_products,
            "is_active_member": customer.is_active_member,
            "score": round(score, 2),
            "risk_level": level,
            "driver": driver,
        }
        scored_customers.append(scored)

        geo_count[customer.geography] = geo_count.get(customer.geography, 0) + 1

        tenure_key = str(max(0, min(10, int(customer.tenure))))
        tenure_risk_sum[tenure_key] += score
        tenure_count[tenure_key] += 1

        point = {"x": int(customer.age), "y": round(float(customer.balance), 2)}
        if score >= 50:
            high_points.append(point)
        else:
            low_points.append(point)

    scored_customers.sort(key=lambda c: c["score"], reverse=True)

    total = len(scored_customers)
    high = sum(1 for c in scored_customers if c["score"] >= 70)
    medium = sum(1 for c in scored_customers if 40 <= c["score"] < 70)
    low = total - high - medium
    avg_score = round(sum(c["score"] for c in scored_customers) / total, 2) if total else 0.0

    churn_rate = round((high / total) * 100, 2) if total else 0.0
    at_risk_balance = sum(c["balance"] for c in scored_customers if c["score"] >= 80)
    active_members = sum(1 for c in scored_customers if c["is_active_member"] == 1)

    top_customers = scored_customers[:5]

    sorted_geo = sorted(geo_count.items(), key=lambda item: item[1], reverse=True)
    geo_labels = [item[0] for item in sorted_geo[:6]]
    geo_values = [item[1] for item in sorted_geo[:6]]

    tenure_labels = [f"{i}Y" for i in range(0, 11)]
    tenure_values = []
    for i in range(0, 11):
        key = str(i)
        if tenure_count[key] == 0:
            tenure_values.append(0)
        else:
            tenure_values.append(round(tenure_risk_sum[key] / tenure_count[key], 2))

    highest_geo = geo_labels[0] if geo_labels else "N/A"
    highest_geo_count = geo_values[0] if geo_values else 0
    inactive_low_balance = sum(
        1 for c in scored_customers if c["is_active_member"] == 0 and c["balance"] < 10000
    )
    multi_product_stable = sum(
        1 for c in scored_customers if c["num_of_products"] >= 2 and c["score"] < 40
    )

    dashboard_data = {
        "bar": {
            "labels": ["Low Risk", "Medium Risk", "High Risk"],
            "values": [low, medium, high],
        },
        "donut": {"labels": geo_labels, "values": geo_values},
        "scatter": {
            "high": high_points[:250],
            "low": low_points[:250],
        },
        "line": {"labels": tenure_labels, "values": tenure_values},
    }

    try:
        feature_importance = get_feature_importance()
    except Exception:
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
        "top_customers": top_customers,
        "highest_geo": highest_geo,
        "highest_geo_count": highest_geo_count,
        "inactive_low_balance": inactive_low_balance,
        "multi_product_stable": multi_product_stable,
        "feature_importance": feature_importance,
        "dashboard_data": dashboard_data,
    }
    return render(request, "core/dashboard.html", context)


@login_required(login_url="login_page")
def risk_level_page(request):
    customers = list(Customer.objects.all())

    rows = []
    geographies = sorted({(c.geography or "").strip() for c in customers if c.geography})

    selected_risk = (request.GET.get("risk_level") or "").strip().lower()
    selected_geo = (request.GET.get("geography") or "").strip()
    selected_active = (request.GET.get("is_active") or "").strip()
    query = (request.GET.get("q") or "").strip().lower()

    for customer in customers:
        score = round(_safe_score(customer), 2)
        level = _risk_level(score)
        level_key = level.lower()

        if selected_risk and level_key != selected_risk:
            continue
        if selected_geo and customer.geography != selected_geo:
            continue
        if selected_active in {"0", "1"} and str(customer.is_active_member) != selected_active:
            continue
        if query and query not in str(customer.customer_id).lower() and query not in (customer.surname or "").lower():
            continue

        rows.append(
            {
                "customer_id": customer.customer_id,
                "surname": customer.surname,
                "initials": _initials(customer.surname),
                "risk_score": score,
                "risk_level": level,
                "risk_class": level_key,
                "driver": get_primary_churn_driver(_to_payload(customer)),
                "balance": float(customer.balance or 0),
                "is_active_member": int(customer.is_active_member or 0),
            }
        )

    rows.sort(key=lambda c: c["risk_score"], reverse=True)

    total = len(rows)
    high = sum(1 for c in rows if c["risk_score"] >= 70)
    medium = sum(1 for c in rows if 40 <= c["risk_score"] < 70)
    low = total - high - medium

    paginator = Paginator(rows, 20)
    page_number = request.GET.get("page", 1)
    try:
        page_obj = paginator.page(page_number)
    except PageNotAnInteger:
        page_obj = paginator.page(1)
    except EmptyPage:
        page_obj = paginator.page(paginator.num_pages)

    page_numbers = []
    if paginator.num_pages <= 7:
        page_numbers = list(paginator.page_range)
    else:
        current = page_obj.number
        page_numbers = [1]
        if current > 4:
            page_numbers.append("...")
        start = max(2, current - 2)
        end = min(paginator.num_pages - 1, current + 2)
        for num in range(start, end + 1):
            page_numbers.append(num)
        if current < paginator.num_pages - 3:
            page_numbers.append("...")
        page_numbers.append(paginator.num_pages)

    querydict = request.GET.copy()
    querydict.pop("page", None)
    base_query = querydict.urlencode()

    context = {
        "customers": page_obj.object_list,
        "total_customers": total,
        "high_risk_count": high,
        "medium_risk_count": medium,
        "low_risk_count": low,
        "geographies": geographies,
        "page_obj": page_obj,
        "paginator": paginator,
        "page_numbers": page_numbers,
        "base_query": base_query,
    }
    return render(request, "dashboard/risk_level.html", context)


@login_required(login_url="login_page")
def data_management_page(request):
    upload_history = (
        UploadHistory.objects.select_related("uploaded_by")
        .order_by("-uploaded_at")[:100]
    )
    return render(
        request,
        "dashboard/data_management.html",
        {
            "upload_history": upload_history,
            "can_manage_dataset": request.user.is_staff,
        },
    )


@login_required(login_url="login_page")
def model_insight_page(request):
    customers = list(Customer.objects.all())

    scored = []
    high_points = []
    low_points = []
    region_totals = {}
    region_high = {}
    truth_pairs = []

    for customer in customers:
        payload = _to_payload(customer)
        try:
            model_score = float(predict_churn(payload))
        except Exception:
            model_score = float(_safe_score(customer))
        score = round(model_score, 2)
        geo = customer.geography or "Unknown"

        scored.append(
            {
                "score": score,
                "geography": geo,
                "age": int(customer.age or 0),
                "balance": float(customer.balance or 0),
                "credit_score": int(customer.credit_score or 0),
                "num_of_products": int(customer.num_of_products or 0),
            }
        )

        point = {"x": int(customer.age or 0), "y": round(float(customer.balance or 0), 2)}
        if score >= 50:
            high_points.append(point)
        else:
            low_points.append(point)

        region_totals[geo] = region_totals.get(geo, 0) + 1
        if score >= 70:
            region_high[geo] = region_high.get(geo, 0) + 1

        raw = customer.churn_risk_score
        if raw is not None:
            try:
                raw_float = float(raw)
            except (TypeError, ValueError):
                raw_float = None
            if raw_float is not None and raw_float in (0.0, 1.0):
                truth_pairs.append((int(raw_float), 1 if model_score >= 50 else 0))

    # Feature importance
    try:
        fi = get_feature_importance()
    except Exception:
        fi = []

    feature_rows = []
    for item in fi[:8]:
        feature_rows.append(
            {
                "name": item["label"],
                "pct": round(float(item["value"]), 1),
                "tip": f"{item['label']} contributes {round(float(item['value']), 1)}% to model decisions.",
            }
        )

    # Regional risk concentration among high-risk customers
    region_data = []
    total_high = sum(region_high.values())
    for geo, high_count in sorted(region_high.items(), key=lambda it: it[1], reverse=True):
        pct = round((high_count / total_high) * 100, 1) if total_high else 0.0
        region_data.append({"name": geo, "pct": pct, "high_count": high_count})
    if not region_data and region_totals:
        # fallback when no one is >= 70, use total distribution
        grand = sum(region_totals.values())
        for geo, total_count in sorted(region_totals.items(), key=lambda it: it[1], reverse=True):
            pct = round((total_count / grand) * 100, 1) if grand else 0.0
            region_data.append({"name": geo, "pct": pct, "high_count": 0})

    # Model health from labeled rows if available
    accuracy = precision = recall = None
    metrics_available = False
    if truth_pairs:
        tp = sum(1 for y, p in truth_pairs if y == 1 and p == 1)
        tn = sum(1 for y, p in truth_pairs if y == 0 and p == 0)
        fp = sum(1 for y, p in truth_pairs if y == 0 and p == 1)
        fn = sum(1 for y, p in truth_pairs if y == 1 and p == 0)
        total = len(truth_pairs)
        accuracy = round(((tp + tn) / total) * 100, 1) if total else 0.0
        precision = round((tp / (tp + fp)) * 100, 1) if (tp + fp) else 0.0
        recall = round((tp / (tp + fn)) * 100, 1) if (tp + fn) else 0.0
        metrics_available = True

    dashboard_data = {
        "donut": {
            "labels": [r["name"] for r in region_data[:6]],
            "values": [r["pct"] for r in region_data[:6]],
        },
        "scatter": {
            "high": high_points[:300],
            "retained": low_points[:300],
        },
    }

    context = {
        "feature_rows": feature_rows,
        "region_data": region_data[:3],
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "metrics_available": metrics_available,
        "labeled_count": len(truth_pairs),
        "training_last_text": "Today",
        "insight_data": dashboard_data,
    }
    return render(request, "dashboard/model_insight.html", context)


@login_required(login_url="login_page")
def settings_page(request):
    User = get_user_model()
    can_view_all_users = request.user.is_staff
    if can_view_all_users:
        members = User.objects.all().order_by("-created_at")
    else:
        members = User.objects.filter(pk=request.user.pk)
    return render(
        request,
        "dashboard/settings.html",
        {
            "members": members,
            "member_count": members.count(),
            "can_manage_dataset": request.user.is_staff,
            "can_view_all_users": can_view_all_users,
        },
    )


@login_required(login_url="login_page")
def clear_dataset(request):
    if not request.user.is_staff:
        messages.error(request, "Only admin users can clear datasets.")
        return HttpResponseRedirect(request.META.get("HTTP_REFERER", "/dashboard/profile/"))

    if request.method == "POST":
        customer_count = Customer.objects.count()
        uploads = list(UploadHistory.objects.all())
        upload_count = len(uploads)

        for upload in uploads:
            if upload.file_name:
                upload.file_name.delete(save=False)

        UploadHistory.objects.all().delete()
        Customer.objects.all().delete()

        messages.success(
            request,
            f"Dataset cleared: {customer_count} customers and {upload_count} upload records removed.",
        )
    else:
        messages.error(request, "Invalid request method for clearing dataset.")
    return HttpResponseRedirect(request.META.get("HTTP_REFERER", "/dashboard/profile/"))


def _risk_level(score: float) -> str:
    if score >= 70:
        return "High"
    if score >= 40:
        return "Medium"
    return "Low"


@login_required(login_url="login_page")
def dashboard_search(request):
    query = request.GET.get("q", "").strip()

    if len(query) < 2:
        return JsonResponse({"query": query, "count": 0, "results": []})

    customers = (
        Customer.objects.annotate(customer_id_str=Cast("customer_id", CharField()))
        .filter(
            Q(customer_id_str__icontains=query)
            | Q(surname__icontains=query)
            | Q(geography__icontains=query)
            | Q(gender__icontains=query)
        )
        .order_by("-churn_risk_score", "surname")[:8]
    )

    results = []
    risk_level_url = reverse("risk_level_page")
    for customer in customers:
        payload = {
            "credit_score": customer.credit_score,
            "geography": customer.geography,
            "gender": customer.gender,
            "age": customer.age,
            "tenure": customer.tenure,
            "balance": customer.balance,
            "num_of_products": customer.num_of_products,
            "has_cr_card": customer.has_cr_card,
            "is_active_member": customer.is_active_member,
        }

        try:
            ml_score = predict_churn(payload)
            driver = get_primary_churn_driver(payload)
        except Exception:
            ml_score = round(float(customer.churn_risk_score or 0), 2)
            driver = "Model scoring unavailable"

        results.append(
            {
                "customer_id": customer.customer_id,
                "surname": customer.surname,
                "geography": customer.geography,
                "gender": customer.gender,
                "risk_score": ml_score,
                "risk_level": _risk_level(ml_score),
                "driver": driver,
                "risk_url": risk_level_url,
            }
        )

    return JsonResponse({"query": query, "count": len(results), "results": results})
