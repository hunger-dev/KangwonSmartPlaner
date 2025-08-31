from __future__ import annotations
import hashlib
import re
from datetime import datetime, date
from typing import List, Tuple, Optional

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

from db.base import SessionLocal
from db.models import Festival

BASE_URL = "https://www.gangwon.to"
LIST_URL = "https://www.gangwon.to/gwtour/now/festival"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/122.0.0.0 Safari/537.36"
    )
}

# ----[1] 기간 파서: "YYYY-MM-DD ~ YYYY-MM-DD" 등 처리 ----
_DATE_PATTERN = r"(\d{4})[.\-\/](\d{1,2})[.\-\/](\d{1,2})"
_RANGE_PATTERN = re.compile(rf"{_DATE_PATTERN}\s*[~\-–]\s*{_DATE_PATTERN}")

def _to_date(y: str, m: str, d: str) -> date:
    return date(int(y), int(m), int(d))

def parse_period(period_raw: Optional[str]) -> Tuple[Optional[date], Optional[date]]:
    if not period_raw:
        return None, None
    m = _RANGE_PATTERN.search(period_raw)
    if not m:
        # 단일 날짜 형태(예: 2025-08-29)면 start=end로 저장
        single = re.search(_DATE_PATTERN, period_raw)
        if single:
            dt = _to_date(*single.groups())
            return dt, dt
        return None, None
    y1, m1, d1, y2, m2, d2 = m.groups()
    return _to_date(y1, m1, d1), _to_date(y2, m2, d2)

# ----[2] 리스트 페이지 파싱 ----
def parse_list_page(url: str) -> List[dict]:
    resp = requests.get(url, headers=HEADERS, timeout=15)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")

    container = soup.select_one("div.now-list.list-type-col4.clearfix")
    if not container:
        return []

    items = []
    for a in container.select("a[href]"):
        detail_url = urljoin(url, a.get("href", "").strip())

        img = a.select_one("img")
        img_src = urljoin(url, img.get("src")) if img and img.get("src") else None
        img_alt = img.get("alt", "").strip() if img else ""

        title_tag = a.select_one(".text strong") or a.select_one("strong")
        title = title_tag.get_text(strip=True) if title_tag else ""

        time_tag = a.find("time")
        period = time_tag.get_text(strip=True) if time_tag else ""

        address = ""
        for sp in a.select("span"):
            if sp.find("time") is None:
                txt = sp.get_text(" ", strip=True)
                if txt:
                    address = txt

        items.append(
            {
                "title": title,
                "period": period,
                "address": address,
                "image_src": img_src,
                "image_alt": img_alt,
                "detail_url": detail_url,
            }
        )
    return items

# ----[3] 해시 생성(중복 방지 키) ----
def make_hash(title: str, detail_url: str, period_raw: Optional[str]) -> str:
    key = f"{(title or '').strip()}|{(detail_url or '').strip()}|{(period_raw or '').strip()}"
    return hashlib.sha256(key.encode("utf-8")).hexdigest()

# ----[4] DB 저장(UPSERT 유사: 있으면 업데이트, 없으면 INSERT) ----
def upsert_festivals(rows: List[dict]) -> tuple[int, int]:
    inserted = 0
    updated = 0
    with SessionLocal() as s:
        for r in rows:
            title = (r.get("title") or "").strip()
            detail_url = r.get("detail_url") or ""
            period_raw = r.get("period") or ""

            h = make_hash(title, detail_url, period_raw)
            start, end = parse_period(period_raw)

            obj = s.query(Festival).filter(Festival.hash == h).one_or_none()
            if obj:
                # 변경 가능성이 있는 필드만 갱신
                obj.title = title or obj.title
                obj.period_raw = period_raw or obj.period_raw
                obj.period_start = start
                obj.period_end = end
                obj.address = r.get("address") or obj.address
                obj.image_src = r.get("image_src") or obj.image_src
                obj.image_alt = r.get("image_alt") or obj.image_alt
                obj.detail_url = detail_url or obj.detail_url
                updated += 1
            else:
                s.add(
                    Festival(
                        title=title,
                        period_raw=period_raw,
                        period_start=start,
                        period_end=end,
                        address=r.get("address"),
                        image_src=r.get("image_src"),
                        image_alt=r.get("image_alt"),
                        detail_url=detail_url,
                        hash=h,
                    )
                )
                inserted += 1
        s.commit()
    return inserted, updated

# ----[5] 오케스트레이션: 크롤 → 파싱 → 저장 ----
def crawl_and_save_festivals() -> dict:
    rows = parse_list_page(LIST_URL)
    ins, upd = upsert_festivals(rows)
    return {"fetched": len(rows), "inserted": ins, "updated": upd}
