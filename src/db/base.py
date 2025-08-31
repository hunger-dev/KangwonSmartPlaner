# src/db/base.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from core.config import settings

class Base(DeclarativeBase):
    pass

def _engine_kwargs(url: str):
    if url.startswith("sqlite"):
        return {"connect_args": {"check_same_thread": False}}
    return {}

engine = create_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    **_engine_kwargs(settings.DATABASE_URL),
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)