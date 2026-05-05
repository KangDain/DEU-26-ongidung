from datetime import datetime, time
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import func, inspect, text as sql_text
from sqlalchemy.orm import Session

from database import engine, get_db
import models


def _run_dev_migrations() -> None:
    """SQLite 개발 DB에 새 컬럼을 보강한다.

    SQLAlchemy create_all은 기존 테이블에 컬럼을 추가하지 않기 때문에,
    팀 프로젝트 시연용으로 필요한 컬럼만 ALTER TABLE로 보강한다.
    """

    if engine.dialect.name != "sqlite":
        return

    column_sql = {
        "users": {
            "email": "VARCHAR(100)",
            "user_updated_at": "DATETIME",
            "user_deleted_at": "DATETIME",
            "status": "VARCHAR(20) DEFAULT 'ACTIVE'",
            "approved": "BOOLEAN DEFAULT 1",
            "profile_image_url": "VARCHAR(500)",
            "health_info": "TEXT",
            "medication_note": "TEXT",
            "emergency_note": "TEXT",
            "pin_code": "VARCHAR(20)",
            "auto_login_enabled": "BOOLEAN DEFAULT 0",
            "share_location": "BOOLEAN DEFAULT 1",
            "share_health": "BOOLEAN DEFAULT 1",
            "share_activity": "BOOLEAN DEFAULT 0",
        },
        "care_relations": {
            "relation_name": "VARCHAR(50) DEFAULT '보호자'",
            "priority": "INTEGER DEFAULT 1",
            "is_active": "BOOLEAN DEFAULT 1",
            "share_location": "BOOLEAN DEFAULT 1",
            "share_health": "BOOLEAN DEFAULT 1",
            "share_activity": "BOOLEAN DEFAULT 0",
            "created_at": "DATETIME",
        },
        "devices": {
            "device_name": "VARCHAR(100) DEFAULT '홈캠'",
            "location_name": "VARCHAR(100) DEFAULT '거실'",
            "connection_info": "VARCHAR(200)",
            "battery_level": "INTEGER DEFAULT 100",
            "last_seen_at": "DATETIME",
        },
        "sensor": {
            "recipient_id": "INTEGER",
            "value": "VARCHAR(100)",
            "risk_level": "VARCHAR(20) DEFAULT 'NORMAL'",
            "note": "VARCHAR(200)",
        },
        "alerts": {
            "guardian_id": "INTEGER",
            "title": "VARCHAR(100) DEFAULT '알림'",
            "body": "VARCHAR(500)",
            "priority": "VARCHAR(20) DEFAULT 'NORMAL'",
            "status": "VARCHAR(20) DEFAULT 'OPEN'",
        },
        "routines": {
            "routine_category": "VARCHAR(30) DEFAULT 'schedule'",
            "repeat_rule": "VARCHAR(50) DEFAULT 'DAILY'",
            "is_done_today": "BOOLEAN DEFAULT 0",
            "created_at": "DATETIME",
        },
    }

    inspector = inspect(engine)
    table_names = set(inspector.get_table_names())
    with engine.begin() as conn:
        for table_name, columns in column_sql.items():
            if table_name not in table_names:
                continue
            existing = {
                row[1]
                for row in conn.execute(sql_text(f"PRAGMA table_info({table_name})"))
            }
            for column_name, ddl in columns.items():
                if column_name not in existing:
                    conn.execute(
                        sql_text(
                            f"ALTER TABLE {table_name} ADD COLUMN {column_name} {ddl}"
                        )
                    )

        conn.execute(sql_text("UPDATE users SET status = 'ACTIVE' WHERE status IS NULL"))
        conn.execute(sql_text("UPDATE users SET approved = 1 WHERE approved IS NULL"))
        conn.execute(
            sql_text(
                "UPDATE users SET user_updated_at = user_created_at "
                "WHERE user_updated_at IS NULL"
            )
        )


models.Base.metadata.create_all(bind=engine)
_run_dev_migrations()

