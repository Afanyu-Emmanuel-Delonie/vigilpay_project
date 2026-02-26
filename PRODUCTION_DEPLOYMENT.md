# Production Deployment Checklist - VigilPay

## Pre-Deployment (Local)

### 1. Verify Code is Ready
```bash
# Check for uncommitted changes
git status

# Run any final migrations locally
python manage.py migrate

# Test API locally
python manage.py runserver 0.0.0.0:8000
# Test: curl http://localhost:8000/api/v1/auth/login/
```

### 2. Commit All Changes
```bash
git add .
git commit -m "Production setup: render.yaml with PostgreSQL, security hardening, production env config"
git push origin afanyuDebug
```

### 3. Merge to Main Branch
```bash
# Create Pull Request on GitHub from afanyuDebug → main
# OR merge locally:
git checkout main
git merge afanyuDebug
git push origin main
```

---

## Render.com Configuration

### 1. Connect Your GitHub Repository
1. Go to https://dashboard.render.com
2. Click **+ New** → **Web Service**
3. Connect your GitHub account and select `vigilpay_project` repository
4. Select branch: **main**
5. Click **Deploy**

### 2. Set Environment Variables in Render Dashboard

Once the service is created:

1. Go to your service > **Environment**
2. Add these key-value pairs:

| Key | Value |
|-----|-------|
| `DEBUG` | `False` |
| `DJANGO_SECRET_KEY` | `9m(r$jm)bjl&^h3+n2zgh!ym&8u_k=!m2f*i(rkf09+$)8$b2b` |
| `ALLOWED_HOSTS` | `vigil-pay.onrender.com,www.vigil-pay.onrender.com` |
| `SECURE_SSL_REDIRECT` | `True` |
| `SESSION_COOKIE_SECURE` | `True` |
| `CSRF_COOKIE_SECURE` | `True` |
| `SECURE_HSTS_SECONDS` | `31536000` |
| `DATABASE_URL` | (Render provides automatically from PostgreSQL service) |

3. Click **Save Changes** (auto-deploys)

### 3. Verify PostgreSQL Database

1. Go to your Render dashboard
2. You should see **vigil-pay-db** service (PostgreSQL)
3. Wait for it to be **Available** (takes ~2-3 minutes)
4. The `DATABASE_URL` will be injected automatically into your web service

### 4. Monitor Deployment Logs

```bash
# In Render dashboard:
# - Logs tab shows build & startup
# - Watch for "Running migrations..." and "Superuser created" messages
# - Errors appear in red
```

### 5. Test Production API

Once deployment succeeds:

```bash
# Test login endpoint
curl -X POST https://vigil-pay.onrender.com/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"afanyuemma2002@gmail.com","password":"UBa22S0391"}'

# Expected response:
# {"access_token": "...", "refresh_token": "...", "user": {...}}
```

If you get a 502 Bad Gateway:
- Wait 2-3 minutes for migrations to complete
- Check Render logs for errors
- Verify DATABASE_URL is set

---

## Post-Deployment

### 1. Create Production Superuser (if needed)

If migrations ran but superuser is missing, SSH into Render:

1. Render dashboard > your service > **Shell**
2. Run:
```bash
python manage.py createsuperuser --username admin --email afanyuemma2002@gmail.com
# Enter password when prompted
```

Or programmatically:
```bash
python manage.py shell
>>> from core.models import User
>>> User.objects.create_superuser(username='admin', email='afanyuemma2002@gmail.com', password='UBa22S0391')
```

### 2. Test Admin Panel

```bash
# Visit
https://vigil-pay.onrender.com/admin/

# Login with:
# Email: afanyuemma2002@gmail.com
# Password: UBa22S0391
```

### 3. View Production Logs

```bash
# Render dashboard > your service > Logs
# Watch for API requests from mobile app
```

---

## Troubleshooting

### Cold Start (Render Free Tier)
- First request after inactivity ~30-60 seconds
- These are normal; increase timeout in Flutter to 45-60 seconds

### Database Connection Failed
```
Error: psycopg2.OperationalError: FATAL: Ident authentication failed
```
**Solution:** Wait for PostgreSQL service to fully initialize (check status in Render > Resources)

### Static Files 404
```bash
python manage.py collectstatic --noinput
```
(Already happens in Dockerfile CMD)

### Migrations Not Running
Check Render logs. If stuck, manually run in Shell:
```bash
python manage.py migrate --noinput
```

---

## Security Notes

✅ **What's Enabled:**
- HTTPS redirect
- Secure cookies (HTTPS only)
- HSTS headers (1 year)
- SECRET_KEY from environment
- DEBUG=False

⚠️ **What to Do:**
1. Replace `DJANGO_SECRET_KEY` with your own (already generated above)
2. Update `ALLOWED_HOSTS` with your custom domain (if using one)
3. Periodically rotate `DJANGO_SECRET_KEY`
4. Enable 2FA on your Render account

---

## Mobile App Configuration

Update Flutter `ApiConstants`:

```dart
class ApiConstants {
  static late final String baseUrl;
  static late final Duration timeout;

  static void initialize({required bool isProd}) {
    if (isProd) {
      baseUrl = 'https://vigil-pay.onrender.com/api/v1';
      timeout = const Duration(seconds: 45);  // Free tier can be slow
    } else {
      baseUrl = 'http://10.0.2.2:8000/api/v1';
      timeout = const Duration(seconds: 20);
    }
  }
}

// In main.dart
void main() {
  ApiConstants.initialize(isProd: true);
  runApp(const MyApp());
}
```

Rebuild and deploy your Flutter app with `isProd: true`.

---

## Deployment Completed ✅

Your VigilPay backend is now live at:
- **API:** https://vigil-pay.onrender.com/api/v1/
- **Admin:** https://vigil-pay.onrender.com/admin/
- **Database:** PostgreSQL on Render (managed)
- **SSL/TLS:** ✅ Automatic via Render

Next: Update your Flutter app endpoints and rebuild for production.
