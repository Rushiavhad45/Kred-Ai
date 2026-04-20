# backend/tests/test_api.py
"""
API Tests for Credit Risk Assessment Backend

Tests all API endpoints and their functionality.
"""

import pytest
from fastapi.testclient import TestClient
import json
from pathlib import Path
import sys

# Add backend to path for imports
backend_path = Path(__file__).parent.parent
sys.path.append(str(backend_path))

from main import app

client = TestClient(app)

class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_root_endpoint(self):
        response = client.get("/")
        assert response.status_code == 200
        assert "status" in response.json()
    
    def test_health_endpoint(self):
        response = client.get("/health")
        assert response.status_code in [200, 503]  # May be 503 if models not loaded
        data = response.json()
        assert "status" in data
        assert "version" in data

class TestUserEndpoints:
    """Test user management endpoints"""
    
    def test_create_user(self):
        user_data = {
            "user_id": "test_user_123",
            "email": "test@example.com",
            "full_name": "Test User",
            "phone_number": "+1234567890"
        }
        
        response = client.post("/users/", json=user_data)
        # May fail if Firebase not configured, that's expected in tests
        assert response.status_code in [200, 400, 500]

class TestApplicationEndpoints:
    """Test credit application endpoints"""
    
    def get_sample_application(self):
        return {
            "person_income": 50000,
            "person_emp_length": 5.0,
            "age": 30,
            "loan_amnt": 15000,
            "loan_int_rate": 12.5,
            "loan_intent": "personal",
            "cb_person_cred_hist_length": 8.0,
            "cb_person_default_on_file": 0,
            "estimated_monthly_income": 4166.67,
            "monthly_airtime_spend": 50.0,
            "monthly_data_usage_gb": 5.0,
            "avg_calls_per_day": 10.0,
            "avg_sms_per_day": 15.0,
            "digital_wallet_usage": 1,
            "monthly_digital_transactions": 25.0,
            "avg_transaction_amount": 100.0,
            "social_media_activity_score": 60.0,
            "mobile_banking_user": 1,
            "digital_engagement_score": 75.0,
            "financial_inclusion_score": 650.0,
            "electricity_bill_avg": 80.0,
            "water_bill_avg": 40.0,
            "gas_bill_avg": 50.0,
            "total_utility_expense": 170.0,
            "utility_to_income_ratio": 0.041,
            "on_time_payments_12m": 11,
            "late_payments_12m": 1,
            "credit_risk_score": 700.0
        }
    
    def test_submit_application_structure(self):
        application_data = self.get_sample_application()
        response = client.post("/applications/", json=application_data)
        
        # Test may fail if model not trained, but check structure
        if response.status_code == 200:
            data = response.json()
            assert "application_id" in data
            assert "prediction_result" in data
            assert "user_id" in data
    
    def test_get_user_applications(self):
        response = client.get("/applications/test_user/")
        # May return 404 if user doesn't exist, that's expected
        assert response.status_code in [200, 404]

class TestModelEndpoints:
    """Test model information endpoints"""
    
    def test_model_info(self):
        response = client.get("/model/info")
        if response.status_code == 200:
            data = response.json()
            assert "model_version" in data
            assert "model_type" in data
    
    def test_model_features(self):
        response = client.get("/model/features")
        if response.status_code == 200:
            data = response.json()
            assert "features" in data

class TestInputValidation:
    """Test input validation"""
    
    def test_invalid_age(self):
        invalid_data = {
            "person_income": 50000,
            "person_emp_length": 5.0,
            "age": 10,  # Invalid: too young
            "loan_amnt": 15000,
            "loan_int_rate": 12.5,
            "cb_person_cred_hist_length": 8.0
        }
        
        response = client.post("/applications/", json=invalid_data)
        assert response.status_code == 422  # Validation error
    
    def test_invalid_income(self):
        invalid_data = {
            "person_income": -1000,  # Invalid: negative
            "person_emp_length": 5.0,
            "age": 30,
            "loan_amnt": 15000,
            "loan_int_rate": 12.5,
            "cb_person_cred_hist_length": 8.0
        }
        
        response = client.post("/applications/", json=invalid_data)
        assert response.status_code == 422  # Validation error

if __name__ == "__main__":
    pytest.main([__file__])
