# backend/tests/test_services.py
"""
Tests for Service Classes

Tests Firebase service, prediction service, and explainability service.
"""

import pytest
from unittest.mock import Mock, patch
import pandas as pd
from pathlib import Path
import sys

# Add backend to path
backend_path = Path(__file__).parent.parent
sys.path.append(str(backend_path))

from services.firebase_service import FirebaseService

class TestFirebaseService:
    """Test Firebase service functionality"""
    
    def setup_method(self):
        """Setup test fixtures"""
        # Mock Firestore client to avoid actual Firebase calls
        with patch('services.firebase_service.get_firestore') as mock_get_firestore:
            self.mock_db = Mock()
            mock_get_firestore.return_value = self.mock_db
            self.firebase_service = FirebaseService()
    
    def test_create_user(self):
        """Test user creation"""
        user_data = {
            'user_id': 'test123',
            'email': 'test@example.com',
            'full_name': 'Test User'
        }
        
        # Mock Firestore operations
        mock_user_ref = Mock()
        self.mock_db.collection.return_value.document.return_value = mock_user_ref
        
        # Should not raise exception
        self.firebase_service.create_user('test123', user_data)
        
        # Verify Firestore was called correctly
        self.mock_db.collection.assert_called_with('users')
        mock_user_ref.set.assert_called_with(user_data)
    
    def test_get_user(self):
        """Test user retrieval"""
        # Mock user document
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = {'user_id': 'test123', 'email': 'test@example.com'}
        
        mock_user_ref = Mock()
        mock_user_ref.get.return_value = mock_doc
        self.mock_db.collection.return_value.document.return_value = mock_user_ref
        
        result = self.firebase_service.get_user('test123')
        
        assert result is not None
        assert result['user_id'] == 'test123'
        assert result['email'] == 'test@example.com'
    
    def test_get_user_not_found(self):
        """Test user retrieval when user doesn't exist"""
        mock_doc = Mock()
        mock_doc.exists = False
        
        mock_user_ref = Mock()
        mock_user_ref.get.return_value = mock_doc
        self.mock_db.collection.return_value.document.return_value = mock_user_ref
        
        result = self.firebase_service.get_user('nonexistent')
        
        assert result is None
    
    def test_store_application(self):
        """Test application storage"""
        application_data = {
            'application_id': 'app123',
            'user_id': 'user123',
            'loan_amnt': 15000,
            'prediction_result': {'status': 'Approved'}
        }
        
        mock_app_ref = Mock()
        mock_collection = Mock()
        mock_collection.document.return_value = mock_app_ref
        
        mock_user_doc = Mock()
        mock_user_doc.collection.return_value = mock_collection
        
        self.mock_db.collection.return_value.document.return_value = mock_user_doc
        
        # Should not raise exception
        self.firebase_service.store_application('user123', 'app123', application_data)
        
        # Verify the call chain
        mock_app_ref.set.assert_called_with(application_data)

class TestServiceIntegration:
    """Test service integration scenarios"""
    
    def test_data_flow_simulation(self):
        """Test simulated data flow through services"""
        # Sample application data
        application_data = {
            'person_income': 50000,
            'person_emp_length': 5.0,
            'age': 30,
            'loan_amnt': 15000,
            'loan_int_rate': 12.5,
            'cb_person_cred_hist_length': 8.0,
            'estimated_monthly_income': 4166.67,
            'monthly_airtime_spend': 50.0,
            'digital_wallet_usage': 1,
            'mobile_banking_user': 1
        }
        
        # Test data preparation (without actual model)
        from models.ml_models import calculate_derived_features, validate_prediction_input
        
        # Calculate derived features
        enhanced_data = calculate_derived_features(application_data)
        
        # Validate input
        validation_errors = validate_prediction_input(enhanced_data)
        
        assert len(validation_errors) == 0, f"Validation errors: {validation_errors}"
        assert 'loan_percent_income' in enhanced_data
        assert 'total_utility_expense' in enhanced_data

class TestErrorHandling:
    """Test error handling in services"""
    
    def test_firebase_service_error_handling(self):
        """Test Firebase service error handling"""
        with patch('services.firebase_service.get_firestore') as mock_get_firestore:
            # Simulate Firebase connection error
            mock_get_firestore.side_effect = Exception("Firebase connection failed")
            
            with pytest.raises(Exception):
                firebase_service = FirebaseService()
    
    def test_data_validation_edge_cases(self):
        """Test data validation with edge cases"""
        from models.ml_models import validate_prediction_input
        
        # Empty data
        errors = validate_prediction_input({})
        assert len(errors) > 0
        
        # Data with None values
        none_data = {
            'person_income': None,
            'loan_amnt': 15000,
            'age': None
        }
        errors = validate_prediction_input(none_data)
        assert len(errors) > 0
        
        # Data with extreme values
        extreme_data = {
            'person_income': -50000,  # Negative income
            'loan_amnt': 0,          # Zero loan amount
            'age': 150,              # Impossible age
            'person_emp_length': 5.0
        }
        errors = validate_prediction_input(extreme_data)
        assert len(errors) > 0

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
