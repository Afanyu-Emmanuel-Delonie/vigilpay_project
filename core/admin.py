# core/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'first_name', 'last_name', 'is_verified', 'is_active')
    list_filter = ('is_verified', 'is_active', 'is_staff')
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'username', 'phone_number', 
                                      'company_name', 'job_title', 'profile_picture')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 
                                   'groups', 'user_permissions')}),
        ('Security', {'fields': ('is_verified', 'two_factor_enabled', 
                                'last_login_ip', 'last_activity')}),
        ('Important dates', {'fields': ('last_login', 'date_joined', 'created_at', 'updated_at')}),
    )
    readonly_fields = ('created_at', 'updated_at', 'last_activity')
    search_fields = ('email', 'first_name', 'last_name', 'company_name')
    ordering = ('email',)

admin.site.register(User, CustomUserAdmin)