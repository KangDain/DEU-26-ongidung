import cv2

cap = cv2.VideoCapture(1)

while True:
    ret, frame = cap.read()
    if not ret:
        print("카메라 안됨")
        break

    cv2.imshow("Webcam Test", frame)

    if cv2.waitKey(1) == 27:  # ESC 누르면 종료
        break

cap.release()
cv2.destroyAllWindows()