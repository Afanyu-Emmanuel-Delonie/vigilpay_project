# `core/` App — Backend Logic Guide

> Handles authentication, user management, and server health for VigilPay. This is the foundation every other app depends on — get this right first.

---

## ✅ Implementation Checklist

The backend developer is responsible for the following:

1. **Custom User Model** — Extends `AbstractUser` to use email as the login identifier (standard for fintech). Supports additional fields like `is_auditor` and `last_activity`.
2. **User Profiles** — A separate model linked to `User` via a OneToOne relationship, storing bank-specific details such as Department and Staff ID.
3. **Signals** — Automatically creates a `Profile` record whenever a new `User` is saved.
4. **Health Check View** — A `JsonResponse` endpoint that confirms the database and server are running correctly.

---

## 📁 Folder Structure

```
core/
├── admin.py      # Manages staff accounts in the Django dashboard
├── apps.py       # Connects signals on app startup via ready()
├── models.py     # User & Profile model definitions
├── signals.py    # Auto profile creation on user save
├── urls.py       # Route definitions (e.g. /health/)
└── views.py      # Health check and core utility views
```

---

## 🤖 Code Generation Prompt

Use the prompt below to generate the initial Python code for this app:

```
Generate the Python-only logic for a Django app named core. Focus strictly on backend structure:

1. models.py: Create a User model inheriting from AbstractUser. Set email as the
   USERNAME_FIELD. Also create a Profile model with a OneToOne link to User and
   a staff_id field.

2. signals.py: Write a post_save signal that creates a Profile automatically
   when a User is created.

3. apps.py: Update the ready() method to import the signals.

4. views.py: Create a health_check view that returns a JsonResponse showing
   the server status and current timestamp.

5. admin.py: Register both models using UserAdmin and ModelAdmin so they are
   fully searchable in the Django dashboard.

Note: Strictly no HTML templates. Use standard Django logic without REST
framework for now.
```

---

## 🧪 Testing the `core` App

Before handing off to the JWT integration stage, verify everything works end-to-end.

### 1. Update Settings

Add the following to `config/settings.py`:

```python
AUTH_USER_MODEL = 'core.User'
```

### 2. Run Migrations

```bash
python manage.py makemigrations core
python manage.py migrate
```

### 3. Verify Signals in the Django Shell

```bash
python manage.py shell
```

```python
from core.models import User, Profile

u = User.objects.create(email="test@bank.com", username="test")
print(Profile.objects.filter(user=u).exists())  # Expected: True
```

### 4. Verify the Health Check Endpoint

With the server running (`python manage.py runserver`), hit the health endpoint:

```bash
curl http://127.0.0.1:8000/health/
```

Expected response:

```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2025-01-01T12:00:00Z"
}
```

---

## ⚠️ Key Constraints

- No HTML templates — all responses are `JsonResponse` or Django admin only
- No Django REST Framework — standard Django views only at this stage
- `AUTH_USER_MODEL` **must** be set before the first migration, or you will need to reset your database