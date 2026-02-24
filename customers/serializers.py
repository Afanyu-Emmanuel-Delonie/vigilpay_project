from rest_framework import serializers

from customers.models import Customer


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = (
            "id",
            "customer_id",
            "surname",
            "credit_score",
            "geography",
            "gender",
            "age",
            "tenure",
            "balance",
            "num_of_products",
            "has_cr_card",
            "is_active_member",
            "churn_risk_score",
        )
        read_only_fields = fields

