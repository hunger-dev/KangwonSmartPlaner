# src/schemas/plan.py
from typing import List, Literal, Optional, Any, Dict
from pydantic import BaseModel, Field, HttpUrl, AwareDatetime

SchemaLiteral = Literal["itinerary_request_v1"]
BudgetLiteral = Literal["low", "normal", "high"]

class ClientInfo(BaseModel):
    app: str
    platform: str
    version: str

class ScheduleInfo(BaseModel):
    title: str
    start_at: AwareDatetime
    end_at: AwareDatetime
    origin_address: str
    destination_address: str
    stay_minutes: int
    festival_id: int
    festival_title: str
    festival_detail_url: Optional[HttpUrl] = None
    festival_address: Optional[str] = None   # ✅ 추가


class Options(BaseModel):
    budget: BudgetLiteral = "normal"
    categories: List[str] = []
    avoid_crowded: bool = False
    start_time: Optional[str] = Field(None, pattern=r"^\d{2}:\d{2}$")
    end_time: Optional[str] = Field(None, pattern=r"^\d{2}:\d{2}$")
    notes: Optional[str] = None

class ItineraryRequest(BaseModel):
    schema_data: SchemaLiteral
    client: ClientInfo
    schedule: ScheduleInfo
    options: Options

class EchoMeta(BaseModel):
    received_at_iso: AwareDatetime
    echo: bool = True

class ItineraryResponse(BaseModel):
    ok: bool = True
    meta: EchoMeta
    request: ItineraryRequest
    result: Dict[str, Any] | None = None  # ← Any 허용

# ⬇️ 저장(커밋) 요청 스키마: ticket + itinerary 배열
class ItineraryItem(BaseModel):
    index: int
    type: str
    title: str
    start_time: AwareDatetime
    end_time: AwareDatetime
    description: str

class PlanCommitPayload(BaseModel):
    ticket: str  # sign_ticket() 결과
    itinerary: List[ItineraryItem] = []
