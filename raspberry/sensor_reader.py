import json
import os
import random
import re
import ssl
import time

import paho.mqtt.client as mqtt
import serial


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
SENSOR_ID = os.getenv("SENSOR_ID")
SENSOR_SOURCE = os.getenv("SENSOR_SOURCE", "mock").lower()
SERIAL_PORT = os.getenv("SERIAL_PORT", "/dev/ttyUSB0")
SERIAL_BAUD = int(os.getenv("SERIAL_BAUD", "9600"))
SERIAL_TIMEOUT = float(os.getenv("SERIAL_TIMEOUT", "2"))
PUBLISH_INTERVAL = float(os.getenv("PUBLISH_INTERVAL", "5"))
SERIAL_FORMAT = os.getenv("SERIAL_FORMAT", "arduino_text").lower()


def with_common_fields(data):
    data.setdefault("device_id", DEVICE_ID)
    if SENSOR_ID and "sensor_id" not in data:
        data["sensor_id"] = int(SENSOR_ID)
    return data


def read_mock_sensor_data():
    return with_common_fields({
        "device_id": DEVICE_ID,
        "temperature": round(random.uniform(18, 36), 2),
        "humidity": round(random.uniform(30, 85), 2),
        "gas_level": round(random.uniform(250, 500), 2),
        "light_level": round(random.uniform(0, 1020), 2),
        "distance_cm": round(random.uniform(5, 200), 2),
    })


class SerialSensorReader:
    def __init__(self, port, baud, timeout):
        self.port = port
        self.baud = baud
        self.timeout = timeout
        self.serial = serial.Serial(port, baud, timeout=timeout)
        time.sleep(2)

    def read(self):
        if SERIAL_FORMAT == "json":
            return self._read_json_line()
        if SERIAL_FORMAT == "arduino_text":
            return self._read_arduino_text_block()
        raise ValueError("SERIAL_FORMAT json veya arduino_text olmali")

    def _read_json_line(self):
        while True:
            line = self.serial.readline().decode("utf-8", errors="replace").strip()
            if not line:
                continue
            try:
                data = json.loads(line)
            except json.JSONDecodeError as exc:
                print(f"[SERIAL] Gecersiz JSON atlandi: {line} ({exc})")
                continue
            if not isinstance(data, dict):
                print(f"[SERIAL] JSON obje degil, atlandi: {line}")
                continue
            return with_common_fields(data)

    def _read_arduino_text_block(self):
        block = []
        in_block = False

        while True:
            line = self.serial.readline().decode("utf-8", errors="replace").strip()
            if not line:
                continue

            if line.startswith("========== SISTEM VERILERI"):
                block = []
                in_block = True
                continue

            if in_block and line.startswith("====================================="):
                data = parse_arduino_text_block(block)
                if data:
                    return with_common_fields(data)
                in_block = False
                block = []
                continue

            if in_block:
                block.append(line)

    def close(self):
        self.serial.close()


def parse_arduino_text_block(lines):
    data = {}

    for line in lines:
        if line.startswith("TEMP:"):
            data["temperature"] = _first_float(line)
        elif line.startswith("ACC:"):
            values = _all_floats(line)
            if len(values) >= 3:
                data["accelerometer"] = {"x": values[0], "y": values[1], "z": values[2]}
        elif line.startswith("GYRO:"):
            values = _all_floats(line)
            if len(values) >= 3:
                data["gyroscope"] = {"x": values[0], "y": values[1], "z": values[2]}
        elif line.startswith("MAG:"):
            values = _all_floats(line)
            if len(values) >= 3:
                data["magnetometer"] = {"x": values[0], "y": values[1], "z": values[2]}
        elif line.startswith("MQ9 Ham Deger:"):
            data["gas_level"] = _first_float(line)
        elif line.startswith("Nem Ham Deger:"):
            values = _all_floats(line)
            if values:
                data["soil_raw"] = values[0]
            if len(values) >= 2:
                data["soil_moisture"] = values[1]
                data["humidity"] = values[1]
        elif line.startswith("Hareket:"):
            data["motion_detected"] = "ALGILANDI" in line.upper()
        elif line.startswith("Buzzer:"):
            data["buzzer"] = "ACIK" in line.upper()

    return data


def _first_float(text):
    values = _all_floats(text)
    return values[0] if values else None


def _all_floats(text):
    return [float(value) for value in re.findall(r"-?\d+(?:\.\d+)?", text)]


def create_sensor_reader():
    if SENSOR_SOURCE == "serial":
        print(f"[SERIAL] Dinleniyor: {SERIAL_PORT} @ {SERIAL_BAUD}")
        return SerialSensorReader(SERIAL_PORT, SERIAL_BAUD, SERIAL_TIMEOUT)
    if SENSOR_SOURCE != "mock":
        raise ValueError("SENSOR_SOURCE mock veya serial olmali")
    print("[SENSOR] Mock veri modu")
    return None


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
    reader = create_sensor_reader()
    client = create_mqtt_client()
    client.loop_start()
    try:
        while True:
            data = reader.read() if reader else read_mock_sensor_data()
            publish_sensor_data(client, data)
            if not reader:
                time.sleep(PUBLISH_INTERVAL)
    finally:
        if reader:
            reader.close()
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    main()
