from django.db import models


class Customer(models.Model):
    customer_id = models.IntegerField()
    surname = models.CharField(max_length=100)
    credit_score = models.IntegerField()
    geography = models.CharField(max_length=50)
    gender = models.CharField(max_length=10)
    age = models.IntegerField()
    tenure = models.IntegerField()
    balance = models.FloatField()
    num_of_products = models.IntegerField()
    has_cr_card = models.IntegerField()
    is_active_member = models.IntegerField()
    churn_risk_score = models.FloatField(null=True, blank=True)

    class Meta:
        db_table = "customers_customer"

