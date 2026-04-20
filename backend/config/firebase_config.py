# credit-risk-fl-project/backend/config/firebase_config.py
"""
Initialises Firebase Admin SDK and exposes a Firestore client.

Usage:
    from config.firebase_config import get_firestore
    db = get_firestore()
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore

# Always use raw string for Windows paths!
SERVICE_KEY_PATH = os.getenv(
    "FIREBASE_SERVICE_KEY",
    r"F:\Atharva\flutter_projects\kredai\firebase\service-account-key.json",
)

def _init_app() -> None:
    """Initialise the default Firebase app exactly once."""
    if not firebase_admin._apps:  # type: ignore
        cred = credentials.Certificate(SERVICE_KEY_PATH)
        firebase_admin.initialize_app(cred)

def get_firestore() -> firestore.Client:  # type: ignore
    """Return a Firestore client instance."""
    _init_app()
    return firestore.client()
