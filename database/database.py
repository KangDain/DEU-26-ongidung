# DB 서버와 연결하는 코드

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# 1. SQLite 데이터베이스 파일 경로 (최상위 폴더에 test.db)
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

# 2. 파이썬, DB 연결 엔진
# (check_same_thread -> FastAPI, SQLite를 같이 쓸 때 필수 설정)
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

# 3. 실제 DB 접속 -> 데이터 넣&뺏 때 사용할 Session 공장 생성
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)