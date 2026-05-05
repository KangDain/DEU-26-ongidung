from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from database import engine, get_db
import models

# DB 테이블 생성 (서버 시작 시 자동 생성)
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# 프론트 통신용 CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ────────────────────────────────────────────────
# 요청 데이터 양식 정의
# ────────────────────────────────────────────────

class UserCreate(BaseModel):
    login_id: str
    user_pw: str
    user_name: str
    user_phone: Optional[str] = None
    user_birth_date: Optional[str] = None
    user_address: Optional[str] = None
    guardian_phone: Optional[str] = None
    # user_type: ELDERLY / CHILD / GENERAL / GUARDIAN (프론트에서 선택한 유형)
    user_type: str = "GENERAL"

class LoginRequest(BaseModel):
    login_id: str
    user_pw: str

class UserUpdate(BaseModel):
    user_name: str


# ────────────────────────────────────────────────
# 1. 회원가입 API
# ────────────────────────────────────────────────
@app.post("/api/signup")
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # 아이디 중복 확인
    existing = db.query(models.User).filter(
        models.User.login_id == user.login_id
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="이미 사용 중인 아이디입니다.")

    # user_type → user_role 매핑
    if user.user_type == "GUARDIAN":
        role = models.UserRole.GUARDIAN
    else:
        role = models.UserRole.RECIPIENT

    new_user = models.User(
        login_id=user.login_id,
        user_pw=user.user_pw,
        user_name=user.user_name,
        user_phone=user.user_phone,
        user_birth_date=user.user_birth_date,
        user_address=user.user_address,
        guardian_phone=user.guardian_phone,
        user_type=user.user_type,
        user_role=role,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "message": f"환영합니다, {new_user.user_name}님!",
        "user_id": new_user.user_id,
    }


# ────────────────────────────────────────────────
# 2. 로그인 API
# ────────────────────────────────────────────────
@app.post("/api/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.login_id == request.login_id,
        models.User.user_pw == request.user_pw,
        models.User.user_is_deleted == False,
    ).first()

    if not user:
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다.")

    return {
        "user_id": user.user_id,
        "login_id": user.login_id,
        "user_name": user.user_name,
        "user_role": user.user_role.value,
        "user_type": user.user_type,
        "user_phone": user.user_phone,
        "user_birth_date": user.user_birth_date,
        "user_address": user.user_address,
        "guardian_phone": user.guardian_phone,
    }


# ────────────────────────────────────────────────
# 3. 유저 목록 조회 (관리자용)
# ────────────────────────────────────────────────
@app.get("/api/users")
async def get_users(db: Session = Depends(get_db)):
    users = db.query(models.User).filter(models.User.user_is_deleted == False).all()
    return [
        {
            "user_id": u.user_id,
            "login_id": u.login_id,
            "user_name": u.user_name,
            "user_phone": u.user_phone,
            "user_role": u.user_role.value,
            "user_type": u.user_type,
            "user_created_at": str(u.user_created_at),
        }
        for u in users
    ]


# ────────────────────────────────────────────────
# 4. 유저 이름 수정
# ────────────────────────────────────────────────
@app.patch("/api/users/{user_id}")
async def update_user_name(user_id: int, user_data: UserUpdate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="유저를 찾을 수 없습니다.")

    old_name = db_user.user_name
    db_user.user_name = user_data.user_name
    db.commit()
    db.refresh(db_user)

    return {"message": f"'{old_name}'님이 '{db_user.user_name}'님으로 변경되었습니다."}
