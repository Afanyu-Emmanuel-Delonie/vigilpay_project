from django.contrib import admin
from .models import Customer


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ('customer_id', 'surname', 'credit_score', 'geography', 'gender', 'age', 'balance', 'churn_risk_score')
    list_filter = ('geography', 'gender', 'is_active_member', 'has_cr_card')
    search_fields = ('surname', 'customer_id')
    ordering = ('customer_id',)
    readonly_fields = ('churn_risk_score',)
