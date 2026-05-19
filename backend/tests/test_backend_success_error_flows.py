import json
import os
import sys
import unittest
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, Mock, patch
from uuid import uuid4

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi import HTTPException

import main
import models
import schemas


class _FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def read(self):
        return json.dumps(self._payload).encode("utf-8")


@contextmanager
def _urlopen_payload(payload):
    yield _FakeResponse(payload)


class AuthErrorFlowTests(unittest.TestCase):
    def test_malformed_token_raises_401(self):
        with self.assertRaises(HTTPException) as context:
            main.get_current_user_id("Bearer not-a-jwt")

        self.assertEqual(context.exception.status_code, 401)
        self.assertEqual(context.exception.detail, "Gecersiz token")

    def test_token_without_uuid_sub_raises_401(self):
        token = "a." + "eyJzdWIiOiAibm90LXV1aWQifQ" + ".c"

        with self.assertRaises(HTTPException) as context:
            main.get_current_user_id(f"Bearer {token}")

        self.assertEqual(context.exception.status_code, 401)
        self.assertEqual(context.exception.detail, "Token kullanici bilgisi okunamadi")


class WeatherAndGeocodeFlowTests(unittest.TestCase):
    @patch("main.urllib.request.urlopen")
    def test_get_current_weather_returns_weather_payload(self, urlopen_mock):
        user = SimpleNamespace(
            home_latitude="41.0",
            home_longitude="39.7",
            home_city="Trabzon",
        )
        urlopen_mock.return_value = _urlopen_payload(
            {
                "current": {
                    "temperature_2m": 23.4,
                    "relative_humidity_2m": 60,
                    "apparent_temperature": 24.0,
                    "weather_code": 61,
                    "wind_speed_10m": 8.2,
                    "is_day": 1,
                    "time": "2026-05-19T12:00",
                },
                "daily": {"uv_index_max": [5.6]},
            }
        )

        with patch("main._get_or_create_user", return_value=user):
            result = main.get_current_weather(user_id=uuid4(), db=Mock())

        self.assertEqual(result["location"], "Trabzon")
        self.assertEqual(result["temperature"], 23.4)
        self.assertEqual(result["condition"], "Yagmurlu")
        self.assertTrue(result["is_day"])

    @patch("main.urllib.request.urlopen")
    def test_get_current_weather_raises_502_when_temperature_missing(self, urlopen_mock):
        user = SimpleNamespace(home_latitude=None, home_longitude=None, home_city=None)
        urlopen_mock.return_value = _urlopen_payload({"current": {}, "daily": {}})

        with patch("main._get_or_create_user", return_value=user):
            with self.assertRaises(HTTPException) as context:
                main.get_current_weather(user_id=uuid4(), db=Mock())

        self.assertEqual(context.exception.status_code, 502)
        self.assertEqual(context.exception.detail, "Hava durumu yaniti eksik")

    @patch("main.urllib.request.urlopen", side_effect=RuntimeError("network down"))
    def test_get_current_weather_raises_503_when_service_fails(self, _):
        user = SimpleNamespace(home_latitude=None, home_longitude=None, home_city=None)

        with patch("main._get_or_create_user", return_value=user):
            with self.assertRaises(HTTPException) as context:
                main.get_current_weather(user_id=uuid4(), db=Mock())

        self.assertEqual(context.exception.status_code, 503)

    @patch("main.urllib.request.urlopen")
    def test_geocode_city_returns_first_result(self, urlopen_mock):
        urlopen_mock.return_value = _urlopen_payload(
            {"results": [{"name": "Trabzon", "country": "Turkiye", "latitude": 41.0, "longitude": 39.7}]}
        )

        latitude, longitude, display_name = main._geocode_city(" Trabzon ")

        self.assertEqual(latitude, "41.0")
        self.assertEqual(longitude, "39.7")
        self.assertEqual(display_name, "Trabzon, Turkiye")

    @patch("main.urllib.request.urlopen")
    def test_geocode_city_returns_clean_city_when_no_result(self, urlopen_mock):
        urlopen_mock.return_value = _urlopen_payload({"results": []})

        latitude, longitude, display_name = main._geocode_city(" Rize ")

        self.assertIsNone(latitude)
        self.assertIsNone(longitude)
        self.assertEqual(display_name, "Rize")


