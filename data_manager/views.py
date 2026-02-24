from django.http import JsonResponse
from django.views import View
from django.contrib.auth.mixins import LoginRequiredMixin

from .models import UploadHistory
from .services import DataProcessor
from customers.models import Customer


# no HTML templates are needed; this view purely handles file upload and
# processing logic.


class UploadDataView(LoginRequiredMixin, View):
    """Endpoint to receive churn data files and persist cleaned rows.

    Expects a multipart POST request with a ``file`` field.  The uploaded file is
    recorded to :class:`data_manager.models.UploadHistory` for auditing and then
    passed off to :class:`DataProcessor` for validation/cleaning.  Finally, each
    row of the cleaned DataFrame is upserted into the ``Customer`` table.
    The response is a simple JSON payload summarising how many records were
    prepared.
    """

    def post(self, request, *args, **kwargs):
        if not request.user.is_staff:
            return JsonResponse({"error": "admin role required"}, status=403)

        # grab uploaded file from request
        csv_file = request.FILES.get('file')
        if not csv_file:
            return JsonResponse({'error': 'no file attached'}, status=400)

        # persist a history record (this saves the file to MEDIA_ROOT)
        history = UploadHistory.objects.create(
            file_name=csv_file,
            uploaded_by=request.user,
        )

        file_path = history.file_name.path
        df, msg = DataProcessor.validate_and_clean(file_path)

        if df.empty:
            history.processed = False
            history.save()
            return JsonResponse({'error': msg}, status=400)

        # upsert each row into Customer; assume CSV contains a customer id column
        count = 0
        next_customer_id = (Customer.objects.order_by("-customer_id").values_list("customer_id", flat=True).first() or 0) + 1
        for _, row in df.iterrows():
            customer_id = row.get('CustomerId')
            if customer_id is None:
                customer_id = next_customer_id
                next_customer_id += 1
            else:
                customer_id = int(customer_id)

            defaults = {
                'surname': row.get('Surname') or f'Customer {customer_id}',
                'credit_score': row.get('CreditScore'),
                'geography': row.get('Geography'),
                'gender': row.get('Gender'),
                'age': row.get('Age'),
                'tenure': row.get('Tenure'),
                'balance': row.get('Balance'),
                'num_of_products': row.get('NumOfProducts'),
                'has_cr_card': row.get('HasCrCard', 0),
                'is_active_member': row.get('IsActiveMember', 0),
                'churn_risk_score': row.get('ChurnRiskScore')
                if 'ChurnRiskScore' in row else None,
            }
            Customer.objects.update_or_create(
                customer_id=customer_id,
                defaults=defaults,
            )
            count += 1

        history.row_count = count
        history.processed = True
        history.save()

        return JsonResponse({'rows_prepared': count})

