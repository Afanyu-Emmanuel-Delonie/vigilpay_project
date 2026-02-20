# `customers/` App — ML Logic Guide

> The analytical core of VigilPay. This app connects the bank's customer records to the machine learning model, producing churn probability scores and actionable risk insights.

---

## ✅ Implementation Checklist

The ML Lead is responsible for three areas:

1. **Customer Profile Model** — Stores the bank *customer's* behavioral data (not the bank staff user). Fields include credit score, geography, balance, product usage, and activity status.
2. **Prediction Logic (`ml_service.py`)** — A service layer that loads the trained `.pkl` model from `ml_assets/`, prepares the input data, and returns a churn probability between `0.0` and `1.0`.
3. **Churn Insights** — Goes beyond a binary yes/no to explain *why* a customer is at risk (e.g., `"Balance too low"`, `"Inactive member"`).

---

## 📁 Folder Structure

```
customers/
├── ml_assets/       # Optional local copy of model files for easy access
├── admin.py         # Dashboard for bank staff to browse customer records
├── models.py        # Customer banking record definitions
├── ml_service.py    # Loads the model and runs predictions
├── urls.py          # Route definitions for triggering analysis
└── views.py         # Bridges the database and the ML service
```

---

## 🤖 Code Generation Prompt

Use the prompt below to generate the initial Python code for this app:

```
I am building the customers app for a Django fintech system called VigilPay.
Generate the Python-only logic for the following:

1. models.py: Create a Customer model with fields: customer_id, surname,
   credit_score, geography, gender, age, tenure, balance, num_of_products,
   has_cr_card, is_active_member, and churn_risk_score (FloatField).

2. ml_service.py: Write a function predict_churn(customer_data) that:
   - Loads a pre-trained Random Forest model using joblib
   - Prepares the input data (handling encoding for Gender and Geography)
   - Returns a probability score between 0 and 1

3. views.py: Create a view analyze_customer(customer_id) that:
   - Retrieves the customer from the database
   - Runs the predict_churn service
   - Updates the churn_risk_score field in the database
   - Returns a JsonResponse with the updated score

4. admin.py: Register the Customer model and make it searchable by customer_id.

Note: Standard Django views only. No HTML templates. Focus on how the ML
model interacts with the database.
```

---

## 🧠 How the ML Pipeline Works

```
HTTP Request (customer_id)
        │
        ▼
   views.py (analyze_customer)
        │  Fetches customer record from DB
        ▼
   ml_service.py (predict_churn)
        │  Loads model from ml_assets/
        │  Encodes Gender & Geography
        │  Runs Random Forest inference
        ▼
   Returns probability score (e.g. 0.85)
        │
        ▼
   views.py saves score → DB
        │
        ▼
   JsonResponse → caller
```

---

## 🧪 Testing the `customers` App

### 1. Run Migrations

```bash
python manage.py makemigrations customers
python manage.py migrate
```

### 2. Test the Prediction Service in the Django Shell

```bash
python manage.py shell
```

```python
from customers.ml_service import predict_churn

# Simulate a customer record
data = {
    'credit_score': 600,
    'geography': 'France',
    'gender': 'Male',
    'age': 40,
    'tenure': 3,
    'balance': 50000,
    'num_of_products': 1,
    'has_cr_card': 1,
    'is_active_member': 0,
}

risk = predict_churn(data)
print(f"Churn risk: {risk * 100:.1f}%")  # Expected: a float between 0–100%
```

### 3. Test the Full View via Shell

```python
from django.test import RequestFactory
from customers.views import analyze_customer

factory = RequestFactory()
request = factory.get('/customers/analyze/1/')
response = analyze_customer(request, customer_id=1)
print(response.content)  # Expected: {"customer_id": 1, "churn_risk_score": 0.85}
```

### 4. Verify the Score Was Saved to the Database

```python
from customers.models import Customer

c = Customer.objects.get(customer_id=1)
print(c.churn_risk_score)  # Should match the score returned above
```

---

## ⚠️ Key Constraints & Notes

- The model file must exist at `ml_assets/model.pkl` before the prediction service will run — coordinate with the Data Lead
- `Geography` and `Gender` must be label-encoded before being passed to the model; raw strings will cause inference to fail
- No HTML templates — all responses are `JsonResponse` only
- No Django REST Framework — standard Django views at this stage
- `churn_risk_score` should be updated in the DB on every call to `analyze_customer`, not just on first run