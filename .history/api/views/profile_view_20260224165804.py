import logging

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from api.permission import IsCustomer, IsVerified
from api.serializers import UserDetailSerializer, UserUpdateSerializer
from core.services import compute_credit_score_breakdown, compute_user_risk, recommend_for_user

logger = logging.getLogger(__name__)


class MeView(APIView):
    """
    GET  /api/v1/users/me/   — Retrieve the authenticated user's full profile.
    PATCH /api/v1/users/me/  — Update editable profile fields.

    Only verified CUSTOMER accounts can access this endpoint.
    Business logic (credit score, risk, recommendations) is delegated
    entirely to core.services — this view stays thin.
    """

    permission_classes = [IsCustomer, IsVerified]

    def get(self, request):
        serializer = UserDetailSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        serializer = UserUpdateSerializer(
            instance=request.user,
            data=request.data,
            partial=True,           # PATCH — only supplied fields are updated
        )

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        serializer.save()

        # Return the full updated profile so the app can refresh in one round-trip.
        return Response(
            {
                "detail": "Profile updated successfully.",
                "user": UserDetailSerializer(request.user).data,
            },
            status=status.HTTP_200_OK,
        )


class DashboardView(APIView):
    """
    GET /api/v1/users/dashboard/

    Returns the full mobile home screen payload in a single call:
    credit analysis, churn risk, and recommended products / resolutions.

    This is intentionally a single aggregated endpoint to minimise
    the number of round-trips the mobile app needs on launch.
    """

    permission_classes = [IsCustomer, IsVerified]

    def get(self, request):
        user = request.user

        try:
            credit_analysis = compute_credit_score_breakdown(user)
            risk = compute_user_risk(user)
            actionable = recommend_for_user(user, risk)
        except Exception:
            logger.exception("Dashboard computation failed for user %s.", user.id)
            return Response(
                {"detail": "Unable to load dashboard data. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response(
            {
                "credit_analysis": credit_analysis,
                "risk_analysis": risk,
                "actionable_items": actionable,
            },
            status=status.HTTP_200_OK,
        )