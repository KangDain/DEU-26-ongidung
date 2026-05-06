# backend&frontend 서버 여는 법

Backend
```
cd backend  # 경로 이동
python -m venv venv  # 가상환경 새로 만들기
./venv/Scripts/pip install fastapi uvicorn sqlalchemy  # 필요한 라이브러리 설치 (Fast API 등)
./venv/Scripts/python -m uvicorn main:app --reload # 서버 실행
```

Frontend
```
cd frontend  # 경로 이동
flutter run -d chrome  # chrome으로 서버 실행
```

# 수정한 부분 & 수정해야할 부분
----------
DB구조 바껴있어서 다시 복구 (일단 기존 ERD대로 하고 나중에 추가 ex. 게임 등등)

app_state.dart 더미 데이터 삭제 and 진짜 데이터 드러나게 수정

약 복용 데이터 앱에서 등록 시 데이터에 등록 가능

app_service 부분 수정(back이랑 연동이 안되었기 때문)

admin으로 로그인 시 admin 페이지로 이동하게 수정

main.py에 보호자 피보호자 연동 코드 작성

피보호자, 보호자 둘이 서로에게 문자메세지 전송 시 서로의 알림창에 등록되도록 임시 수정 (메세지 기능 추가 시 DB 데이터 다 엎어야해서 일단 추후 논의)

+ 보호자  안정 tap에서 긴급이 뜨는 이유 → 임시로 DB에 피보호자 alert에 FALL_DOWN 등록함 (작동하는지 확인하기 위함)

# frontend 수정 부탁
----------

user type이 관리자면 관리자로 이동하게 수정

guardian이 메세지 전송 시 backend로 전송되게끔 수정
