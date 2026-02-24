from django.core.management.base import BaseCommand

from customers.ml_service import predict_churn
from customers.models import Customer


class Command(BaseCommand):
    help = "Recompute churn_risk_score for all customers using latest trained model."

    def handle(self, *args, **options):
        total = 0
        high = 0
        medium = 0
        low = 0

        for customer in Customer.objects.all():
            payload = {
                "credit_score": customer.credit_score,
                "geography": customer.geography,
                "gender": customer.gender,
                "age": customer.age,
                "tenure": customer.tenure,
                "balance": float(customer.balance or 0.0),
                "num_of_products": customer.num_of_products,
                "has_cr_card": customer.has_cr_card,
                "is_active_member": customer.is_active_member,
                "has_active_complaint": 0,
            }
            score = float(predict_churn(payload))
            customer.churn_risk_score = round(score, 2)
            customer.save(update_fields=["churn_risk_score"])
            total += 1
            if score >= 70:
                high += 1
            elif score >= 40:
                medium += 1
            else:
                low += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Rescored {total} customers. high={high}, medium={medium}, low={low}"
            )
        )
