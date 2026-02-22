from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Create or update default admin users for VigilPay."

    DEFAULT_PASSWORD = "innovation"
    ADMINS = [
        {
            "first_name": "Afanyu",
            "last_name": "Emmanuel",
            "username": "afanyu.emmanuel",
            "email": "afanyuemmanuel@gmail.com",
        },
        {
            "first_name": "Lama",
            "last_name": "Suleman",
            "username": "lama.suleman",
            "email": "lamasuleman@gmail.com",
        },
        {
            "first_name": "Shema",
            "last_name": "Christian",
            "username": "shema.christian",
            "email": "shemachristian@gmail.com",
        },
    ]

    def handle(self, *args, **options):
        User = get_user_model()

        for row in self.ADMINS:
            user, created = User.objects.get_or_create(
                email=row["email"],
                defaults={
                    "username": row["username"],
                    "first_name": row["first_name"],
                    "last_name": row["last_name"],
                },
            )

            user.username = row["username"]
            user.first_name = row["first_name"]
            user.last_name = row["last_name"]
            user.is_staff = True
            user.is_superuser = True
            user.is_active = True
            user.set_password(self.DEFAULT_PASSWORD)
            user.save()

            status = "created" if created else "updated"
            self.stdout.write(
                self.style.SUCCESS(f"{status}: {row['email']} (admin)")
            )

        self.stdout.write(self.style.WARNING("Default password set to: innovation"))
