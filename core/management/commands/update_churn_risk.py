from django.core.management.base import BaseCommand
from django.utils import timezone
from core.models import User, Complaint
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Update churn risk scores for all customers based on their activity'

    def handle(self, *args, **options):
        self.stdout.write('Starting churn risk update...')
        
        users = User.objects.filter(user_type='customer', is_active=True)
        updated_count = 0

        for user in users:
            try:
                # Basic churn risk calculation
                probability = 100 - ((user.credit_score - 300) / 5.5)
                probability = max(0, min(100, probability))
                
                # Increase risk if user has active complaints
                if user.has_active_complaint:
                    probability = min(probability + 20, 100)
                
                user.churn_probability = round(probability, 2)
                
                # Determine risk tier
                if probability >= 70:
                    user.churn_risk_tier = 'high'
                elif probability >= 40:
                    user.churn_risk_tier = 'medium'
                else:
                    user.churn_risk_tier = 'low'
                
                user.save(update_fields=['churn_probability', 'churn_risk_tier'])
                updated_count += 1
                
            except Exception as e:
                logger.error(f'Error updating churn risk for user {user.id}: {str(e)}')
        
        self.stdout.write(
            self.style.SUCCESS(f'✓ Updated churn risk for {updated_count} customers')
        )
