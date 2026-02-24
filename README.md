# VigilPay

VigilPay is a Django-based churn-risk and customer-engagement platform with:
- Web dashboard pages (risk, data management, model insights, engagement hub)
- Mobile-oriented API endpoints (JWT auth + profile/predict/complaints/goals/surveys)
- CSV dataset upload and validation pipeline
- Custom user model (`core.User`)

## Tech Stack

- Python 3.13
- Django 6.x
- SQLite (default local DB)
- Django REST Framework + SimpleJWT
- Pandas / NumPy / scikit-learn / xgboost / shap (ML support dependencies)

## Project Structure

```text
vigil_pay/
  config/            # Django project settings and root URL config
  core/              # Auth pages, API views/serializers, custom user model
  dashboard/         # Dashboard web views + dashboard URL routes
  customers/         # Customer dataset model + churn helper service
  data_manager/      # Upload history model + CSV upload endpoint
  templates/         # HTML templates
  static/            # Source static assets for runserver
  staticfiles/       # collectstatic output
  manage.py
```

## Key Features

- Custom user model with app-specific profile/risk fields
- Login supports both username and email
- Admin/staff gated dataset upload and cleanup operations
- CSV validation before data replacement (schema + value checks)
- Dashboard analytics pages using customer dataset
- API endpoints for customer lifecycle and interaction flow

## Setup (Local)

### 1. Create and activate virtual environment

Windows (PowerShell):

```powershell
py -m venv venv
.\venv\Scripts\Activate.ps1
```

macOS/Linux:

```bash
python -m venv venv
source venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Apply migrations

```bash
py manage.py migrate
```

### 4. Run server

```bash
py manage.py runserver
```

App URL:
- `http://127.0.0.1:8000/`

## Environment Variables

You can run without extra env vars locally. Optional:

- `DJANGO_SECRET_KEY` (recommended for non-dev use)
- `DEBUG` (`True`/`False`)
- `ALLOWED_HOSTS` (comma-separated)
- `RENDER` / `RENDER_EXTERNAL_HOSTNAME` (Render deployment context)
- Security toggles:
  - `SECURE_SSL_REDIRECT`
  - `SESSION_COOKIE_SECURE`
  - `CSRF_COOKIE_SECURE`
  - `SECURE_HSTS_SECONDS`
  - `SECURE_HSTS_INCLUDE_SUBDOMAINS`
  - `SECURE_HSTS_PRELOAD`

## URLs

### Core Web Routes

- `/` landing
- `/login/`
- `/register/`
- `/forgot-password/`
- `/reset-password/`
- `/verify-otp/`
- `/logout/`

### Dashboard Routes

- `/dashboard/` (`dashboard_page`)
- `/dashboard/engagement-hub/`
- `/dashboard/risk-level/`
- `/dashboard/data-management/`
- `/dashboard/model-insight/`
- `/dashboard/profile/`
- `/dashboard/settings/`
- `/dashboard/data-management/upload/` (POST)
- `/dashboard/search/`
- `/dashboard/clear-dataset/` (POST)

### API Routes (`/api/`)

Auth:
- `POST /api/auth/mobile/login/`
- `POST /api/auth/mobile/refresh/`
- `POST /api/auth/mobile/logout/`
- `GET /api/auth/mobile/me/`

Registration/Profile/Predict:
- `POST /api/register/web/`
- `POST /api/register/mobile/`
- `GET /api/profile/`
- `GET /api/predict/`

Business objects:
- `GET /api/products/`
- `GET|POST /api/complaints/`
- `POST /api/complaints/<id>/resolve/`
- `GET|POST /api/goals/`
- `GET|POST /api/surveys/`
- `GET|POST /api/notifications/`
- `POST /api/notifications/<id>/review/`
- `GET|POST /api/interactions/`
- `POST /api/training-data/export/`

## Authentication and Validation Rules

### Login (`/login/`)

- Accepts username or email as identifier
- Requires non-empty identifier + password
- Email format is validated when identifier contains `@`
- Username format validated as `^[A-Za-z0-9_]{3,150}$`

### Registration/API User Validation

- Username:
  - Only letters, numbers, underscores
  - Minimum 3 characters
  - Case-insensitive uniqueness check
- Email:
  - Normalized to lowercase
  - Case-insensitive uniqueness check
- Password:
  - Required
  - Django password validators enforced

## CSV Upload Validation (Data Management)

Upload endpoint validates before writing:

- File must be `.csv`
- Max file size: 10MB
- CSV must include required headers:
  - `CustomerId`, `Surname`, `CreditScore`, `Geography`, `Gender`
  - `Age`, `Tenure`, `Balance`, `NumOfProducts`
  - `HasCrCard`, `IsActiveMember`
- Row constraints:
  - `CreditScore` in `0..1000`
  - `Age` in `0..120`
  - `Tenure` in `0..100`
  - `Balance >= 0`
  - `NumOfProducts` in `1..10`
  - `HasCrCard` and `IsActiveMember` must be `0` or `1`

Writes occur in a DB transaction:
- Existing `Customer` rows are replaced atomically
- If validation fails, no partial replacement occurs

## Admin / Superuser

Create superuser interactively:

```bash
py manage.py createsuperuser
```

Admin URL:
- `/admin/`

## Common Troubleshooting

### `no such table: auth_user`

Cause:
- Project uses custom user model (`AUTH_USER_MODEL = "core.User"`), so auth table is `users`, not `auth_user`.

Fix:
- Ensure settings include `AUTH_USER_MODEL = "core.User"`
- Run migrations: `py manage.py migrate`

### `staticfiles.E002` (`STATICFILES_DIRS` contains `STATIC_ROOT`)

Cause:
- `staticfiles` (collectstatic output) was added to `STATICFILES_DIRS`.

Fix:
- Keep `STATICFILES_DIRS` to source static directories only (e.g. `static/`)
- Keep `STATIC_ROOT` as output (`staticfiles/`)

### `NoReverseMatch: dashboard_page`

Cause:
- Dashboard routes failed to import or were not loaded.

Fix:
- Ensure apps/modules exist and are in `INSTALLED_APPS`:
  - `dashboard`, `customers`, `data_manager`
- Check route import health:
  - `py manage.py shell -c "from django.urls import reverse; print(reverse('dashboard_page'))"`

### Command typo

Use:

```bash
py manage.py makemigrations
```

Not:
- `py mananage.py makemigrations`

## Health Endpoint

- `GET /healthz/` returns `ok`

## Deployment Notes

- `render.yaml` and `Dockerfile` exist in repo for hosted/container workflows.
- For production, do not use Django development server.

---

If you want, the next improvement is to add automated tests for:
- login validation (username/email paths)
- CSV validator error cases
- route sanity (`reverse()` checks for critical names)
