# backend/tests/test_models.py
"""
Tests for ML Models and Related Functions

Tests model loading, prediction, and utility functions.
"""

import pytest
import pandas as pd
import numpy as np
from pathlib import Path
import sys

# Add backend to path
backend_path = Path(__file__).parent.parent
sys.path.append(str(backend_path))

from models.ml_models import ModelManager, calculate_derived_features, validate_prediction_input
from services.prediction_service import PredictionService
from services.explainability_service import ExplainabilityService

class TestModelManager:
    """Test ModelManager functionality"""
    
    def setup_method(self):
        """Setup test fixtures"""
        self.model_manager = ModelManager("test_models")
        self.sample_data = {
            'person_income': 50000,
            'loan_amnt': 15000,
            'person_emp_length': 5.0,
            'age': 30,
            'cb_person_cred_hist_length': 8.0,
            'electricity_bill_avg': 80.0,
            'water_bill_avg': 40.0,
            'gas_bill_avg': 50.0,
        }
    
    def test_prepare_model_features(self):
        """Test feature preparation"""
        df = self.model_manager.prepare_model_features(self.sample_data)
        
        assert isinstance(df, pd.DataFrame)
        assert len(df) == 1
        assert 'person_income' in df.columns
        assert 'loan_amnt' in df.columns
        
        # Check that missing features are filled with 0
        assert 'monthly_airtime_spend' in df.columns
        assert df['monthly_airtime_spend'].iloc[0] == 0
    
    def test_validate_model_input(self):
        """Test input validation"""
        required_features = ['person_income', 'loan_amnt', 'age']
        
        # Valid input
        assert self.model_manager.validate_model_input(self.sample_data, required_features)
        
        # Missing feature
        incomplete_data = {'person_income': 50000}
        assert not self.model_manager.validate_model_input(incomplete_data, required_features)

class TestDerivedFeatures:
    """Test derived feature calculations"""
    
    def test_calculate_derived_features(self):
        """Test derived feature calculation"""
        data = {
            'loan_amnt': 15000,
            'person_income': 50000,
            'electricity_bill_avg': 80.0,
            'water_bill_avg': 40.0,
            'gas_bill_avg': 50.0,
            'estimated_monthly_income': 4166.67,
            'digital_wallet_usage': 1,
            'mobile_banking_user': 1,
            'monthly_digital_transactions': 25,
            'social_media_activity_score': 60,
        }
        
        derived = calculate_derived_features(data)
        
        # Check loan to income ratio
        assert 'loan_percent_income' in derived
        expected_ratio = 15000 / 50000
        assert abs(derived['loan_percent_income'] - expected_ratio) < 0.001
        
        # Check total utility expense
        assert 'total_utility_expense' in derived
        assert derived['total_utility_expense'] == 170.0  # 80 + 40 + 50
        
        # Check utility to income ratio
        assert 'utility_to_income_ratio' in derived
        expected_util_ratio = 170.0 / 4166.67
        assert abs(derived['utility_to_income_ratio'] - expected_util_ratio) < 0.001

class TestInputValidation:
    """Test input validation functions"""
    
    def test_validate_prediction_input(self):
        """Test prediction input validation"""
        valid_data = {
            'person_income': 50000,
            'loan_amnt': 15000,
            'person_emp_length': 5.0,
            'age': 30
        }
        
        errors = validate_prediction_input(valid_data)
        assert len(errors) == 0
        
        # Test invalid age
        invalid_data = valid_data.copy()
        invalid_data['age'] = 10
        errors = validate_prediction_input(invalid_data)
        assert len(errors) > 0
        assert any('age' in error.lower() for error in errors)
        
        # Test missing required field
        incomplete_data = {
            'person_income': 50000,
            'loan_amnt': 15000,
            # Missing age and emp_length
        }
        errors = validate_prediction_input(incomplete_data)
        assert len(errors) > 0

class TestPredictionService:
    """Test PredictionService (if model is available)"""
    
    def setup_method(self):
        """Setup prediction service"""
        try:
            self.prediction_service = PredictionService()
            self.has_model = self.prediction_service.model is not None
        except:
            self.has_model = False
    
    @pytest.mark.skipif(True, reason="Requires trained model")
    def test_prediction_structure(self):
        """Test prediction output structure"""
        if not self.has_model:
            pytest.skip("Model not available")
        
        sample_data = {
            'person_income': 50000,
            'person_emp_length': 5.0,
            'age': 30,
            'loan_amnt': 15000,
            'loan_int_rate': 12.5,
            'cb_person_cred_hist_length': 8.0
        }
        
        result = self.prediction_service.predict(sample_data)
        
        assert 'loan_status' in result
        assert 'risk_probability' in result
        assert 'risk_category' in result
        assert 'confidence' in result
        assert 'prediction_timestamp' in result
        
        # Check value ranges
        assert 0 <= result['risk_probability'] <= 1
        assert 0 <= result['confidence'] <= 1
        assert result['loan_status'] in ['Approved', 'Denied']

if __name__ == "__main__":
    pytest.main([__file__])
