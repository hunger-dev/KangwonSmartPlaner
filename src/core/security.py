# src/core/security.py
import base64, hmac, json, hashlib
from typing import Any, Dict
from core.config import settings

def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

def _unb64(s: str) -> bytes:
    pad = "=" * (-len(s) % 4)
    return base64.urlsafe_b64decode(s + pad)

def sign_ticket(payload: Dict[str, Any]) -> str:
    """
    미리보기 응답에 첨부하는 서명 토큰.
    서버는 상태 저장 안 하고, 클라가 이 ticket을 들고 다시 오면 저장.
    """
    body = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode()
    sig = hmac.new(settings.SECRET_KEY.encode(), body, hashlib.sha256).digest()
    return _b64(body) + "." + _b64(sig)

def verify_ticket(ticket: str) -> Dict[str, Any]:
    """
    클라가 보낸 ticket을 검증하고 원본 payload 복원.
    """
    try:
        body_b64, sig_b64 = ticket.split(".", 1)
    except ValueError:
        raise ValueError("invalid ticket format")

    body = _unb64(body_b64)
    sig = _unb64(sig_b64)
    exp = hmac.new(settings.SECRET_KEY.encode(), body, hashlib.sha256).digest()
    if not hmac.compare_digest(sig, exp):
        raise ValueError("invalid ticket signature")

    return json.loads(body.decode())
