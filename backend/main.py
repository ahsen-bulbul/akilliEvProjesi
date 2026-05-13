import base64
import hashlib
import hmac
import json
import logging
import os
from contextlib import asynccontextmanager
from typing import List, Optional
from uuid import UUID

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import models
import schemas
from database import engine, get_db
from mqtt_client import start_mqtt_client
from firebase_service import initialize_firebase

models.Base.metadata.create_all(bind=engine)


def _b64url_decode(value: str) -> bytes:
    padded = value + "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(padded.encode("utf-8"))


def get_current_user_id(authorization: Optional[str] = Header(default=None)) -> UUID:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Oturum gerekli")

    token = authorization.removeprefix("Bearer ").strip()
    parts = token.split(".")
    if len(parts) != 3:
        raise HTTPException(status_code=401, detail="Gecersiz token")

    secret = os.getenv("SUPABASE_JWT_SECRET")
    if secret:
        signed = f"{parts[0]}.{parts[1]}".encode("utf-8")
        expected = hmac.new(secret.encode("utf-8"), signed, hashlib.sha256).digest()
        received = _b64url_decode(parts[2])
        if not hmac.compare_digest(expected, received):
            raise HTTPException(status_code=401, detail="Token dogrulanamadi")

    try:
        payload = json.loads(_b64url_decode(parts[1]))
        return UUID(payload["sub"])
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Token kullanici bilgisi okunamadi") from exc


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Firebase initialize et
    initialize_firebase()
    
    # MQTT başlat
    if os.getenv("ENABLE_MQTT") == "1":
        try:
            start_mqtt_client()
        except Exception as exc:
            logging.warning("MQTT subscriber baslatilamadi: %s", exc)
    yield


app = FastAPI(title="Smart Home API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/sensors", response_model=List[schemas.SensorReadingOut])
def get_sensor_readings(
    limit: int = 50,
    sensor_id: Optional[int] = None,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    query = (
        db.query(models.SensorReading, models.Sensor)
        .join(models.Sensor, models.Sensor.id == models.SensorReading.sensor_id)
        .filter(models.Sensor.user_id == user_id)
    )
    if sensor_id:
        query = query.filter(models.SensorReading.sensor_id == sensor_id)

    rows = query.order_by(models.SensorReading.created_at.desc()).limit(limit).all()
    readings = []
    for reading, sensor in rows:
        reading.sensor_name = sensor.sensor_name
        reading.sensor_type = sensor.sensor_type
        readings.append(reading)
    return readings


@app.get("/sensors/latest", response_model=schemas.SensorReadingOut)
def get_latest_reading(
    sensor_id: Optional[int] = None,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    query = (
        db.query(models.SensorReading, models.Sensor)
        .join(models.Sensor, models.Sensor.id == models.SensorReading.sensor_id)
        .filter(models.Sensor.user_id == user_id)
    )
    if sensor_id:
        query = query.filter(models.SensorReading.sensor_id == sensor_id)

    row = query.order_by(models.SensorReading.created_at.desc()).first()
    if not row:
        raise HTTPException(status_code=404, detail="Veri bulunamadi")
    reading, sensor = row
    reading.sensor_name = sensor.sensor_name
    reading.sensor_type = sensor.sensor_type
    return reading


@app.get("/rooms", response_model=List[schemas.RoomOut])
def get_rooms(
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    return db.query(models.Room).filter(models.Room.user_id == user_id).order_by(models.Room.name).all()


@app.get("/devices", response_model=List[schemas.DeviceOut])
def get_devices(
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.Device)
        .filter(models.Device.user_id == user_id)
        .order_by(models.Device.device_name)
        .all()
    )


@app.get("/sensor-definitions", response_model=List[schemas.SensorOut])
def get_sensors(
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.Sensor)
        .filter(models.Sensor.user_id == user_id)
        .order_by(models.Sensor.sensor_name)
        .all()
    )


@app.post("/control")
def send_control_command(
    cmd: schemas.ControlCommand,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    log = models.DeviceControl(
        user_id=user_id,
        target_type=cmd.target_type,
        target_id=cmd.target_id,
        action=cmd.action,
        value=cmd.value,
    )
    db.add(log)

    if cmd.target_type == "device":
        device = (
            db.query(models.Device)
            .filter(models.Device.id == cmd.target_id, models.Device.user_id == user_id)
            .first()
        )
        if not device:
            raise HTTPException(status_code=404, detail="Cihaz bulunamadi")
        if cmd.action in {"turn_on", "on", "device_on"}:
            device.status = True
        elif cmd.action in {"turn_off", "off", "device_off"}:
            device.status = False

    db.commit()

    return {"status": "ok", "action": cmd.action}


@app.post("/fcm-token", response_model=schemas.FCMTokenOut)
def register_fcm_token(
    token_data: schemas.FCMTokenIn,
    db: Session = Depends(get_db),
):
    """FCM token kaydını oluştur veya güncelle"""
    try:
        # Mevcut token'ı kontrol et
        existing = db.query(models.FCMToken).filter(
            models.FCMToken.token == token_data.token
        ).first()
        
        if existing:
            # Zaten varsa updated_at'i güncelle
            existing.updated_at = db.func.now()
            db.commit()
            return existing
        else:
            # Yeni token oluştur
            new_token = models.FCMToken(token=token_data.token)
            db.add(new_token)
            db.commit()
            db.refresh(new_token)
            return new_token
    except Exception as e:
        logging.error(f"Error registering FCM token: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="FCM token kaydedilemedi")


@app.get("/health")
def health():
    return {"status": "running"}
