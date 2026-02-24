# `dashboard/` App — Analytics & KPI Logic Guide

> The "Math Office" of VigilPay. This app aggregates data from the `customers` app and transforms it into KPIs, risk segments, and chart-ready JSON — giving decision-makers a real-time view of churn exposure.

---

## ✅ Implementation Checklist

The Dashboard Lead is responsible for three areas:

1. **KPI Calculations (`services.py`)** — Pure aggregation logic that answers high-level business questions without exposing raw records.
2. **Trend & Regional Analysis** — Cross-cutting views comparing churn risk by geography, demographics, and time.
3. **Data Serialization for Charts** — Views that return JSON-ready dictionaries shaped for Plotly or D3.js, so the frontend requires zero data transformation.

---

## 📁 Folder Structure

```
dashboard/
├── admin.py      # Usually empty — dashboard reads from other apps
├── apps.py
├── services.py   # The "Math Office": all KPI and aggregation logic lives here
├── urls.py       # Route definitions for the summary endpoint
└── views.py      # Calls service methods and returns JsonResponse
```

---

## 📊 KPI Reference

| KPI Name | Logic | Why It Matters |
|---|---|---|
| **Total Churn Rate** | `Predicted Churned / Total Customers` | Top-line health metric for leadership |
| **Revenue at Risk** | Sum of `balance` where `churn_risk_score > 0.80` | Converts ML output into a dollar figure |
| **Risk Segmentation** | Group customers into Low / Medium / High bands | Drives resource allocation for retention teams |
| **Churn Velocity** | Risk increase % since last month | Identifies if things are deteriorating fast |
| **High-Value Churn** | `churn_risk_score > 0.8` AND `balance > $50,000` | Tells the bank which "whales" to call immediately |
| **Active At-Risk** | `churn_risk_score > 0.7` AND `is_active_member = True` | Finds loyal customers who are suddenly unhappy |

---

## 🤖 Code Generation Prompt

Use the prompt below to generate the initial Python code for this app:

```
I am building the dashboard app for VigilPay, a Django fintech project.
Generate the Python-only logic for the following analytics:

1. services.py: Create an AnalyticsService class with methods:
   - get_global_stats(): Returns a dict with Total Customers, Average Churn
     Risk, and total balance for customers with churn_risk_score > 0.80.
   - get_risk_distribution(): Groups customers by churn_risk_score into bands
     (0–0.3, 0.3–0.7, 0.7–1.0) and returns counts for each.
   - get_regional_breakdown(): Uses Django's Count and Avg aggregation to
     return churn risk per geographical location.

2. views.py: Create a DashboardSummaryView that calls these service methods
   and returns a combined JsonResponse.

3. urls.py: Create a path for the summary view at /dashboard/summary/.

Constraint: Django ORM aggregation and Pandas for data shaping only.
No HTML templates. All output must be JSON-serializable.
```

---

## 🧠 How the Aggregation Pipeline Works

```
GET /dashboard/summary/
        │
        ▼
   views.py (DashboardSummaryView)
        │
        ├── AnalyticsService.get_global_stats()
        │         └── ORM: Count, Avg, Sum on Customer queryset
        │
        ├── AnalyticsService.get_risk_distribution()
        │         └── ORM: filter by score bands → count per band
        │
        └── AnalyticsService.get_regional_breakdown()
                  └── ORM: values('geography').annotate(Avg, Count)
        │
        ▼
   Merged into single JsonResponse → Frontend / Plotly
```

---

## 🧪 Testing the `dashboard` App

### 1. Verify Aggregations in the Django Shell

```bash
python manage.py shell
```

```python
from dashboard.services import AnalyticsService

stats = AnalyticsService.get_global_stats()
print(f"Total Customers:     {stats['total_customers']}")
print(f"Avg Churn Risk:      {stats['avg_churn_risk']:.2%}")
print(f"Revenue at Risk:     ${stats['at_risk_balance']:,.2f}")
```

### 2. Verify Risk Distribution

```python
distribution = AnalyticsService.get_risk_distribution()
print(distribution)
# Expected: {'low': 412, 'medium': 318, 'high': 270}
```

### 3. Verify Regional Breakdown

```python
regional = AnalyticsService.get_regional_breakdown()
print(regional)
# Expected: [{'geography': 'France', 'avg_risk': 0.42, 'count': 500}, ...]
```

### 4. Check the Full JSON Response

```bash
curl http://127.0.0.1:8000/dashboard/summary/
```

Verify the response shape matches what the frontend will consume — particularly that risk distribution data includes both `labels` and `values` arrays, which Plotly expects directly:

```json
{
  "global_stats": {
    "total_customers": 1000,
    "avg_churn_risk": 0.43,
    "at_risk_balance": 4820000.00
  },
  "risk_distribution": {
    "labels": ["Low", "Medium", "High"],
    "values": [412, 318, 270]
  },
  "regional_breakdown": [
    { "geography": "France", "avg_risk": 0.42, "count": 500 },
    { "geography": "Germany", "avg_risk": 0.61, "count": 300 }
  ]
}
```

---

## ⚠️ Key Constraints & Notes

- All data is **read-only** — the dashboard never writes to the `customers` table; that is the ML Lead's responsibility
- All service methods must return **JSON-serializable types** (dicts, lists, floats, ints) — avoid returning QuerySets or Decimal objects directly
- Django's `Decimal` fields must be cast to `float` before serialization, or `JsonResponse` will raise a `TypeError`
- No HTML templates — all responses are `JsonResponse` only
- No Django REST Framework — standard Django views at this stage