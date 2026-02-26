# VigilPay: Docker & Mobile API Setup Guide

## Table of Contents

1. [Docker Setup](#docker-setup)
2. [Mobile API Documentation](#mobile-api-documentation)
3. [Running Locally with Docker](#running-locally-with-docker)
4. [Deployment](#deployment)

---

## Docker Setup

### Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 1.29+)
- **.env file** (see [Environment Variables](#environment-variables))

### What's Included

The updated Docker setup includes:

- **Dockerfile** - Optimized Python 3.11 image with Gunicorn
- **docker-compose.yml** - Multi-container setup with PostgreSQL
- Health checks for robustness
- Non-root user for security
- Static file collection

### Environment Variables

Create a `.env` file in the project root:

```env
# Django Settings
DEBUG=False
DJANGO_SECRET_KEY=your-super-secret-key-change-in-production

# Database (PostgreSQL)
DATABASE_URL=postgresql://vigilpay_user:secure_password_change_me@db:5432/vigilpay

# Allowed Hosts (comma-separated, add your domain/IP)
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,yourdomain.com,192.168.1.100

# Security (set to True in production with HTTPS)
SECURE_SSL_REDIRECT=False
SESSION_COOKIE_SECURE=False
CSRF_COOKIE_SECURE=False

# Port
PORT=8000
```

---

## Mobile API Documentation

### Base URLs

#### Local Development

- **Without Docker**: `http://YOUR_LOCAL_IP:8000/api/`
- **With Docker**: `http://YOUR_DOCKER_HOST:8000/api/`

To find your local IP:

- **Windows**: `ipconfig` → Look for "IPv4 Address" (e.g., `192.168.1.42`)
- **macOS/Linux**: `ifconfig` or `hostname -I`

#### Production

- **Render**: `https://vigil-pay.onrender.com/api/`
- **Custom Domain**: `https://yourdomain.com/api/`

---

### Authentication

All endpoints (except auth) require **JWT Bearer Token**.

#### 1. Register New User

```
POST /api/auth/register/

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "secure_password123"
}

Response (201 Created):
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### 2. Login

```
POST /api/auth/login/

{
  "username": "john_doe",
  "password": "secure_password123"
}

Response (200 OK):
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com"
  }
}
```

#### 3. Refresh Token

```
POST /api/auth/token/refresh/

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}

Response (200 OK):
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### 4. Logout

```
POST /api/auth/logout/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "detail": "Successfully logged out."
}
```

---

### User Endpoints

#### Get Current User Profile

```
GET /api/users/me/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "churn_risk_score": 0.65,
  "last_login": "2026-02-26T10:30:00Z"
}
```

#### Get Dashboard Data

```
GET /api/users/dashboard/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "user": {
    "id": 1,
    "username": "john_doe"
  },
  "churn_risk": 0.65,
  "engagement_score": 0.78,
  "recommendations": [
    {
      "id": 1,
      "title": "Check out our premium features",
      "description": "Unlock more analytics..."
    }
  ]
}
```

---

### Complaints API

#### List User Complaints

```
GET /api/complaints/
Headers: Authorization: Bearer {access_token}

Query Parameters:
  - page: 1 (paginated, 20 per page)

Response (200 OK):
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "title": "Issues with payment",
      "description": "Cannot process payment",
      "status": "open",
      "created_at": "2026-02-20T10:00:00Z"
    }
  ]
}
```

#### Create Complaint

```
POST /api/complaints/
Headers: Authorization: Bearer {access_token}

{
  "title": "Issues with payment",
  "description": "Cannot process payment method"
}

Response (201 Created):
{
  "id": 1,
  "title": "Issues with payment",
  "description": "Cannot process payment method",
  "status": "open",
  "created_at": "2026-02-26T10:00:00Z"
}
```

#### Get Complaint Details

```
GET /api/complaints/{id}/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "id": 1,
  "title": "Issues with payment",
  "description": "Cannot process payment method",
  "status": "open",
  "created_at": "2026-02-26T10:00:00Z",
  "updated_at": "2026-02-26T10:00:00Z"
}
```

#### Update Complaint

```
PATCH /api/complaints/{id}/
Headers: Authorization: Bearer {access_token}

{
  "status": "resolved",
  "description": "Updated description"
}

Response (200 OK): [Updated object]
```

---

### Products API

#### List Products

```
GET /api/products/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "count": 10,
  "results": [
    {
      "id": 1,
      "name": "Premium Plan",
      "description": "Full access to all features",
      "price": "29.99"
    }
  ]
}
```

#### Get Product Details

```
GET /api/products/{id}/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "id": 1,
  "name": "Premium Plan",
  "description": "Full access to all features",
  "price": "29.99",
  "features": ["Advanced Analytics", "Priority Support"]
}
```

---

### Notifications API

#### List Notifications

```
GET /api/notifications/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "count": 3,
  "results": [
    {
      "id": 1,
      "title": "New Message",
      "message": "You have a new message",
      "is_read": false,
      "created_at": "2026-02-26T10:00:00Z"
    }
  ]
}
```

#### Mark Notification as Read

```
POST /api/notifications/{id}/read/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "id": 1,
  "is_read": true
}
```

---

### Goals API

#### List User Goals

```
GET /api/goals/
Headers: Authorization: Bearer {access_token}

Response (200 OK):
{
  "count": 2,
  "results": [
    {
      "id": 1,
      "title": "Save $1000",
      "description": "Build emergency fund",
      "target_amount": 1000,
      "current_amount": 350,
      "status": "in_progress"
    }
  ]
}
```

#### Create Goal

```
POST /api/goals/
Headers: Authorization: Bearer {access_token}

{
  "title": "Save $1000",
  "description": "Build emergency fund",
  "target_amount": 1000
}

Response (201 Created):
{
  "id": 1,
  "title": "Save $1000",
  "description": "Build emergency fund",
  "target_amount": 1000,
  "current_amount": 0,
  "status": "in_progress"
}
```

---

### Surveys API

#### Submit Survey

```
POST /api/surveys/
Headers: Authorization: Bearer {access_token}

{
  "survey_id": 1,
  "responses": {
    "question_1": "Very Satisfied",
    "question_2": "Would Recommend"
  }
}

Response (201 Created):
{
  "id": 1,
  "survey_id": 1,
  "submitted_at": "2026-02-26T10:00:00Z"
}
```

---

## Running Locally with Docker

### 1. Build and Start Containers

```bash
# Copy environment file
cp .env.example .env

# Build Docker image
docker-compose build

# Start all services
docker-compose up -d
```

### 2. Initialize Database

```bash
# Run migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# (Optional) Load sample data
docker-compose exec web python manage.py loaddata sample_data
```

### 3. Access Services

- **Web API**: http://localhost:8000/api/
- **Admin Panel**: http://localhost:8000/admin/
- **Database**: PostgreSQL on localhost:5432

### 4. View Logs

```bash
# All containers
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f db
```

### 5. Stop Containers

```bash
docker-compose down

# Remove volumes (clears database)
docker-compose down -v
```

---

## Mobile Client Setup

### React Native / Flutter Setup

Add the API endpoint to your environment configuration:

**React Native (.env)**

```
API_BASE_URL=http://192.168.1.100:8000/api/
```

**Flutter (main.dart)**

```dart
const String apiBaseUrl = 'http://192.168.1.100:8000/api/';
```

### Token Management

Store tokens securely:

- **React Native**: Use `react-native-secure-store`
- **Flutter**: Use `flutter_secure_storage`
- **Web**: Use HttpOnly cookies (recommended)

### Sample Login Flow

```javascript
// React Native Example
const loginUser = async (username, password) => {
  try {
    const response = await fetch(`${API_BASE_URL}auth/login/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password }),
    });

    const data = await response.json();
    if (data.access_token) {
      // Store tokens securely
      await SecureStore.setItem("access_token", data.access_token);
      await SecureStore.setItem("refresh_token", data.refresh_token);
      return data.user;
    }
  } catch (error) {
    console.error("Login failed:", error);
  }
};
```

---

## Deployment

### On Render.com (Current Setup)

The `render.yaml` already contains the deployment configuration for Docker.

```bash
# Push to your branch
git add .
git commit -m "Docker setup for VigilPay"
git push origin your-branch

