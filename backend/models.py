from sqlalchemy import Boolean, Column, DateTime, Integer, String, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from database import Base


class Room(Base):
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    name = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    room_id = Column(Integer, index=True, nullable=True)
    device_name = Column(String(100), nullable=False)
    device_type = Column(String(50), nullable=False)
    status = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Sensor(Base):
    __tablename__ = "sensors"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    room_id = Column(Integer, index=True, nullable=True)
    sensor_name = Column(String(100), nullable=False)
    sensor_type = Column(String(50), nullable=False)
    active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id = Column(Integer, primary_key=True, index=True)
    sensor_id = Column(Integer, index=True, nullable=False)
    data = Column(JSONB, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    sensor_name = None
    sensor_type = None

    @property
    def temperature(self):
        return self.data.get("temperature") if self.data else None

    @property
    def humidity(self):
        return self.data.get("humidity") if self.data else None

    @property
    def gas_level(self):
        return self.data.get("gas_level") if self.data else None

    @property
    def light_level(self):
        return self.data.get("light_level") if self.data else None

    @property
    def distance_cm(self):
        return self.data.get("distance_cm") if self.data else None


class DeviceControl(Base):
    __tablename__ = "device_controls"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    target_type = Column(String(20), nullable=False)
    target_id = Column(Integer, nullable=False)
    action = Column(String(50), nullable=False)
    value = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class FCMToken(Base):
    __tablename__ = "fcm_tokens"

    id = Column(Integer, primary_key=True, index=True)
    token = Column(String(255), unique=True, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

