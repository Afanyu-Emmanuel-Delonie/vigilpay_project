# VigilPay — Fintech Churn Prediction System

> A specialized Machine Learning tool for digital banks to identify customers at risk of churning. By analyzing transaction patterns and account activity, VigilPay gives retention teams the insights they need to act before a customer walks away.

---

## 🚀 Quick Start

### 1. Clone & Navigate
```bash
git clone <your-repo-link>
cd vigilpay_project
```

### 2. Environment Setup
```bash
python -m venv venv

# Activate the virtual environment:
# Windows:   venv\Scripts\activate
# Mac/Linux: source venv/bin/activate

pip install -r requirements.txt
```

### 3. Database & Server
```bash
python manage.py migrate
python manage.py runserver
```

---

## 📂 Team Responsibility Matrix

The project is split into 4 Django apps. Find your assigned area below:

| App Folder | Lead | Key Features |
|---|---|---|
| `core/` | Auth Lead | User Login/Logout, Sign-up for Bank Staff, Landing Page |
| `dashboard/` | UI/UX Lead | Global KPIs (Total Churn Rate, Revenue at Risk), Plotly Charts |
| `customers/` | ML Lead | Individual Churn Risk Scores, "Why they are leaving" analysis |
| `data_manager/` | Data Lead | CSV/Excel Upload, Data Cleaning, Model Retraining logic |

---

## 🧠 Machine Learning Core

The brain of VigilPay lives in `ml_assets/`.

- **Model:** Random Forest Classifier
- **Goal:** Predict `1` (Churn) or `0` (Stay) based on customer behavior
- **Input Features:** Account balance, transaction frequency, last login date, and customer age

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django 5.0 |
| Frontend | Bootstrap 5 & Crispy Forms |
| Data Science | Pandas, Scikit-Learn, XGBoost |
| Visualizations | Plotly (interactive graphs) |

---

## 📁 Project Structure

```
vigilpay_project/
├── core/            # Auth & landing page
├── dashboard/       # KPIs & charts
├── customers/       # Churn risk scoring
├── data_manager/    # Data upload & model retraining
├── ml_assets/       # Trained model & preprocessing artifacts
├── manage.py
└── requirements.txt
```

---

## 🤝 Contributing

1. Branch off `main` using the convention `feature/<your-app>-<short-description>`
2. Keep changes scoped to your assigned app folder where possible
3. Open a pull request and request a review from your team lead before merging