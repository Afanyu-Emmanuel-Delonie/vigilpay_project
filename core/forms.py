from datetime import timedelta

from django import forms
from django.contrib.auth.password_validation import validate_password
from django.core.validators import RegexValidator
from django.utils import timezone

from core.models import User, UserOTP


class RegistrationForm(forms.Form):
    first_name = forms.CharField(max_length=150)
    last_name = forms.CharField(max_length=150)
    username = forms.CharField(
        max_length=150,
        validators=[
            RegexValidator(
                regex=r"^[A-Za-z0-9_]+$",
                message="Username can only contain letters, numbers, and underscores.",
            )
        ],
    )
    email = forms.EmailField(max_length=254)
    password = forms.CharField(widget=forms.PasswordInput)
    confirm_password = forms.CharField(widget=forms.PasswordInput)

    def clean_username(self):
        username = self.cleaned_data["username"].strip()
        if len(username) < 3:
            raise forms.ValidationError("Username must be at least 3 characters long.")
        if User.objects.filter(username__iexact=username).exists():
            raise forms.ValidationError("Username already exists.")
        return username

    def clean_email(self):
        email = self.cleaned_data["email"].strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise forms.ValidationError("Email already exists.")
        return email

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")

        if password and confirm_password and password != confirm_password:
            self.add_error("confirm_password", "Passwords do not match.")

        if password:
            temp_user = User(
                username=cleaned_data.get("username", ""),
                email=cleaned_data.get("email", ""),
                first_name=cleaned_data.get("first_name", ""),
                last_name=cleaned_data.get("last_name", ""),
            )
            validate_password(password, user=temp_user)
        return cleaned_data


class OTPVerificationForm(forms.Form):
    otp_code = forms.CharField(
        max_length=6,
        min_length=6,
        validators=[
            RegexValidator(regex=r"^\d{6}$", message="OTP must be a 6-digit number.")
        ],
    )


class ForgotPasswordForm(forms.Form):
    email = forms.EmailField(max_length=254)

    def clean_email(self):
        email = self.cleaned_data["email"].strip().lower()
        if not User.objects.filter(email__iexact=email, is_verified=True).exists():
            raise forms.ValidationError("No verified account found with this email.")
        return email


class ResetPasswordForm(forms.Form):
    password = forms.CharField(widget=forms.PasswordInput)
    confirm_password = forms.CharField(widget=forms.PasswordInput)

    def __init__(self, *args, user=None, **kwargs):
        self.user = user
        super().__init__(*args, **kwargs)

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm_password = cleaned_data.get("confirm_password")
        if password and confirm_password and password != confirm_password:
            self.add_error("confirm_password", "Passwords do not match.")
        if password:
            validate_password(password, user=self.user)
        return cleaned_data


def otp_not_throttled(user, purpose):
    one_minute_ago = timezone.now() - timedelta(minutes=1)
    return not UserOTP.objects.filter(
        user=user,
        purpose=purpose,
        created_at__gte=one_minute_ago,
    ).exists()