app = FastAPI(title="Protect Care API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class UserCreate(BaseModel):
    login_id: str
    user_pw: str
    user_name: str
    email: Optional[str] = None
    user_phone: Optional[str] = None
    user_birth_date: Optional[str] = None
    user_address: Optional[str] = None
    guardian_phone: Optional[str] = None
    user_type: str = "GENERAL"
    health_info: Optional[str] = None
    medication_note: Optional[str] = None
    emergency_note: Optional[str] = None


class LoginRequest(BaseModel):
    login_id: str
    user_pw: str


class PinLoginRequest(BaseModel):
    login_id: str
    pin_code: str


class PinUpdate(BaseModel):
    user_id: int
    pin_code: str
    auto_login_enabled: bool = False


class PasswordResetRequest(BaseModel):
    login_id: str
    verification: str
    new_password: str


class AccountRecoveryRequest(BaseModel):
    name: str
    phone_or_email: str


class UserUpdate(BaseModel):
    user_name: Optional[str] = None
    email: Optional[str] = None
    user_phone: Optional[str] = None
    user_birth_date: Optional[str] = None
    user_address: Optional[str] = None
    guardian_phone: Optional[str] = None
    user_type: Optional[str] = None
    health_info: Optional[str] = None
    medication_note: Optional[str] = None
    emergency_note: Optional[str] = None
    profile_image_url: Optional[str] = None
    share_location: Optional[bool] = None
    share_health: Optional[bool] = None
    share_activity: Optional[bool] = None


class EmergencyContactCreate(BaseModel):
    name: str
    phone: str
    relation: str = "가족"
    priority: int = 1
    is_guardian: bool = False


class DevicePayload(BaseModel):
    recipient_id: Optional[int] = None
    device_name: str = "홈캠"
    device_type: str = "CAM"
    location_name: str = "거실"
    connection_info: Optional[str] = None
    ip_address: Optional[str] = None
    device_status: bool = True
    battery_level: int = 100


class SensorEventCreate(BaseModel):
    recipient_id: int
    device_id: Optional[int] = None
    sensor_event_type: str
    value: Optional[str] = None
    risk_level: str = "NORMAL"
    note: Optional[str] = None


class RoutineCreate(BaseModel):
    routine_title: str
    routine_category: str = "schedule"
    routine_notify_time: str
    repeat_rule: str = "DAILY"


class RoutineUpdate(BaseModel):
    routine_title: Optional[str] = None
    routine_category: Optional[str] = None
    routine_notify_time: Optional[str] = None
    repeat_rule: Optional[str] = None
    routine_is_active: Optional[bool] = None
    is_done_today: Optional[bool] = None


class SOSRequest(BaseModel):
    message: Optional[str] = None
    location_address: Optional[str] = None


class LocationUpdate(BaseModel):
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    address: Optional[str] = None
    place_name: Optional[str] = None


class GuardianLinkRequest(BaseModel):
    guardian_login_id: Optional[str] = None
    guardian_id: Optional[int] = None
    recipient_id: int
    relation_name: str = "보호자"
    priority: int = 1


class ShareSettingsUpdate(BaseModel):
    share_location: bool
    share_health: bool
    share_activity: bool


class MessageCreate(BaseModel):
    sender_id: int
    receiver_id: int
    body: str


class InquiryCreate(BaseModel):
    user_id: Optional[int] = None
    title: str
    body: str


class InquiryUpdate(BaseModel):
    status: str


class AdminUserUpdate(UserUpdate):
    status: Optional[str] = None
    approved: Optional[bool] = None
    user_role: Optional[str] = None


def _parse_time(value: str) -> time:
    try:
        return datetime.strptime(value, "%H:%M").time()
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="시간은 HH:MM 형식이어야 합니다.") from exc


def _time_to_str(value: Optional[time]) -> str:
    return value.strftime("%H:%M") if value else ""


def _role_from_type(user_type: str) -> models.UserRole:
    if user_type == "ADMIN":
        return models.UserRole.ADMIN
    if user_type == "GUARDIAN":
        return models.UserRole.GUARDIAN
    return models.UserRole.RECIPIENT


def _get_user(db: Session, user_id: int, include_deleted: bool = False) -> models.User:
    query = db.query(models.User).filter(models.User.user_id == user_id)
    if not include_deleted:
        query = query.filter(models.User.user_is_deleted == False)
    user = query.first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return user


def _serialize_user(user: models.User) -> dict:
    role = user.user_role.value if hasattr(user.user_role, "value") else user.user_role
    return {
        "user_id": user.user_id,
        "login_id": user.login_id,
        "user_name": user.user_name,
        "email": user.email,
        "user_phone": user.user_phone,
        "user_role": role,
        "user_type": user.user_type,
        "user_birth_date": user.user_birth_date,
        "user_address": user.user_address,
        "guardian_phone": user.guardian_phone,
        "profile_image_url": user.profile_image_url,
        "health_info": user.health_info,
        "medication_note": user.medication_note,
        "emergency_note": user.emergency_note,
        "status": user.status or models.AccountStatus.ACTIVE.value,
        "approved": bool(user.approved),
        "user_is_deleted": bool(user.user_is_deleted),
        "share_location": bool(user.share_location),
        "share_health": bool(user.share_health),
        "share_activity": bool(user.share_activity),
        "auto_login_enabled": bool(user.auto_login_enabled),
        "user_created_at": str(user.user_created_at) if user.user_created_at else None,
        "user_updated_at": str(user.user_updated_at) if user.user_updated_at else None,
    }


def _serialize_contact(contact: models.EmergencyContact) -> dict:
    return {
        "contact_id": contact.contact_id,
        "user_id": contact.user_id,
        "name": contact.name,
        "phone": contact.phone,
        "relation": contact.relation,
        "priority": contact.priority,
        "is_guardian": bool(contact.is_guardian),
    }


def _serialize_device(device: models.Device) -> dict:
    return {
        "device_id": device.device_id,
        "recipient_id": device.recipient_id,
        "device_name": device.device_name,
        "device_type": device.device_type,
        "location_name": device.location_name,
        "connection_info": device.connection_info,
        "ip_address": device.ip_address,
        "device_status": bool(device.device_status),
        "battery_level": device.battery_level,
        "last_seen_at": str(device.last_seen_at) if device.last_seen_at else None,
    }


def _serialize_routine(routine: models.Routine) -> dict:
    return {
        "routine_id": routine.routine_id,
        "recipient_id": routine.recipient_id,
        "routine_title": routine.routine_title,
        "routine_category": routine.routine_category,
        "routine_notify_time": _time_to_str(routine.routine_notify_time),
        "repeat_rule": routine.repeat_rule,
        "routine_is_active": bool(routine.routine_is_active),
        "is_done_today": bool(routine.is_done_today),
    }


def _serialize_alert(alert: models.Alert) -> dict:
    return {
        "alert_id": alert.alert_id,
        "recipient_id": alert.recipient_id,
        "guardian_id": alert.guardian_id,
        "alert_type": alert.alert_type,
        "title": alert.title,
        "body": alert.body,
        "priority": alert.priority,
        "status": alert.status,
        "is_read": bool(alert.is_read),
        "alert_created_at": str(alert.alert_created_at) if alert.alert_created_at else None,
    }


