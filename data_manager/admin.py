from django.contrib import admin
from .models import UploadHistory


@admin.register(UploadHistory)
class UploadHistoryAdmin(admin.ModelAdmin):
    list_display = ('pk', 'file_name', 'processed', 'row_count', 'uploaded_at', 'uploaded_by')
    list_filter = ('processed', 'uploaded_at')
    search_fields = ('file_name', 'uploaded_by__username')
    ordering = ('-uploaded_at',)
    readonly_fields = ('uploaded_at',)
