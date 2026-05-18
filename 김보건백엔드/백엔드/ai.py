import cv2

hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())


def detect_person(frame):
    if frame is None:
        return False, []

    resized = cv2.resize(frame, (640, 480))
    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

    boxes, weights = hog.detectMultiScale(
        gray,
        winStride=(8, 8),
        padding=(8, 8),
        scale=1.05
    )

    result_boxes = []

    for (x, y, w, h) in boxes:
        result_boxes.append({
            "x": int(x),
            "y": int(y),
            "width": int(w),
            "height": int(h)
        })

    return len(result_boxes) > 0, result_boxes