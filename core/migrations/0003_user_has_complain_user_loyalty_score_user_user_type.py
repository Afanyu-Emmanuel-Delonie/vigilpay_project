from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0002_userotp"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="has_complain",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="user",
            name="loyalty_score",
            field=models.FloatField(default=0.0),
        ),
        migrations.AddField(
            model_name="user",
            name="user_type",
            field=models.CharField(
                choices=[("PRO", "Web User"), ("CUSTOMER", "Mobile User")],
                default="CUSTOMER",
                max_length=16,
            ),
        ),
    ]
