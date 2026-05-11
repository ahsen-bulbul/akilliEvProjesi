from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class SensorReadingOut(BaseModel):
    id:          int
    device_id:   str
    temperature: Optional[float]
    humidity:    Optional[float]
    gas_level:   Optional[float]
    light_level: Optional[float]
    distance_cm: Optional[float]
    created_at:  datetime

    class Config:
        from_attributes = True

class ControlCommand(BaseModel):
    device_id: str
    action:    str
    value:     Optional[str] = None