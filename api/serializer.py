from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from core.models import Complaint, Goal, Notification, Product, Survey, User


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

class RegisterSerializer(serializers.Serializer):
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    def validate_username(self, value):
        if len(value) < 3:
            raise serializers.ValidationError("Username must be at least 3 characters.")
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("Username already taken.")
        return value

    def validate_email(self, value):
        value = value.lower()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Email already registered.")
        return value

    def validate(self, attrs):
        if attrs["password"] != attrs["confirm_password"]:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        validate_password(attrs["password"])
        return attrs

    def create(self, validated_data):
        validated_data.pop("confirm_password")
        password = validated_data.pop("password")
        user = User(user_type=User.USER_TYPE_CUSTOMER, **validated_data)
        user.set_password(password)
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(help_text="User email address")
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        password = attrs["password"]
        request = self.context.get("request")

        # Find user by email
        user_obj = User.objects.filter(email__iexact=email).first()
        
        if user_obj is None:
            raise serializers.ValidationError({"detail": "Invalid email or password."})
        
        # Authenticate using username (Django standard)
        user = authenticate(request=request, username=user_obj.username, password=password)

        if user is None:
            raise serializers.ValidationError({"detail": "Invalid email or password."})
        if not user.is_active:
            raise serializers.ValidationError({"detail": "Account is deactivated."})
        if not user.is_customer:
            raise serializers.ValidationError({"detail": "Use the web portal to log in."})

        attrs["user"] = user
        return attrs


# ---------------------------------------------------------------------------
# User
# ---------------------------------------------------------------------------

class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    member_since = serializers.DateTimeField(source="created_at", format="%Y-%m-%d") 

    class Meta:
        model = User
        fields = [
            "id", "username", "email", "full_name", "phone_number",
            "profile_picture", "user_type", "is_verified",
            "balance", "loyalty_score", "credit_score", "churn_probability",
            "has_active_complaint", "member_since",
        ]
        read_only_fields = fields

    def get_full_name(self, obj):
        return obj.get_full_name()
    
class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["first_name", "last_name", "phone_number", "profile_picture"]


# ---------------------------------------------------------------------------
# Complaint
# ---------------------------------------------------------------------------

class ComplaintSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    category_display = serializers.CharField(source="get_category_display", read_only=True)
    created_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M", read_only=True)

    class Meta:
        model = Complaint
        fields = [
            "id", "text", "category", "category_display",
            "status", "status_display", "resolution_note", "created_at",
        ]
        read_only_fields = fields


class ComplaintCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = ["text"]

    def validate_text(self, value):
        value = value.strip()
        if len(value) < 10:
            raise serializers.ValidationError("Please provide at least 10 characters.")
        return value

    def create(self, validated_data):
        return Complaint.objects.create(**validated_data)


# ---------------------------------------------------------------------------
# Product
# ---------------------------------------------------------------------------

class ProductSerializer(serializers.ModelSerializer):
    type_display = serializers.CharField(source="get_type_display", read_only=True)

    class Meta:
        model = Product
        fields = ["id", "name", "type", "type_display", "description"]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------

class NotificationSerializer(serializers.ModelSerializer):
    created_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M", read_only=True)

    class Meta:
        model = Notification
        fields = ["id", "title", "message", "is_read", "created_at"]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Goal
# ---------------------------------------------------------------------------

class GoalSerializer(serializers.ModelSerializer):
    progress = serializers.FloatField(read_only=True)
    created_at = serializers.DateField(format="%Y-%m-%d", read_only=True)

    class Meta:
        model = Goal
        fields = ["id", "title", "target_amount", "current_amount", "progress", "is_completed", "created_at"]
        read_only_fields = ["id", "progress", "is_completed", "created_at"]

    def validate_target_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Target must be greater than zero.")
        return value

    def validate_current_amount(self, value):
        if value < 0:
            raise serializers.ValidationError("Current amount cannot be negative.")
        return value

    def validate(self, attrs):
        target = attrs.get("target_amount", getattr(self.instance, "target_amount", 0))
        current = attrs.get("current_amount", getattr(self.instance, "current_amount", 0))
        if current > target:
            raise serializers.ValidationError({"current_amount": "Cannot exceed target amount."})
        if current >= target and target > 0:
            attrs["is_completed"] = True
        return attrs

    def create(self, validated_data):
        return Goal.objects.create(**validated_data)


# ---------------------------------------------------------------------------
# Survey
# ---------------------------------------------------------------------------

class SurveySerializer(serializers.ModelSerializer):
    class Meta:
        model = Survey
        fields = ["rating", "feedback"]

    def validate_rating(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value

    def create(self, validated_data):
        return Survey.objects.create(**validated_data)