from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Complaint, Product, Notification, Goal, Survey


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'user_type', 'is_staff', 'is_superuser', 'is_verified')
    list_filter = ('user_type', 'is_staff', 'is_superuser', 'is_verified')
    search_fields = ('username', 'email')
    ordering = ('-created_at',)
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('user_type', 'is_verified', 'phone_number', 'profile_picture')}),
    )
    
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Additional Info', {'fields': ('user_type', 'is_verified', 'phone_number')}),
    )


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('pk', 'user', 'category', 'status', 'sentiment_score', 'created_at')
    list_filter = ('status', 'category', 'created_at')
    search_fields = ('user__username', 'text')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'min_score_required', 'min_balance_required', 'is_active', 'created_at')
    list_filter = ('type', 'is_active')
    search_fields = ('name', 'description')
    ordering = ('name',)


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('pk', 'target_user', 'title', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('target_user__username', 'title', 'message')
    ordering = ('-created_at',)


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ('pk', 'user', 'title', 'target_amount', 'current_amount', 'is_completed', 'created_at')
    list_filter = ('is_completed', 'created_at')
    search_fields = ('user__username', 'title')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Survey)
class SurveyAdmin(admin.ModelAdmin):
    list_display = ('pk', 'user', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('user__username', 'feedback')
    ordering = ('-created_at',)
    readonly_fields = ('created_at',)
