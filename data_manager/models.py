# data_manager/models.py

from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model

User = get_user_model()


class UploadHistory(models.Model):
    """
    Stores metadata about uploaded CSV files for churn processing.

    Fields:
    - file_name: The actual uploaded file (stored in MEDIA_ROOT)
    - uploaded_by: The user who uploaded the file
    - processed: Whether the file was successfully processed
    - row_count: Number of cleaned rows prepared from the file
    - uploaded_at: Timestamp for auditing
    """

    file_name = models.FileField(upload_to='uploads/')
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='upload_histories'
    )
    processed = models.BooleanField(default=False)
    row_count = models.IntegerField(default=0)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.file_name.name} - {self.uploaded_by.username}"