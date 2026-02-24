import logging
import random

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from core.models import Complaint, Goal, Notification, Product, Survey, User
from .serializers import (
    ComplaintCreateSerializer, ComplaintSerializer,
    GoalSerializer, LoginSerializer, NotificationSerializer,
    ProductSerializer, RegisterSerializer, SurveySerializer,
    UserSerializer, UserUpdateSerializer,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def get_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


def seed_profile(user):
    """Give a new customer a random financial profile on registration."""
    if user.balance > 0:
        return
    user.credit_score = float(random.randint(480, 820))
    user.balance = round(random.uniform(500.0, 25000.0), 2)
    user.loyalty_score = round(random.uniform(0.0, 100.0), 2)
    user.activity_rate = round(random.uniform(0.05, 1.0), 3)
    user.save(update_fields=["credit_score", "balance", "loyalty_score", "activity_rate"])


def compute_credit_score(user):
    """Rule-based credit score breakdown."""
    activity = max(0.0, min(user.activity_rate, 1.0))
    loyalty = max(0.0, min(user.loyalty_score, 100.0))
    balance = max(user.balance, 0.0)

    base = 300
    loyalty_pts = round((loyalty / 100.0) * 180, 2)
    activity_pts = round(activity * 170, 2)
    balance_pts = round(min(balance / 20000.0, 1.0) * 120, 2)
    consistency = (
        80 if not user.has_active_complaint and activity >= 0.7 else
        45 if not user.has_active_complaint and activity >= 0.4 else
        20 if not user.has_active_complaint else 0
    )
    penalty = -70 if user.has_active_complaint else 0

    score = int(round(max(300, min(base + loyalty_pts + activity_pts + balance_pts + consistency + penalty, 850))))
    user.credit_score = float(score)
    user.save(update_fields=["credit_score"])

    if score >= 760:
        summary = "Excellent score."
    elif score >= 690:
        summary = "Good score. Keep maintaining your activity."
    elif score >= 620:
        summary = "Fair score. Increase activity to improve."
    else:
        summary = "Developing score. Focus on regular usage."

    return {
        "score": score,
        "range": {"min": 300, "max": 850},
        "summary": summary,
        "factors": [
            {"name": "Base", "points": base},
            {"name": "Loyalty", "points": loyalty_pts},
            {"name": "Activity", "points": activity_pts},
            {"name": "Balance", "points": balance_pts},
            {"name": "Consistency bonus", "points": consistency},
            {"name": "Complaint penalty", "points": penalty},
        ],
    }


def compute_risk(user):
    """Rule-based churn risk — no ML dependency."""
    probability = round(max(0, min(100, 100 - (user.credit_score - 300) / 5.5)), 2)
    if user.has_active_complaint:
        probability = min(probability + 20, 100)

    tier = "high" if probability >= 70 else "medium" if probability >= 40 else "low"
    user.churn_probability = probability
    user.save(update_fields=["churn_probability"])

    return {"probability": probability, "tier": tier}


def get_recommendations(user, risk):
    """Product recommendations based on user profile and risk tier."""
    resolutions, products = [], []

    if user.has_active_complaint:
        offer = Product.objects.filter(type=Product.TYPE_RESOLUTION, is_active=True).first()
        if offer:
            resolutions.append(offer.name)
        return {"active_resolutions": resolutions, "suggested_products": products}

    if risk["probability"] > 70 and user.balance >= 7000:
        names = ["Gold Card Upgrade", "VIP Savings Bonus"]
    elif risk["probability"] < 30 and user.credit_score >= 700:
        names = ["Personal Loan", "Investment Portfolio"]
    else:
        names = list(
            Product.objects.filter(
                is_active=True,
                min_score_required__lte=user.credit_score,
                min_balance_required__lte=user.balance,
            ).exclude(type=Product.TYPE_RESOLUTION).values_list("name", flat=True)[:2]
        )

    products = list(Product.objects.filter(name__in=names, is_active=True).values_list("name", flat=True))
    return {"active_resolutions": resolutions, "suggested_products": products}


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        seed_profile(user)
        return Response(
            {"detail": "Account created.", "tokens": get_tokens(user), "user": UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.validated_data["user"]
        return Response(
            {"detail": "Login successful.", "tokens": get_tokens(user), "user": UserSerializer(user).data},
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response({"detail": "Refresh token required."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            RefreshToken(refresh_token).blacklist()
        except Exception:
            return Response({"detail": "Invalid or expired token."}, status=status.HTTP_400_BAD_REQUEST)
        return Response({"detail": "Logged out."})


# ---------------------------------------------------------------------------
# User
# ---------------------------------------------------------------------------

class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserUpdateSerializer(instance=request.user, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response({"detail": "Profile updated.", "user": UserSerializer(request.user).data})


class DashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        credit = compute_credit_score(user)
        risk = compute_risk(user)
        recommendations = get_recommendations(user, risk)
        return Response({
            "credit_analysis": credit,
            "risk_analysis": risk,
            "actionable_items": recommendations,
        })


# ---------------------------------------------------------------------------
# Complaints
# ---------------------------------------------------------------------------

class ComplaintListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        complaints = Complaint.objects.filter(user=request.user)
        return Response(ComplaintSerializer(complaints, many=True).data)

    def post(self, request):
        serializer = ComplaintCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        complaint = serializer.save(user=request.user)
        return Response(
            {"detail": "Complaint submitted.", "complaint": ComplaintSerializer(complaint).data},
            status=status.HTTP_201_CREATED,
        )


class ComplaintDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            complaint = Complaint.objects.get(pk=pk, user=request.user)
        except Complaint.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(ComplaintSerializer(complaint).data)


# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------

class ProductListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        products = Product.objects.filter(is_active=True).exclude(type=Product.TYPE_RESOLUTION)
        return Response(ProductSerializer(products, many=True).data)


class ProductDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            product = Product.objects.get(pk=pk, is_active=True)
        except Product.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(ProductSerializer(product).data)


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------

class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(target_user=request.user)
        return Response(NotificationSerializer(notifications, many=True).data)


class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, target_user=request.user)
        except Notification.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        notification.is_read = True
        notification.save(update_fields=["is_read"])
        return Response({"detail": "Marked as read."})


# ---------------------------------------------------------------------------
# Goals
# ---------------------------------------------------------------------------

class GoalListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        goals = Goal.objects.filter(user=request.user)
        return Response(GoalSerializer(goals, many=True).data)

    def post(self, request):
        serializer = GoalSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        goal = serializer.save(user=request.user)
        return Response(
            {"detail": "Goal created.", "goal": GoalSerializer(goal).data},
            status=status.HTTP_201_CREATED,
        )


class GoalDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_goal(self, pk, user):
        try:
            return Goal.objects.get(pk=pk, user=user)
        except Goal.DoesNotExist:
            return None

    def get(self, request, pk):
        goal = self._get_goal(pk, request.user)
        if not goal:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(GoalSerializer(goal).data)

    def patch(self, request, pk):
        goal = self._get_goal(pk, request.user)
        if not goal:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = GoalSerializer(instance=goal, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response({"detail": "Goal updated.", "goal": GoalSerializer(goal).data})

    def delete(self, request, pk):
        goal = self._get_goal(pk, request.user)
        if not goal:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        goal.delete()
        return Response({"detail": "Goal deleted."}, status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Surveys
# ---------------------------------------------------------------------------

class SurveySubmitView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SurveySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save(user=request.user)
        return Response({"detail": "Thank you for your feedback."}, status=status.HTTP_201_CREATED)