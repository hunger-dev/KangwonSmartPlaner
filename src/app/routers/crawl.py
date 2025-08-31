from fastapi import APIRouter
from services.crawling import crawl_and_save_festivals

router = APIRouter()

@router.post("/run")
def run_once():
    return crawl_and_save_festivals()

@router.get("/run", include_in_schema=False)
def run_once_get():
    return crawl_and_save_festivals()