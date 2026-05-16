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
from sqlalchemy import text

import models
import schemas
from database import engine, get_db
from mqtt_client import start_mqtt_client
from firebase_service import initialize_firebase


def _b64url_decode(value: str) -> bytes:
    padded = value + "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(padded.encode("utf-8"))


def _get_auth_payload(authorization: Optional[str]) -> dict:
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
        return json.loads(_b64url_decode(parts[1]))
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Token kullanici bilgisi okunamadi") from exc


def get_current_user_id(authorization: Optional[str] = Header(default=None)) -> UUID:
    payload = _get_auth_payload(authorization)
    try:
        return UUID(payload["sub"])
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Token kullanici bilgisi okunamadi") from exc


def get_current_user_claims(authorization: Optional[str] = Header(default=None)) -> dict:
    payload = _get_auth_payload(authorization)
    try:
        payload["user_id"] = UUID(payload["sub"])
        return payload
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
        with engine.begin() as connection:
            connection.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255)"))
            connection.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(100)"))
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


def _get_profile_username(db: Session, user_id: UUID) -> Optional[str]:
    try:
        row = db.execute(
            text("SELECT username FROM profiles WHERE id = :user_id"),
            {"user_id": str(user_id)},
        ).mappings().first()
        if row:
            return row.get("username")
    except Exception as exc:
        logging.debug("Profil kullanici adi okunamadi: %s", exc)
    return None


