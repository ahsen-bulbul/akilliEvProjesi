import base64
import hashlib
import hmac
import json
import logging
import os
import urllib.parse
import urllib.request
from contextlib import asynccontextmanager
from typing import List, Optional
from uuid import UUID

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import func
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

import models
import schemas
from database import engine, get_db
from mqtt_client import start_mqtt_client
from firebase_service import initialize_firebase


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


def _weather_condition(code: Optional[int]) -> str:
    if code is None:
        return "Bilinmiyor"
    if code == 0:
        return "Acik"
    if code in {1, 2}:
        return "Parcali bulutlu"
    if code == 3:
        return "Bulutlu"
    if code in {45, 48}:
        return "Sisli"
    if code in {51, 53, 55, 56, 57}:
        return "Cisenti"
    if code in {61, 63, 65, 66, 67, 80, 81, 82}:
        return "Yagmurlu"
    if code in {71, 73, 75, 77, 85, 86}:
        return "Karli"
    if code in {95, 96, 99}:
        return "Firtinali"
    return "Degisken"


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        models.Base.metadata.create_all(bind=engine)
    except SQLAlchemyError as exc:
        logging.warning("Veritabani semasi kontrol edilemedi: %s", exc)

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


@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    logging.warning("Veritabani gecici olarak kullanilamiyor: %s", exc)
    return JSONResponse(
        status_code=503,
        content={"detail": "Veritabani gecici olarak kullanilamiyor."},
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


@app.get("/weather/current", response_model=schemas.WeatherOut)
def get_current_weather(
    user_id: UUID = Depends(get_current_user_id),
):
    del user_id
    latitude = os.getenv("HOME_LATITUDE", "41.0027")
    longitude = os.getenv("HOME_LONGITUDE", "39.7168")
    location = os.getenv("HOME_LOCATION_NAME", "Trabzon")

    params = urllib.parse.urlencode(
        {
            "latitude": latitude,
            "longitude": longitude,
            "current": ",".join(
                [
                    "temperature_2m",
                    "relative_humidity_2m",
                    "apparent_temperature",
                    "weather_code",
                    "wind_speed_10m",
                    "is_day",
                ]
            ),
            "daily": "uv_index_max",
            "timezone": "auto",
        }
    )
    url = f"https://api.open-meteo.com/v1/forecast?{params}"

    try:
        with urllib.request.urlopen(url, timeout=8) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except Exception as exc:
        logging.warning("Hava durumu servisi okunamadi: %s", exc)
        raise HTTPException(status_code=503, detail="Hava durumu servisi gecici olarak kullanilamiyor")

    current = payload.get("current") or {}
    daily = payload.get("daily") or {}
    temperature = current.get("temperature_2m")
    if temperature is None:
        raise HTTPException(status_code=502, detail="Hava durumu yaniti eksik")

    weather_code = current.get("weather_code")
    uv_index = (daily.get("uv_index_max") or [None])[0]

    return {
        "location": location,
        "temperature": temperature,
        "apparent_temperature": current.get("apparent_temperature"),
        "humidity": current.get("relative_humidity_2m"),
        "wind_speed": current.get("wind_speed_10m"),
        "uv_index": uv_index,
        "condition": _weather_condition(weather_code),
        "weather_code": weather_code,
        "is_day": current.get("is_day") == 1,
        "observed_at": current.get("time"),
    }


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
            existing.updated_at = func.now()
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