class AdminAndSetupFlowTests(unittest.TestCase):
    def test_require_admin_allows_admin_user(self):
        with patch("main._get_or_create_user"), patch("main._is_user_admin", return_value=True):
            main._require_admin(Mock(), uuid4())

    def test_require_admin_rejects_non_admin_user(self):
        with patch("main._get_or_create_user"), patch("main._is_user_admin", return_value=False):
            with self.assertRaises(HTTPException) as context:
                main._require_admin(Mock(), uuid4())

        self.assertEqual(context.exception.status_code, 403)
        self.assertEqual(context.exception.detail, "Admin yetkisi gerekli")

    def test_validate_room_for_user_allows_none_room(self):
        db = Mock()

        main._validate_room_for_user(db, None, uuid4())

        db.query.assert_not_called()

    def test_validate_room_for_user_rejects_missing_room(self):
        db = Mock()
        db.query.return_value.filter.return_value.first.return_value = None

        with self.assertRaises(HTTPException) as context:
            main._validate_room_for_user(db, 10, uuid4())

        self.assertEqual(context.exception.status_code, 404)
        self.assertEqual(context.exception.detail, "Oda bu kullaniciya ait degil")

    def test_create_setup_package_creates_studio_package(self):
        db = MagicMock()
        user_id = uuid4()
        user = SimpleNamespace(
            home_city=None,
            home_latitude=None,
            home_longitude=None,
            setup_package=None,
        )

        with patch("main._setup_counts", return_value={"room_count": 0}), patch(
            "main._get_or_create_user", return_value=user
        ), patch("main._geocode_city", return_value=("41.0", "39.7", "Trabzon")):
            result = main._create_setup_package(db, user_id, "studio", "Trabzon")

        self.assertEqual(result["package_id"], "studio")
        self.assertEqual(result["home_city"], "Trabzon")
        self.assertEqual(result["room_count"], 3)
        self.assertEqual(result["device_count"], 4)
        self.assertEqual(result["sensor_count"], 5)
        self.assertEqual(user.setup_package, "studio")
        db.commit.assert_called_once()

    def test_create_setup_package_rejects_invalid_package(self):
        with self.assertRaises(HTTPException) as context:
            main._create_setup_package(Mock(), uuid4(), "unknown", "Trabzon")

        self.assertEqual(context.exception.status_code, 400)
        self.assertEqual(context.exception.detail, "Gecersiz paket")

    def test_create_setup_package_rejects_already_configured_user(self):
        with patch("main._setup_counts", return_value={"room_count": 1}):
            with self.assertRaises(HTTPException) as context:
                main._create_setup_package(Mock(), uuid4(), "studio", "Trabzon")

        self.assertEqual(context.exception.status_code, 409)
        self.assertEqual(context.exception.detail, "Kullanici kurulumu zaten yapilmis")


