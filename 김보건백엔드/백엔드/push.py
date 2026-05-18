import os
import firebase_admin
from firebase_admin import credentials, messaging

firebase_app = None


def init_firebase():
    global firebase_app

    if firebase_app is not None:
        return True

    if not os.path.exists("firebase_key.json"):
        return False

    cred = credentials.Certificate("firebase_key.json")
    firebase_app = firebase_admin.initialize_app(cred)

    return True


def send_push_notification(token, title, body):
    try:
        if not init_firebase():
            return False

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            token=token
        )

        messaging.send(message)

        return True

    except Exception:
        return False