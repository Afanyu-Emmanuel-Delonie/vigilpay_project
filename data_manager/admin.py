from django.contrib import admin

from data_manager.models import UploadHistory


@admin.register(UploadHistory)
class UploadHistoryAdmin(admin.ModelAdmin):
    list_display = ('file_name', 'uploaded_by', 'processed', 'row_count', 'uploaded_at')
    search_fields = ('file_name', 'uploaded_by__email', 'uploaded_by__username')
    list_filter = ('processed', 'uploaded_at')

