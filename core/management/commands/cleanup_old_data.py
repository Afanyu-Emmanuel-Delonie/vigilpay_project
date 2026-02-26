from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from core.models import Notification, Complaint
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Clean up and archive old data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='Delete records older than N days (default: 30)'
        )

    def handle(self, *args, **options):
        days = options['days']
        cutoff_date = timezone.now() - timedelta(days=days)
        
        self.stdout.write(f'Cleaning up data older than {days} days ({cutoff_date.date()})...')
        
        # Delete old read notifications
        old_notifications = Notification.objects.filter(
            is_read=True,
            updated_at__lt=cutoff_date
        )
        notif_count = old_notifications.count()
        old_notifications.delete()
        self.stdout.write(
            self.style.SUCCESS(f'✓ Deleted {notif_count} old read notifications')
        )
        
        # Delete old resolved complaints
        old_complaints = Complaint.objects.filter(
            status='resolved',
            updated_at__lt=cutoff_date
        )
        complaint_count = old_complaints.count()
        old_complaints.delete()
        self.stdout.write(
            self.style.SUCCESS(f'✓ Deleted {complaint_count} old resolved complaints')
        )
        
        # Log cleanup
        logger.info(f'Data cleanup completed: {notif_count} notifications, {complaint_count} complaints removed')
        
        self.stdout.write(
            self.style.SUCCESS('✓ Cleanup completed successfully')
        )
