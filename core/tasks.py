from core.models import Complaint


POSITIVE_WORDS = {
    "good",
    "great",
    "fast",
    "helpful",
    "excellent",
    "resolved",
    "happy",
}
NEGATIVE_WORDS = {
    "bad",
    "delay",
    "slow",
    "angry",
    "terrible",
    "issue",
    "problem",
    "complaint",
    "frustrated",
    "failed",
    "charge",
}


def sentiment_analysis(complaint: Complaint) -> float:
    words = [w.strip(".,!?").lower() for w in complaint.text.split()]
    if not words:
        return 0.0

    pos = sum(1 for w in words if w in POSITIVE_WORDS)
    neg = sum(1 for w in words if w in NEGATIVE_WORDS)
    score = (pos - neg) / max(len(words), 1)
    complaint.sentiment_score = round(score, 4)

    text = complaint.text.lower()
    if any(x in text for x in {"fee", "charge", "billing", "refund"}):
        complaint.category = Complaint.CATEGORY_BILLING
    elif any(x in text for x in {"app", "login", "crash", "error"}):
        complaint.category = Complaint.CATEGORY_TECHNICAL
    elif any(x in text for x in {"service", "delay", "support", "agent"}):
        complaint.category = Complaint.CATEGORY_SERVICE
    else:
        complaint.category = Complaint.CATEGORY_SUPPORT

    complaint.save(update_fields=["sentiment_score", "category", "updated_at"])
    return complaint.sentiment_score
