# backend/services/firebase_service.py
"""
Firebase Service for Firestore Operations

Handles all Firebase Firestore interactions for user and application data.
"""

from config.firebase_config import get_firestore
from google.cloud.firestore import Client
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)

class FirebaseService:
    """Service for Firebase Firestore operations"""
    
    def __init__(self):
        self.db: Client = get_firestore()
        
    def create_user(self, user_id: str, user_data: Dict[str, Any]):
        """Create a new user document"""
        try:
            user_ref = self.db.collection('users').document(user_id)
            user_ref.set(user_data)
            logger.info(f"User created in Firestore: {user_id}")
            
        except Exception as e:
            logger.error(f"Error creating user in Firestore: {str(e)}")
            raise
    
    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user document by ID"""
        try:
            user_ref = self.db.collection('users').document(user_id)
            user_doc = user_ref.get()
            
            if user_doc.exists:
                return user_doc.to_dict()
            return None
            
        except Exception as e:
            logger.error(f"Error getting user from Firestore: {str(e)}")
            raise
    
    def store_application(self, user_id: str, application_id: str, application_data: Dict[str, Any]):
        """Store credit application in user's subcollection"""
        try:
            app_ref = self.db.collection('users').document(user_id).collection('applications').document(application_id)
            app_ref.set(application_data)
            logger.info(f"Application stored: {application_id}")
            
        except Exception as e:
            logger.error(f"Error storing application: {str(e)}")
            raise
    
    def get_application(self, application_id: str) -> Optional[Dict[str, Any]]:
        """Get application by ID (searches across all users)"""
        try:
            # This is a simplified approach - in production, you might want to index by application_id
            users = self.db.collection('users').stream()
            
            for user in users:
                app_ref = self.db.collection('users').document(user.id).collection('applications').document(application_id)
                app_doc = app_ref.get()
                
                if app_doc.exists:
                    return app_doc.to_dict()
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting application: {str(e)}")
            raise
    
    def get_user_applications(self, user_id: str, limit: int = 10, offset: int = 0) -> List[Dict[str, Any]]:
        """Get user's applications with pagination"""
        try:
            apps_ref = self.db.collection('users').document(user_id).collection('applications')
            
            # Order by submission time, most recent first
            query = apps_ref.order_by('submitted_at', direction='DESCENDING').limit(limit).offset(offset)
            
            applications = []
            for app_doc in query.stream():
                app_data = app_doc.to_dict()
                applications.append(app_data)
            
            return applications
            
        except Exception as e:
            logger.error(f"Error getting user applications: {str(e)}")
            raise
