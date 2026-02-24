from django.contrib.auth import get_user_model
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from core.models import AppNotification, Complaint, InteractionLog, Product, SurveyResponse, UserGoal
from core.retention_engine import assign_random_onboarding_profile

User = get_user_model()


class RegisterSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError("Email already exists.")
        return email

    def validate_username(self, value):
        username = value.strip()
        if User.objects.filter(username__iexact=username).exists():
            raise serializers.ValidationError("Username already exists.")
        return username

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated_data):
        user_type = self.context["user_type"]
        user = User(
            username=validated_data["username"],
            email=validated_data["email"],
            first_name=validated_data.get("first_name", ""),
            last_name=validated_data.get("last_name", ""),
            user_type=user_type,
            is_active=True,
            is_verified=True,
        )
        user.set_password(validated_data["password"])
        user.save()
        assign_random_onboarding_profile(user)
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            "id",
            "username",
            "email",
            "user_type",
            "loyalty_score",
            "calculated_credit_score",
            "has_active_complaint",
            "has_complain",
        )
        read_only_fields = fields


class ComplaintSerializer(serializers.ModelSerializer):
    class Meta:
        model = Complaint
        fields = (
            "id",
            "user",
            "text",
            "sentiment_score",
            "category",
            "status",
            "resolution_note",
            "created_at",
        )
        read_only_fields = ("id", "user", "sentiment_score", "category", "status", "resolution_note", "created_at")


class ComplaintResolveSerializer(serializers.Serializer):
    resolution_note = serializers.CharField()


class UserGoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserGoal
        fields = ("id", "title", "target_amount", "current_amount", "is_completed", "created_at")
        read_only_fields = ("id", "is_completed", "created_at")


class SurveyResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = SurveyResponse
        fields = ("id", "rating", "feedback", "created_at")
        read_only_fields = ("id", "created_at")


class AppNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppNotification
        fields = (
            "id",
            "title",
            "message",
            "target_user",
            "is_reviewed",
            "is_confirmed",
            "created_at",
        )
        read_only_fields = ("id", "is_reviewed", "is_confirmed", "created_at")


class AppNotificationUpdateSerializer(serializers.Serializer):
    is_reviewed = serializers.BooleanField(required=False)
    is_confirmed = serializers.BooleanField(required=False)


class InteractionLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = InteractionLog
        fields = ("id", "complaint", "product", "event_type", "metadata", "created_at")
        read_only_fields = ("id", "created_at")


class ProductSerializer(serializers.ModelSerializer):
    price = serializers.SerializerMethodField()
    currency = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ("id", "name", "price", "currency")
        read_only_fields = fields

    def get_price(self, obj):
        # Frontend expects a display price; use product threshold as an anchor.
        return float(obj.min_balance_required or 0.0)

    def get_currency(self, obj):
        return "GHS"


class MobileLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        password = attrs["password"]
        user = authenticate(
            request=self.context.get("request"),
            username=email,
            password=password,
        )
        if not user:
            raise serializers.ValidationError("Invalid email or password.")
        if not user.is_active:
            raise serializers.ValidationError("Account is inactive.")
        if user.user_type != User.USER_TYPE_CUSTOMER:
            raise serializers.ValidationError("This endpoint is for mobile customer accounts only.")
        attrs["user"] = user
        return attrs

    def create_tokens(self, user):
        refresh = RefreshToken.for_user(user)
        user.last_login = timezone.now()
        user.save(update_fields=["last_login"])
        return {
            "access": str(refresh.access_token),
            "refresh": str(refresh),
        }


class MobileLogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()
