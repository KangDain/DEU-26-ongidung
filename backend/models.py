from datetime import datetime
import enum

from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    Time,
)

from database import Base


class UserRole(enum.Enum):
    GUARDIAN = "GUARDIAN"
    RECIPIENT = "RECIPIENT"
    ADMIN = "ADMIN"


class AccountStatus(enum.Enum):
    ACTIVE = "ACTIVE"
    PENDING = "PENDING"
    DISABLED = "DISABLED"
    DELETED = "DELETED"


class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, autoincrement=True)
    login_id = Column(String(50), unique=True, nullable=False)
    user_pw = Column(String(255), nullable=False)
    user_name = Column(String(50), nullable=False)
    email = Column(String(100))
    user_phone = Column(String(20))
    user_role = Column(Enum(UserRole), nullable=False, default=UserRole.RECIPIENT)
    user_created_at = Column(DateTime, default=datetime.utcnow)
    user_updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    user_deleted_at = Column(DateTime)
    user_is_deleted = Column(Boolean, default=False)
    status = Column(String(20), default=AccountStatus.ACTIVE.value)
    approved = Column(Boolean, default=True)

    user_birth_date = Column(String(20))
    user_address = Column(String(200))
    guardian_phone = Column(String(20))
    user_type = Column(String(20), default="GENERAL")
    profile_image_url = Column(String(500))

    health_info = Column(Text)
    medication_note = Column(Text)
    emergency_note = Column(Text)

    pin_code = Column(String(20))
    auto_login_enabled = Column(Boolean, default=False)

    share_location = Column(Boolean, default=True)
    share_health = Column(Boolean, default=True)
    share_activity = Column(Boolean, default=False)


class CareRelation(Base):
    __tablename__ = "care_relations"

    relation_id = Column(Integer, primary_key=True, autoincrement=True)
    guardian_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    relation_name = Column(String(50), default="보호자")
    priority = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    share_location = Column(Boolean, default=True)
    share_health = Column(Boolean, default=True)
    share_activity = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    contact_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    name = Column(String(50), nullable=False)
    phone = Column(String(20), nullable=False)
    relation = Column(String(50), default="가족")
    priority = Column(Integer, default=1)
    is_guardian = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Device(Base):
    __tablename__ = "devices"

    device_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    device_name = Column(String(100), default="홈캠")
    device_type = Column(String(20), nullable=False)
    location_name = Column(String(100), default="거실")
    connection_info = Column(String(200))
    ip_address = Column(String(50))
    device_status = Column(Boolean, default=True)
    battery_level = Column(Integer, default=100)
    last_seen_at = Column(DateTime, default=datetime.utcnow)
    device_is_deleted = Column(Boolean, default=False)


class SensorLog(Base):
    __tablename__ = "sensor"

    sensor_log_id = Column(BigInteger, primary_key=True, autoincrement=True)
    device_id = Column(Integer, ForeignKey("devices.device_id"))
    recipient_id = Column(Integer, ForeignKey("users.user_id"))
    sensor_event_type = Column(String(50), nullable=False)
    value = Column(String(100))
    risk_level = Column(String(20), default="NORMAL")
    note = Column(String(200))
    sensor_created_at = Column(DateTime, default=datetime.utcnow)


class Alert(Base):
    __tablename__ = "alerts"

    alert_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    guardian_id = Column(Integer, ForeignKey("users.user_id"))
    alert_type = Column(String(50), nullable=False)
    title = Column(String(100), default="알림")
    body = Column(String(500))
    priority = Column(String(20), default="NORMAL")
    status = Column(String(20), default="OPEN")
    is_read = Column(Boolean, default=False)
    alert_created_at = Column(DateTime, default=datetime.utcnow)


class Routine(Base):
    __tablename__ = "routines"

    routine_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    routine_title = Column(String(100), nullable=False)
    routine_category = Column(String(30), default="schedule")
    routine_notify_time = Column(Time, nullable=False)
    repeat_rule = Column(String(50), default="DAILY")
    routine_is_active = Column(Boolean, default=True)
    is_done_today = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class LocationLog(Base):
    __tablename__ = "location_logs"

    location_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    latitude = Column(String(30))
    longitude = Column(String(30))
    address = Column(String(200))
    place_name = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)


class Message(Base):
    __tablename__ = "messages"

    message_id = Column(Integer, primary_key=True, autoincrement=True)
    sender_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    body = Column(String(500), nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class EmergencyEvent(Base):
    __tablename__ = "emergency_events"

    event_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    status = Column(String(20), default="OPEN")
    message = Column(String(500))
    location_address = Column(String(200))
    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime)


class Inquiry(Base):
    __tablename__ = "inquiries"

    inquiry_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"))
    title = Column(String(100), nullable=False)
    body = Column(String(1000), nullable=False)
    status = Column(String(20), default="OPEN")
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime)


class GameMission(Base):
    __tablename__ = "game_missions"

    mission_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    title = Column(String(100), nullable=False)
    mission_type = Column(String(50), default="health")
    points = Column(Integer, default=10)
    is_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
