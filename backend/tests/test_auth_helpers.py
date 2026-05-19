import base64
import hashlib
import hmac
import json
import os
import sys
import unittest
from pathlib import Path
from uuid import UUID, uuid4

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi import HTTPException

import main


def _b64url(data):
    encoded = base64.urlsafe_b64encode(json.dumps(data).encode("utf-8"))
    return encoded.rstrip(b"=").decode("utf-8")


def _token(payload, secret=None):
    header = _b64url({"alg": "HS256", "typ": "JWT"})
    body = _b64url(payload)
    signing_input = f"{header}.{body}".encode("utf-8")
    if secret:
        signature = hmac.new(secret.encode("utf-8"), signing_input, hashlib.sha256).digest()
        signed = base64.urlsafe_b64encode(signature).rstrip(b"=").decode("utf-8")
    else:
        signed = "signature"
    return f"{header}.{body}.{signed}"


class AuthHelperTests(unittest.TestCase):
    def tearDown(self):
        os.environ.pop("SUPABASE_JWT_SECRET", None)

    def test_get_current_user_id_reads_sub_claim(self):
        user_id = uuid4()
        token = _token({"sub": str(user_id), "email": "user@example.com"})

        result = main.get_current_user_id(f"Bearer {token}")

        self.assertEqual(result, user_id)
        self.assertIsInstance(result, UUID)

    def test_get_current_user_claims_adds_uuid_user_id(self):
        user_id = uuid4()
        token = _token({"sub": str(user_id), "role": "authenticated"})

        claims = main.get_current_user_claims(f"Bearer {token}")

        self.assertEqual(claims["sub"], str(user_id))
        self.assertEqual(claims["user_id"], user_id)
        self.assertEqual(claims["role"], "authenticated")

    def test_missing_bearer_token_raises_401(self):
        with self.assertRaises(HTTPException) as context:
            main.get_current_user_id(None)

        self.assertEqual(context.exception.status_code, 401)
        self.assertEqual(context.exception.detail, "Oturum gerekli")

    def test_invalid_signature_raises_401_when_secret_is_configured(self):
        os.environ["SUPABASE_JWT_SECRET"] = "test-secret"
        token = _token({"sub": str(uuid4())}, secret="wrong-secret")

        with self.assertRaises(HTTPException) as context:
            main.get_current_user_id(f"Bearer {token}")

        self.assertEqual(context.exception.status_code, 401)
        self.assertEqual(context.exception.detail, "Token dogrulanamadi")


if __name__ == "__main__":
    unittest.main()
