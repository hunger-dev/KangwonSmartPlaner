import os
import requests
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from openai import OpenAI
import httpx
import certifi

# 환경변수에서 API 키 읽기
GOOGLE_API_KEY = "AIzaSyDtmP9H6utavbigd5NZxrTqoe2sATsAj3A"
OPENAI_API_KEY = "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"

class GoogleAPIError(Exception):
    pass

@dataclass
class Place:
    name: str
    address: str
    category: List[str]
    rating: Optional[float]
    lat: float
    lng: float
    operating_hours: List[str]

class PlacesClient:
    def __init__(self, api_key: Optional[str] = None, language: str = "ko"):
        self.api_key = api_key or GOOGLE_API_KEY
        if not self.api_key:
            raise ValueError("GOOGLE_API_KEY가 설정되지 않았습니다.")
        self.language = language

    def get_coords_from_place_name(self, place_name: str) -> str:
        place_id = self._find_place_id(place_name)
        if not place_id:
            return ""
        coords = self._geocode_place_id(place_id)
        return coords or ""

    def _find_place_id(self, place_name: str) -> str:
        url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
        params = {
            "input": place_name,
            "inputtype": "textquery",
            "key": self.api_key,
            "language": self.language,
            "fields": "place_id",
        }
        try:
            r = requests.get(url, params=params, timeout=10)
            r.raise_for_status()
            candidates = r.json().get("candidates", [])
            return candidates[0]["place_id"] if candidates else ""
        except requests.exceptions.RequestException as e:
            raise GoogleAPIError(f"findplacefromtext 실패: {e}") from e

    def _geocode_place_id(self, place_id: str) -> Optional[str]:
        url = "https://maps.googleapis.com/maps/api/geocode/json"
        params = {"place_id": place_id, "key": self.api_key, "language": self.language}
        try:
            r = requests.get(url, params=params, timeout=10)
            r.raise_for_status()
            results = r.json().get("results", [])
            if not results:
                return None
            loc = results[0]["geometry"]["location"]
            return f"{loc['lat']},{loc['lng']}"
        except requests.exceptions.RequestException as e:
            raise GoogleAPIError(f"geocode 실패: {e}") from e

    def get_place_details(self, place_id: str) -> Dict[str, Any]:
        url = "https://maps.googleapis.com/maps/api/place/details/json"
        params = {
            "place_id": place_id,
            "fields": "name,formatted_address,rating,opening_hours,vicinity",
            "key": self.api_key,
            "language": self.language,
        }
        try:
            r = requests.get(url, params=params, timeout=10)
            r.raise_for_status()
            return r.json().get("result", {}) or {}
        except requests.exceptions.RequestException as e:
            raise GoogleAPIError(f"place details 실패: {e}") from e

    def search_places_nearby(self, location: str, keyword: str, radius_m: int = 10000) -> List[Dict[str, Any]]:
        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        params = {
            "location": location,
            "keyword": keyword,
            "radius": radius_m,
            "key": self.api_key,
            "language": self.language,
        }
        try:
            r = requests.get(url, params=params, timeout=10)
            r.raise_for_status()
            return r.json().get("results", []) or []
        except requests.exceptions.RequestException as e:
            raise GoogleAPIError(f"nearbysearch 실패: {e}") from e

    def find_near_places(self, fest_location: str, keywords: Optional[List[str]] = None, radius_m: int = 10000) -> List[Place]:
        if not keywords:
            keywords = ["관광", "레저", "맛집", "자연경관", "체험", "카페", "식당", "박물관", "전시"]
        results: List[Place] = []

        for kw in keywords:
            try:
                raw = self.search_places_nearby(location=fest_location, keyword=kw, radius_m=radius_m)
            except GoogleAPIError as e:
                print(f"[에러] keyword={kw} API 호출 실패: {e}")
                continue

            for j, r in enumerate(raw):
                try:
                    loc = r.get("geometry", {}).get("location", {})
                    lat, lng = loc.get("lat"), loc.get("lng")
                    if lat is None or lng is None:
                        continue

                    details = {}
                    pid = r.get("place_id")
                    if pid:
                        try:
                            details = self.get_place_details(pid) or {}
                        except GoogleAPIError as e:
                            print(f"[경고] details 실패 idx={j}: {e}")

                    results.append(
                        Place(
                            name=details.get("name", r.get("name", "정보 없음")),
                            address=details.get("formatted_address", r.get("vicinity", "정보 없음")),
                            category=r.get("types") or ["정보 없음"],
                            rating=details.get("rating", r.get("rating")),
                            lat=lat,
                            lng=lng,
                            operating_hours=details.get("opening_hours", {}).get("weekday_text", ["정보 없음"]),
                        )
                    )
                except Exception as e:
                    print(f"[에러] keyword={kw} 처리 중 오류: {e}")

        return results

