from rest_framework import permissions, status
from rest_framework.generics import ListCreateAPIView
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from core.api_serializers import (
    AppNotificationSerializer,
    AppNotificationUpdateSerializer,
    ComplaintResolveSerializer,
    ComplaintSerializer,
    InteractionLogSerializer,
    MobileLoginSerializer,
    MobileLogoutSerializer,
    ProductSerializer,
    RegisterSerializer,
    SurveyResponseSerializer,
    UserGoalSerializer,
    UserProfileSerializer,
)
from core.models import AppNotification, Complaint, InteractionLog, Product, User, UserGoal
from core.retention_engine import (
    generate_training_data,
    profile_payload,
    resolve_complaint,
)


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        path = request.path.rstrip("/").lower()
        if path.endswith("/web"):
            user_type = User.USER_TYPE_PRO
        elif path.endswith("/mobile"):
            user_type = User.USER_TYPE_CUSTOMER
        else:
            return Response(
                {"detail": "Unsupported registration source."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = RegisterSerializer(
            data=request.data,
            context={"user_type": user_type},
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        return Response(
            {
                "id": str(user.id),
                "username": user.username,
                "email": user.email,
                "user_type": user.user_type,
            },
            status=status.HTTP_201_CREATED,
        )


class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response(profile_payload(request.user), status=status.HTTP_200_OK)


class PredictView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response(profile_payload(request.user), status=status.HTTP_200_OK)


class ComplaintListCreateView(ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ComplaintSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return Complaint.objects.select_related("user").all()
        return Complaint.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ComplaintResolveView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, complaint_id):
        if not request.user.is_staff:
            return Response(
                {"detail": "Only admin users can resolve complaints."},
                status=status.HTTP_403_FORBIDDEN,
            )
        complaint = Complaint.objects.filter(id=complaint_id).first()
        if not complaint:
            return Response({"detail": "Complaint not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = ComplaintResolveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        resolve_complaint(complaint, serializer.validated_data["resolution_note"])
        return Response({"detail": "Complaint resolved."}, status=status.HTTP_200_OK)


class GoalListCreateView(ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserGoalSerializer

    def get_queryset(self):
        return UserGoal.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SurveyListCreateView(ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SurveyResponseSerializer

    def get_queryset(self):
        return self.request.user.survey_responses.all()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ProductListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        queryset = Product.objects.filter(is_active=True).order_by("name")
        payload = ProductSerializer(queryset, many=True).data
        return Response({"results": payload}, status=status.HTTP_200_OK)


class NotificationListCreateView(ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AppNotificationSerializer

    def get_queryset(self):
        return AppNotification.objects.filter(Q(target_user=self.request.user) | Q(target_user__isnull=True))

    def perform_create(self, serializer):
        if not self.request.user.is_staff:
            raise PermissionError("Only admin users can create notifications.")
        serializer.save(created_by=self.request.user)

    def create(self, request, *args, **kwargs):
        if not request.user.is_staff:
            return Response(
                {"detail": "Only admin users can create notifications."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().create(request, *args, **kwargs)


class NotificationReviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, notification_id):
        if not request.user.is_staff:
            return Response(
                {"detail": "Only admin users can review notifications."},
                status=status.HTTP_403_FORBIDDEN,
            )
        notification = AppNotification.objects.filter(id=notification_id).first()
        if not notification:
            return Response({"detail": "Notification not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = AppNotificationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        for key, value in serializer.validated_data.items():
            setattr(notification, key, value)
        notification.save(update_fields=list(serializer.validated_data.keys()))
        return Response({"detail": "Notification updated."}, status=status.HTTP_200_OK)


class InteractionLogListCreateView(ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = InteractionLogSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return InteractionLog.objects.select_related("user", "complaint", "product").all()
        return InteractionLog.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ExportTrainingDataView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if not request.user.is_staff:
            return Response(
                {"detail": "Only admin users can export training data."},
                status=status.HTTP_403_FORBIDDEN,
            )
        export_path = generate_training_data()
        return Response({"csv_path": export_path}, status=status.HTTP_200_OK)


class MobileLoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = MobileLoginSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        tokens = serializer.create_tokens(user)
        return Response(
            {
                "tokens": tokens,
                "user": {
                    "id": str(user.id),
                    "username": user.username,
                    "email": user.email,
                    "user_type": user.user_type,
                },
            },
            status=status.HTTP_200_OK,
        )


class MobileLogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = MobileLogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            token = RefreshToken(serializer.validated_data["refresh"])
            token.blacklist()
        except Exception:
            return Response({"detail": "Invalid refresh token."}, status=status.HTTP_400_BAD_REQUEST)
        return Response({"detail": "Logged out successfully."}, status=status.HTTP_200_OK)


class MobileMeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response(profile_payload(request.user), status=status.HTTP_200_OK)
