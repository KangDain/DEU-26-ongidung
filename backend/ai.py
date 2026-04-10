import cv2

hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

def detect_person(frame):
    if frame is None:
        return False

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    boxes, _ = hog.detectMultiScale(gray)

    return len(boxes) > 0