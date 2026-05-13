import firebase_admin
from firebase_admin import credentials, messaging
import os
import logging

# Firebase Admin SDK'yı başlat
def initialize_firebase():
    """Firebase Admin SDK'yı başlat"""
    try:
        # Eğer daha önce başlatılmışsa yeniden başlatma
        if not firebase_admin._apps:
            # Credentials dosyasının yolu
            creds_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-key.json")
            if os.path.exists(creds_path):
                cred = credentials.Certificate(creds_path)
                firebase_admin.initialize_app(cred)
                logging.info("Firebase initialized successfully")
            else:
                logging.warning(f"Firebase credentials file not found at {creds_path}")
    except Exception as e:
        logging.error(f"Firebase initialization error: {e}")


def send_sensor_alert(fcm_token: str, alerts: list[str]) -> bool:
    """FCM token'a sensor alert bildirimi gönder"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title="Smart Home Alert",
                body=f"{', '.join(alerts)} normal aralığın dışında.",
            ),
            data={
                "type": "sensor_alert",
                "alerts": ",".join(alerts),
            },
            token=fcm_token,
        )
        response = messaging.send(message)
        logging.info(f"Notification sent successfully: {response}")
        return True
    except Exception as e:
        logging.error(f"Error sending notification: {e}")
        return False


def send_multicast_alert(fcm_tokens: list[str], alerts: list[str]) -> dict:
    """Birden fazla cihaza sensor alert bildirimi gönder"""
    try:
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title="Smart Home Alert",
                body=f"{', '.join(alerts)} normal aralığın dışında.",
            ),
            data={
                "type": "sensor_alert",
                "alerts": ",".join(alerts),
            },
            tokens=fcm_tokens,
        )
        response = messaging.send_multicast(message)
        logging.info(f"Multicast notifications sent: {response.success} successful")
        return {
            "success": response.success,
            "failure": response.failure,
        }
    except Exception as e:
        logging.error(f"Error sending multicast notification: {e}")
        return {"success": 0, "failure": len(fcm_tokens)}
