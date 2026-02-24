"""
core.services.complaints
-------------------------
Business logic for complaint handling:
  - Sentiment scoring and category auto-classification
  - Complaint resolution with audit trail
"""

import logging

from models import Complaint, InteractionLog

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Sentiment word lists
# ---------------------------------------------------------------------------

_POSITIVE_WORDS = frozenset({
    "good", "great", "fast", "helpful", "excellent",
    "resolved", "happy", "satisfied", "easy", "smooth",
})

_NEGATIVE_WORDS = frozenset({
    "bad", "delay", "slow", "angry", "terrible", "issue",
    "problem", "complaint", "frustrated", "failed", "charge",
    "wrong", "unhappy", "broken", "unresolved", "poor",
})

# Keyword → category mapping evaluated in order.
# The first match wins. Falls back to CATEGORY_SUPPORT.
_CATEGORY_KEYWORDS: list[tuple[str, list[str]]] = [
    (Complaint.CATEGORY_BILLING,   ["fee", "charge", "billing", "refund", "payment"]),
    (Complaint.CATEGORY_TECHNICAL, ["app", "login", "crash", "error", "bug", "glitch"]),
    (Complaint.CATEGORY_SERVICE,   ["service", "delay", "support", "agent", "response"]),
]


# ---------------------------------------------------------------------------
# Sentiment analysis
# ---------------------------------------------------------------------------

def run_sentiment_analysis(complaint: Complaint) -> float:
    """
    Score the complaint's text, classify its category, and persist both.

    Returns the computed sentiment score (positive > 0, negative < 0).
    Called automatically by the post_save signal on new complaints.
    """
    words = [w.strip(".,!?;:").lower() for w in complaint.text.split()]

    if not words:
        complaint.sentiment_score = 0.0
        complaint.save(update_fields=["sentiment_score", "updated_at"])
        return 0.0

    positive = sum(1 for w in words if w in _POSITIVE_WORDS)
    negative = sum(1 for w in words if w in _NEGATIVE_WORDS)
    score = round((positive - negative) / len(words), 4)

    category = _classify_category(complaint.text)

    complaint.sentiment_score = score
    complaint.category = category
    complaint.save(update_fields=["sentiment_score", "category", "updated_at"])

    logger.debug(
        "Complaint #%s scored %.4f, classified as '%s'.",
        complaint.pk, score, category,
    )
    return score


def _classify_category(text: str) -> str:
    """Return the best-matching category for the given complaint text."""
    text_lower = text.lower()
    for category, keywords in _CATEGORY_KEYWORDS:
        if any(kw in text_lower for kw in keywords):
            return category
    return Complaint.CATEGORY_SUPPORT


# ---------------------------------------------------------------------------
# Resolution
# ---------------------------------------------------------------------------

def resolve_complaint(complaint: Complaint, note: str) -> None:
    """
    Mark a complaint as resolved, write the resolution note, update the
    user's complaint flag, and create an audit log entry.

    Args:
        complaint:  The open Complaint instance to resolve.
        note:       The resolution note written by the stakeholder.

    Raises:
        ValueError: If the complaint is already resolved.
    """
    if complaint.is_resolved:
        raise ValueError(f"Complaint #{complaint.pk} is already resolved.")

    complaint.status = Complaint.STATUS_RESOLVED
    complaint.resolution_note = note
    complaint.save(update_fields=["status", "resolution_note", "updated_at"])

    # Recompute the flag from the DB — single source of truth
    user = complaint.user
    user.update_complaint_flag()

    # Immutable audit trail
    InteractionLog.objects.create(
        user=user,
        complaint=complaint,
        event_type=InteractionLog.EVENT_RESOLUTION_SUCCESS,
        metadata={"resolution_note": note},
    )

    logger.info(
        "Complaint #%s resolved for user %s. Active complaint flag: %s.",
        complaint.pk, user.id, user.has_active_complaint,
    )