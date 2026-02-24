from django.conf import settings
from django.db import models


class UploadHistory(models.Model):
    file_name = models.FileField(max_length=100, upload_to="uploads/")
    processed = models.BooleanField(default=False)
    row_count = models.IntegerField(default=0)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    class Meta:
        db_table = "data_manager_uploadhistory"
        ordering = ["-uploaded_at"]

