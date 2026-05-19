import os
import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pydantic import ValidationError

import models
import schemas


class SensorReadingModelTests(unittest.TestCase):
    def test_sensor_reading_properties_return_values_from_data(self):
        reading = models.SensorReading(
            sensor_id=1,
            data={
                "temperature": 24.5,
                "humidity": 58,
                "gas_level": 120,
                "light_level": 340,
                "distance_cm": 12.8,
            },
        )

        self.assertEqual(reading.temperature, 24.5)
        self.assertEqual(reading.humidity, 58)
        self.assertEqual(reading.gas_level, 120)
        self.assertEqual(reading.light_level, 340)
        self.assertEqual(reading.distance_cm, 12.8)

    def test_sensor_reading_properties_return_none_when_data_missing(self):
        reading = models.SensorReading(sensor_id=1, data=None)

        self.assertIsNone(reading.temperature)
        self.assertIsNone(reading.humidity)
        self.assertIsNone(reading.gas_level)
        self.assertIsNone(reading.light_level)
        self.assertIsNone(reading.distance_cm)


class SchemaTests(unittest.TestCase):
    def test_control_command_defaults_target_type_and_value(self):
        command = schemas.ControlCommand(target_id=5, action="turn_on")

        self.assertEqual(command.target_type, "device")
        self.assertEqual(command.target_id, 5)
        self.assertEqual(command.action, "turn_on")
        self.assertIsNone(command.value)

    def test_chat_message_create_trims_are_left_to_business_logic(self):
        message = schemas.ChatMessageCreate(text="  Merhaba  ")

        self.assertEqual(message.text, "  Merhaba  ")
        self.assertIsNone(message.target_user_id)

    def test_sensor_create_defaults_active_to_true(self):
        target_user_id = uuid4()

        sensor = schemas.SensorCreate(
            target_user_id=target_user_id,
            sensor_name="Salon Sensoru",
            sensor_type="temperature",
        )

        self.assertEqual(sensor.target_user_id, target_user_id)
        self.assertTrue(sensor.active)
        self.assertIsNone(sensor.room_id)

    def test_user_out_can_validate_from_sqlalchemy_model(self):
        user_id = uuid4()
        user = models.User(
            id=user_id,
            email="user@example.com",
            username="akilli-ev",
            is_admin=False,
            created_at=datetime.now(timezone.utc),
        )

        output = schemas.UserOut.model_validate(user)

        self.assertEqual(output.id, user_id)
        self.assertEqual(output.email, "user@example.com")
        self.assertEqual(output.username, "akilli-ev")
        self.assertFalse(output.is_admin)

    def test_fcm_token_input_requires_token(self):
        with self.assertRaises(ValidationError):
            schemas.FCMTokenIn()


if __name__ == "__main__":
    unittest.main()
