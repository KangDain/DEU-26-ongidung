from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, time
from typing import List

from database import engine, get_db
import models

# 테이블을 생성
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Protect Care API (Original ERD)")

# 프론트엔드 연동을 위한 CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# 📝 Pydantic 스키마 (데이터 통신 양식)
# ==========================================
class UserCreate(BaseModel):
    login_id: str
    user_pw: str
    user_name: str
    user_phone: str
    user_role: str  # "GUARDIAN", "RECIPIENT", "ADMIN"

class LoginRequest(BaseModel):
    login_id: str
    user_pw: str

class RelationCreate(BaseModel):
    guardian_id: int
    recipient_id: int

class RoutineCreate(BaseModel):
    routine_title: str
    routine_notify_time: str # "HH:MM" 형식 (예: "08:00")

class AlertCreate(BaseModel):
    alert_type: str # "FALL_DOWN", "NO_MOVEMENT" 등

# ==========================================
# API 엔드포인트
# ==========================================

@app.post("/api/signup")
async def signup(user: UserCreate, db: Session = Depends(get_db)):
    # 중복 검사
    if db.query(models.User).filter(models.User.login_id == user.login_id).first():
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디입니다.")
    
    # enum 변환
    role_enum = models.UserRole.RECIPIENT
    if user.user_role == "GUARDIAN": role_enum = models.UserRole.GUARDIAN
    elif user.user_role == "ADMIN": role_enum = models.UserRole.ADMIN

    new_user = models.User(
        login_id=user.login_id,
        user_pw=user.user_pw,
        user_name=user.user_name,
        user_phone=user.user_phone,
        user_role=role_enum
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": f"{new_user.user_name}님 가입 완료!", "user_id": new_user.user_id}

@app.post("/api/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.login_id == request.login_id,
        models.User.user_pw == request.user_pw,
        models.User.user_is_deleted == False
    ).first()
    
    if not user:
        raise HTTPException(status_code=401, detail="아이디/비밀번호가 틀렸습니다.")
    
    return {
        "user_id": user.user_id,
        "user_name": user.user_name,
        "user_role": user.user_role.value
    }

@app.post("/api/relations")
async def create_relation(req: RelationCreate, db: Session = Depends(get_db)):
    new_relation = models.CareRelation(
        guardian_id=req.guardian_id,
        recipient_id=req.recipient_id
    )
    db.add(new_relation)
    db.commit()
    return {"message": "보호 관계가 연결되었습니다!"}

@app.post("/api/users/{recipient_id}/routines")
async def add_routine(recipient_id: int, req: RoutineCreate, db: Session = Depends(get_db)):
    # "08:00" 문자열을 파이썬 time 객체로 변환
    hour, minute = map(int, req.routine_notify_time.split(":"))
    notify_time = time(hour, minute)

    new_routine = models.Routine(
        recipient_id=recipient_id,
        routine_title=req.routine_title,
        routine_notify_time=notify_time
    )
    db.add(new_routine)
    db.commit()
    return {"message": "루틴이 등록되었습니다."}

@app.post("/api/users/{recipient_id}/alerts")
async def create_alert(recipient_id: int, req: AlertCreate, db: Session = Depends(get_db)):
    new_alert = models.Alert(
        recipient_id=recipient_id,
        alert_type=req.alert_type
    )
    db.add(new_alert)
    db.commit()
    return {"message": "긴급 알림이 발생했습니다!"}

@app.get("/api/users/{user_id}/dashboard")
async def get_dashboard(user_id: int, db: Session = Depends(get_db)):
    routines = db.query(models.Routine).filter(models.Routine.recipient_id == user_id).all()
    # 최근 알림 10개만 가져오기
    alerts = db.query(models.Alert).filter(models.Alert.recipient_id == user_id).order_by(models.Alert.alert_id.desc()).limit(10).all()
    
    # 프론트엔드가 알아먹는 '루틴' 양식으로 포장
    routine_data = []
    for r in routines:
        routine_data.append({
            "routine_id": r.routine_id,
            "routine_title": r.routine_title,
            # 시간 데이터가 있으면 HH:MM으로 변환
            "routine_notify_time": r.routine_notify_time.strftime("%H:%M") if hasattr(r, 'routine_notify_time') and r.routine_notify_time else "",
            # 제목에 '약'이 들어가면 투약, 아니면 일반 일정으로 분류
            "routine_category": "medication" if "약" in r.routine_title else "schedule",
            "is_done_today": False 
        })

    # 프론트엔드가 찰떡같이 알아먹는 '알림' 양식으로 포장
    alert_data = []
    for a in alerts:
        alert_data.append({
            "alert_id": a.alert_id,
            "title": "긴급 상황 감지!" if a.alert_type == "FALL_DOWN" else "일반 알림",
            "body": f"센서 알림: {a.alert_type}",
            "alert_type": a.alert_type,
            "is_read": False
        })

    # 프론트엔드의 AppState가 원하는 최종 JSON 형태로 합체
    return {
        "summary": {
            "safety_status": "긴급" if any(a.alert_type == "FALL_DOWN" for a in alerts) else "안전",
        },
        "routines": routine_data,
        "notifications": alert_data,
        "unread_notifications": len(alerts)
    }

# 약/일정 목록 불러오기 API
@app.get("/api/users/{recipient_id}/routines")
async def get_routines(recipient_id: int, db: Session = Depends(get_db)):
    routines = db.query(models.Routine).filter(models.Routine.recipient_id == recipient_id).all()
    
    result = []
    for r in routines:
        result.append({
            "routine_id": r.routine_id,
            "routine_title": r.routine_title,
            "routine_notify_time": r.routine_notify_time.strftime("%H:%M") if hasattr(r, 'routine_notify_time') and r.routine_notify_time else "",
            "routine_category": "medication" if "약" in r.routine_title else "schedule",
            "is_done_today": False
        })
    return result

class GuardianLinkRequest(BaseModel):
    guardian_id: int

# 보호자와 대상자 연결하기 API
@app.post("/api/users/{recipient_id}/guardian-links")
async def connect_guardian(recipient_id: int, req: GuardianLinkRequest, db: Session = Depends(get_db)):
    # 이미 연결되어 있는지 확인
    existing = db.query(models.CareRelation).filter(
        models.CareRelation.guardian_id == req.guardian_id,
        models.CareRelation.recipient_id == recipient_id
    ).first()
    
    if existing:
        return {"message": "이미 연결되어 있습니다."}

    # 새로운 관계 묶어주기
    relation = models.CareRelation(
        guardian_id=req.guardian_id,
        recipient_id=recipient_id
    )
    db.add(relation)
    db.commit()
    return {"message": "보호자가 성공적으로 연결되었습니다!"}

# ==========================================
# 보호자용: 내 피보호자(어르신) 목록 불러오기
# ==========================================
@app.get("/api/guardians/{guardian_id}/recipients")
async def get_guardian_recipients(guardian_id: int, db: Session = Depends(get_db)):
    # 보호자 ID로 묶여있는 연결고리 찾기
    relations = db.query(models.CareRelation).filter(models.CareRelation.guardian_id == guardian_id).all()
    
    result = []
    for rel in relations:
        user = db.query(models.User).filter(models.User.user_id == rel.recipient_id).first()
        if user:
            result.append({
                "relation_id": rel.relation_id,
                # 플러터가 어떤 변수명으로 아이디를 찾을지 몰라 3종 세트 다 넣음
                "id": user.user_id,
                "user_id": user.user_id,
                "recipient_id": user.user_id,
                
                "name": user.user_name,
                "phone": user.user_phone,
                "status": "안전",
                "type": "어르신",
                "lastUpdate": "방금 전",
                "heartRate": 72,
                "steps": 2340,
                "location": "서울 강남구",
                "hasAlert": False
            })
    return result

# ==========================================
# 피보호자용: 내 보호자 목록 불러오기 (진짜 버전!)
# ==========================================
@app.get("/api/users/{user_id}/guardian-links")
async def get_guardian_links(user_id: int, db: Session = Depends(get_db)):
    # 피보호자(user_id)와 묶여있는 연결고리(CareRelation) 찾기
    relations = db.query(models.CareRelation).filter(models.CareRelation.recipient_id == user_id).all()
    
    result = []
    for rel in relations:
        # 연결고리에 적힌 보호자의 상세 정보 가져오기
        guardian = db.query(models.User).filter(models.User.user_id == rel.guardian_id).first()
        if guardian:
            result.append({
                "relation_id": rel.relation_id,
                "guardian_id": guardian.user_id,
                # 데이터 포장
                "guardian": {
                    "user_name": guardian.user_name,
                    "login_id": guardian.login_id,
                    "user_phone": guardian.user_phone
                },
                "relation_name": "보호자",
                "share_location": True,
                "share_health": True,
                "share_activity": False
            })
    return result

# ==========================================
#  메시지 전송 (알림 테이블에 몰래 숨겨서 저장!)
# ==========================================
class MessageRequest(BaseModel):
    sender_id: int
    receiver_id: int
    body: str

@app.post("/api/messages")
async def send_message(req: MessageRequest, db: Session = Depends(get_db)):
    # 프론트엔드가 정확히 누구한테 보내고 있는지 터미널에 감시 카메라
    print(f"🔥 [디버그 스파이] 보낸사람: {req.sender_id} -> 받는사람: {req.receiver_id} | 내용: {req.body}")
    
    msg_content = f"MSG|{req.body}"
    new_alert = models.Alert(
        recipient_id=req.receiver_id, 
        alert_type=msg_content[:50]   
    )
    db.add(new_alert)
    db.commit()
    return {"message": "메시지가 알림으로 전송되었습니다!"}

# ==========================================
#  알림 목록 불러오기 (숨겨둔 메시지 예쁘게 포장 뜯기)
# ==========================================
@app.get("/api/users/{user_id}/notifications")
async def get_notifications(user_id: int, db: Session = Depends(get_db)):
    alerts = db.query(models.Alert).filter(models.Alert.recipient_id == user_id).order_by(models.Alert.alert_id.desc()).all()
    
    result = []
    for a in alerts:
        # MSG| 로 시작하면 메시지 알림, 아니면 일반 알림!
        if a.alert_type.startswith("MSG|"):
            title = "새로운 메시지 "
            body = a.alert_type.split("|", 1)[1]
            ui_type = "MESSAGE"
        else:
            title = "시스템 알림"
            body = f"센서 감지: {a.alert_type}"
            ui_type = "SYSTEM"
            
        result.append({
            "alert_id": a.alert_id,
            "title": title,
            "body": body,
            "type": ui_type, # 프론트엔드가 아이콘을 결정하는 핵심 키!
            "alert_created_at": a.alert_created_at.isoformat(),
            "is_read": a.is_read
        })
    return result

# ==========================================
#  메인 대시보드
# ==========================================
@app.get("/api/users/{user_id}/dashboard")
async def get_dashboard(user_id: int, db: Session = Depends(get_db)):
    routines = db.query(models.Routine).filter(models.Routine.recipient_id == user_id).all()
    alerts = db.query(models.Alert).filter(models.Alert.recipient_id == user_id).order_by(models.Alert.alert_id.desc()).limit(10).all()
    
    routine_data = []
    for r in routines:
        routine_data.append({
            "routine_id": r.routine_id,
            "routine_title": r.routine_title,
            "routine_notify_time": r.routine_notify_time.strftime("%H:%M") if hasattr(r, 'routine_notify_time') and r.routine_notify_time else "",
            "routine_category": "medication" if "약" in r.routine_title else "schedule",
            "is_done_today": False 
        })

    alert_data = []
    for a in alerts:
        if a.alert_type.startswith("MSG|"):
            title = "새로운 메시지"
            body = a.alert_type.split("|", 1)[1]
            ui_type = "MESSAGE"
        else:
            title = "긴급 상황 감지!" if a.alert_type == "FALL_DOWN" else "일반 알림"
            body = f"센서 알림: {a.alert_type}"
            ui_type = a.alert_type

        alert_data.append({
            "alert_id": a.alert_id,
            "title": title,
            "body": body,
            "type": ui_type,
            "is_read": False
        })

    return {
        "summary": {
            "safety_status": "긴급" if any(a.alert_type == "FALL_DOWN" for a in alerts) else "안전",
        },
        "routines": routine_data,
        "notifications": alert_data,
        "unread_notifications": len(alerts)
    }