class FestPlanner:
    """
    - 체류시간 제약 X
    - 숙소/주차장 미고려
    - 이동수단/경로 최적화 미고려
    - OpenAI 응답 호출 포함
    """

    def __init__(self, fest_title: str, fest_location_text: str, travel_needs: Dict[str, Any], places_client: Optional[PlacesClient] = None):
        self.fest_title = fest_title
        self.travel_needs = self._normalize_needs(travel_needs)
        self.places = places_client or PlacesClient()
        self.fest_location = self.places.get_coords_from_place_name(fest_location_text)
        self.client = OpenAI(
            api_key=OPENAI_API_KEY,
            http_client=httpx.Client(verify=certifi.where())  # ⬅️ 추가
        )

    def _normalize_needs(self, needs: Dict[str, Any]) -> Dict[str, Any]:
        if "budget" not in needs and "burget" in needs:
            needs["budget"] = needs.pop("burget")
        required = ["start_at", "end_at", "categories"]
        for k in required:
            if k not in needs:
                raise ValueError(f"travel_needs에 '{k}'가 필요합니다.")
        if not isinstance(needs["categories"], list):
            needs["categories"] = [str(needs["categories"])]
        return needs

    def find_places_in_categories(self, categories: List[str], radius_km: int = 10) -> List[Place]:
        if not self.fest_location:
            return []
        radius_m = max(1000, int(radius_km * 1000))
        return self.places.find_near_places(self.fest_location, keywords=categories, radius_m=radius_m)

    def build_prompt(self, nearby_places: Optional[List[Place]] = None) -> str:
        snippets = []
        for p in (nearby_places or [])[:20]:
            cat = ", ".join(p.category[:3])
            snippets.append(f"- {p.name} | {cat} | 평점:{p.rating} | {p.address}")
        places_block = "\n".join(snippets) if snippets else "(근처 후보 없음)"

        start_at = self.travel_needs["start_at"]
        end_at = self.travel_needs["end_at"]
        categories = ", ".join(self.travel_needs["categories"])
        budget = self.travel_needs.get("budget", "미지정")

        user_prompt = f"""
역할: 여행 플래너

입력 정보
- 행사명: {self.fest_title}
- 행사장(위도,경도): {self.fest_location}  # 예: "37.1234,127.5678"
- 여행 기간(시작~종료, KST ISO8601): {start_at} ~ {end_at}
- 추가 고려 옵션:
  - 최대 예산: {budget}
  - 희망 여행 컨셉(참고용): {categories}

참고용 주변 장소(최대 20개)
{places_block}

요구사항
1) 내부 자료와 웹 서칭을 통해 주변 장소 후보를 탐색하고, 검증 가능한 대표 정보(명칭·카테고리·대략적 평판/특징)를 근거로 선정할 것.
2) 행사는 반드시 일정 중 최소 1회 이상 포함할 것(type="festival").
3) 이동 시간을 현실적으로 반영하되, 특정 이동수단이나 경로 최적화는 고려하지 말 것.
4) 예산 제약은 반드시 준수하고, 희망 여행 컨셉은 참고만 할 것.
5) 숙소와 주차장은 고려하지 말 것(추천·배치·유형 사용 금지).
6) 모든 시간은 KST ISO8601 형식으로 기입할 것(예: 2025-08-19T10:00:00+09:00).
7) 장소 유형(type)은 다음 중 하나로만 사용: festival, place, cafe, restaurant.
8) 결과는 JSON만 출력하고, 그 외 설명/텍스트는 포함하지 말 것.
9) description에 출처와url은 포함하지 않는다.

출력 스키마 예시
{{
  "itinerary": [
    {{
      "index": 1,
      "type": "festival",
      "title": "{self.fest_title}",
      "start_time": "2025-08-19T10:00:00+09:00",
      "end_time": "2025-08-19T11:30:00+09:00",
      "description": "행사장 중심 활동"
    }},
    {{
      "index": 2,
      "type": "place",
      "title": "소양강 스카이워크",
      "start_time": "2025-08-19T11:30:00+09:00",
      "end_time": "2025-08-19T12:00:00+09:00",
      "description": "주변 추천지"
    }}
  ],
  "totals": {{
    "estimated_cost_krw": 0,
    "estimated_travel_time_minutes": 0
  }}
}}
"""
        return user_prompt.strip()

    def suggest_plan(self) -> Any:
        """
        1) 주변 후보 수집
        2) 프롬프트 생성
        3) OpenAI responses.create 호출
        4) output_text 또는 {"error": "..."} 반환
        """
        try:
            if not OPENAI_API_KEY:
                return {"error": "OPENAI_API_KEY가 설정되지 않았습니다."}

            # 1) 후보 수집
            nearby_places = []
            if self.fest_location:
                nearby_places = self.find_places_in_categories(self.travel_needs["categories"], radius_km=10)

            # 2) 프롬프트 생성
            user_prompt = self.build_prompt(nearby_places=nearby_places)

            # 3) OpenAI 호출 (요청하신 패턴)
            response = self.client.responses.create(
                model="gpt-4o-mini",
                tools=[{"type": "web_search_preview"}],
                input=user_prompt
            )
            # 4) 결과 반환
            # SDK별 속성명이 다를 수 있으나, 요청 포맷에 맞춰 output_text 우선 시도
            return getattr(response, "output_text", None) or str(response)

        except Exception as e:
            return {"error": f"OpenAI API 호출 실패: {str(e)}"}