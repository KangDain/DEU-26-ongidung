import cv2
from datetime import datetime
import os
import time

rtsp_url = "rtsp://c20232897:ehddmleo123@192.168.0.5:554/stream1"

cap = None


def open_camera():
    global cap

    try:
        if cap is not None and cap.isOpened():
            return cap

        cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)

        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        cap.set(cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, 3000)
        cap.set(cv2.CAP_PROP_READ_TIMEOUT_MSEC, 3000)

        if not cap.isOpened():
            cap.release()
            cap = None
            return None

        return cap

    except Exception:
        cap = None
        return None


def get_frame():
    global cap

    try:
        camera = open_camera()

        if camera is None:
            return None

        ret, frame = camera.read()

        if not ret or frame is None:
            camera.release()
            cap = None
            return None

        return frame

    except Exception:
        if cap is not None:
            cap.release()
        cap = None
        return None


def generate_frames():
    while True:
        frame = get_frame()

        if frame is None:
            time.sleep(0.5)
            continue

        ret, buffer = cv2.imencode(".jpg", frame)

        if not ret:
            time.sleep(0.1)
            continue

        frame_bytes = buffer.tobytes()

        yield (
            b"--frame\r\n"
            b"Content-Type: image/jpeg\r\n\r\n" +
            frame_bytes +
            b"\r\n"
        )


def save_capture(frame):
    if not os.path.exists("captures"):
        os.makedirs("captures")

    filename = datetime.now().strftime("%Y%m%d_%H%M%S.jpg")
    path = os.path.join("captures", filename)

    cv2.imwrite(path, frame)

    return path


def release_camera():
    global cap

    if cap is not None:
        cap.release()
        cap = None