# backend/models/ml_models.py
"""
Machine Learning Models Utility Functions

Contains utility functions for model loading, validation, and management.
"""
 
import joblib
import pandas as pd
import numpy as np
from pathlib import Path
import logging
from typing import Optional, Dict, Any, List
from sklearn.base import BaseEstimator
import lightgbm as lgb

logger = logging.getLogger(__name__)

class ModelManager:
    """Utility class for managing ML models and their operations"""
    
    def __init__(self, models_dir: str = "trained_models"):
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(exist_ok=True)
        
    def save_model(self, model: BaseEstimator, model_name: str) -> str:
        """Save a trained model to disk"""
        try:
            model_path = self.models_dir / f"{model_name}.pkl"
            joblib.dump(model, model_path)
            logger.info(f"Model saved: {model_path}")
            return str(model_path)
        except Exception as e:
            logger.error(f"Error saving model: {str(e)}")
            raise
    
    def load_model(self, model_name: str) -> Optional[BaseEstimator]:
        """Load a trained model from disk"""
        try:
            model_path = self.models_dir / f"{model_name}.pkl"
            if not model_path.exists():
                logger.warning(f"Model file not found: {model_path}")
                return None
            
            model = joblib.load(model_path)
            logger.info(f"Model loaded: {model_path}")
            return model
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            return None
    
    def validate_model_input(self, data: Dict[str, Any], expected_features: List[str]) -> bool:
        """Validate that input data contains all required features"""
        missing_features = []
        for feature in expected_features:
            if feature not in data:
                missing_features.append(feature)
        
        if missing_features:
            logger.warning(f"Missing features: {missing_features}")
            return False
        return True
    
    def prepare_model_features(self, data: Dict[str, Any]) -> pd.DataFrame:
        """Prepare input data for model prediction"""
        # Define expected features (should match training data)
        expected_features = [
            'person_income', 'person_emp_length', 'loan_amnt', 'loan_int_rate', 
            'loan_percent_income', 'cb_person_cred_hist_length', 'age', 
            'estimated_monthly_income', 'monthly_airtime_spend', 'monthly_data_usage_gb',
            'avg_calls_per_day', 'avg_sms_per_day', 'digital_wallet_usage',
            'monthly_digital_transactions', 'avg_transaction_amount', 
            'social_media_activity_score', 'mobile_banking_user',
            'digital_engagement_score', 'financial_inclusion_score',
            'electricity_bill_avg', 'water_bill_avg', 'gas_bill_avg',
            'total_utility_expense', 'utility_to_income_ratio', 
            'on_time_payments_12m', 'late_payments_12m', 'credit_risk_score'
        ]
        
        # Create DataFrame with expected features
        df = pd.DataFrame([data])
        
        # Add missing features with default values
        for feature in expected_features:
            if feature not in df.columns:
                df[feature] = 0
        
        # Select only expected features in correct order
        df = df[expected_features]
        
        # Handle missing values
        df = df.fillna(0)
        
        return df
    
    def get_model_info(self, model: BaseEstimator) -> Dict[str, Any]:
        """Get information about a trained model"""
        info = {
            'model_type': type(model).__name__,
            'model_class': str(type(model))
        }
        
        # Add LightGBM specific info
        if isinstance(model, lgb.LGBMClassifier):
            info.update({
                'n_features': model.n_features_,
                'n_classes': model.n_classes_,
                'objective': getattr(model, 'objective', 'unknown'),
                'boosting_type': getattr(model, 'boosting_type', 'unknown')
            })
            
            if hasattr(model, 'feature_importances_'):
                info['has_feature_importance'] = True
                info['top_features'] = self._get_top_features(model)
        
        return info
    
    def _get_top_features(self, model: lgb.LGBMClassifier, top_n: int = 10) -> Dict[str, float]:
        """Get top N most important features from LightGBM model"""
        if not hasattr(model, 'feature_importances_'):
            return {}
        
        feature_names = getattr(model, 'feature_name_', [f"feature_{i}" for i in range(len(model.feature_importances_))])
        importance_dict = dict(zip(feature_names, model.feature_importances_))
        
        # Sort by importance and take top N
        sorted_features = sorted(importance_dict.items(), key=lambda x: x[1], reverse=True)
        return dict(sorted_features[:top_n])

def calculate_derived_features(data: Dict[str, Any]) -> Dict[str, Any]:
    """Calculate derived features from input data"""
    derived_data = data.copy()
    
    # Calculate loan to income ratio
    if 'loan_amnt' in data and 'person_income' in data and data['person_income'] > 0:
        derived_data['loan_percent_income'] = data['loan_amnt'] / data['person_income']
    
    # Calculate total utility expense
    utility_fields = ['electricity_bill_avg', 'water_bill_avg', 'gas_bill_avg']
    total_utility = sum(data.get(field, 0) for field in utility_fields)
    derived_data['total_utility_expense'] = total_utility
    
    # Calculate utility to income ratio
    monthly_income = data.get('estimated_monthly_income', data.get('person_income', 0) / 12)
    if monthly_income > 0:
        derived_data['utility_to_income_ratio'] = total_utility / monthly_income
    
    # Calculate digital engagement score
    digital_indicators = [
        data.get('digital_wallet_usage', 0),
        data.get('mobile_banking_user', 0),
        min(data.get('monthly_digital_transactions', 0) / 20, 1),  # Normalize to 0-1
        min(data.get('social_media_activity_score', 0) / 100, 1),  # Normalize to 0-1
    ]
    derived_data['digital_engagement_score'] = sum(digital_indicators) * 25  # Scale to 0-100
    
    return derived_data

def validate_prediction_input(data: Dict[str, Any]) -> List[str]:
    """Validate input data and return list of validation errors"""
    errors = []
    
    # Check required fields
    required_fields = ['person_income', 'loan_amnt', 'person_emp_length', 'age']
    for field in required_fields:
        if field not in data or data[field] is None:
            errors.append(f"Missing required field: {field}")
    
    # Validate ranges
    if 'age' in data and data['age'] is not None:
        if data['age'] < 18 or data['age'] > 100:
            errors.append("Age must be between 18 and 100")
    
    if 'person_income' in data and data['person_income'] is not None:
        if data['person_income'] <= 0:
            errors.append("Income must be greater than 0")
    
    if 'loan_amnt' in data and data['loan_amnt'] is not None:
        if data['loan_amnt'] <= 0:
            errors.append("Loan amount must be greater than 0")
    
    return errors
