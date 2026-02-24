from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="UserOTP",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("purpose", models.CharField(choices=[("registration", "Registration"), ("password_reset", "Password Reset")], max_length=32)),
                ("code", models.CharField(max_length=6)),
                ("expires_at", models.DateTimeField()),
                ("is_used", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("user", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="otps", to=settings.AUTH_USER_MODEL)),
            ],
            options={
                "db_table": "user_otps",
            },
        ),
        migrations.AddIndex(
            model_name="userotp",
            index=models.Index(fields=["user", "purpose", "is_used"], name="user_otps_user_id_290c53_idx"),
        ),
        migrations.AddIndex(
            model_name="userotp",
            index=models.Index(fields=["expires_at"], name="user_otps_expires_5a164f_idx"),
        ),
    ]
