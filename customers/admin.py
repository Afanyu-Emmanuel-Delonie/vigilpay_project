from django.contrib import admin

from customers.models import Customer


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ('customer_id', 'surname', 'geography', 'age', 'churn_risk_score')
    search_fields = ('customer_id', 'surname', 'geography')
    list_filter = ('geography', 'gender', 'is_active_member')

