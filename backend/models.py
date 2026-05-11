from sqlalchemy import Column, Integer, Float, String, DateTime, func
from database import Base

class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id          = Column(Integer, primary_key=True, index=True)
    device_id   = Column(String, index=True)
    temperature = Column(Float, nullable=True)
    humidity    = Column(Float, nullable=True)
    gas_level   = Column(Float, nullable=True)
    light_level = Column(Float, nullable=True)
    distance_cm = Column(Float, nullable=True)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

class DeviceControl(Base):
    __tablename__ = "device_controls"

    id        = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, index=True)
    action    = Column(String)       # "fan_on", "light_off" vs.
    value     = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())