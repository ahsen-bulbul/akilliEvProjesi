from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Supabase → Settings → Database → Connection string (URI) kısmından al
# "Transaction" modunu kullan (port 6543) — connection pooling için
DATABASE_URL = (
    "postgresql://postgres.hhmgdtqznfcatkblmouq:7YTyHu2kTK178rGR"
    "@aws-1-ap-southeast-2.pooler.supabase.com:5432/postgres"
)

# SSL zorunlu — Supabase bağlantısı şifresiz kabul etmez
engine = create_engine(
    DATABASE_URL,
    connect_args={"sslmode": "require"},
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True   # kopuk bağlantıları otomatik temizler
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()