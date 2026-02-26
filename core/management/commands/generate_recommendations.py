from django.core.management.base import BaseCommand
from django.utils import timezone
from core.models import User, Notification
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Generate personalized recommendations for all customers'

    def handle(self, *args, **options):
        self.stdout.write('Generating personalized recommendations...')
        
        users = User.objects.filter(user_type='customer', is_active=True)
        created_count = 0

        for user in users:
            try:
                # Generate recommendations based on churn risk
                recommendations = self._get_recommendations(user)
                
                for rec in recommendations:
                    # Check if notification already exists today
                    existing = Notification.objects.filter(
                        target_user=user,
                        title=rec['title'],
                        created_at__date=timezone.now().date()
                    ).exists()
                    
                    if not existing:
                        notification = Notification.objects.create(
                            target_user=user,
                            title=rec['title'],
                            message=rec['message'],
                            notification_type='recommendation'
                        )
                        created_count += 1
                        logger.info(f'Created recommendation notification for user {user.id}')
                
            except Exception as e:
                logger.error(f'Error generating recommendations for user {user.id}: {str(e)}')
        
        self.stdout.write(
            self.style.SUCCESS(f'✓ Created {created_count} recommendation notifications')
        )

    def _get_recommendations(self, user):
        """Generate recommendations based on user profile and risk tier"""
        recommendations = []
        
        # High risk: Urgent engagement
        if user.churn_risk_tier == 'high':
            recommendations.append({
                'title': 'Special Offer Just For You',
                'message': 'We\'ve prepared an exclusive offer to help you get more value. Check it out now!'
            })
            recommendations.append({
                'title': 'Need Help?',
                'message': 'We noticed you might be experiencing issues. Our support team is here to help.'
            })
        
        # Medium risk: Retention opportunities
        elif user.churn_risk_tier == 'medium':
            recommendations.append({
                'title': 'Unlock Premium Features',
                'message': 'Upgrade to premium and enjoy unlimited benefits tailored for you.'
            })
        
        # Low risk: Cross-sell opportunities
        else:
            recommendations.append({
                'title': 'Recommended For You',
                'message': 'Based on your interests, we found products you might love.'
            })
        
        return recommendations
