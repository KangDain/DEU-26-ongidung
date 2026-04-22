from backend.database import engine
from backend.models import Base

print("DB Table 생성을 시작합니다...")

# models.py에 정의해둔 Base 클래스를 바탕으로
# 엔진에 연결된 DB에 테이블들을 만들어줌
Base.metadata.create_all(bind=engine)

print("테이블 생성 완료")