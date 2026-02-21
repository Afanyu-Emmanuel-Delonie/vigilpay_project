from django.shortcuts import render

def landing_page(request):
    return render(request, 'core/index.html')


def login_page(request):
    return render(request, 'core/login.html')


def dashboard_page(request):
    context = {
        "metrics": [
            {"label": "At-Risk Accounts", "value": "248", "trend": "+12.4%"},
            {"label": "Retention Saved", "value": "$84,200", "trend": "+8.1%"},
            {"label": "Prediction Accuracy", "value": "94.6%", "trend": "+1.2%"},
            {"label": "Active Monitors", "value": "12,840", "trend": "+3.7%"},
        ],
        "alerts": [
            {
                "bank": "First Trust Bank",
                "segment": "SME Loans",
                "risk_score": "87%",
                "status": "High",
            },
            {
                "bank": "Northline Credit",
                "segment": "Retail Savings",
                "risk_score": "74%",
                "status": "Medium",
            },
            {
                "bank": "Metro Capital",
                "segment": "Payroll Accounts",
                "risk_score": "61%",
                "status": "Medium",
            },
            {
                "bank": "Union Ledger",
                "segment": "Student Accounts",
                "risk_score": "42%",
                "status": "Low",
            },
        ],
    }
    return render(request, 'core/dashboard.html', context)
