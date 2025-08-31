# src/services/timezone.py
from datetime import datetime
from zoneinfo import ZoneInfo

KST = ZoneInfo("Asia/Seoul")

def to_kst(dt: datetime) -> datetime:
    """tz-aware datetime → Asia/Seoul로 변환"""
    if dt.tzinfo is None:
        raise ValueError("timezone-aware datetime expected")
    return dt.astimezone(KST)
