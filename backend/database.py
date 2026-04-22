from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# SQLite 데이터베이스 파일 이름 설정 (이름은 맘대로 해도 됨!)
SQLALCHEMY_DATABASE_URL = "sqlite:///./ongidung.db"

# DB 엔진 시동 걸기 (SQLite 전용 설정 포함)
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# 데이터베이스와 대화할 수 있는 세션 만들기
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 앞으로 만들 모든 DB 테이블의 뼈대가 될 클래스
Base = declarative_base()

# DB 세션을 열고 닫는 안전한 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()