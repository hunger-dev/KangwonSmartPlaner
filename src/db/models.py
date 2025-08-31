# src/db/models.py

from typing import Optional
from datetime import date, datetime
from sqlalchemy import String, Text, Date, DateTime, func, UniqueConstraint, Index, JSON, Boolean, Integer, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from db.base import Base

class Festival(Base):
    __tablename__ = "festival"
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(300), nullable=False)
    period_raw: Mapped[Optional[str]] = mapped_column(String(120))
    period_start: Mapped[Optional[date]] = mapped_column(Date)
    period_end:   Mapped[Optional[date]] = mapped_column(Date)
    address:   Mapped[Optional[str]] = mapped_column(String(300))
    image_src: Mapped[Optional[str]] = mapped_column(Text)
    image_alt: Mapped[Optional[str]] = mapped_column(String(300))
    detail_url: Mapped[Optional[str]] = mapped_column(Text)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    hash: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    __table_args__ = (
        UniqueConstraint("hash", name="uq_festival_hash"),
        Index("ix_festival_period_start", "period_start"),
        Index("ix_festival_created_at", "created_at"),
    )

class PlanRequest(Base):
    __tablename__ = "plan_request"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    # 원본 요청(요약본 또는 전체 JSON) 저장해 추적 가능
    client_app: Mapped[str]      = mapped_column(String(40))
    client_platform: Mapped[str] = mapped_column(String(20))
    client_version: Mapped[str]  = mapped_column(String(20))
    schedule_json: Mapped[dict]  = mapped_column(JSON)   # {"title":..., "start_at":..., ...}
    options_json:  Mapped[dict]  = mapped_column(JSON)   # {"budget":..., ...}

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class PlanItineraryItem(Base):
    __tablename__ = "plan_itinerary_item"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    plan_request_id: Mapped[int] = mapped_column(ForeignKey("plan_request.id", ondelete="CASCADE"), index=True)

    index: Mapped[int]        = mapped_column(Integer, nullable=False)       # 1부터
    type: Mapped[str]         = mapped_column(String(24), nullable=False)    # 'festival' | 'place' ...
    title: Mapped[str]        = mapped_column(String(300), nullable=False)
    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_time:   Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    description: Mapped[str]  = mapped_column(String(1000), nullable=False, default="")

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())