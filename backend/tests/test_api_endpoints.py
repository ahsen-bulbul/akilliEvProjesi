import os
import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch
from uuid import uuid4

os.environ["DATABASE_URL"] = "sqlite:///:memory:"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi import HTTPException

import main
import schemas


class ApiEndpointTests(unittest.TestCase):
    def setUp(self):
        self.user_id = uuid4()
        self.db = Mock()

    def test_health_endpoint_returns_running(self):
        response = main.health()

        self.assertEqual(response, {"status": "running"})

    def test_me_endpoint_returns_current_user_from_claims(self):
        user = SimpleNamespace(
            id=self.user_id,
            email="user@example.com",
            username="akilli-ev",
            is_admin=False,
        )

        with patch("main._get_or_create_user", return_value=user) as get_user:
            response = main.get_me(
                claims={"user_id": self.user_id, "email": "user@example.com"},
                db=self.db,
            )

        self.assertEqual(response.email, "user@example.com")
        self.assertFalse(response.is_admin)
        get_user.assert_called_once_with(self.db, self.user_id, email="user@example.com")

    def test_chat_endpoint_rejects_blank_message(self):
        with patch("main._get_or_create_user", return_value=SimpleNamespace(is_admin=False)):
            with self.assertRaises(HTTPException) as context:
                main.create_chat_message(
                    schemas.ChatMessageCreate(text="   "),
                    user_id=self.user_id,
                    db=self.db,
                )

        self.assertEqual(context.exception.status_code, 400)
        self.assertEqual(context.exception.detail, "Mesaj bos olamaz")
        self.db.commit.assert_not_called()

    def test_chat_messages_admin_requires_target_user(self):
        with patch("main._get_or_create_user", return_value=SimpleNamespace(is_admin=True)):
            with self.assertRaises(HTTPException) as context:
                main.list_chat_messages(user_id=self.user_id, db=self.db)

        self.assertEqual(context.exception.status_code, 400)
        self.assertEqual(context.exception.detail, "Hedef kullanici gerekli")

    def test_control_endpoint_rejects_missing_device_without_commit(self):
        self.db.query.return_value.filter.return_value.first.return_value = None

        with self.assertRaises(HTTPException) as context:
            main.send_control_command(
                schemas.ControlCommand(target_id=999, action="turn_on"),
                user_id=self.user_id,
                db=self.db,
            )

        self.assertEqual(context.exception.status_code, 404)
        self.assertEqual(context.exception.detail, "Cihaz bulunamadi")
        self.db.commit.assert_not_called()

    def test_admin_users_endpoint_rejects_non_admin(self):
        with patch("main._get_or_create_user"), patch("main._is_user_admin", return_value=False):
            with self.assertRaises(HTTPException) as context:
                main.list_users(user_id=self.user_id, db=self.db)

        self.assertEqual(context.exception.status_code, 403)
        self.assertEqual(context.exception.detail, "Admin yetkisi gerekli")

    def test_fcm_token_endpoint_creates_new_token(self):
        token = SimpleNamespace(
            id=1,
            token="fcm-token-1",
            created_at=datetime.now(timezone.utc),
        )
        self.db.query.return_value.filter.return_value.first.return_value = None
        self.db.refresh.side_effect = lambda obj: setattr(obj, "id", token.id) or setattr(
            obj,
            "created_at",
            token.created_at,
        )

        response = main.register_fcm_token(
            schemas.FCMTokenIn(token=token.token),
            db=self.db,
        )

        self.assertEqual(response.token, "fcm-token-1")
        self.db.add.assert_called_once()
        self.db.commit.assert_called_once()

    def test_control_endpoint_turns_device_on(self):
        device = SimpleNamespace(status=False)
        self.db.query.return_value.filter.return_value.first.return_value = device

        response = main.send_control_command(
            schemas.ControlCommand(target_id=1, action="turn_on"),
            user_id=self.user_id,
            db=self.db,
        )

        self.assertEqual(response, {"status": "ok", "action": "turn_on"})
        self.assertTrue(device.status)
        self.db.commit.assert_called_once()

    def test_setup_status_endpoint_returns_counts(self):
        counts = {
            "is_configured": True,
            "room_count": 2,
            "device_count": 3,
            "sensor_count": 4,
            "package_id": "studio",
            "home_city": "Trabzon",
        }

        with patch("main._setup_counts", return_value=counts) as setup_counts:
            response = main.get_setup_status(user_id=self.user_id, db=self.db)

        self.assertEqual(response, counts)
        setup_counts.assert_called_once_with(self.db, self.user_id)


if __name__ == "__main__":
    unittest.main()
