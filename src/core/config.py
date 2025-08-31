from pydantic_settings import BaseSettings
from typing import List
from pathlib import Path

class Settings(BaseSettings):
    APP_NAME: str = "FastAPI Starter"
    APP_VERSION: str = "0.1.0"
    CORS_ALLOW_ORIGINS: List[str] = ["*"]
    _DB_PATH = (Path(__file__).resolve().parents[2] / "data" / "app.db").as_posix()
    DATABASE_URL: str = f"sqlite:///{_DB_PATH}"
    CRAWL_ON_STARTUP: bool = True
    INITIAL_CRAWL_DELAY_SECONDS: int = 5 
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()