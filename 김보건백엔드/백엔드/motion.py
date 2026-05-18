import cv2

previous_gray = None


def detect_motion(frame):
    global previous_gray

    if frame is None:
        return False, 0

    resized = cv2.resize(frame, (640, 480))
    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (21, 21), 0)

    if previous_gray is None:
        previous_gray = gray
        return False, 0

    frame_delta = cv2.absdiff(previous_gray, gray)
    threshold = cv2.threshold(frame_delta, 25, 255, cv2.THRESH_BINARY)[1]
    threshold = cv2.dilate(threshold, None, iterations=2)

    contours, _ = cv2.findContours(
        threshold,
        cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE
    )

    motion_area = 0

    for contour in contours:
        area = cv2.contourArea(contour)

        if area > 1000:
            motion_area += area

    previous_gray = gray

    motion_detected = motion_area > 3000

    return motion_detected, int(motion_area)