class ControlAndChatFlowTests(unittest.TestCase):
    def test_send_control_command_turns_device_on(self):
        db = Mock()
        device = SimpleNamespace(status=False)
        db.query.return_value.filter.return_value.first.return_value = device

        result = main.send_control_command(
            schemas.ControlCommand(target_id=1, action="turn_on"),
            user_id=uuid4(),
            db=db,
        )

        self.assertEqual(result, {"status": "ok", "action": "turn_on"})
        self.assertTrue(device.status)
        db.add.assert_called_once()
        db.commit.assert_called_once()

    def test_send_control_command_turns_device_off(self):
        db = Mock()
        device = SimpleNamespace(status=True)
        db.query.return_value.filter.return_value.first.return_value = device

        main.send_control_command(
            schemas.ControlCommand(target_id=1, action="turn_off"),
            user_id=uuid4(),
            db=db,
        )

        self.assertFalse(device.status)

    def test_send_control_command_rejects_missing_device(self):
        db = Mock()
        db.query.return_value.filter.return_value.first.return_value = None

        with self.assertRaises(HTTPException) as context:
            main.send_control_command(
                schemas.ControlCommand(target_id=99, action="turn_on"),
                user_id=uuid4(),
                db=db,
            )

        self.assertEqual(context.exception.status_code, 404)
        self.assertEqual(context.exception.detail, "Cihaz bulunamadi")
        db.commit.assert_not_called()

    def test_create_chat_message_rejects_blank_text(self):
        with patch("main._get_or_create_user", return_value=SimpleNamespace(is_admin=False)):
            with self.assertRaises(HTTPException) as context:
                main.create_chat_message(
                    schemas.ChatMessageCreate(text="   "),
                    user_id=uuid4(),
                    db=Mock(),
                )

        self.assertEqual(context.exception.status_code, 400)
        self.assertEqual(context.exception.detail, "Mesaj bos olamaz")

    def test_create_chat_message_user_sends_to_first_admin(self):
        db = Mock()
        user_id = uuid4()
        admin_id = uuid4()

        with patch("main._get_or_create_user", return_value=SimpleNamespace(is_admin=False)), patch(
            "main._get_first_admin", return_value=SimpleNamespace(id=admin_id)
        ):
            message = main.create_chat_message(
                schemas.ChatMessageCreate(text=" Merhaba admin "),
                user_id=user_id,
                db=db,
            )

        self.assertEqual(message.user_id, user_id)
        self.assertEqual(message.sender_id, user_id)
        self.assertEqual(message.receiver_id, admin_id)
        self.assertEqual(message.text, "Merhaba admin")
        db.add.assert_called_once()
        db.commit.assert_called_once()
        db.refresh.assert_called_once_with(message)

    def test_create_chat_message_admin_requires_target_user(self):
        with patch("main._get_or_create_user", return_value=SimpleNamespace(is_admin=True)):
            with self.assertRaises(HTTPException) as context:
                main.create_chat_message(
                    schemas.ChatMessageCreate(text="Merhaba"),
                    user_id=uuid4(),
                    db=Mock(),
                )

        self.assertEqual(context.exception.status_code, 400)
        self.assertEqual(context.exception.detail, "Hedef kullanici gerekli")

    def test_create_chat_message_admin_sends_to_target_user(self):
        db = Mock()
        admin_id = uuid4()
        target_id = uuid4()

        with patch("main._get_or_create_user", return_value=SimpleNamespace(is_admin=True)), patch(
            "main._get_target_user", return_value=SimpleNamespace(id=target_id)
        ):
            message = main.create_chat_message(
                schemas.ChatMessageCreate(text="Merhaba", target_user_id=target_id),
                user_id=admin_id,
                db=db,
            )

        self.assertEqual(message.user_id, target_id)
        self.assertEqual(message.sender_id, admin_id)
        self.assertEqual(message.receiver_id, target_id)
        self.assertEqual(message.text, "Merhaba")


class FCMTokenFlowTests(unittest.TestCase):
    def test_register_fcm_token_creates_new_token(self):
        db = Mock()
        db.query.return_value.filter.return_value.first.return_value = None
        token_data = schemas.FCMTokenIn(token="token-1")

        result = main.register_fcm_token(token_data, db=db)

        self.assertIsInstance(result, models.FCMToken)
        self.assertEqual(result.token, "token-1")
        db.add.assert_called_once_with(result)
        db.commit.assert_called_once()
        db.refresh.assert_called_once_with(result)

    def test_register_fcm_token_updates_existing_token(self):
        db = Mock()
        existing = SimpleNamespace(token="token-1", updated_at=None)
        db.query.return_value.filter.return_value.first.return_value = existing

        result = main.register_fcm_token(schemas.FCMTokenIn(token="token-1"), db=db)

        self.assertIs(result, existing)
        self.assertIsNotNone(existing.updated_at)
        db.add.assert_not_called()
        db.commit.assert_called_once()

    def test_register_fcm_token_rolls_back_and_raises_500_on_error(self):
        db = Mock()
        db.query.side_effect = RuntimeError("db down")

        with self.assertRaises(HTTPException) as context:
            main.register_fcm_token(schemas.FCMTokenIn(token="token-1"), db=db)

        self.assertEqual(context.exception.status_code, 500)
        self.assertEqual(context.exception.detail, "FCM token kaydedilemedi")
        db.rollback.assert_called_once()


class HealthFlowTests(unittest.TestCase):
    def test_health_returns_running_status(self):
        self.assertEqual(main.health(), {"status": "running"})


if __name__ == "__main__":
    unittest.main()
