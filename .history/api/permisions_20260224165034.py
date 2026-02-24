from rest_framework.permissions import BasePermission

from core.models import User


class IsCustomer(BasePermission):
    """
    Grants access only to mobile users (USER_TYPE_CUSTOMER).
    Web/stakeholder users (USER_TYPE_PRO) are explicitly blocked
    from the mobile API even if they hold a valid JWT.
    """

    message = "Access restricted to mobile customer accounts."

    def has_permission(self, request, view):
        return (
            request.user is not None
            and request.user.is_authenticated
            and request.user.user_type == User.USER_TYPE_CUSTOMER
        )


class IsVerified(BasePermission):
    """
    Grants access only to users who have completed account verification.
    Pair this with IsCustomer on endpoints that require a verified account.
    """

    message = "Please verify your account before accessing this resource."

    def has_permission(self, request, view):
        return (
            request.user is not None
            and request.user.is_authenticated
            and request.user.is_verified
        )