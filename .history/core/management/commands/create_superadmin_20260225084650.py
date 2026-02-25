from django.core.management.base import BaseCommand
from core.models import User


class Command(BaseCommand):
    help = 'Creates a super admin user for the application'

    def add_arguments(self, parser):
        parser.add_argument(
            '--username',
            type=str,
            default='afanyu_emmanuel',
            help='Username for the super admin',
        )
        parser.add_argument(
            '--email',
            type=str,
            default='afanyuemmanuel@gmail.com',
            help='Email for the super admin',
        )
        parser.add_argument(
            '--password',
            type=str,
            default='innovation',
            help='Password for the super admin',
        )

    def handle(self, *args, **options):
        username = options['username']
        email = options['email']
        password = options['password']

        # Check if user already exists
        if User.objects.filter(username=username).exists():
            self.stdout.write(
                self.style.WARNING(f'User "{username}" already exists. Updating...')
            )
            user = User.objects.get(username=username)
            user.email = email
            user.set_password(password)
            user.is_superuser = True
            user.is_staff = True
            user.is_verified = True
            user.save()
            self.stdout.write(
                self.style.SUCCESS(f'Super admin "{username}" updated successfully!')
            )
        else:
            # Create new super admin user
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                is_superuser=True,
                is_staff=True,
                is_verified=True,
            )
            self.stdout.write(
                self.style.SUCCESS(f'Super admin "{username}" created successfully!')
            )
        
        # Verify the user
        user = User.objects.get(username=username)
        self.stdout.write(f'Username: {user.username}')
        self.stdout.write(f'Email: {user.email}')
        self.stdout.write(f'Is Superuser: {user.is_superuser}')
        self.stdout.write(f'Is Staff: {user.is_staff}')
        self.stdout.write(f'Is Verified: {user.is_verified}')
