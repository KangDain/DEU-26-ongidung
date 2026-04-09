# ERD 테이블 파이썬 코드로 정의

from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum, Time, BigInteger
from sqlalchemy.orm import declarative_base, relationship
import enum
from datetime import datetime

#모든 모델의 기본 클래스
Base = declarative_base()

class UserRole(enum.Enum):
    GARDIAN = "GARDIAN"     # 보호자
    RECIPIENT = "RECIPIENT" # 보호 대상자
    ADMIN = "ADMIN"         # 관리자

# ----- Users Table
class User(Base):
    __tablename__ = "users"
    
    user_id = Column(Integer, primary_key=True, autoincrement=True)
    login_id = Column(String(50), unique=True, nullable=False)
    user_pw = Column(String(255), nullable=False)
    # 해시(암호화)해서 저장
    user_name = Column(String(50), nullable=False)
    user_phone = Column(String(20))
    user_role = Column(Enum(UserRole), nullable=False)
    user_created_at = Column(DateTime, default=datetime.utcnow)
    user_is_deleted = Column(Boolean, default=False)

# ----- CareRelation Table
class CareRelation(Base):
    __tablename__ = "care_relations"

    relation_id = Column(Integer, primary_key=True, autoincrement=True)
    guardian_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

# ----- Device Table
class Device(Base):
    __tablename__ = "devices"

    device_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    device_type = Column(String(20), nullable=False) # CAM, PIR, TEMP, DOOR 등
    ip_address = Column(String(50))
    device_status = Column(Boolean, default=True)
    device_is_deleted = Column(Boolean, default=False)

# ----- Sensor Table
class SensorLog(Base):
    __tablename__ = "sensor"

    sensor_log_id = Column(BigInteger, primary_key=True, autoincrement=True)
    device_id = Column(Integer, ForeignKey("devices.device_id"), nullable=False)
    sensor_event_type = Column(String(50), nullable=False) 
    # MOTION_DETECTED, DOOR_OPEN 등
    sensor_created_at = Column(DateTime, default=datetime.utcnow)

# ----- Alert Table
class Alert(Base):
    __tablename__ = "alerts"

    alert_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    alert_type = Column(String(50), nullable=False)
    # NO_MOVEMENT, FALL_DOWN 등
    is_read = Column(Boolean, default=False)
    alert_created_at = Column(DateTime, default=datetime.utcnow)

# ----- Routine Table
class Routine(Base):
    __tablename__ = "routines"

    routine_id = Column(Integer, primary_key=True, autoincrement=True)
    recipient_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    routine_title = Column(String(100), nullable=False)
    routine_notify_time = Column(Time, nullable=False)
    routine_is_active = Column(Boolean, default=True)