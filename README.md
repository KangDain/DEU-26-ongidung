실행 방법
#venv 폴더 전체 삭제하고 다시 가상 폴더 만들기
#python -m venv .venv
#.\.venv\Script\activate
#pip install opencv-python
#pip install uvicorn
#python -m pip install fastapi uvicorn opencv-python
#python test_camera.py (이거는 테스트) 카메라 안열릴시 cap = cv2.VideoCapture(1) 이 코드에서 () 안에 있는 숫자 0,1,2 하나씩 해보기
#python -m uvicorn main:app --reload
