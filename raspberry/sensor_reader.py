import json
import os
import random
import ssl
import time

import paho.mqtt.client as mqtt


def load_env_file(path=".env"):
    if not os.path.exists(path):
        return

    with open(path, encoding="utf-8") as env_file:
        for line in env_file:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_env_file()

MQTT_BROKER = os.getenv("MQTT_BROKER", "")
MQTT_PORT = int(os.getenv("MQTT_PORT", "8883"))
MQTT_USERNAME = os.getenv("MQTT_USERNAME")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD")
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "home/sensor/all")
MQTT_TLS = os.getenv("MQTT_TLS", "1") == "1"
DEVICE_ID = os.getenv("DEVICE_ID", "Ankara-RPi-01")


def read_sensor_data():
    return {
        "device_id": DEVICE_ID,
        "temperature": round(random.uniform(18, 36), 2),
        "humidity": round(random.uniform(30, 85), 2),
        "gas_level": round(random.uniform(250, 500), 2),
        "light_level": round(random.uniform(0, 1020), 2),
        "distance_cm": round(random.uniform(5, 200), 2),
    }


def create_mqtt_client():
    if not MQTT_BROKER:
        raise ValueError("MQTT_BROKER environment variable tanimli degil")

    client = mqtt.Client(client_id=f"{DEVICE_ID}-publisher")

    if MQTT_USERNAME and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)

    if MQTT_TLS:
        client.tls_set(tls_version=ssl.PROTOCOL_TLS_CLIENT)
        client.tls_insecure_set(False)

    client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    return client


def publish_sensor_data(client, data):
    payload = json.dumps(data)
    result = client.publish(MQTT_TOPIC, payload, qos=1)
    result.wait_for_publish()
    print(f"[MQTT] Gonderildi: {payload}")


def main():
    client = create_mqtt_client()
    client.loop_start()
    try:
        while True:
            publish_sensor_data(client, read_sensor_data())
            time.sleep(5)
    finally:
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    main()
