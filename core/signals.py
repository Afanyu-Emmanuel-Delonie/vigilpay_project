from django.db.models.signals import post_save
from django.dispatch import receiver

from core.models import Complaint
from core.tasks import sentiment_analysis


@receiver(post_save, sender=Complaint)
def complaint_saved(sender, instance, created, **kwargs):
    if created:
        user = instance.user
        user.has_active_complaint = True
        user.has_complain = True
        user.save(update_fields=["has_active_complaint", "has_complain"])
        sentiment_analysis(instance)
