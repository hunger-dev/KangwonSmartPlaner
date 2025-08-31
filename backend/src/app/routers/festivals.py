from fastapi import APIRouter, Query
from sqlalchemy import select, func, and_, case
from db.base import SessionLocal
from db.models import Festival

router = APIRouter()

DEFAULT_FIRST_PAGE = 16  # 첫 페이지 기본 개수

@router.get("/first-page")
def first_page(
    limit: int = Query(DEFAULT_FIRST_PAGE, ge=1, le=50),
    q: str | None = None,  # (옵션) 제목 검색어
):
    """
    축제 '최신 스냅샷'만 모아서 첫 페이지 분량 반환.
    같은 축제(detail_url)는 최신 created_at 한 건만.
    """
    with SessionLocal() as s:
        # 같은 축제(detail_url)에서 최신(created_at)만 뽑는 서브쿼리
        subq = (
            s.query(
                Festival.detail_url,
                func.max(Festival.created_at).label("max_created"),
            )
            .group_by(Festival.detail_url)
            .subquery()
        )

        stmt = (
            select(Festival)
            .join(
                subq,
                and_(
                    Festival.detail_url == subq.c.detail_url,
                    Festival.created_at == subq.c.max_created,
                ),
            )
        )
        if q:
            stmt = stmt.filter(Festival.title.contains(q))

        # 기간 있는 것 우선, 최신순
        stmt = stmt.order_by(
            case((Festival.period_start.is_(None), 1), else_=0),
            Festival.period_start.desc(),
            Festival.created_at.desc(),
        ).limit(limit)

        rows = s.execute(stmt).scalars().all()

        return [
            {
                "id": f.id,
                "title": f.title,
                "period": {"raw": f.period_raw, "start": f.period_start, "end": f.period_end},
                "address": f.address,
                "image_src": f.image_src,
                "detail_url": f.detail_url,
            }
            for f in rows
        ]