# Render will auto-build and deploy
```

Update environment variables in Render dashboard:

- Add all variables from `.env.example`
- Set `DEBUG=False`
- Set `DJANGO_SECRET_KEY` to a strong random value
- Update `ALLOWED_HOSTS` with your Render domain

### Local Docker Best Practices

1. **Never commit .env** - Add to `.gitignore`
2. **Use secrets** - For production, use environment variable services
3. **Update settings.py** - Add CORS headers if needed:
   ```python
   CORS_ALLOWED_ORIGINS = [
       'YOUR_MOBILE_APP_DOMAIN',
   ]
   ```

---

## Mobile API Endpoint Summary

| Method | Endpoint                    | Auth | Purpose               |
| ------ | --------------------------- | ---- | --------------------- |
| POST   | `/auth/register/`           | ❌   | Register new user     |
| POST   | `/auth/login/`              | ❌   | User login            |
| POST   | `/auth/logout/`             | ✅   | User logout           |
| POST   | `/auth/token/refresh/`      | ❌   | Refresh JWT token     |
| GET    | `/users/me/`                | ✅   | Get current user      |
| GET    | `/users/dashboard/`         | ✅   | Get dashboard data    |
| GET    | `/complaints/`              | ✅   | List complaints       |
| POST   | `/complaints/`              | ✅   | Create complaint      |
| GET    | `/complaints/{id}/`         | ✅   | Get complaint details |
| PATCH  | `/complaints/{id}/`         | ✅   | Update complaint      |
| GET    | `/products/`                | ✅   | List products         |
| GET    | `/products/{id}/`           | ✅   | Get product details   |
| GET    | `/notifications/`           | ✅   | List notifications    |
| POST   | `/notifications/{id}/read/` | ✅   | Mark as read          |
| GET    | `/goals/`                   | ✅   | List goals            |
| POST   | `/goals/`                   | ✅   | Create goal           |
| POST   | `/surveys/`                 | ✅   | Submit survey         |

---

## Troubleshooting

### Port Already in Use

```bash
# Change port in docker-compose.yml or use:
docker-compose up -d -p 8001
```

### Database Connection Issues

```bash
# Check database logs
docker-compose logs db

# Reset database
docker-compose down -v
docker-compose up -d
```

### Mobile Device Can't Reach Backend

1. Ensure both are on same network (Wi-Fi)
2. Check firewall rules
3. Use your computer's local IP (not localhost)
4. Test with: `curl http://192.168.1.100:8000/api/auth/login/`

---

## Need Help?

- Check logs: `docker-compose logs -f`
- Test endpoints: Use Postman or Insomnia
- Debug mobile: Enable verbose logging in your app
- See Django logs: `docker-compose logs web`
