from fastapi import FastAPI
from fastapi.responses import StreamingResponse, FileResponse
from pydantic import BaseModel
from datetime import datetime

from camera import get_frame, generate_frames, save_capture, release_camera
from ai import detect_person
from motion import detect_motion
from push import send_push_notification
from location import calculate_distance, reverse_geocode

app = FastAPI()

users = []
locations = []
sos_events = []
game_missions = []
alerts = []
device_tokens = []


class SignupRequest(BaseModel):
    login_id: str
    password: str
    user_name: str
    phone: str | None = None
    role: str
    pin_code: str | None = None


class LoginRequest(BaseModel):
    login_id: str
    password: str


class PinLoginRequest(BaseModel):
    login_id: str
    pin_code: str


class LocationRequest(BaseModel):
    user_id: int
    latitude: float
    longitude: float
    address: str | None = None


class DistanceRequest(BaseModel):
    user_id: int
    target_latitude: float
    target_longitude: float


class SOSRequest(BaseModel):
    user_id: int
    message: str = "긴급 상황 발생"
    latitude: float | None = None
    longitude: float | None = None


class MissionRequest(BaseModel):
    user_id: int
    title: str
    mission_type: str
    points: int = 10


class MissionCompleteRequest(BaseModel):
    user_id: int
    mission_id: int


class DeviceTokenRequest(BaseModel):
    user_id: int
    token: str


@app.get("/")
def root():
    return {"message": "IoT 기반 돌봄 서비스 백엔드 서버 실행 중"}


@app.get("/health")
def health_check():
    return {
        "server": "running",
        "camera": "not_checked",
        "user_count": len(users),
        "location_count": len(locations),
        "sos_count": len(sos_events),
        "mission_count": len(game_missions),
        "alert_count": len(alerts)
    }


@app.get("/camera/status")
def camera_status():
    frame = get_frame()

    return {
        "status": "ok",
        "camera": "connected" if frame is not None else "disconnected"
    }


