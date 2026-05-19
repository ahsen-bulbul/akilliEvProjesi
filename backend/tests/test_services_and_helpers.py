import os
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi import HTTPException

import firebase_service
import main


class WeatherHelperTests(unittest.TestCase):
    def test_weather_condition_maps_known_codes(self):
        cases = {
            None: "Bilinmiyor",
            0: "Acik",
            2: "Parcali bulutlu",
            3: "Bulutlu",
            45: "Sisli",
            55: "Cisenti",
            63: "Yagmurlu",
            75: "Karli",
            95: "Firtinali",
            123: "Degisken",
        }

        for code, expected in cases.items():
            with self.subTest(code=code):
                self.assertEqual(main._weather_condition(code), expected)

    def test_geocode_city_rejects_blank_city(self):
        with self.assertRaises(HTTPException) as context:
            main._geocode_city("   ")

        self.assertEqual(context.exception.status_code, 400)
        self.assertEqual(context.exception.detail, "Ev sehri gerekli")


class FirebaseServiceTests(unittest.TestCase):
    @patch("firebase_service.messaging.send")
    def test_send_sensor_alert_returns_true_when_message_sent(self, send_mock):
        send_mock.return_value = "message-id"

        result = firebase_service.send_sensor_alert("token-1", ["Gaz", "Sicaklik"])

        self.assertTrue(result)
        send_mock.assert_called_once()
        message = send_mock.call_args.args[0]
        self.assertEqual(message.token, "token-1")
        self.assertEqual(message.data["type"], "sensor_alert")
        self.assertEqual(message.data["alerts"], "Gaz,Sicaklik")

    @patch("firebase_service.messaging.send")
    def test_send_sensor_alert_returns_false_when_firebase_fails(self, send_mock):
        send_mock.side_effect = RuntimeError("firebase down")

        result = firebase_service.send_sensor_alert("token-1", ["Gaz"])

        self.assertFalse(result)

    @patch("firebase_service.messaging.send_multicast")
    def test_send_multicast_alert_returns_success_and_failure_counts(self, send_mock):
        response = Mock(success=2, failure=1)
        send_mock.return_value = response

        result = firebase_service.send_multicast_alert(
            ["token-1", "token-2", "token-3"],
            ["Nem"],
        )

        self.assertEqual(result, {"success": 2, "failure": 1})
        send_mock.assert_called_once()

    @patch("firebase_service.messaging.send_multicast")
    def test_send_multicast_alert_counts_all_tokens_failed_on_exception(self, send_mock):
        send_mock.side_effect = RuntimeError("firebase down")

        result = firebase_service.send_multicast_alert(["token-1", "token-2"], ["Nem"])

        self.assertEqual(result, {"success": 0, "failure": 2})


if __name__ == "__main__":
    unittest.main()
