# backend/services/prediction_service.py
"""
Credit Risk Prediction Service

Handles loading the trained model and making predictions on new data.
"""

import joblib
import pandas as pd
import numpy as np
from pathlib import Path
import logging
from typing import Dict, Any, List
from datetime import datetime

logger = logging.getLogger(__name__)

class PredictionService:
    """Service for credit risk predictions"""
    
    def __init__(self, model_path: str = "trained_models/global_credit_model.pkl"):
        self.model_path = Path(model_path)
        self.model = None
        self.feature_columns = None
        self._load_model()
    
    def _load_model(self):
        """Load the trained model"""
        try:
            if not self.model_path.exists():
                raise FileNotFoundError(f"Model file not found at {self.model_path}")
            
            self.model = joblib.load(self.model_path)
            logger.info(f"Model loaded successfully from {self.model_path}")
            
            # Store feature names for consistency
            if hasattr(self.model, 'feature_name_'):
                self.feature_columns = self.model.feature_name_
            
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            raise
    
    def prepare_input_data(self, input_data: Dict[str, Any]) -> pd.DataFrame:
        """Prepare input data for prediction"""
        # Define expected features (same as training)
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
        df = pd.DataFrame([input_data])
        
        # Ensure all expected features are present
        for feature in expected_features:
            if feature not in df.columns:
                df[feature] = 0  # Default value for missing features
        
        # Select only expected features in correct order
        df = df[expected_features]
        
        # Handle missing values
        df = df.fillna(0)
        
        return df
    
    def predict(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Make credit risk prediction"""
        try:
            if self.model is None:
                raise ValueError("Model not loaded")
            
            # Prepare input data
            df = self.prepare_input_data(input_data)
            
            # Make prediction
            prediction_proba = self.model.predict_proba(df)[0]
            prediction = self.model.predict(df)[0]
            
            # Calculate risk probability (probability of default)
            risk_probability = prediction_proba[1]
            
            # Determine loan status based on risk threshold
            risk_threshold = 0.5  # Adjustable threshold
            loan_status = "Denied" if risk_probability > risk_threshold else "Approved"
            
            # Create risk category
            if risk_probability <= 0.3:
                risk_category = "Low Risk"
            elif risk_probability <= 0.7:
                risk_category = "Medium Risk"
            else:
                risk_category = "High Risk"
            
            result = {
                "loan_status": loan_status,
                "risk_probability": float(risk_probability),
                "risk_category": risk_category,
                "confidence": float(max(prediction_proba)),
                "prediction_timestamp": datetime.now().isoformat(),
                "model_version": "1.0"
            }
            
            logger.info(f"Prediction made: {loan_status} (risk: {risk_probability:.3f})")
            return result
            
        except Exception as e:
            logger.error(f"Error making prediction: {str(e)}")
            raise
    
    def predict_batch(self, input_data_list: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Make batch predictions"""
        results = []
        for input_data in input_data_list:
            try:
                result = self.predict(input_data)
                results.append(result)
            except Exception as e:
                logger.error(f"Error in batch prediction: {str(e)}")
                results.append({
                    "error": str(e),
                    "loan_status": "Error",
                    "risk_probability": 0.0
                })
        return results
    
    def get_feature_importance(self) -> Dict[str, float]:
        """Get feature importance from the model"""
        if self.model is None:
            raise ValueError("Model not loaded")
        
        if hasattr(self.model, 'feature_importances_'):
            importance_dict = {}
            feature_names = self.feature_columns or [f"feature_{i}" for i in range(len(self.model.feature_importances_))]
            
            for name, importance in zip(feature_names, self.model.feature_importances_):
                importance_dict[name] = float(importance)
            
            # Sort by importance
            return dict(sorted(importance_dict.items(), key=lambda x: x[1], reverse=True))
        
        return {}