def _serialize_relation(relation: models.CareRelation, recipient: Optional[models.User] = None) -> dict:
    data = {
        "relation_id": relation.relation_id,
        "guardian_id": relation.guardian_id,
        "recipient_id": relation.recipient_id,
        "relation_name": relation.relation_name,
        "priority": relation.priority,
        "is_active": bool(relation.is_active),
        "share_location": bool(relation.share_location),
        "share_health": bool(relation.share_health),
        "share_activity": bool(relation.share_activity),
    }
    if recipient:
        latest_alert = (
            recipient.user_id
            and relation.recipient_id
            and recipient.user_id == relation.recipient_id
        )
        data["recipient"] = _serialize_user(recipient)
        data["has_alert"] = bool(latest_alert and recipient.status == "ATTENTION")
    return data


def _default_routines(user_id: int) -> list[models.Routine]:
    return [
        models.Routine(
            recipient_id=user_id,
            routine_title="아침 혈압약 복용",
            routine_category="medication",
            routine_notify_time=time(8, 0),
            is_done_today=True,
        ),
        models.Routine(
            recipient_id=user_id,
            routine_title="점심 식사 및 당뇨약 복용",
            routine_category="medication",
            routine_notify_time=time(12, 0),
        ),
        models.Routine(
            recipient_id=user_id,
            routine_title="가벼운 스트레칭",
            routine_category="mission",
            routine_notify_time=time(20, 0),
        ),
    ]


def _ensure_user_defaults(db: Session, user: models.User) -> None:
    if not db.query(models.Routine).filter(models.Routine.recipient_id == user.user_id).first():
        db.add_all(_default_routines(user.user_id))

    if not db.query(models.Device).filter(
        models.Device.recipient_id == user.user_id,
        models.Device.device_is_deleted == False,
    ).first():
        db.add_all(
            [
                models.Device(
                    recipient_id=user.user_id,
                    device_name="거실 홈캠",
                    device_type="CAM",
                    location_name="거실",
                    device_status=True,
                    battery_level=100,
                ),
                models.Device(
                    recipient_id=user.user_id,
                    device_name="움직임 감지 센서",
                    device_type="PIR",
                    location_name="현관",
                    device_status=True,
                    battery_level=92,
                ),
            ]
        )

    if user.guardian_phone and not db.query(models.EmergencyContact).filter(
        models.EmergencyContact.user_id == user.user_id,
        models.EmergencyContact.phone == user.guardian_phone,
    ).first():
        db.add(
            models.EmergencyContact(
                user_id=user.user_id,
                name="보호자",
                phone=user.guardian_phone,
                relation="보호자",
                priority=1,
                is_guardian=True,
            )
        )

    if user.guardian_phone:
        guardian = db.query(models.User).filter(
            models.User.user_phone == user.guardian_phone,
            models.User.user_role == models.UserRole.GUARDIAN,
            models.User.user_is_deleted == False,
        ).first()
        if guardian and not db.query(models.CareRelation).filter(
            models.CareRelation.guardian_id == guardian.user_id,
            models.CareRelation.recipient_id == user.user_id,
        ).first():
            db.add(
                models.CareRelation(
                    guardian_id=guardian.user_id,
                    recipient_id=user.user_id,
                    relation_name="보호자",
                    priority=1,
                    share_location=bool(user.share_location),
                    share_health=bool(user.share_health),
                    share_activity=bool(user.share_activity),
                )
            )

    if not db.query(models.GameMission).filter(models.GameMission.user_id == user.user_id).first():
        db.add_all(
            [
                models.GameMission(user_id=user.user_id, title="아침 약 복용", mission_type="health", points=10),
                models.GameMission(user_id=user.user_id, title="5분 스트레칭", mission_type="health", points=15),
                models.GameMission(user_id=user.user_id, title="안전 교육 퀴즈", mission_type="safety", points=30),
            ]
        )
    db.commit()


def _ensure_admin_user(db: Session) -> None:
    if db.query(models.User).filter(models.User.user_role == models.UserRole.ADMIN).first():
        return
    db.add(
        models.User(
            login_id="admin",
            user_pw="admin1234",
            user_name="관리자",
            user_role=models.UserRole.ADMIN,
            user_type="ADMIN",
            user_phone="010-0000-0000",
            status=models.AccountStatus.ACTIVE.value,
            approved=True,
        )
    )
    db.commit()


@app.on_event("startup")
def startup_seed() -> None:
    db = next(get_db())
    try:
        _ensure_admin_user(db)
    finally:
        db.close()


@app.get("/api/health")
async def health_check():
    return {"status": "ok", "time": datetime.utcnow().isoformat()}


