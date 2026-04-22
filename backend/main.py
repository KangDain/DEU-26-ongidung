from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
from database import engine, get_db
import models

# DB 테이블 생성 (이미 생겼지만 혹시 모르니 둡니다)
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# 프론트 통신용 CORS 방어막
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------------------------------
# 📝 프론트에서 백엔드로 보낼 "데이터 양식(택배 상자)" 정의
# ----------------------------------------------------
class UserCreate(BaseModel):
    login_id: str
    user_pw: str
    user_name: str
    user_phone: str

# ----------------------------------------------------
# 1️⃣ 회원가입 API (진짜 DB에 유저 정보 저장!)
# ----------------------------------------------------
@app.post("/api/signup")
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # 프론트에서 받은 데이터로 새 유저 객체 생성
    new_user = models.User(
        login_id=user.login_id,
        user_pw=user.user_pw, # (주의: 실전엔 해시 암호화해야 하지만 지금은 쌩으로!)
        user_name=user.user_name,
        user_phone=user.user_phone,
        user_role=models.UserRole.GUARDIAN # 기본값은 보호자로 세팅
    )
    db.add(new_user) # DB에 올리기
    db.commit()      # 도장 쾅! (저장 확정)
    db.refresh(new_user)
    
    return {"message": f"환영합니다, {new_user.user_name}님!", "user_id": new_user.user_id}

# ----------------------------------------------------
# 2️⃣ 유저 목록 조회 API (진짜 DB에서 꺼내오기)
# ----------------------------------------------------
@app.get("/api/users")
async def get_users(db: Session = Depends(get_db)):
    # users 테이블에 있는 모든 데이터를 싹 다 가져와라!
    users = db.query(models.User).all()
    return users

# 📝 수정할 때 사용할 데이터 양식 (이름만 바꿀 수도 있으니까!)
class UserUpdate(BaseModel):
    user_name: str

# ----------------------------------------------------
# 3️⃣ 유저 정보 수정 API (이름 바꾸기!)
# ----------------------------------------------------
@app.patch("/api/users/{user_id}")
async def update_user_name(user_id: int, user_data: UserUpdate, db: Session = Depends(get_db)):
    # 1. DB에서 해당 ID를 가진 유저를 찾음
    db_user = db.query(models.User).filter(models.User.user_id == user_id).first()
    
    if not db_user:
        return {"error": "유저를 찾을 수 없어요!"}
    
    # 2. 이름을 새 이름으로 교체
    old_name = db_user.user_name
    db_user.user_name = user_data.user_name
    
    # 3. DB에 저장
    db.commit()
    db.refresh(db_user)
    
    return {"message": f"성공! '{old_name}'님이 '{db_user.user_name}'님으로 개명되었습니다."}