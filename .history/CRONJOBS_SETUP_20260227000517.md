# VigilPay Cronjobs Setup Guide

## Overview

Your VigilPay application now has scheduled tasks (cronjobs) configured to:

1. **Update churn risk scores** - Daily at 2 AM
2. **Generate personalized recommendations** - Every 6 hours
3. **Cleanup old data** - Weekly on Sundays at 3 AM

---

## Installation

### 1. Install django-crontab Package

```bash
pip install django-crontab
```

Or if using Docker:

```bash
docker-compose exec web pip install django-crontab
```

### 2. Install Cronjobs in System

```bash
python manage.py crontab add
```

Or with Docker:

```bash
docker-compose exec web python manage.py crontab add
```

**Output should be:**

```
adding cronjob: (0 2 * * *) -> core.management.commands.update_churn_risk
adding cronjob: (0 */6 * * *) -> core.management.commands.generate_recommendations
adding cronjob: (0 3 * * 0) -> core.management.commands.cleanup_old_data
```

---

## Cronjob Schedule

### Cron Time Format: `(minute hour day month weekday)`

| Job                      | Schedule | Cron          | When                     |
| ------------------------ | -------- | ------------- | ------------------------ |
| Update Churn Risk        | Daily    | `0 2 * * *`   | 2:00 AM every day        |
| Generate Recommendations | Every 6h | `0 */6 * * *` | 12 AM, 6 AM, 12 PM, 6 PM |
| Cleanup Old Data         | Weekly   | `0 3 * * 0`   | Sundays at 3:00 AM       |

---

## Management Commands (Run Manually)

You can also run these commands manually anytime:

### Update Churn Risk

```bash
python manage.py update_churn_risk
```

### Generate Recommendations

```bash
python manage.py generate_recommendations
```

### Cleanup Old Data

```bash
python manage.py cleanup_old_data --days 30
```

**Options for cleanup:**

```bash
--days N    Delete records older than N days (default: 30)

# Example: Delete data older than 60 days
python manage.py cleanup_old_data --days 60
```

---

## View Cronjob Status

### List all installed cronjobs

```bash
python manage.py crontab show
```

### View cronjob logs

Logs are stored at (configurable):

- `/tmp/churn_update.log`
- `/tmp/recommendations.log`
- `/tmp/cleanup.log`

```bash
# Watch churn update logs
tail -f /tmp/churn_update.log

# Watch recommendation logs
tail -f /tmp/recommendations.log

# Watch cleanup logs
tail -f /tmp/cleanup.log
```

---

## Configuration

Cronjobs are configured in `config/settings.py`:

```python
CRONJOBS = [
    # Update churn risk scores daily at 2 AM
    ('0 2 * * *', 'core.management.commands.update_churn_risk.Command'),

    # Generate recommendations every 6 hours
    ('0 */6 * * *', 'core.management.commands.generate_recommendations.Command'),

    # Clean up old data weekly (Sundays at 3 AM)
    ('0 3 * * 0', 'core.management.commands.cleanup_old_data.Command'),
]
```

### Disable in Development

To disable cronjobs in development mode:

```python
# In config/settings.py
if DEBUG:
    CRONJOBS = []  # Uncomment to disable
```

---

## Production Deployment (Render.com)

Cronjobs work on Render as long as:

1. ✅ At least one web service is running
2. ✅ `django-crontab` is installed (in `requirements.txt` ✓)
3. ✅ Cronjobs configured in settings (✓)

After deploying to Render:

1. Install cronjobs in the Render container:

   ```bash
   # In Render dashboard > Shell
   python manage.py crontab add
   ```

2. To verify:
   ```bash
   python manage.py crontab show
   ```

---

## Troubleshooting

### Cronjobs not running?

1. **Check if crontab is installed:**

   ```bash
   python manage.py crontab show
   ```

2. **Reinstall cronjobs:**

   ```bash
   python manage.py crontab remove
   python manage.py crontab add
   ```

3. **Check system crontab (Linux/Mac):**

   ```bash
   crontab -l
   ```

4. **Check logs:**

   ```bash
   tail -f /tmp/*.log
   ```

5. **Test a command manually:**
   ```bash
   python manage.py update_churn_risk
   ```

### On Windows?

Windows doesn't have built-in cron. Use:

- **Windows Task Scheduler** (recommended)
- **APScheduler** (as alternative to django-crontab)

---

## Next Steps

1. ✅ Install django-crontab: `pip install django-crontab`
2. ✅ Add cronjobs: `python manage.py crontab add`
3. ✅ Verify: `python manage.py crontab show`
4. ✅ Monitor logs: `tail -f /tmp/*.log`

---

## Custom Cronjobs

To add more scheduled tasks:

1. **Create new management command** in `core/management/commands/`:

   ```python
   from django.core.management.base import BaseCommand

   class Command(BaseCommand):
       help = 'My custom scheduled task'

       def handle(self, *args, **options):
           self.stdout.write('Running custom task...')
           # Your code here
   ```

2. **Add to CRONJOBS** in `config/settings.py`:

   ```python
   CRONJOBS = [
       ('*/5 * * * *', 'core.management.commands.my_task.Command'),  # Every 5 min
   ]
   ```

3. **Reinstall cronjobs:**
   ```bash
   python manage.py crontab remove
   python manage.py crontab add
   ```

---

## Cron Time Syntax Reference

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6, 0 = Sunday)
│ │ │ │ │
│ │ │ │ │
* * * * *

# Examples:
0 0 * * *       # Every day at midnight
0 */6 * * *     # Every 6 hours
0 2 * * *       # Daily at 2 AM
0 3 * * 0       # Sundays at 3 AM
*/5 * * * *     # Every 5 minutes
0 9-17 * * 1-5  # 9 AM to 5 PM on weekdays
```

---

Your scheduled tasks are now ready to automate important business processes! 🚀
