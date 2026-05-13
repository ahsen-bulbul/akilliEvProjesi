from pydantic import BaseModel
from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID


class RoomOut(BaseModel):
    id: int
    user_id: UUID
    name: str
    created_at: datetime

    class Config:
        from_attributes = True


class DeviceOut(BaseModel):
    id: int
    user_id: UUID
    room_id: Optional[int]
    device_name: str
    device_type: str
    status: bool
    created_at: datetime

    class Config:
        from_attributes = True


class SensorOut(BaseModel):
    id: int
    user_id: UUID
    room_id: Optional[int]
    sensor_name: str
    sensor_type: str
    active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class SensorReadingOut(BaseModel):
    id: int
    sensor_id: int
    sensor_name: Optional[str] = None
    sensor_type: Optional[str] = None
    data: Dict[str, Any]
    temperature: Optional[float]
    humidity:    Optional[float]
    gas_level:   Optional[float]
    light_level: Optional[float]
    distance_cm: Optional[float]
    created_at:  datetime

    class Config:
        from_attributes = True

class ControlCommand(BaseModel):
    target_type: str = "device"
    target_id: int
    action: str
    value: Optional[str] = None


class FCMTokenIn(BaseModel):
    token: str


class FCMTokenOut(BaseModel):
    id: int
    token: str
    created_at: datetime

    class Config:
        from_attributes = True

