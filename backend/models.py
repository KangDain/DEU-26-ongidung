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
    Time,
)

from database import Base


class UserRole(enum.Enum):
    GUARDIAN = "GUARDIAN"
    RECIPIENT = "RECIPIENT"
    ADMIN = "ADMIN"


# 1. 사용자 테이블
class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, autoincrement=True)
    login_id = Column(String(50), unique=True, nullable=False)
    user_pw = Column(String(255), nullable=False)
    user_name = Column(String(50), nullable=False)
    user_phone = Column(String(20))
    user_role = Column(Enum(UserRole), nullable=False, default=UserRole.RECIPIENT)
    user_created_at = Column(DateTime, default=datetime.utcnow)
    user_is_deleted = Column(Boolean, default=False)


# 2. 보호 연결 테이블
class CareRelation(Base):
    __tablename__ = "care_relations"

    relation_id = Column(Integer, primary_key=True, autoincrement=True)
    guardian_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)


# 3. 기기 및 센서 테이블
class Device(Base):
    __tablename__ = "devices"

    device_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    device_type = Column(String(20), nullable=False)
    ip_address = Column(String(50))
    device_status = Column(Boolean, default=True)
    device_is_deleted = Column(Boolean, default=False)


# 4. 센서 로그 테이블
class SensorLog(Base):
    __tablename__ = "sensor_logs"

    sensor_log_id = Column(BigInteger, primary_key=True, autoincrement=True)
    device_id = Column(Integer, ForeignKey("devices.device_id"))
    sensor_event_type = Column(String(50), nullable=False)
    sensor_created_at = Column(DateTime, default=datetime.utcnow)


# 5. 알림 및 이상 상황 테이블
class Alert(Base):
    __tablename__ = "alerts"

    alert_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    alert_type = Column(String(50), nullable=False)
    is_read = Column(Boolean, default=False)
    alert_created_at = Column(DateTime, default=datetime.utcnow)


# 6. 생활 습관 (루틴) 테이블
class Routine(Base):
    __tablename__ = "routines"

    routine_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    routine_title = Column(String(100), nullable=False)
    routine_notify_time = Column(Time, nullable=False)
    routine_is_active = Column(Boolean, default=True)