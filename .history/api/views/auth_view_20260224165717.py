import logging

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from api.serializers import LoginSerializer, RegisterSerializer, UserProfileSerializer
from core.services import assign_random_onboarding_profile

logger = logging.getLogger(__name__)


def _token_pair(user) -> dict:
    """Generate a JWT access + refresh token pair for the given user."""
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

class RegisterView(APIView):
    """
    POST /api/v1/auth/register/

    Creates a new CUSTOMER account and returns tokens immediately so the
    mobile app can proceed without a separate login step.

    Body:
        first_name, last_name, username, email, password, confirm_password
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = serializer.save()
        except Exception:
            logger.exception("Unexpected error while creating user account.")
            return Response(
                {"detail": "Account creation failed. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        # Seed random onboarding profile so credit score / risk APIs
        # have data to work with right away.
        assign_random_onboarding_profile(user)

        return Response(
            {
                "detail": "Account created successfully.",
                "tokens": _token_pair(user),
                "user": UserProfileSerializer(user).data,
            },
            status=status.HTTP_201_CREATED,
        )


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class LoginView(APIView):
    """
    POST /api/v1/auth/login/

    Authenticates a CUSTOMER and returns a JWT token pair.
    Stakeholder (PRO) accounts are rejected — they use the web portal.

    Body:
        identifier  — username or email
        password
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.validated_data["user"]

        try:
            tokens = _token_pair(user)
        except Exception:
            logger.exception("Token generation failed for user %s.", user.id)
            return Response(
                {"detail": "Login failed due to a server error. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response(
            {
                "detail": "Login successful.",
                "tokens": tokens,
                "user": UserProfileSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Logout
# ---------------------------------------------------------------------------

class LogoutView(APIView):
    """
    POST /api/v1/auth/logout/

    Blacklists the provided refresh token, invalidating the session.
    The mobile app should discard the access token locally after calling this.

    Body:
        refresh  — the refresh token to blacklist
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")

        if not refresh_token:
            return Response(
                {"detail": "Refresh token is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except Exception:
            # Token may already be expired or invalid — still treat as a
            # successful logout from the client's perspective.
            logger.warning("Logout called with an invalid or already-used refresh token.")
            return Response(
                {"detail": "Token is invalid or has already been revoked."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({"detail": "Logged out successfully."}, status=status.HTTP_200_OK)