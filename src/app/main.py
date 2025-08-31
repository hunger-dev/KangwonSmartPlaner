from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.lifecycles import on_startup, on_shutdown
from app.routers import health
from core.config import settings
from app.routers import health
from app.routers import crawl as crawl_router
from app.routers.festivals import router as festivals_router
from app.routers import plan 

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        docs_url="/docs",      # Swagger UI
        redoc_url="/redoc",    # ReDoc
    )

    # CORS (초기엔 모두 허용, 필요 시 제한)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ALLOW_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routers
    app.include_router(health.router, tags=["health"])

    # Lifecycles
    app.add_event_handler("startup", on_startup)
    app.add_event_handler("shutdown", on_shutdown)
    app.include_router(health.router, tags=["health"])
    app.include_router(crawl_router.router, prefix="/crawl", tags=["crawl"])
    app.include_router(festivals_router, prefix="/festivals", tags=["festivals"])
    app.include_router(plan.router)

    return app


app = create_app()

# (옵션) python로 직접 실행할 때
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
