import os
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv(
    "DJANGO_SECRET_KEY",
    "django-insecure-change-me-in-production",
)

ON_RENDER = bool(os.getenv("RENDER"))
DEBUG = os.getenv("DEBUG", "False" if ON_RENDER else "True").lower() in {
    "1",
    "true",
    "yes",
    "on",
}

_env_hosts = [h.strip() for h in os.getenv("ALLOWED_HOSTS", "").split(",") if h.strip()]
_default_hosts = ["127.0.0.1", "localhost", "10.0.2.2", "0.0.0.0"]
_render_hostname = os.getenv("RENDER_EXTERNAL_HOSTNAME", "").strip()
if _render_hostname:
    _default_hosts.append(_render_hostname)

if DEBUG:
    ALLOWED_HOSTS = ["*"]
else:
    ALLOWED_HOSTS = _env_hosts if _env_hosts else _default_hosts

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt.token_blacklist",
    "corsheaders",
    # django_crontab is added dynamically on Unix-like systems (Windows lacks fcntl)

    # local apps
    "core",
    "customers",
    "data_manager",
    "dashboard",
    "api",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

try:
    import dj_database_url

    DATABASES = {
        "default": dj_database_url.config(
            default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}",
            conn_max_age=600,
            ssl_require=False,
        )
    }
except Exception:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = []
if (BASE_DIR / "static").exists():
    STATICFILES_DIRS.append(BASE_DIR / "static")
STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedStaticFilesStorage",
    },
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
AUTH_USER_MODEL = "core.User"

# ── Security ──────────────────────────────────────────────────────────────────
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = os.getenv("SECURE_SSL_REDIRECT", str(not DEBUG)).lower() in {
    "1", "true", "yes", "on",
}
SESSION_COOKIE_SECURE = os.getenv("SESSION_COOKIE_SECURE", str(not DEBUG)).lower() in {
    "1", "true", "yes", "on",
}
CSRF_COOKIE_SECURE = os.getenv("CSRF_COOKIE_SECURE", str(not DEBUG)).lower() in {
    "1", "true", "yes", "on",
}
SECURE_HSTS_SECONDS = int(os.getenv("SECURE_HSTS_SECONDS", "0" if DEBUG else "31536000"))
SECURE_HSTS_INCLUDE_SUBDOMAINS = os.getenv(
    "SECURE_HSTS_INCLUDE_SUBDOMAINS", "True"
).lower() in {"1", "true", "yes", "on"}
SECURE_HSTS_PRELOAD = os.getenv("SECURE_HSTS_PRELOAD", "True").lower() in {
    "1", "true", "yes", "on",
}

# ── Django REST Framework ─────────────────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

# ── CORS ──────────────────────────────────────────────────────────────────────
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True  # 👈 allows emulator + any dev client freely
else:
    CORS_ALLOWED_ORIGINS = [
        # web clients
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8001",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "http://0.0.0.0:8000",
        "http://0.0.0.0:3000",
        # Android emulator
        "http://10.0.2.2:8000",
        "http://10.0.2.2:8001",
    ]

    # append any extra origins from environment
    _cors_origins = os.getenv("CORS_ALLOWED_ORIGINS", "").split(",")
    for _origin in _cors_origins:
        _origin = _origin.strip()
        if _origin and _origin not in CORS_ALLOWED_ORIGINS:
            CORS_ALLOWED_ORIGINS.append(_origin)

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]

# ── CSRF ──────────────────────────────────────────────────────────────────────
CSRF_TRUSTED_ORIGINS = [
    "http://10.0.2.2:8000",      
    "http://10.0.2.2:8001",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "https://127.0.0.1:8443",
    "https://localhost:8443",
]

# append render hostname if available
if _render_hostname:
    CSRF_TRUSTED_ORIGINS.append(f"https://{_render_hostname}")

# ── Simple JWT ────────────────────────────────────────────────────────────────
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME':        timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME':       timedelta(days=30),
    'ROTATE_REFRESH_TOKENS':        True,
    'BLACKLIST_AFTER_ROTATION':     True,   
    'AUTH_HEADER_TYPES':            ('Bearer',),
    'AUTH_TOKEN_CLASSES':           ('rest_framework_simplejwt.tokens.AccessToken',),
}

# ── Cronjobs (Scheduled Tasks) ─────────────────────────────────────────────────
CRONJOBS = [
    # Update churn risk scores daily at 2 AM
    ('0 2 * * *', 'core.management.commands.update_churn_risk.Command', '>> /tmp/churn_update.log 2>&1'),
    
    # Generate recommendations every 6 hours
    ('0 */6 * * *', 'core.management.commands.generate_recommendations.Command', '>> /tmp/recommendations.log 2>&1'),
    
    # Clean up old data weekly (Sundays at 3 AM)
    ('0 3 * * 0', 'core.management.commands.cleanup_old_data.Command', '>> /tmp/cleanup.log 2>&1'),
]

# Disable cronjobs in test/development if needed
if DEBUG:
    CRONJOBS = []  # Uncomment this line to skip cronjobs in development


