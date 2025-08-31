# 강원 스마트 여행 플래너 (Kangwon Smart Travel Planner)

> **여행 · 축제 · 주차를 한 번에** — LLM + Google/T map API 기반 개인화 일정 추천 & 혼잡/주차 연동 서비스  
> Monorepo: `backend/` (FastAPI) + `frontend/` (Android)

---
## 📌 부록: 배경 요약
- **개발 배경**: 강원도 축제 기간의 심각한 주차 혼잡/불법주차, 체류 경험 저하, 주민–관광객 갈등
- **개발 방향**: 여행-주차-축제를 통합한 확장형 일정 계획 + 실시간 데이터 기반 혼잡 예측/대체 루트
- **차별점**: LLM 기반 암시적 선호 반영, 주차/축제라는 현실 제약을 함께 고려하는 실행가능 일정
---

## 👀 프로젝트 한눈에 보기
- 강원도 주요 도시(강릉·원주·춘천 등)는 **주차장 확보율이 100%+** 임에도 **체감 주차난**이 꾸준히 발생합니다. 축제 기간에는 혼잡이 특히 심각합니다.  
- 기존 여행 서비스는 숙박/관광지 위주로만 최적화되어 **축제 일정·회차·대기·셔틀**과 **주차(잔여 대수, 요금, 도보거리)** 같은 **현실 제약**을 반영하지 못합니다.  
- 본 프로젝트는 **LLM(ChatGPT API)** 과 **Google API, T map API** 를 결합하여 **여행-주차-축제**를 **통합 최적화**합니다.

**핵심 가치**
- 개인 선호(예산, 가족 동반, 야간/도보 회피 등) + 축제 제약 + 주차 제약을 함께 반영
- 실시간 교통/주차 데이터를 활용해 **혼잡 예측** 및 **대체 루트/주차장** 제시
- 현장성이 높은 **실행 가능한 일정** 제공 → 체류 만족도 및 재방문율 향상

---

## 🧩 주요 기능
- **LLM 기반 맞춤 일정 설계**: 불완전/모호한 사용자 입력을 일정 변수로 변환
- **축제 제약 연동**: 날짜·회차·대기시간·입장 제한·셔틀 운행 고려
- **주차 최적화**: 잔여 공간, 요금, 목적지 도보 거리 기반 추천
- **경로 최적화**: T map 경유지 최적화 API로 실시간 교통 반영
- **대시보드(운영자)**: 가동률/민원/혼잡 예측·열지도 시각화(향후)

---

## 🏗️ 아키텍처 개요
![앱 프로토타입](docs/images/app_screens.png)
![주차 보도](docs/images/news_parking.png)
![개요/아키텍처](docs/images/overview_arch.png)



---

## 📁 저장소 구조
```
KangwonSmartPlaner/
├── backend/                 # FastAPI 서비스
│   ├── src/                 # API, 서비스 로직
│   ├── data/                # (옵션) 샘플/시드 데이터
│   ├── alembic.ini          # (옵션) 마이그레이션
│   ├── .env.example         # 백엔드 환경변수 템플릿
│   └── ...                
├── frontend/                # Android (Kotlin/Compose or XML)
│   ├── app/
│   ├── gradle/
│   ├── build.gradle
│   ├── settings.gradle
│   └── ...
├── docs/
│   └── images/              # README용 이미지들(위 3개 파일명 추천)
├── .gitignore
└── README.md
```

---

## ⚙️ 빠른 시작

### 1) Backend (FastAPI)
#### 요구사항
- Python 3.10+
- (선택) PostgreSQL 등 RDBMS

#### 환경변수
`backend/.env.example` 를 복사해 `.env` 생성 후 값 채우기:
```
OPENAI_API_KEY=sk-...
GOOGLE_MAPS_API_KEY=...
TMAP_API_KEY=...
DATABASE_URL=postgresql+psycopg2://user:pass@host:5432/dbname
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

#### 실행
```bash
cd backend
python -m venv .venv && . .venv/Scripts/activate  # (Windows PowerShell: .venv\Scripts\Activate.ps1)
pip install -r requirements.txt
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```
- API 문서는 기본적으로 `http://localhost:8000/docs` (Swagger) 에서 확인 가능합니다.

### 2) Frontend (Android)
#### 요구사항
- Android Studio (Giraffe+), Android SDK
- JDK 17 권장

#### 설정 & 빌드
- (선택) `local.properties` 에 SDK 경로 설정:  
  `sdk.dir=C\:\\Users\\<you>\\AppData\\Local\\Android\\Sdk`
- API 키는 `local.properties` 또는 `res/values/strings.xml` 등 안전한 위치에 주입합니다. (절대 공개 저장소에 실제 키 노출 금지)
- 빌드/실행: Android Studio에서 `frontend/` 열고 Run ▶