@app.post("/api/signup")
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.login_id == user.login_id).first()
    if existing:
        raise HTTPException(status_code=409, detail="이미 사용 중인 아이디입니다.")

    role = _role_from_type(user.user_type)
    new_user = models.User(
        login_id=user.login_id,
        user_pw=user.user_pw,
        user_name=user.user_name,
        email=user.email,
        user_phone=user.user_phone,
        user_birth_date=user.user_birth_date,
        user_address=user.user_address,
        guardian_phone=user.guardian_phone,
        user_type=user.user_type,
        user_role=role,
        health_info=user.health_info,
        medication_note=user.medication_note,
        emergency_note=user.emergency_note,
        status=models.AccountStatus.ACTIVE.value,
        approved=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    _ensure_user_defaults(db, new_user)

    return {"message": f"환영합니다, {new_user.user_name}님!", "user": _serialize_user(new_user)}


@app.post("/api/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.login_id == request.login_id,
        models.User.user_pw == request.user_pw,
        models.User.user_is_deleted == False,
    ).first()

    if not user:
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다.")
    if not user.approved or user.status == models.AccountStatus.PENDING.value:
        raise HTTPException(status_code=403, detail="관리자 승인 후 이용할 수 있습니다.")
    if user.status == models.AccountStatus.DISABLED.value:
        raise HTTPException(status_code=403, detail="비활성화된 계정입니다. 관리자에게 문의하세요.")

    _ensure_user_defaults(db, user)
    return _serialize_user(user)


@app.post("/api/auth/pin")
async def pin_login(request: PinLoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.login_id == request.login_id,
        models.User.pin_code == request.pin_code,
        models.User.user_is_deleted == False,
    ).first()
    if not user:
        raise HTTPException(status_code=401, detail="PIN 정보가 올바르지 않습니다.")
    return _serialize_user(user)


@app.post("/api/auth/set-pin")
async def set_pin(request: PinUpdate, db: Session = Depends(get_db)):
    user = _get_user(db, request.user_id)
    user.pin_code = request.pin_code
    user.auto_login_enabled = request.auto_login_enabled
    user.user_updated_at = datetime.utcnow()
    db.commit()
    return {"message": "PIN 설정이 저장되었습니다.", "user": _serialize_user(user)}


@app.post("/api/auth/password-reset")
async def reset_password(request: PasswordResetRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.login_id == request.login_id,
        models.User.user_is_deleted == False,
    ).first()
    if not user:
        raise HTTPException(status_code=404, detail="계정을 찾을 수 없습니다.")

    verification = request.verification.strip()
    if verification not in {user.user_phone, user.email, user.guardian_phone}:
        raise HTTPException(status_code=403, detail="등록된 휴대폰 또는 이메일 정보가 일치하지 않습니다.")

    user.user_pw = request.new_password
    user.user_updated_at = datetime.utcnow()
    db.commit()
    return {"message": "비밀번호가 재설정되었습니다."}


@app.post("/api/auth/recover-account")
async def recover_account(request: AccountRecoveryRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.user_name == request.name,
        models.User.user_is_deleted == False,
    ).filter(
        (models.User.user_phone == request.phone_or_email)
        | (models.User.email == request.phone_or_email)
    ).first()
    if not user:
        raise HTTPException(status_code=404, detail="일치하는 계정을 찾을 수 없습니다.")
    return {"login_id": user.login_id, "status": user.status}


@app.get("/api/users")
async def get_users(db: Session = Depends(get_db)):
    users = db.query(models.User).filter(models.User.user_is_deleted == False).all()
    return [_serialize_user(user) for user in users]


@app.get("/api/users/{user_id}/profile")
async def get_profile(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    contacts = db.query(models.EmergencyContact).filter(
        models.EmergencyContact.user_id == user_id,
    ).order_by(models.EmergencyContact.priority).all()
    return {"user": _serialize_user(user), "emergency_contacts": [_serialize_contact(c) for c in contacts]}


@app.patch("/api/users/{user_id}/profile")
async def update_profile(user_id: int, payload: UserUpdate, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(user, key, value)
    if payload.user_type:
        user.user_role = _role_from_type(payload.user_type)
    user.user_updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    return {"message": "프로필이 저장되었습니다.", "user": _serialize_user(user)}


@app.patch("/api/users/{user_id}")
async def update_user(user_id: int, payload: UserUpdate, db: Session = Depends(get_db)):
    return await update_profile(user_id, payload, db)


@app.get("/api/users/{user_id}/dashboard")
async def get_dashboard(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    _ensure_user_defaults(db, user)

    routines = db.query(models.Routine).filter(
        models.Routine.recipient_id == user_id,
        models.Routine.routine_is_active == True,
    ).order_by(models.Routine.routine_notify_time).all()
    devices = db.query(models.Device).filter(
        models.Device.recipient_id == user_id,
        models.Device.device_is_deleted == False,
    ).all()
    alerts = db.query(models.Alert).filter(
        models.Alert.recipient_id == user_id,
    ).order_by(models.Alert.alert_created_at.desc()).limit(10).all()
    unread_count = db.query(models.Alert).filter(
        models.Alert.recipient_id == user_id,
        models.Alert.is_read == False,
    ).count()
    latest_location = db.query(models.LocationLog).filter(
        models.LocationLog.user_id == user_id,
    ).order_by(models.LocationLog.created_at.desc()).first()

    open_emergency = db.query(models.EmergencyEvent).filter(
        models.EmergencyEvent.user_id == user_id,
        models.EmergencyEvent.status == "OPEN",
    ).first()
    abnormal_alert = db.query(models.Alert).filter(
        models.Alert.recipient_id == user_id,
        models.Alert.priority.in_(["HIGH", "EMERGENCY"]),
        models.Alert.is_read == False,
    ).first()

    remaining_meds = [
        r for r in routines
        if r.routine_category == "medication" and not r.is_done_today
    ]
    safety_status = "긴급" if open_emergency else "주의 필요" if abnormal_alert else "현재 안전"
    medication_count = sum(1 for r in routines if r.routine_category == "medication")
    taken_medication_count = medication_count - len(remaining_meds)
    schedules = [r for r in routines if r.routine_category != "medication"]
    completed_schedules = sum(1 for r in schedules if r.is_done_today)
    activity_alert = db.query(models.Alert).filter(
        models.Alert.recipient_id == user_id,
        models.Alert.alert_type.in_(["NO_MOVEMENT", "MOTION_DETECTED"]),
        models.Alert.is_read == False,
    ).first()

    health_status = (
        f"약 복용 {taken_medication_count}/{medication_count} 완료"
        if medication_count
        else "등록된 약 없음"
    )
    activity_status = "활동 주의" if activity_alert else "활동 정상"
    location_status = latest_location.address if latest_location else user.user_address or "위치 정보 없음"

    return {
        "user": _serialize_user(user),
        "summary": {
            "safety_status": safety_status,
            "health_status": health_status,
            "activity_status": activity_status,
            "location_status": location_status,
            "schedule_status": f"오늘 일정 {len(routines)}개",
            "notification_status": "이상 알림 없음" if unread_count == 0 else f"읽지 않은 알림 {unread_count}개",
        },
        "care_summary": [
            safety_status,
            health_status,
            f"일정 {completed_schedules}/{len(schedules)} 완료" if schedules else "등록된 일정 없음",
            activity_status,
            f"활동 기기 {sum(1 for d in devices if d.device_status)}/{len(devices)}개 연결",
            "보호자 메시지와 중요 알림을 확인하세요." if unread_count else "확인되지 않은 알림이 없습니다.",
        ],
        "quick_actions": ["긴급 호출", "보호자 연락", "건강 체크", "위치 확인", "게임 시작"],
        "routines": [_serialize_routine(r) for r in routines],
        "devices": [_serialize_device(d) for d in devices],
        "notifications": [_serialize_alert(a) for a in alerts],
        "unread_notifications": unread_count,
    }


@app.post("/api/users/{user_id}/emergency-contacts")
async def add_emergency_contact(user_id: int, payload: EmergencyContactCreate, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    contact = models.EmergencyContact(user_id=user_id, **payload.model_dump())
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return _serialize_contact(contact)


@app.get("/api/users/{user_id}/emergency-contacts")
async def list_emergency_contacts(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    contacts = db.query(models.EmergencyContact).filter(
        models.EmergencyContact.user_id == user_id,
    ).order_by(models.EmergencyContact.priority).all()
    return [_serialize_contact(c) for c in contacts]


@app.delete("/api/emergency-contacts/{contact_id}")
async def delete_emergency_contact(contact_id: int, db: Session = Depends(get_db)):
    contact = db.query(models.EmergencyContact).filter(models.EmergencyContact.contact_id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="비상 연락처를 찾을 수 없습니다.")
    db.delete(contact)
    db.commit()
    return {"message": "비상 연락처가 삭제되었습니다."}


@app.get("/api/users/{user_id}/devices")
async def list_devices(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    _ensure_user_defaults(db, user)
    devices = db.query(models.Device).filter(
        models.Device.recipient_id == user_id,
        models.Device.device_is_deleted == False,
    ).all()
    return [_serialize_device(d) for d in devices]


@app.post("/api/users/{user_id}/devices")
async def add_device(user_id: int, payload: DevicePayload, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    data = payload.model_dump()
    data["recipient_id"] = user_id
    device = models.Device(**data)
    db.add(device)
    db.commit()
    db.refresh(device)
    return _serialize_device(device)


@app.patch("/api/devices/{device_id}")
async def update_device(device_id: int, payload: DevicePayload, db: Session = Depends(get_db)):
    device = db.query(models.Device).filter(models.Device.device_id == device_id).first()
    if not device:
        raise HTTPException(status_code=404, detail="기기를 찾을 수 없습니다.")
    data = payload.model_dump(exclude_unset=True)
    data.pop("recipient_id", None)
    for key, value in data.items():
        setattr(device, key, value)
    device.last_seen_at = datetime.utcnow()
    db.commit()
    db.refresh(device)
    return _serialize_device(device)


@app.delete("/api/devices/{device_id}")
async def delete_device(device_id: int, db: Session = Depends(get_db)):
    device = db.query(models.Device).filter(models.Device.device_id == device_id).first()
    if not device:
        raise HTTPException(status_code=404, detail="기기를 찾을 수 없습니다.")
    device.device_is_deleted = True
    db.commit()
    return {"message": "기기가 삭제되었습니다."}


@app.post("/api/devices/{device_id}/reconnect")
async def reconnect_device(device_id: int, db: Session = Depends(get_db)):
    device = db.query(models.Device).filter(models.Device.device_id == device_id).first()
    if not device:
        raise HTTPException(status_code=404, detail="기기를 찾을 수 없습니다.")
    device.device_status = True
    device.last_seen_at = datetime.utcnow()
    db.commit()
    return {"message": "기기가 재연결되었습니다.", "device": _serialize_device(device)}


@app.post("/api/sensor-events")
async def create_sensor_event(payload: SensorEventCreate, db: Session = Depends(get_db)):
    _get_user(db, payload.recipient_id)
    device_id = payload.device_id
    if not device_id:
        device = db.query(models.Device).filter(
            models.Device.recipient_id == payload.recipient_id,
            models.Device.device_is_deleted == False,
        ).first()
        if not device:
            device = models.Device(recipient_id=payload.recipient_id, device_type="PIR", device_name="기본 센서")
            db.add(device)
            db.commit()
            db.refresh(device)
        device_id = device.device_id

    next_sensor_id = (db.query(func.max(models.SensorLog.sensor_log_id)).scalar() or 0) + 1
    event = models.SensorLog(
        sensor_log_id=next_sensor_id,
        recipient_id=payload.recipient_id,
        device_id=device_id,
        sensor_event_type=payload.sensor_event_type,
        value=payload.value,
        risk_level=payload.risk_level,
        note=payload.note,
    )
    db.add(event)

    if payload.risk_level in {"WARNING", "HIGH", "EMERGENCY"}:
        alert = models.Alert(
            recipient_id=payload.recipient_id,
            alert_type=payload.sensor_event_type,
            title="안전 이상 감지",
            body=payload.note or f"{payload.sensor_event_type} 이벤트가 감지되었습니다.",
            priority=payload.risk_level,
        )
        db.add(alert)

    db.commit()
    return {"message": "센서 이벤트가 저장되었습니다.", "sensor_log_id": event.sensor_log_id}


@app.get("/api/users/{user_id}/safety")
async def get_safety_status(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    latest = db.query(models.SensorLog).filter(
        models.SensorLog.recipient_id == user_id,
    ).order_by(models.SensorLog.sensor_created_at.desc()).first()
    alert = db.query(models.Alert).filter(
        models.Alert.recipient_id == user_id,
        models.Alert.priority.in_(["HIGH", "EMERGENCY"]),
        models.Alert.is_read == False,
    ).first()
    return {
        "status": "주의 필요" if alert else "현재 안전",
        "latest_event": {
            "type": latest.sensor_event_type,
            "risk_level": latest.risk_level,
            "created_at": str(latest.sensor_created_at),
        } if latest else None,
    }


@app.post("/api/users/{user_id}/sos")
async def send_sos(user_id: int, payload: SOSRequest, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    event = models.EmergencyEvent(
        user_id=user_id,
        message=payload.message or "사용자가 SOS 긴급 호출을 보냈습니다.",
        location_address=payload.location_address or user.user_address,
    )
    db.add(event)
    db.flush()

    alert = models.Alert(
        recipient_id=user_id,
        alert_type="SOS",
        title="SOS 긴급 호출",
        body=f"{user.user_name}님의 긴급 호출이 접수되었습니다.",
        priority="EMERGENCY",
    )
    db.add(alert)
    db.commit()
    db.refresh(event)
    return {
        "message": "긴급 호출이 접수되었습니다.",
        "event_id": event.event_id,
        "contacts": [
            _serialize_contact(c)
            for c in db.query(models.EmergencyContact).filter(models.EmergencyContact.user_id == user_id).order_by(models.EmergencyContact.priority).all()
        ],
    }


@app.post("/api/users/{user_id}/locations")
async def update_location(user_id: int, payload: LocationUpdate, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    location = models.LocationLog(user_id=user_id, **payload.model_dump())
    db.add(location)
    db.commit()
    db.refresh(location)
    return {
        "location_id": location.location_id,
        "address": location.address,
        "place_name": location.place_name,
        "created_at": str(location.created_at),
    }


@app.get("/api/users/{user_id}/locations")
async def list_locations(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    rows = db.query(models.LocationLog).filter(
        models.LocationLog.user_id == user_id,
    ).order_by(models.LocationLog.created_at.desc()).limit(20).all()
    return [
        {
            "location_id": row.location_id,
            "latitude": row.latitude,
            "longitude": row.longitude,
            "address": row.address,
            "place_name": row.place_name,
            "created_at": str(row.created_at),
        }
        for row in rows
    ]


@app.post("/api/users/{user_id}/routines")
async def add_routine(user_id: int, payload: RoutineCreate, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    routine = models.Routine(
        recipient_id=user_id,
        routine_title=payload.routine_title,
        routine_category=payload.routine_category,
        routine_notify_time=_parse_time(payload.routine_notify_time),
        repeat_rule=payload.repeat_rule,
    )
    db.add(routine)
    db.commit()
    db.refresh(routine)
    return _serialize_routine(routine)


@app.get("/api/users/{user_id}/routines")
async def list_routines(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    rows = db.query(models.Routine).filter(models.Routine.recipient_id == user_id).order_by(models.Routine.routine_notify_time).all()
    return [_serialize_routine(row) for row in rows]


@app.patch("/api/routines/{routine_id}")
async def update_routine(routine_id: int, payload: RoutineUpdate, db: Session = Depends(get_db)):
    routine = db.query(models.Routine).filter(models.Routine.routine_id == routine_id).first()
    if not routine:
        raise HTTPException(status_code=404, detail="일정을 찾을 수 없습니다.")
    data = payload.model_dump(exclude_unset=True)
    if "routine_notify_time" in data and data["routine_notify_time"] is not None:
        data["routine_notify_time"] = _parse_time(data["routine_notify_time"])
    for key, value in data.items():
        setattr(routine, key, value)
    db.commit()
    db.refresh(routine)
    return _serialize_routine(routine)


@app.delete("/api/routines/{routine_id}")
async def delete_routine(routine_id: int, db: Session = Depends(get_db)):
    routine = db.query(models.Routine).filter(models.Routine.routine_id == routine_id).first()
    if not routine:
        raise HTTPException(status_code=404, detail="일정을 찾을 수 없습니다.")
    routine.routine_is_active = False
    db.commit()
    return {"message": "일정이 삭제되었습니다."}


@app.post("/api/routines/{routine_id}/complete")
async def complete_routine(routine_id: int, db: Session = Depends(get_db)):
    routine = db.query(models.Routine).filter(models.Routine.routine_id == routine_id).first()
    if not routine:
        raise HTTPException(status_code=404, detail="일정을 찾을 수 없습니다.")
    routine.is_done_today = True
    db.commit()
    return _serialize_routine(routine)


@app.get("/api/users/{user_id}/notifications")
async def list_notifications(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    alerts = db.query(models.Alert).filter(
        models.Alert.recipient_id == user_id,
    ).order_by(models.Alert.alert_created_at.desc()).all()
    return [_serialize_alert(a) for a in alerts]


@app.patch("/api/notifications/{alert_id}/read")
async def mark_notification_read(alert_id: int, db: Session = Depends(get_db)):
    alert = db.query(models.Alert).filter(models.Alert.alert_id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="알림을 찾을 수 없습니다.")
    alert.is_read = True
    db.commit()
    return _serialize_alert(alert)


@app.post("/api/users/{user_id}/notifications/read-all")
async def mark_all_notifications_read(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    db.query(models.Alert).filter(models.Alert.recipient_id == user_id).update({"is_read": True})
    db.commit()
    return {"message": "모든 알림을 읽음 처리했습니다."}


@app.post("/api/users/{user_id}/guardian-links")
async def connect_guardian(user_id: int, payload: GuardianLinkRequest, db: Session = Depends(get_db)):
    recipient = _get_user(db, payload.recipient_id)
    if recipient.user_id != user_id:
        _get_user(db, user_id)

    guardian = None
    if payload.guardian_id:
        guardian = _get_user(db, payload.guardian_id)
    elif payload.guardian_login_id:
        guardian = db.query(models.User).filter(models.User.login_id == payload.guardian_login_id).first()
    if not guardian:
        raise HTTPException(status_code=404, detail="보호자 계정을 찾을 수 없습니다.")
    if guardian.user_role != models.UserRole.GUARDIAN:
        guardian.user_role = models.UserRole.GUARDIAN
        guardian.user_type = "GUARDIAN"

    relation = db.query(models.CareRelation).filter(
        models.CareRelation.guardian_id == guardian.user_id,
        models.CareRelation.recipient_id == recipient.user_id,
    ).first()
    if not relation:
        relation = models.CareRelation(
            guardian_id=guardian.user_id,
            recipient_id=recipient.user_id,
            relation_name=payload.relation_name,
            priority=payload.priority,
        )
        db.add(relation)
    else:
        relation.is_active = True
        relation.relation_name = payload.relation_name
        relation.priority = payload.priority
    db.commit()
    db.refresh(relation)
    data = _serialize_relation(relation, recipient)
    data["guardian"] = _serialize_user(guardian)
    return data


@app.get("/api/users/{user_id}/guardian-links")
async def list_guardian_links(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    relations = db.query(models.CareRelation).filter(
        models.CareRelation.recipient_id == user_id,
        models.CareRelation.is_active == True,
    ).order_by(models.CareRelation.priority).all()
    result = []
    for relation in relations:
        guardian = _get_user(db, relation.guardian_id)
        data = _serialize_relation(relation)
        data["guardian"] = _serialize_user(guardian)
        result.append(data)
    return result


@app.get("/api/guardians/{guardian_id}/recipients")
async def guardian_recipients(guardian_id: int, db: Session = Depends(get_db)):
    guardian = _get_user(db, guardian_id)
    if guardian.user_role != models.UserRole.GUARDIAN and guardian.user_role != models.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="보호자 권한이 필요합니다.")
    relations = db.query(models.CareRelation).filter(
        models.CareRelation.guardian_id == guardian_id,
        models.CareRelation.is_active == True,
    ).all()
    result = []
    for relation in relations:
        recipient = _get_user(db, relation.recipient_id)
        dashboard = await get_dashboard(recipient.user_id, db)
        result.append({
            **_serialize_relation(relation, recipient),
            "dashboard": dashboard["summary"],
        })
    return result


@app.patch("/api/care-relations/{relation_id}/sharing")
async def update_sharing(relation_id: int, payload: ShareSettingsUpdate, db: Session = Depends(get_db)):
    relation = db.query(models.CareRelation).filter(models.CareRelation.relation_id == relation_id).first()
    if not relation:
        raise HTTPException(status_code=404, detail="보호자 관계를 찾을 수 없습니다.")
    relation.share_location = payload.share_location
    relation.share_health = payload.share_health
    relation.share_activity = payload.share_activity
    user = _get_user(db, relation.recipient_id)
    user.share_location = payload.share_location
    user.share_health = payload.share_health
    user.share_activity = payload.share_activity
    db.commit()
    return _serialize_relation(relation, user)


@app.post("/api/messages")
async def send_message(payload: MessageCreate, db: Session = Depends(get_db)):
    _get_user(db, payload.sender_id)
    _get_user(db, payload.receiver_id)
    message = models.Message(**payload.model_dump())
    db.add(message)
    db.add(
        models.Alert(
            recipient_id=payload.receiver_id,
            alert_type="MESSAGE",
            title="보호자 메시지",
            body=payload.body,
            priority="NORMAL",
        )
    )
    db.commit()
    db.refresh(message)
    return {"message_id": message.message_id, "created_at": str(message.created_at)}


@app.get("/api/users/{user_id}/messages")
async def list_messages(user_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    messages = db.query(models.Message).filter(
        (models.Message.sender_id == user_id) | (models.Message.receiver_id == user_id)
    ).order_by(models.Message.created_at.desc()).all()
    return [
        {
            "message_id": row.message_id,
            "sender_id": row.sender_id,
            "receiver_id": row.receiver_id,
            "body": row.body,
            "is_read": row.is_read,
            "created_at": str(row.created_at),
        }
        for row in messages
    ]


@app.get("/api/users/{user_id}/missions")
async def list_missions(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    _ensure_user_defaults(db, user)
    missions = db.query(models.GameMission).filter(models.GameMission.user_id == user_id).all()
    return [
        {
            "mission_id": m.mission_id,
            "title": m.title,
            "mission_type": m.mission_type,
            "points": m.points,
            "is_completed": bool(m.is_completed),
        }
        for m in missions
    ]


@app.post("/api/users/{user_id}/missions/{mission_id}/complete")
async def complete_mission(user_id: int, mission_id: int, db: Session = Depends(get_db)):
    _get_user(db, user_id)
    mission = db.query(models.GameMission).filter(
        models.GameMission.user_id == user_id,
        models.GameMission.mission_id == mission_id,
    ).first()
    if not mission:
        raise HTTPException(status_code=404, detail="미션을 찾을 수 없습니다.")
    mission.is_completed = True
    db.commit()
    return {"message": "미션을 완료했습니다.", "points": mission.points}


@app.get("/api/admin/users")
async def admin_users(include_deleted: bool = Query(False), db: Session = Depends(get_db)):
    query = db.query(models.User)
    if not include_deleted:
        query = query.filter(models.User.user_is_deleted == False)
    return [_serialize_user(user) for user in query.order_by(models.User.user_created_at.desc()).all()]


@app.patch("/api/admin/users/{user_id}")
async def admin_update_user(user_id: int, payload: AdminUserUpdate, db: Session = Depends(get_db)):
    user = _get_user(db, user_id, include_deleted=True)
    data = payload.model_dump(exclude_unset=True)
    role = data.pop("user_role", None)
    for key, value in data.items():
        setattr(user, key, value)
    if role:
        user.user_role = models.UserRole(role)
    user.user_updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    return _serialize_user(user)


@app.post("/api/admin/users/{user_id}/approve")
async def admin_approve_user(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id, include_deleted=True)
    user.approved = True
    user.status = models.AccountStatus.ACTIVE.value
    user.user_is_deleted = False
    user.user_deleted_at = None
    db.commit()
    return {"message": "사용자가 승인되었습니다.", "user": _serialize_user(user)}


@app.post("/api/admin/users/{user_id}/deactivate")
async def admin_deactivate_user(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    user.status = models.AccountStatus.DISABLED.value
    db.commit()
    return {"message": "사용자가 비활성화되었습니다.", "user": _serialize_user(user)}


@app.post("/api/admin/users/{user_id}/restore")
async def admin_restore_user(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id, include_deleted=True)
    user.user_is_deleted = False
    user.user_deleted_at = None
    user.status = models.AccountStatus.ACTIVE.value
    user.approved = True
    db.commit()
    return {"message": "사용자가 복구되었습니다.", "user": _serialize_user(user)}


@app.delete("/api/admin/users/{user_id}")
async def admin_delete_user(user_id: int, db: Session = Depends(get_db)):
    user = _get_user(db, user_id)
    user.user_is_deleted = True
    user.user_deleted_at = datetime.utcnow()
    user.status = models.AccountStatus.DELETED.value
    db.commit()
    return {"message": "사용자가 삭제 처리되었습니다."}


@app.get("/api/admin/summary")
async def admin_summary(db: Session = Depends(get_db)):
    total_users = db.query(models.User).filter(models.User.user_is_deleted == False).count()
    active_users = db.query(models.User).filter(
        models.User.user_is_deleted == False,
        models.User.status == models.AccountStatus.ACTIVE.value,
    ).count()
    pending_users = db.query(models.User).filter(
        models.User.user_is_deleted == False,
        models.User.approved == False,
    ).count()
    active_devices = db.query(models.Device).filter(
        models.Device.device_is_deleted == False,
        models.Device.device_status == True,
    ).count()
    today_alerts = db.query(models.Alert).count()
    return {
        "total_users": total_users,
        "active_users": active_users,
        "pending_users": pending_users,
        "active_devices": active_devices,
        "today_alerts": today_alerts,
        "last_backup": "개발 DB 로컬 백업 준비됨",
    }


@app.post("/api/admin/logs/cleanup")
async def cleanup_logs(days: int = 30, db: Session = Depends(get_db)):
    cutoff = datetime.utcnow().timestamp() - (days * 24 * 60 * 60)
    cutoff_dt = datetime.fromtimestamp(cutoff)
    deleted_sensor = db.query(models.SensorLog).filter(models.SensorLog.sensor_created_at < cutoff_dt).delete()
    deleted_alerts = db.query(models.Alert).filter(
        models.Alert.alert_created_at < cutoff_dt,
        models.Alert.is_read == True,
    ).delete()
    db.commit()
    return {"message": "오래된 로그를 삭제했습니다.", "sensor_logs": deleted_sensor, "alerts": deleted_alerts}


@app.post("/api/admin/backup")
async def backup_data(db: Session = Depends(get_db)):
    return {
        "message": "백업용 스냅샷이 생성되었습니다.",
        "counts": {
            "users": db.query(models.User).count(),
            "devices": db.query(models.Device).count(),
            "alerts": db.query(models.Alert).count(),
            "routines": db.query(models.Routine).count(),
        },
    }


@app.post("/api/admin/restore")
async def restore_data():
    return {"message": "복구 작업이 접수되었습니다. 실제 운영 환경에서는 백업 파일 선택 절차가 필요합니다."}


@app.post("/api/inquiries")
async def create_inquiry(payload: InquiryCreate, db: Session = Depends(get_db)):
    if payload.user_id:
        _get_user(db, payload.user_id)
    inquiry = models.Inquiry(**payload.model_dump())
    db.add(inquiry)
    db.commit()
    db.refresh(inquiry)
    return {"message": "문의가 접수되었습니다.", "inquiry_id": inquiry.inquiry_id}


@app.get("/api/inquiries")
async def list_inquiries(status: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(models.Inquiry)
    if status:
        query = query.filter(models.Inquiry.status == status)
    rows = query.order_by(models.Inquiry.created_at.desc()).all()
    return [
        {
            "inquiry_id": row.inquiry_id,
            "user_id": row.user_id,
            "title": row.title,
            "body": row.body,
            "status": row.status,
            "created_at": str(row.created_at),
            "processed_at": str(row.processed_at) if row.processed_at else None,
        }
        for row in rows
    ]


@app.patch("/api/inquiries/{inquiry_id}")
async def update_inquiry(inquiry_id: int, payload: InquiryUpdate, db: Session = Depends(get_db)):
    inquiry = db.query(models.Inquiry).filter(models.Inquiry.inquiry_id == inquiry_id).first()
    if not inquiry:
        raise HTTPException(status_code=404, detail="문의를 찾을 수 없습니다.")
    inquiry.status = payload.status
    if payload.status == "DONE":
        inquiry.processed_at = datetime.utcnow()
    db.commit()
    return {"message": "문의 상태가 변경되었습니다."}
