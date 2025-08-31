# src/services/plan_transformer.py
from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

from schemas.plan import ItineraryRequest
from services.timezone import to_kst

@dataclass(frozen=True)
class DomainSchedule:
    title: str
    start_at_kst: datetime
    end_at_kst: datetime
    origin_address: str
    destination_address: str
    stay_minutes: int
    festival_id: int
    festival_title: str
    festival_detail_url: Optional[str]
    festival_address: Optional[str] = None  # ✅ 추가

@dataclass(frozen=True)
class DomainOptions:
    budget: str
    categories: List[str]
    avoid_crowded: bool
    start_time: Optional[str]
    end_time: Optional[str]
    notes: str  # 항상 문자열

@dataclass(frozen=True)
class PlanCommand:
    schedule: DomainSchedule
    options: DomainOptions
    client_app: str
    client_platform: str
    client_version: str

def build_plan_command(req: ItineraryRequest) -> PlanCommand:
    s = req.schedule
    o = req.options

    schedule = DomainSchedule(
        title=s.title,
        start_at_kst=to_kst(s.start_at),
        end_at_kst=to_kst(s.end_at),
        origin_address=s.origin_address,
        destination_address=s.destination_address,
        stay_minutes=s.stay_minutes,
        festival_id=s.festival_id,
        festival_title=s.festival_title,
        festival_detail_url=str(s.festival_detail_url) if s.festival_detail_url else None,
        festival_address=s.festival_address,  # ✅ 전달
    )

    options = DomainOptions(
        budget=o.budget,
        categories=o.categories or [],
        avoid_crowded=bool(o.avoid_crowded),
        start_time=o.start_time,
        end_time=o.end_time,
        notes=(o.notes or ""),  # 빈 문자열 허용
    )

    return PlanCommand(
        schedule=schedule,
        options=options,
        client_app=req.client.app,
        client_platform=req.client.platform,
        client_version=req.client.version,
    )
