import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from db.base import Base, engine

from core.scheduler import scheduler
from core.config import settings
from services.crawling import crawl_and_save_festivals
def init_db():
    # 최초 1회 테이블 생성 (이미 있으면 아무 일도 안 함)
    Base.metadata.create_all(bind=engine)

logger = logging.getLogger(__name__)

def _daily_crawl_job():
    stats = crawl_and_save_festivals()
    logger.info("[CRAWL][DAILY] %s", stats)

def _initial_crawl_job():
    stats = crawl_and_save_festivals()
    logger.info("[CRAWL][INITIAL] %s", stats)

async def on_startup():
    init_db() 
    # 매일 03:00 크론 잡
    scheduler.add_job(
        _daily_crawl_job,
        trigger="cron",
        hour=3, minute=0,
        id="daily_crawl",
        replace_existing=True,
        coalesce=True,
        max_instances=1,
        misfire_grace_time=600,
    )

    # 서버 시작 후 한 번만 실행(비차단 방식)
    if settings.CRAWL_ON_STARTUP:
        tz = ZoneInfo("Asia/Seoul")
        run_at = datetime.now(tz) + timedelta(seconds=settings.INITIAL_CRAWL_DELAY_SECONDS)
        scheduler.add_job(
            _initial_crawl_job,
            trigger="date",
            run_date=run_at,
            id="initial_crawl",
            replace_existing=True,
            coalesce=True,
            max_instances=1,
        )

    scheduler.start()
    logger.info("Scheduler started. Jobs: daily_crawl + initial_crawl(%s).",
                "on" if settings.CRAWL_ON_STARTUP else "off")

async def on_shutdown():
    try:
        scheduler.shutdown(wait=False)
    except Exception:
        pass
    logger.info("Scheduler stopped.")