def _get_or_create_user(
    db: Session,
    user_id: UUID,
    email: Optional[str] = None,
) -> models.User:
    admin_ids = {
        item.strip()
        for item in os.getenv("ADMIN_USER_IDS", "").split(",")
        if item.strip()
    }
    is_env_admin = str(user_id) in admin_ids
    username = _get_profile_username(db, user_id)
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user:
        changed = False
        if is_env_admin and not user.is_admin:
            user.is_admin = True
            changed = True
        if email and user.email != email:
            user.email = email
            changed = True
        if username and user.username != username:
            user.username = username
            changed = True
        if changed:
            db.commit()
            db.refresh(user)
        return user

    # First local user becomes admin unless explicit ADMIN_USER_IDS is used.
    user_count = db.query(models.User).count()
    is_first_user = user_count == 0 and not admin_ids
    user = models.User(
        id=user_id,
        email=email,
        username=username,
        is_admin=is_env_admin or is_first_user,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _is_user_admin(db: Session, user_id: UUID) -> bool:
    user = db.query(models.User).filter(models.User.id == user_id).first()
    return bool(user and user.is_admin)


def _require_admin(db: Session, user_id: UUID) -> None:
    _get_or_create_user(db, user_id)
    if not _is_user_admin(db, user_id):
        raise HTTPException(status_code=403, detail="Admin yetkisi gerekli")


def _get_target_user(db: Session, target_user_id: UUID) -> models.User:
    user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if user:
        return user
    user = models.User(id=target_user_id, is_admin=False)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _validate_room_for_user(
    db: Session,
    room_id: Optional[int],
    target_user_id: UUID,
) -> None:
    if room_id is None:
        return
    room = (
        db.query(models.Room)
        .filter(models.Room.id == room_id, models.Room.user_id == target_user_id)
        .first()
    )
    if not room:
        raise HTTPException(status_code=404, detail="Oda bu kullaniciya ait degil")


@app.get("/me", response_model=schemas.UserOut)
def get_me(
    claims: dict = Depends(get_current_user_claims),
    db: Session = Depends(get_db),
):
    user = _get_or_create_user(
        db,
        claims["user_id"],
        email=claims.get("email"),
    )
    return user


@app.get("/admin/users", response_model=List[schemas.UserOut])
def list_users(
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    admin_ids = {
        item.strip()
        for item in os.getenv("ADMIN_USER_IDS", "").split(",")
        if item.strip()
    }
    users = (
        db.query(models.User)
        .filter(models.User.is_admin.is_(False))
        .filter(models.User.id != user_id)
        .order_by(models.User.created_at.desc())
        .all()
    )
    users = [user for user in users if str(user.id) not in admin_ids]
    changed = False
    for user in users:
        username = _get_profile_username(db, user.id)
        if username and user.username != username:
            user.username = username
            changed = True
    if changed:
        db.commit()
    return users


@app.delete("/admin/users/{target_user_id}")
def delete_user(
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    if target_user_id == user_id:
        raise HTTPException(status_code=400, detail="Admin kendi hesabini silemez")

    user = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanici bulunamadi")

    db.query(models.DeviceControl).filter(
        models.DeviceControl.user_id == target_user_id
    ).delete(synchronize_session=False)
    db.query(models.Device).filter(
        models.Device.user_id == target_user_id
    ).delete(synchronize_session=False)
    db.query(models.Sensor).filter(
        models.Sensor.user_id == target_user_id
    ).delete(synchronize_session=False)
    db.query(models.Room).filter(
        models.Room.user_id == target_user_id
    ).delete(synchronize_session=False)
    db.delete(user)
    db.commit()
    return {"status": "deleted"}


@app.get("/admin/users/{target_user_id}/rooms", response_model=List[schemas.RoomOut])
def list_user_rooms(
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    _get_target_user(db, target_user_id)
    return (
        db.query(models.Room)
        .filter(models.Room.user_id == target_user_id)
        .order_by(models.Room.name)
        .all()
    )


@app.get("/admin/users/{target_user_id}/devices", response_model=List[schemas.DeviceOut])
def list_user_devices(
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    _get_target_user(db, target_user_id)
    return (
        db.query(models.Device)
        .filter(models.Device.user_id == target_user_id)
        .order_by(models.Device.device_name)
        .all()
    )


@app.get("/admin/users/{target_user_id}/sensors", response_model=List[schemas.SensorOut])
def list_user_sensors(
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    _get_target_user(db, target_user_id)
    return (
        db.query(models.Sensor)
        .filter(models.Sensor.user_id == target_user_id)
        .order_by(models.Sensor.sensor_name)
        .all()
    )


@app.post("/admin/rooms", response_model=schemas.RoomOut)
def create_room(
    payload: schemas.RoomCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    _get_target_user(db, payload.target_user_id)

    room = models.Room(user_id=payload.target_user_id, name=payload.name)
    db.add(room)
    db.commit()
    db.refresh(room)
    return room


@app.delete("/admin/rooms/{room_id}")
def delete_room(
    room_id: int,
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    room = (
        db.query(models.Room)
        .filter(models.Room.id == room_id, models.Room.user_id == target_user_id)
        .first()
    )
    if not room:
        raise HTTPException(status_code=404, detail="Oda bulunamadi")

    db.query(models.Device).filter(
        models.Device.room_id == room_id,
        models.Device.user_id == target_user_id,
    ).delete(synchronize_session=False)
    db.query(models.Sensor).filter(
        models.Sensor.room_id == room_id,
        models.Sensor.user_id == target_user_id,
    ).delete(synchronize_session=False)
    db.delete(room)
    db.commit()
    return {"status": "deleted"}


@app.post("/admin/sensors", response_model=schemas.SensorOut)
def create_sensor(
    payload: schemas.SensorCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    _get_target_user(db, payload.target_user_id)
    _validate_room_for_user(db, payload.room_id, payload.target_user_id)

    sensor = models.Sensor(
        user_id=payload.target_user_id,
        sensor_name=payload.sensor_name,
        sensor_type=payload.sensor_type,
        room_id=payload.room_id,
        active=payload.active,
    )
    db.add(sensor)
    db.commit()
    db.refresh(sensor)
    return sensor


@app.delete("/admin/sensors/{sensor_id}")
def delete_sensor(
    sensor_id: int,
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    sensor = (
        db.query(models.Sensor)
        .filter(models.Sensor.id == sensor_id, models.Sensor.user_id == target_user_id)
        .first()
    )
    if not sensor:
        raise HTTPException(status_code=404, detail="Sensor bulunamadi")
    db.delete(sensor)
    db.commit()
    return {"status": "deleted"}


@app.post("/admin/devices", response_model=schemas.DeviceOut)
def create_device(
    payload: schemas.DeviceCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    _get_target_user(db, payload.target_user_id)
    _validate_room_for_user(db, payload.room_id, payload.target_user_id)

    device = models.Device(
        user_id=payload.target_user_id,
        device_name=payload.device_name,
        device_type=payload.device_type,
        room_id=payload.room_id,
    )
    db.add(device)
    db.commit()
    db.refresh(device)
    return device


@app.delete("/admin/devices/{device_id}")
def delete_device(
    device_id: int,
    target_user_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    _require_admin(db, user_id)
    device = (
        db.query(models.Device)
        .filter(models.Device.id == device_id, models.Device.user_id == target_user_id)
        .first()
    )
    if not device:
        raise HTTPException(status_code=404, detail="Cihaz bulunamadi")
    db.delete(device)
    db.commit()
    return {"status": "deleted"}


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
