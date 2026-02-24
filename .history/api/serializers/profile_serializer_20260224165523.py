from rest_framework import serializers

from core.models import User


class UserDetailSerializer(serializers.ModelSerializer):
    """
    Full profile representation used on the /me/ endpoint.
    Includes all fields the mobile app needs to render the home screen.
    """

    full_name = serializers.SerializerMethodField()
    member_since = serializers.DateField(source="created_at", format="%Y-%m-%d")

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "full_name",
            "first_name",
            "last_name",
            "phone_number",
            "profile_picture",
            "company_name",
            "job_title",
            "user_type",
            "is_verified",
            "loyalty_score",
            "calculated_credit_score",
            "has_active_complaint",
            "onboarding_balance",
            "onboarding_activity_rate",
            "onboarding_prediction",
            "member_since",
        ]
        read_only_fields = fields

    def get_full_name(self, obj) -> str:
        return obj.get_full_name()


class UserUpdateSerializer(serializers.ModelSerializer):
    """
    Allows the mobile user to update their own editable profile fields.
    Fields like user_type, is_verified, credit_score etc. are intentionally
    excluded — those are system-managed and must never be changed by the user.
    """

    class Meta:
        model = User
        fields = [
            "first_name",
            "last_name",
            "phone_number",
            "profile_picture",
            "company_name",
            "job_title",
        ]

    def validate_phone_number(self, value):
        if value and not value.replace("+", "").replace(" ", "").isdigit():
            raise serializers.ValidationError("Enter a valid phone number.")
        return value