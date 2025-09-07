# src/services/plan_service.py  // ⬇️ 정확 패치 (추천 호출 + 저장 + 리턴)
from __future__ import annotations
import json
from typing import Any, Dict, List
from sqlalchemy.orm import Session
from db.base import SessionLocal, Base, engine
from schemas.plan import ItineraryRequest
from services.plan_transformer import build_plan_command
from services.plan_repository import save_plan_request, save_plan_items
from datetime import datetime, time, timezone

def _make_parking_items(addresses: list[str], base_dt: datetime, title: str) -> list[dict]:
    """
    주소 목록 → parking 아이템 리스트로 변환.
    시간은 base_dt의 '날짜 00:00'로 통일 (타임존 유지).
    """
    if not addresses:
        return []
    # base_dt(aware)에서 그 날 00:00 유지
    tz = base_dt.tzinfo or timezone.utc
    start = datetime.combine(base_dt.date(), time(0, 0, 0), tz)
    start_iso = start.isoformat()
    # end는 같게 넣어 UI가 깨지지 않도록
    end_iso = start_iso

    items = []
    for i, addr in enumerate(addresses, start=1):
        items.append({
            "index": i,                     # 일단 임시 index
            "type": "parking",
            "title": title,                 # 축제명 등
            "start_time": start_iso,
            "end_time":   end_iso,
            "description": addr,
        })
    return items


def _merge_and_reindex(*lists: list[dict]) -> list[dict]:
    """
    여러 리스트를 순서대로 합치고 index를 1..N으로 재부여
    """
    merged: list[dict] = []
    for lst in lists:
        if not lst:
            continue
        merged.extend(lst)

    # 1..N 재부여
    for idx, item in enumerate(merged, start=1):
        item["index"] = idx
    return merged


# ⬇️ 원본 추천 코드는 수정하지 않고 가져다 씀
from services.plan_recommend import FestPlanner  # ← 너가 준 파일/클래스 이름 그대로 사용

def ensure_schema_once():
    Base.metadata.create_all(bind=engine)

def _parse_model_output(o: Any) -> Dict[str, Any]:
    """
    FestPlanner.suggest_plan() 출력 파서:
    - str(JSON) 또는 dict({"itinerary":[...]}) → dict로 통일
    """
    if isinstance(o, dict):
        return o
    if isinstance(o, str):
        s = o.strip()
        if s.startswith("{") and s.endswith("}"):
            return json.loads(s)
        # responses.create의 str(response) 같은 케이스 방어
        # JSON 본문만 골라내기 시도
        left = s.find("{")
        right = s.rfind("}")
        if left != -1 and right != -1 and right > left:
            return json.loads(s[left:right+1])
    # 실패 시 빈 결과
    return {"itinerary": []}

def _normalize_itinerary(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """필수 필드만 추려서 DB/응답 공용 형태로 표준화"""
    norm: List[Dict[str, Any]] = []
    for it in items:
        try:
            norm.append({
                "index": int(it["index"]),
                "type": str(it["type"]),
                "title": str(it["title"]),
                "start_time": str(it["start_time"]),
                "end_time": str(it["end_time"]),
                "description": str(it.get("description") or ""),
            })
        except Exception:
            # 필수 키 누락 등은 스킵
            continue
    # index 기준 정렬
    norm.sort(key=lambda x: x["index"])
    return norm

def process_plan_sync(payload: ItineraryRequest) -> dict:
    """
    /plan/generate:
      1) 요청 가공 → plan_id 저장
      2) 추천 시스템 호출 (원본 그대로 사용)
      3) 추천 결과(itinerary) 저장
      4) 응답 리턴
    """
    ensure_schema_once()

    # 1) 입력 가공
    cmd = build_plan_command(payload)

    # 2) 요청 저장 → plan_id
    with SessionLocal() as db:  # type: Session
        plan_id = save_plan_request(db, cmd)
    print(cmd.schedule.festival_address)
    # 3) 추천 호출 (원본 코드 사용: 위치 텍스트는 origin_address 우선, 없으면 destination → 제목)
    fest_title = cmd.schedule.festival_title or cmd.schedule.title
    fest_location_text = (
        cmd.schedule.festival_address
    )
    travel_needs = {
        "start_at": cmd.schedule.start_at_kst.isoformat(),
        "end_at": cmd.schedule.end_at_kst.isoformat(),
        "categories": cmd.options.categories,
        "budget": cmd.options.budget,  # 원본 함수는 budget 있으면 사용
    }
    print("********")
    planner = FestPlanner(
        fest_title=fest_title,
        fest_location_text=fest_location_text,
        travel_needs=travel_needs,
    )
    raw = planner.suggest_plan()
    parsed = _parse_model_output(raw)
    itinerary = _normalize_itinerary(parsed.get("itinerary") or [])
    
    # # 4) 추천 결과 저장
    # if itinerary:
    #     with SessionLocal() as db:  # type: Session
    #         save_plan_items(db, plan_id, itinerary)

    # parking_addresses = [
    # "강원특별자치도 양구군 양구읍 박수근로 366-27",
    # "강원특별자치도 양구군 양구읍 박수근로 366-33",
    # "강원특별자치도 양구군 양구읍 박수근로365번길 20-2",
    # ]

    # # 축제명(타이틀)과 일정 시작일을 사용해 parking 아이템 생성
    # parking_items = _make_parking_items(
    #     parking_addresses,
    #     cmd.schedule.start_at_kst,          # 시작일(aware datetime)
    #     fest_title                          # 주차 타이틀은 축제명으로
    # )

    # # 메인 + 주차 머지 후 재인덱싱
    # itinerary = _merge_and_reindex(itinerary, parking_items)

    # 5) 응답
    return {
        "plan_id": plan_id,
        "schedule": {
            "title": cmd.schedule.title,
            "start_at_kst": cmd.schedule.start_at_kst.isoformat(),
            "end_at_kst": cmd.schedule.end_at_kst.isoformat(),
            "stay_minutes": cmd.schedule.stay_minutes,
        },
        "options": {
            "budget": cmd.options.budget,
            "categories": cmd.options.categories,
            "notes": cmd.options.notes,
        },
        "itinerary": itinerary,  # ← 앱에서 바로 렌더 가능
    }
