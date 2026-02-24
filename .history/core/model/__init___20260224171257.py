"""
core.models
-----------
All models are imported here so Django's app registry and any code that
does `from core.models import X` keeps working exactly as before.

File layout:
    user.py        →  User, UserProfile, UserOTP
    complaint.py   →  Complaint
    product.py     →  Product
    engagement.py  →  UserGoal, SurveyResponse, AppNotification, InteractionLog
"""

from .user import User, UserOTP, UserProfile
from .complaint import Complaint
from .product import Product
from .engagement import AppNotification, InteractionLog, SurveyResponse, UserGoal

__all__ = [
    # user
    "User",
    "UserProfile",
    "UserOTP",
    # complaint
    "Complaint",
    # product
    "Product",
    # engagement
    "UserGoal",
    "SurveyResponse",
    "AppNotification",
    "InteractionLog",
]