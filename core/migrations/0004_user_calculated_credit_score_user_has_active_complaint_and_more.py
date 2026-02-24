from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0003_user_has_complain_user_loyalty_score_user_user_type"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="calculated_credit_score",
            field=models.FloatField(default=600.0),
        ),
        migrations.AddField(
            model_name="user",
            name="has_active_complaint",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="user",
            name="onboarding_activity_rate",
            field=models.FloatField(default=0.0),
        ),
        migrations.AddField(
            model_name="user",
            name="onboarding_balance",
            field=models.FloatField(default=0.0),
        ),
        migrations.AddField(
            model_name="user",
            name="onboarding_prediction",
            field=models.FloatField(default=0.0),
        ),
        migrations.CreateModel(
            name="AppNotification",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("title", models.CharField(max_length=150)),
                ("message", models.TextField()),
                ("is_reviewed", models.BooleanField(default=False)),
                ("is_confirmed", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("created_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="created_notifications", to=settings.AUTH_USER_MODEL)),
                ("target_user", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name="notifications", to=settings.AUTH_USER_MODEL)),
            ],
            options={"db_table": "app_notifications", "ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="Complaint",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("text", models.TextField()),
                ("sentiment_score", models.FloatField(default=0.0)),
                ("category", models.CharField(choices=[("billing", "Billing"), ("support", "Support"), ("technical", "Technical"), ("service", "Service")], default="support", max_length=32)),
                ("status", models.CharField(choices=[("open", "Open"), ("resolved", "Resolved")], default="open", max_length=16)),
                ("resolution_note", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("user", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="complaints", to=settings.AUTH_USER_MODEL)),
            ],
            options={"db_table": "complaints", "ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="Product",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=120, unique=True)),
                ("type", models.CharField(choices=[("loan", "Loan"), ("card", "Card"), ("bonus", "Bonus"), ("resolution", "Resolution")], max_length=16)),
                ("min_score_required", models.FloatField(default=0.0)),
                ("min_balance_required", models.FloatField(default=0.0)),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={"db_table": "products", "ordering": ["name"]},
        ),
        migrations.CreateModel(
            name="SurveyResponse",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("rating", models.IntegerField(default=3)),
                ("feedback", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("user", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="survey_responses", to=settings.AUTH_USER_MODEL)),
            ],
            options={"db_table": "survey_responses", "ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="UserGoal",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("title", models.CharField(max_length=150)),
                ("target_amount", models.FloatField(default=0.0)),
                ("current_amount", models.FloatField(default=0.0)),
                ("is_completed", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("user", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="goals", to=settings.AUTH_USER_MODEL)),
            ],
            options={"db_table": "user_goals", "ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="InteractionLog",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("event_type", models.CharField(choices=[("product_accepted", "Product Accepted"), ("product_rejected", "Product Rejected"), ("resolution_sent", "Resolution Sent"), ("resolution_success", "Resolution Success")], max_length=32)),
                ("metadata", models.JSONField(blank=True, default=dict)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("complaint", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="interactions", to="core.complaint")),
                ("product", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="interactions", to="core.product")),
                ("user", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="interactions", to=settings.AUTH_USER_MODEL)),
            ],
            options={"db_table": "interaction_logs", "ordering": ["-created_at"]},
        ),
    ]
