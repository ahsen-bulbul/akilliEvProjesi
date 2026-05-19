import json
import os
import sys
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import mqtt_client


class MqttClientTests(unittest.TestCase):
    def test_on_message_persists_sensor_payload(self):
        db = Mock()
        msg = SimpleNamespace(
            topic="home/sensor/all",
            payload=json.dumps(
                {
                    "sensor_id": 7,
                    "device_id": "raspberry-pi",
                    "temperature": 24.5,
                    "humidity": 58,
                    "gas_level": 120,
                    "accelerometer": {"x": 1, "y": 2, "z": 3},
                }
            ).encode("utf-8"),
        )

        with patch("mqtt_client.SessionLocal", return_value=db), redirect_stdout(StringIO()):
            mqtt_client.on_message(Mock(), None, msg)

        db.add.assert_called_once()
        reading = db.add.call_args.args[0]
        self.assertEqual(reading.sensor_id, 7)
        self.assertEqual(reading.data["device_id"], "raspberry-pi")
        self.assertEqual(reading.data["temperature"], 24.5)
        self.assertEqual(reading.data["accelerometer"], {"x": 1, "y": 2, "z": 3})
        db.commit.assert_called_once()
        db.close.assert_called_once()

    def test_on_message_ignores_invalid_json_without_opening_session(self):
        msg = SimpleNamespace(topic="home/sensor/all", payload=b"{invalid-json")

        with patch("mqtt_client.SessionLocal") as session_factory, redirect_stdout(StringIO()):
            mqtt_client.on_message(Mock(), None, msg)

        session_factory.assert_not_called()


if __name__ == "__main__":
    unittest.main()
