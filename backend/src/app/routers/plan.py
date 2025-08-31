# src/app/routers/plan.py
from fastapi import APIRouter, Request, HTTPException
from datetime import datetime, timezone
import logging
import uuid


from schemas.plan import ItineraryRequest, ItineraryResponse, EchoMeta, PlanCommitPayload
from services.plan_service import process_plan_sync

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/plan", tags=["plan"])

@router.post("/generate", response_model=ItineraryResponse)
def generate_plan(req: Request, payload: ItineraryRequest):
    """
    클라이언트가 여행 일정 요청을 보내면:
    1) payload(요청 데이터)를 로그로 남김
    2) 서비스 레이어 호출 → 추천 시스템 실행
    3) EchoMeta로 요청 수신 시간 기록
    4) ItineraryResponse 구조로 응답 반환
    """
    try:
        logger.info("ItineraryRequest received",
                    extra={"payload": payload.model_dump(mode="json")})

        # 서비스 호출 → 실제 추천 실행
        result_meta = process_plan_sync(payload)

        logger.info("Plan processed", extra={"result_meta": result_meta})

        # 응답 메타 생성
        meta = EchoMeta(
            received_at_iso=datetime.now(tz=timezone.utc),
            echo=True,
        )

        # 최종 응답 반환
        print(result_meta)
        return ItineraryResponse(
            ok=True,
            meta=meta,
            request=payload,
            result=result_meta
        )

    except Exception as e:
        logger.exception("Plan generation failed")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/save")
def save_plan(payload: PlanCommitPayload):
    """
    클라에서 온 PlanCommitPayload(ticket, itinerary)를 영구 저장.
    반환 포맷은 자유 — 여기선 id와 저장 시각만 간단히 반환.
    """
    try:
      if not payload.itinerary:
          raise HTTPException(status_code=400, detail="itinerary is empty")

      # 예: UUID 발급 후 저장 (여기선 메모리/파일/DB 중 택1)
      plan_id = str(uuid.uuid4())
      saved_at = datetime.now(tz=timezone.utc)

      # 예시) 파일로 떨어뜨리기 (DB 대체)
      # with open(f"./.plans/{plan_id}.json", "w", encoding="utf-8") as f:
      #     json.dump(payload.model_dump(mode="json"), f, ensure_ascii=False, indent=2)

      # TODO: 실제 DB에 저장하는 로직으로 교체 (SQLite, Postgres 등)
      # save_to_db(plan_id, payload)

      return {"id": plan_id, "saved_at": saved_at.isoformat()}

    except HTTPException:
      raise
    except Exception as e:
      logger.exception("Plan save failed")
      raise HTTPException(status_code=500, detail=str(e))