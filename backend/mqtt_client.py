import json
import os
import ssl
from pathlib import Path

import paho.mqtt.client as mqtt

from database import SessionLocal
from models import SensorReading


def load_env_file(path=".env"):
    if not os.path.exists(path):
        return

    with open(path, encoding="utf-8") as env_file:
        for line in env_file:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ[key.strip()] = value.strip().strip('"').strip("'")


load_env_file()
load_env_file(Path(__file__).with_name(".env"))

MQTT_BROKER = os.getenv("MQTT_BROKER", "")
MQTT_PORT = int(os.getenv("MQTT_PORT", "8883"))
MQTT_USERNAME = os.getenv("MQTT_USERNAME")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD")
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "home/sensor/all")
MQTT_TLS = os.getenv("MQTT_TLS", "1") == "1"
MQTT_SENSOR_ID = os.getenv("MQTT_SENSOR_ID")


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        client.subscribe(MQTT_TOPIC, qos=1)
        print(f"[MQTT] Baglandi ve dinleniyor: {MQTT_TOPIC}")
        return

    print(f"[MQTT] Baglanti basarisiz. rc={rc}")


def on_message(client, userdata, msg):
    db = None
    try:
        data = json.loads(msg.payload.decode())
        sensor_id = data.get("sensor_id") or MQTT_SENSOR_ID
        if not sensor_id:
            raise ValueError("MQTT mesajinda sensor_id yok ve MQTT_SENSOR_ID tanimli degil")

        db = SessionLocal()
        reading = SensorReading(
            sensor_id=int(sensor_id),
            data={
                "device_id": data.get("device_id"),
                "temperature": data.get("temperature"),
                "humidity": data.get("humidity"),
                "gas_level": data.get("gas_level"),
                "light_level": data.get("light_level"),
                "distance_cm": data.get("distance_cm"),
                "soil_raw": data.get("soil_raw"),
                "soil_moisture": data.get("soil_moisture"),
                "motion_detected": data.get("motion_detected"),
                "buzzer": data.get("buzzer"),
                "accelerometer": data.get("accelerometer"),
                "gyroscope": data.get("gyroscope"),
                "magnetometer": data.get("magnetometer"),
            },
        )
        db.add(reading)
        db.commit()
        print(f"[DB] MQTT verisi kaydedildi: sensor_id={sensor_id}, topic={msg.topic}")
    except Exception as e:
        print(f"[MQTT] Mesaj isleme hatasi: topic={msg.topic}, hata={e}")
    finally:
        if db is not None:
            db.close()


def start_mqtt_client():
    if not MQTT_BROKER:
        raise ValueError("MQTT_BROKER environment variable tanimli degil")

    client = mqtt.Client(client_id="backend-subscriber")
    client.on_connect = on_connect
    client.on_message = on_message

    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)

    if MQTT_TLS:
        client.tls_set(tls_version=ssl.PROTOCOL_TLS_CLIENT)
        client.tls_insecure_set(False)

    client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    client.loop_start()
    print(f"[MQTT] Subscriber baslatildi: {MQTT_BROKER}:{MQTT_PORT}")
    return client
