from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.validators import RegexValidator
from rest_framework import serializers

from core.models import User


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

class RegisterSerializer(serializers.Serializer):
    """
    Validates and creates a new CUSTOMER account.

    Mobile users always register as USER_TYPE_CUSTOMER. The user_type
    field is not exposed — it is set automatically on save.
    """

    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    username = serializers.CharField(
        max_length=150,
        validators=[
            RegexValidator(
                regex=r"^[A-Za-z0-9_]+$",
                message="Username may only contain letters, numbers, and underscores.",
            )
        ],
    )
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(write_only=True, style={"input_type": "password"})
    confirm_password = serializers.CharField(write_only=True, style={"input_type": "password"})

    # ------------------------------------------------------------------
    # Field-level validation
    # ------------------------------------------------------------------

    def validate_username(self, value):
        value = value.strip()
        if len(value) < 3:
            raise serializers.ValidationError("Username must be at least 3 characters.")
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    # ------------------------------------------------------------------
    # Cross-field validation
    # ------------------------------------------------------------------

    def validate(self, attrs):
        password = attrs.get("password")
        confirm_password = attrs.get("confirm_password")

        if password != confirm_password:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})

        # Run Django's built-in password validators against a temp user
        # so rules like "too similar to username" work correctly.
        temp_user = User(
            username=attrs.get("username", ""),
            email=attrs.get("email", ""),
            first_name=attrs.get("first_name", ""),
            last_name=attrs.get("last_name", ""),
        )
        validate_password(password, user=temp_user)
        return attrs

    # ------------------------------------------------------------------
    # Save
    # ------------------------------------------------------------------

    def create(self, validated_data):
        validated_data.pop("confirm_password")
        password = validated_data.pop("password")

        user = User(
            user_type=User.USER_TYPE_CUSTOMER,
            is_verified=False,          # verification flow can be added later
            **validated_data,
        )
        user.set_password(password)
        user.save()
        return user


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class LoginSerializer(serializers.Serializer):
    """
    Accepts either a username or an email address alongside a password.
    Returns the authenticated User instance via .validated_data['user'].
    """

    identifier = serializers.CharField(
        help_text="Your username or email address."
    )
    password = serializers.CharField(write_only=True, style={"input_type": "password"})

    def validate(self, attrs):
        identifier = attrs.get("identifier", "").strip()
        password = attrs.get("password", "")
        request = self.context.get("request")

        user = self._resolve_user(identifier, password, request)

        if user is None:
            raise serializers.ValidationError(
                {"detail": "Invalid credentials. Please check your username/email and password."}
            )

        if not user.is_active:
            raise serializers.ValidationError(
                {"detail": "This account has been deactivated. Please contact support."}
            )

        if user.user_type != User.USER_TYPE_CUSTOMER:
            raise serializers.ValidationError(
                {"detail": "Web/stakeholder accounts must log in through the web portal."}
            )

        attrs["user"] = user
        return attrs

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _resolve_user(self, identifier: str, password: str, request) -> User | None:
        """
        Try authenticating directly. If the identifier looks like an email
        and direct auth fails, look up the username first then retry.
        """
        user = authenticate(request=request, username=identifier, password=password)
        if user is not None:
            return user

        if "@" in identifier:
            matched = User.objects.filter(email__iexact=identifier).first()
            if matched:
                user = authenticate(request=request, username=matched.username, password=password)

        return user


# ---------------------------------------------------------------------------
# User profile (read-only, returned after login / on profile endpoint)
# ---------------------------------------------------------------------------

class UserProfileSerializer(serializers.ModelSerializer):
    """
    Lightweight user representation returned in auth responses.
    Sensitive fields (password hash, internal flags) are never exposed.
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
            "phone_number",
            "user_type",
            "is_verified",
            "loyalty_score",
            "calculated_credit_score",
            "member_since",
        ]
        read_only_fields = fields   # this serializer is for output only

    def get_full_name(self, obj) -> str:
        return obj.get_full_name()