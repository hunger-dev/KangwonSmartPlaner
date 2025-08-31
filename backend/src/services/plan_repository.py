from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from db.models import PlanRequest, PlanItineraryItem

def save_plan_request(db: Session, cmd) -> int:
    """
    요청 1건 저장 → plan_id 반환
    """
    row = PlanRequest(
        client_app=cmd.client_app,
        client_platform=cmd.client_platform,
        client_version=cmd.client_version,
        schedule_json={
            "title": cmd.schedule.title,
            "start_at": cmd.schedule.start_at_kst.isoformat(),
            "end_at": cmd.schedule.end_at_kst.isoformat(),
            "origin_address": cmd.schedule.origin_address,
            "destination_address": cmd.schedule.destination_address,
            "stay_minutes": cmd.schedule.stay_minutes,
            "festival_id": cmd.schedule.festival_id,
            "festival_title": cmd.schedule.festival_title,
            "festival_detail_url": cmd.schedule.festival_detail_url,
        },
        options_json={
            "budget": cmd.options.budget,
            "categories": cmd.options.categories,
            "avoid_crowded": cmd.options.avoid_crowded,
            "start_time": cmd.options.start_time,
            "end_time": cmd.options.end_time,
            "notes": cmd.options.notes,
        },
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row.id  # ← plan_id

def _parse_iso(s: str) -> datetime:
    return datetime.fromisoformat(s)

def save_plan_items(db: Session, plan_id: int, items: list[dict]) -> None:
    """
    추천 결과 여러 건을 plan_request_id 외래키로 저장
    """
    rows = [
        PlanItineraryItem(
            plan_request_id=plan_id,
            index=int(it["index"]),
            type=str(it["type"]),
            title=str(it["title"]),
            start_time=_parse_iso(it["start_time"]),
            end_time=_parse_iso(it["end_time"]),
            description=str(it.get("description") or ""),
        )
        for it in items
    ]
    if rows:
        db.add_all(rows)
        db.commit()