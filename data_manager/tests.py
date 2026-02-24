import io
import pandas as pd
from django.test import TestCase, Client
from django.contrib.auth import get_user_model

User = get_user_model()
from django.urls import reverse

from .services import DataProcessor
from .models import UploadHistory
from customers.models import Customer


class ServiceTests(TestCase):
    """Tests for the DataProcessor utility class."""

    def setUp(self):
        # sample dataframe with required columns and some missing values
        self.sample = pd.DataFrame({
            'CreditScore': [600, None],
            'Age': [40, 30],
            'Tenure': [3, None],
            'Balance': [1000.0, None],
            'NumOfProducts': [1, 2],
            'Gender': ['Male', 'Female'],
            'Geography': ['France', 'Spain'],
        })
        self.temp_csv = io.StringIO()
        self.sample.to_csv(self.temp_csv, index=False)
        self.temp_csv.seek(0)

    def test_validate_and_clean_success(self):
        # write to a real temporary file because the method expects a path
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w+', suffix='.csv', delete=False) as f:
            self.sample.to_csv(f, index=False)
            f_path = f.name

        df, msg = DataProcessor.validate_and_clean(f_path)
        self.assertEqual(msg, 'success')
        # missing numeric should have been filled
        self.assertFalse(df['CreditScore'].isnull().any())
        self.assertEqual(df['Gender'].dtype, int)
        self.assertIn('Geography', df.columns)

    def test_validate_and_clean_missing_column(self):
        # drop a required column
        bad = self.sample.drop(columns=['Age'])
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w+', suffix='.csv', delete=False) as f:
            bad.to_csv(f, index=False)
            f_path = f.name

        df, msg = DataProcessor.validate_and_clean(f_path)
        self.assertTrue(df.empty)
        self.assertIn('missing required columns', msg)


class UploadViewTests(TestCase):
    """Integration tests for the upload endpoint."""

    def setUp(self):
        self.user = User.objects.create_user(username='tester', password='pw')
        self.client = Client()
        self.upload_url = reverse('upload-data')

    def test_post_without_file(self):
        self.client.login(username='tester', password='pw')
        resp = self.client.post(self.upload_url, {})
        self.assertEqual(resp.status_code, 400)
        self.assertIn('error', resp.json())

    def test_full_upload_flow(self):
        self.client.login(username='tester', password='pw')
        # build a minimal valid CSV
        df = pd.DataFrame({
            'CustomerId': [1],
            'CreditScore': [700],
            'Age': [50],
            'Tenure': [5],
            'Balance': [500.0],
            'NumOfProducts': [2],
            'Gender': ['Male'],
            'Geography': ['Germany'],
        })
        csv_bytes = df.to_csv(index=False).encode('utf-8')
        resp = self.client.post(self.upload_url, {'file': io.BytesIO(csv_bytes)}, format='multipart')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json().get('rows_prepared'), 1)

        self.assertEqual(UploadHistory.objects.count(), 1)
        self.assertEqual(Customer.objects.count(), 1)

