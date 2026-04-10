from fastapi import FastAPI
from camera import get_frame
from ai import detect_person

app = FastAPI()

@app.get("/")
def root():
    return {"message": "api 서버 실행중"""}

@app.get("/detect")
def detect():
    frame = get_frame()
    result = detect_person(frame)

    return {
        "status": "ok",
        "person_detected": result
    }