@app.post("/signup")
def signup(data: SignupRequest):
    for user in users:
        if user["login_id"] == data.login_id:
            return {
                "status": "fail",
                "message": "이미 존재하는 아이디입니다."
            }

    if data.role not in ["GUARDIAN", "RECIPIENT", "ADMIN"]:
        return {
            "status": "fail",
            "message": "role은 GUARDIAN, RECIPIENT, ADMIN 중 하나여야 합니다."
        }

    user = {
        "user_id": len(users) + 1,
        "login_id": data.login_id,
        "password": data.password,
        "user_name": data.user_name,
        "phone": data.phone,
        "role": data.role,
        "pin_code": data.pin_code,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    users.append(user)

    return {
        "status": "ok",
        "message": "회원가입 성공",
        "user": {
            "user_id": user["user_id"],
            "login_id": user["login_id"],
            "user_name": user["user_name"],
            "role": user["role"]
        }
    }


@app.post("/login")
def login(data: LoginRequest):
    for user in users:
        if user["login_id"] == data.login_id and user["password"] == data.password:
            return {
                "status": "ok",
                "message": "로그인 성공",
                "user": {
                    "user_id": user["user_id"],
                    "login_id": user["login_id"],
                    "user_name": user["user_name"],
                    "role": user["role"]
                }
            }

    return {
        "status": "fail",
        "message": "아이디 또는 비밀번호가 일치하지 않습니다."
    }


@app.post("/pin-login")
def pin_login(data: PinLoginRequest):
    for user in users:
        if user["login_id"] == data.login_id and user["pin_code"] == data.pin_code:
            return {
                "status": "ok",
                "message": "PIN 로그인 성공",
                "user": {
                    "user_id": user["user_id"],
                    "login_id": user["login_id"],
                    "user_name": user["user_name"],
                    "role": user["role"]
                }
            }

    return {
        "status": "fail",
        "message": "PIN 번호가 일치하지 않습니다."
    }


@app.get("/users")
def get_users():
    safe_users = []

    for user in users:
        safe_users.append({
            "user_id": user["user_id"],
            "login_id": user["login_id"],
            "user_name": user["user_name"],
            "phone": user["phone"],
            "role": user["role"],
            "created_at": user["created_at"]
        })

    return {
        "status": "ok",
        "users": safe_users
    }


@app.get("/video_feed")
def video_feed():
    return StreamingResponse(
        generate_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )


@app.get("/camera/capture")
def capture_camera():
    frame = get_frame()

    if frame is None:
        return {
            "status": "fail",
            "message": "홈캠 연결 실패"
        }

    path = save_capture(frame)

    return {
        "status": "ok",
        "message": "사진 캡처 완료",
        "capture_path": path,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }


@app.get("/capture/image")
def get_capture_image(path: str):
    return FileResponse(path)


@app.get("/detect")
def detect():
    frame = get_frame()

    if frame is None:
        return {
            "status": "fail",
            "message": "홈캠 연결 실패",
            "person_detected": False
        }

    person_detected, boxes = detect_person(frame)

    capture_path = None
    safety_status = "normal"

    if person_detected:
        capture_path = save_capture(frame)
        safety_status = "warning"

        alerts.append({
            "alert_id": len(alerts) + 1,
            "type": "person_detected",
            "message": "홈캠에서 사람이 감지되었습니다.",
            "capture_path": capture_path,
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })

        for item in device_tokens:
            send_push_notification(
                item["token"],
                "사람 감지",
                "홈캠에서 사람이 감지되었습니다."
            )

    return {
        "status": "ok",
        "safety_status": safety_status,
        "person_detected": person_detected,
        "detected_boxes": boxes,
        "capture_path": capture_path,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }


@app.get("/motion")
def motion_check():
    frame = get_frame()

    if frame is None:
        return {
            "status": "fail",
            "message": "홈캠 연결 실패",
            "motion_detected": False
        }

    motion_detected, motion_area = detect_motion(frame)

    capture_path = None
    safety_status = "normal"

    if motion_detected:
        capture_path = save_capture(frame)
        safety_status = "warning"

        alerts.append({
            "alert_id": len(alerts) + 1,
            "type": "motion_detected",
            "message": "움직임이 감지되었습니다.",
            "motion_area": motion_area,
            "capture_path": capture_path,
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })

        for item in device_tokens:
            send_push_notification(
                item["token"],
                "움직임 감지",
                "홈캠에서 움직임이 감지되었습니다."
            )

    return {
        "status": "ok",
        "safety_status": safety_status,
        "motion_detected": motion_detected,
        "motion_area": motion_area,
        "capture_path": capture_path,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }


@app.post("/push/token")
def save_device_token(data: DeviceTokenRequest):
    for item in device_tokens:
        if item["user_id"] == data.user_id:
            item["token"] = data.token

            return {
                "status": "ok",
                "message": "푸시 토큰 갱신 완료"
            }

    device_tokens.append({
        "user_id": data.user_id,
        "token": data.token,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

    return {
        "status": "ok",
        "message": "푸시 토큰 저장 완료"
    }


@app.post("/location")
def save_location(data: LocationRequest):
    address = data.address

    if address is None:
        address = reverse_geocode(
            data.latitude,
            data.longitude
        )

    location = {
        "location_id": len(locations) + 1,
        "user_id": data.user_id,
        "latitude": data.latitude,
        "longitude": data.longitude,
        "address": address,
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    locations.append(location)

    return {
        "status": "ok",
        "message": "위치 저장 완료",
        "data": location
    }


@app.get("/location/{user_id}")
def get_location(user_id: int):
    user_locations = [
        loc for loc in locations
        if loc["user_id"] == user_id
    ]

    if len(user_locations) == 0:
        return {
            "status": "fail",
            "message": "저장된 위치가 없습니다."
        }

    return {
        "status": "ok",
        "latest_location": user_locations[-1],
        "location_history": user_locations
    }


@app.post("/location/distance")
def get_distance(data: DistanceRequest):
    user_locations = [
        loc for loc in locations
        if loc["user_id"] == data.user_id
    ]

    if len(user_locations) == 0:
        return {
            "status": "fail",
            "message": "사용자 위치가 없습니다."
        }

    latest = user_locations[-1]

    distance = calculate_distance(
        latest["latitude"],
        latest["longitude"],
        data.target_latitude,
        data.target_longitude
    )

    return {
        "status": "ok",
        "distance_km": distance
    }


@app.get("/alerts")
def get_alerts():
    return {
        "status": "ok",
        "alerts": alerts
    }


@app.on_event("shutdown")
def shutdown_event():
    release_camera()