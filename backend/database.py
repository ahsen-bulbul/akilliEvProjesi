import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


def load_env_file(path):
    if not os.path.exists(path):
        return

    with open(path, encoding="utf-8") as env_file:
        for line in env_file:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_env_file(".env")
load_env_file(Path(__file__).with_name(".env"))

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable tanimli degil")

engine_kwargs = {"pool_pre_ping": True}
if not DATABASE_URL.startswith("sqlite"):
    engine_kwargs.update(
        {
            "connect_args": {"sslmode": "require"},
            "pool_size": 5,
            "max_overflow": 10,
        }
    )

engine = create_engine(DATABASE_URL, **engine_kwargs)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
