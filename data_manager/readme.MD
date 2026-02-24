# `data_manager/` App — Data Pipeline Guide

> The gatekeeper of VigilPay. This app ensures only clean, correctly structured data ever reaches the ML model or the customer database. Think of it as a validation and transformation lab that sits between raw uploads and the rest of the system.

---

## ✅ Implementation Checklist

The Data Lead is responsible for four areas:

1. **File Management Model** — Tracks every CSV upload: who submitted it, when, whether it was processed, and how many rows it contained.
2. **Validation Engine** — Opens the CSV and checks for all required ML feature columns before anything else happens. Files missing required columns are rejected immediately with a descriptive error.
3. **Pandas Transformation Service** — Cleans the validated data by imputing missing numeric values with the column median and encoding categorical fields (`Gender`, `Geography`) into numbers the model can consume.
4. **Bulk Injection Logic** — Upserts the cleaned records into the `Customer` model in the `customers` app — inserting new customers and updating existing ones without creating duplicates.

---

## 📁 Folder Structure

```
data_manager/
├── migrations/    # Auto-generated database migrations
├── models.py      # UploadHistory — tracks every file submission
├── services.py    # DataProcessor — the validation and cleaning logic
├── urls.py        # Route for the upload endpoint
└── views.py       # Orchestrates the upload flow and triggers the pipeline
```

---

## 🤖 Code Generation Prompt

Use the prompt below to generate the initial Python code for this app:

```
I am building the data_manager app for VigilPay. Generate the Python-only
logic for the following:

1. models.py: Create an UploadHistory model with fields: file_name (FileField),
   uploaded_by (ForeignKey to User), processed (BooleanField), and row_count
   (IntegerField).

2. services.py: Write a DataProcessor class with a method
   validate_and_clean(file_path) that:
   - Loads the CSV using Pandas
   - Checks for required columns: CreditScore, Age, Tenure, Balance,
     NumOfProducts
   - Fills missing numeric values with the column median
   - Encodes Gender and Geography into numeric values
   - Returns a cleaned DataFrame and a success/failure message

3. views.py: Create an UploadDataView that:
   - Handles a POST request with a file attachment
   - Saves the file record to UploadHistory
   - Calls the DataProcessor service
   - Upserts cleaned rows into the Customer model
   - Returns a JsonResponse summarising how many rows were prepared

4. urls.py: Create a path for the upload view.

Constraint: No HTML templates. Focus on file handling logic and Pandas
integration only.
```

---

## 🔁 How the Pipeline Works

```
POST /data-manager/upload/  (CSV file attached)
        │
        ▼
   views.py (UploadDataView)
        │  Saves file record to UploadHistory (processed=False)
        ▼
   services.py (DataProcessor.validate_and_clean)
        │  ① Check required columns — reject if any are missing
        │  ② Impute missing numeric values with column median
        │  ③ Encode Gender & Geography to numeric values
        ▼
   Returns cleaned DataFrame + status message
        │
        ▼
   views.py  — Upsert rows → customers.Customer
        │  Updates UploadHistory (processed=True, row_count=N)
        ▼
   JsonResponse: { "status": "ok", "rows_processed": N }
```

---

## 🧪 Testing the `data_manager` App

### 1. Run Migrations

```bash
python manage.py makemigrations data_manager
python manage.py migrate
```

### 2. Test the Validation Engine in the Django Shell

```bash
python manage.py shell
```

```python
from data_manager.services import DataProcessor

processor = DataProcessor()

# Test with a valid file
result = processor.validate_and_clean('path/to/valid_customers.csv')
print(result['status'])   # Expected: "success"
print(result['data'])     # Expected: a cleaned Pandas DataFrame

# Test with a file missing required columns
result = processor.validate_and_clean('path/to/bad_file.csv')
print(result['status'])   # Expected: "error"
print(result['message'])  # Expected: "Missing required columns: Balance, Tenure"
```

### 3. Test the Full Upload View

```bash
curl -X POST http://127.0.0.1:8000/data-manager/upload/ \
  -H "Content-Type: multipart/form-data" \
  -F "file=@customers.csv"
```

Expected response:

```json
{
  "status": "ok",
  "rows_processed": 500,
  "rows_failed": 2
}
```

### 4. Verify Records Were Upserted

```python
from customers.models import Customer

print(Customer.objects.count())  # Should reflect rows from the uploaded file
```

---

## ⚠️ Key Constraints & Notes

- The validation step must run **before** any data touches the database — a partial write on a bad file is worse than a clean rejection
- Required columns are: `CreditScore`, `Age`, `Tenure`, `Balance`, `NumOfProducts` — any upload missing these must be rejected
- Use `update_or_create()` on `Customer` for the upsert — never use a plain `create()` in bulk injection as it will produce duplicates on re-uploads
- Uploaded files should be saved to `MEDIA_ROOT` — ensure `MEDIA_ROOT` and `MEDIA_URL` are configured in `config/settings.py` before testing
- No HTML templates — all responses are `JsonResponse` only
- No Django REST Framework — standard Django views at this stage