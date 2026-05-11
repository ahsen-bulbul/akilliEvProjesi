import logging
import os
from contextlib import asynccontextmanager
from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import models
import schemas
from database import engine, get_db
from mqtt_client import start_mqtt_client

models.Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
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
    device_id: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(models.SensorReading)
    if device_id:
        query = query.filter(models.SensorReading.device_id == device_id)
    return query.order_by(models.SensorReading.created_at.desc()).limit(limit).all()


@app.get("/sensors/latest", response_model=schemas.SensorReadingOut)
def get_latest_reading(
    device_id: str = "Ankara-RPi-01",
    db: Session = Depends(get_db),
):
    reading = (
        db.query(models.SensorReading)
        .filter(models.SensorReading.device_id == device_id)
        .order_by(models.SensorReading.created_at.desc())
        .first()
    )
    if not reading:
        raise HTTPException(status_code=404, detail="Veri bulunamadi")
    return reading


@app.post("/control")
def send_control_command(
    cmd: schemas.ControlCommand,
    db: Session = Depends(get_db),
):
    log = models.DeviceControl(
        device_id=cmd.device_id,
        action=cmd.action,
        value=cmd.value,
    )
    db.add(log)
    db.commit()

    return {"status": "ok", "action": cmd.action}


@app.get("/health")
def health():
    return {"status": "running"}
