# backend/services/explainability_service.py
"""
Enhanced Explainability Service using SHAP with Recommendations

Provides model explanations and personalized recommendations for credit risk predictions.
"""

import joblib
import pandas as pd
import numpy as np
from pathlib import Path
import logging
from typing import Dict, Any, List
import shap

logger = logging.getLogger(__name__)

class ExplainabilityService:
    """Enhanced service for generating model explanations using SHAP with recommendations"""
    
    def __init__(self, explainer_path: str = "trained_models/shap_explainer.pkl"):
        self.explainer_path = Path(explainer_path)
        self.explainer = None
        self._load_explainer()
    
    def _load_explainer(self):
        """Load the SHAP explainer"""
        try:
            if not self.explainer_path.exists():
                raise FileNotFoundError(f"SHAP explainer not found at {self.explainer_path}")
            
            self.explainer = joblib.load(self.explainer_path)
            logger.info(f"SHAP explainer loaded successfully from {self.explainer_path}")
            
        except Exception as e:
            logger.error(f"Error loading SHAP explainer: {str(e)}")
            raise
    
    def prepare_input_data(self, input_data: Dict[str, Any]) -> pd.DataFrame:
        """Prepare input data for SHAP explanation"""
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
        
        df = pd.DataFrame([input_data])
        
        for feature in expected_features:
            if feature not in df.columns:
                df[feature] = 0
        
        df = df[expected_features]
        df = df.fillna(0)
        
        return df
    
    def explain_prediction(self, input_data: Dict[str, Any], top_n: int = 10) -> Dict[str, Any]:
        """Generate comprehensive SHAP explanation with recommendations"""
        try:
            if self.explainer is None:
                raise ValueError("SHAP explainer not loaded")
            
            df = self.prepare_input_data(input_data)
            shap_values = self.explainer.shap_values(df)
            
            if isinstance(shap_values, list):
                shap_values = shap_values[1]
            
            feature_names = df.columns.tolist()
            
            # Create enhanced feature contributions
            feature_contributions = {}
            for i, (feature, shap_value) in enumerate(zip(feature_names, shap_values[0])):
                feature_contributions[feature] = {
                    "shap_value": float(shap_value),
                    "feature_value": float(df.iloc[0, i]),
                    "impact": "increases_risk" if shap_value > 0 else "decreases_risk",
                    "description": self._get_feature_description(feature, float(df.iloc[0, i]), float(shap_value)),
                    "recommendation": self._get_feature_recommendation(feature, float(df.iloc[0, i]), float(shap_value))
                }
            
            # Sort by absolute SHAP value and take top N
            sorted_features = sorted(
                feature_contributions.items(),
                key=lambda x: abs(x[1]["shap_value"]),
                reverse=True
            )[:top_n]
            
            # Generate base explanation
            explanation = {
                "top_features": dict(sorted_features),
                "base_value": float(self.explainer.expected_value[1] if isinstance(self.explainer.expected_value, list) else self.explainer.expected_value),
                "prediction_value": float(self.explainer.expected_value[1] if isinstance(self.explainer.expected_value, list) else self.explainer.expected_value) + float(np.sum(shap_values[0])),
                "total_shap_contribution": float(np.sum(shap_values[0]))
            }
            
            # Add human-readable explanations
            explanation["readable_explanation"] = self._create_readable_explanation(dict(sorted_features))
            
            # Generate personalized recommendations
            explanation["recommendations"] = self._generate_personalized_recommendations(
                dict(sorted_features), input_data
            )
            
            logger.info("Enhanced SHAP explanation generated successfully")
            return explanation
            
        except Exception as e:
            logger.error(f"Error generating SHAP explanation: {str(e)}")
            raise
    
    def _get_feature_description(self, feature: str, value: float, shap_value: float) -> str:
        """Get detailed description for a feature"""
        descriptions = {
            'person_income': f"Your annual income of ₹{value:,.0f} {'positively' if shap_value > 0 else 'negatively'} affects your risk profile",
            'loan_amnt': f"The requested loan amount of ₹{value:,.0f} {'increases' if shap_value > 0 else 'decreases'} the assessed risk",
            'loan_int_rate': f"The interest rate of {value:.1f}% {'contributes to higher' if shap_value > 0 else 'helps lower'} risk assessment",
            'late_payments_12m': f"Having {value:.0f} late payments in the last 12 months {'significantly increases' if shap_value > 0 else 'does not increase'} your risk",
            'on_time_payments_12m': f"Your {value:.0f} on-time payments {'demonstrate reliability' if shap_value < 0 else 'are noted'} in the assessment",
            'digital_engagement_score': f"Your digital engagement score of {value:.0f} {'shows good' if shap_value < 0 else 'indicates limited'} digital financial behavior",
            'utility_to_income_ratio': f"Your utility-to-income ratio of {value:.3f} {'is considered high' if shap_value > 0 else 'is within acceptable range'}",
            'age': f"Your age of {value:.0f} years {'is factored into' if shap_value != 0 else 'neutrally affects'} the risk calculation",
            'cb_person_cred_hist_length': f"Your credit history of {value:.1f} years {'provides' if shap_value < 0 else 'shows limited'} evidence of creditworthiness"
        }
        
        return descriptions.get(feature, f"This feature with value {value:.2f} {'increases' if shap_value > 0 else 'decreases'} your risk assessment")
    
    def _get_feature_recommendation(self, feature: str, value: float, shap_value: float) -> str:
        """Get specific recommendation for a feature"""
        if abs(shap_value) < 0.01:  # Low impact features don't need recommendations
            return None
            
        recommendations = {
            'late_payments_12m': "Set up automatic payments and payment reminders to avoid future late payments",
            'on_time_payments_12m': "Continue your excellent payment history - it's your strongest asset",
            'utility_to_income_ratio': "Consider reducing utility costs through energy-efficient appliances or budget management",
            'loan_int_rate': "Shop around for better interest rates or consider improving your credit score first",
            'digital_engagement_score': "Increase your digital financial activities like mobile banking and digital payments",
            'person_income': "Consider documenting additional income sources or pursuing income growth opportunities",
            'loan_amnt': "Consider requesting a smaller loan amount to improve approval chances",
            'cb_person_cred_hist_length': "Maintain your existing credit accounts to build a longer credit history",
            'age': "Age is a natural factor - focus on other controllable aspects of your financial profile"
        }
        
        if shap_value > 0:  # Only provide recommendations for risk-increasing features
            return recommendations.get(feature, "Consider improving this aspect of your financial profile")
        
        return None
    
    def _create_readable_explanation(self, top_features: Dict[str, Dict[str, Any]]) -> List[str]:
        """Create human-readable explanations"""
        explanations = []
        
        feature_mappings = {
            'person_income': 'Annual Income',
            'loan_amnt': 'Loan Amount',
            'loan_int_rate': 'Interest Rate',
            'loan_percent_income': 'Loan-to-Income Ratio',
            'cb_person_cred_hist_length': 'Credit History Length',
            'age': 'Age',
            'utility_to_income_ratio': 'Utility-to-Income Ratio',
            'on_time_payments_12m': 'On-time Payments (12m)',
            'late_payments_12m': 'Late Payments (12m)',
            'digital_engagement_score': 'Digital Engagement Score',
            'credit_risk_score': 'Credit Risk Score',
            'monthly_digital_transactions': 'Monthly Digital Transactions',
            'social_media_activity_score': 'Social Media Activity',
            'mobile_banking_user': 'Mobile Banking Usage'
        }
        
        for feature, data in top_features.items():
            readable_name = feature_mappings.get(feature, feature.replace('_', ' ').title())
            shap_value = data['shap_value']
            feature_value = data['feature_value']
            impact = data['impact']
            
            impact_text = "increases" if impact == "increases_risk" else "decreases"
            
            explanation = f"{readable_name} (value: {feature_value:.2f}) {impact_text} risk by {abs(shap_value):.3f}"
            explanations.append(explanation)
        
        return explanations
    
    def _generate_personalized_recommendations(self, top_features: Dict[str, Dict[str, Any]], input_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate personalized recommendations based on SHAP analysis"""
        recommendations = []
        
        # Analyze top risk-increasing features
        risk_increasing_features = {k: v for k, v in top_features.items() if v['impact'] == 'increases_risk'}
        
        # Sort by impact magnitude
        sorted_risk_features = sorted(risk_increasing_features.items(), key=lambda x: abs(x[1]['shap_value']), reverse=True)
        
        for feature, data in sorted_risk_features[:5]:  # Top 5 risk factors
            rec = self._create_recommendation(feature, data, input_data)
            if rec:
                recommendations.append(rec)
        
        # Add general recommendations
        if len(recommendations) < 3:
            recommendations.extend(self._get_general_recommendations(input_data))
        
        return recommendations[:5]  # Limit to 5 recommendations
    
    def _create_recommendation(self, feature: str, data: Dict[str, Any], input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a specific recommendation for a feature"""
        shap_value = abs(data['shap_value'])
        
        recommendations_map = {
            'late_payments_12m': {
                'title': 'Improve Payment History',
                'description': 'Your recent late payments are significantly impacting your credit risk assessment.',
                'action_item': 'Set up automatic payments and payment reminders to ensure timely payments going forward.',
                'category': 'payment',
                'priority': min(0.9, shap_value * 10)  # Scale priority based on impact
            },
            'utility_to_income_ratio': {
                'title': 'Optimize Utility Expenses',
                'description': 'Your utility expenses relative to income are higher than optimal for credit assessment.',
                'action_item': 'Review and reduce utility costs through energy-saving measures or budget optimization.',
                'category': 'utility',
                'priority': min(0.8, shap_value * 8)
            },
            'loan_int_rate': {
                'title': 'Explore Better Interest Rates',
                'description': 'The current interest rate is affecting your loan approval chances.',
                'action_item': 'Shop around with different lenders or work on improving your credit score for better rates.',
                'category': 'credit',
                'priority': min(0.7, shap_value * 6)
            },
            'digital_engagement_score': {
                'title': 'Increase Digital Financial Activity',
                'description': 'Low digital engagement may be limiting your credit profile strength.',
                'action_item': 'Use mobile banking, digital payments, and financial apps more regularly to build digital footprint.',
                'category': 'digital',
                'priority': min(0.6, shap_value * 5)
            },
            'loan_amnt': {
                'title': 'Consider Loan Amount Adjustment',
                'description': 'The requested loan amount might be too high relative to your current financial profile.',
                'action_item': 'Consider requesting a smaller amount or work on improving income/credit before applying.',
                'category': 'credit',
                'priority': min(0.8, shap_value * 7)
            }
        }
        
        return recommendations_map.get(feature)
    
    def _get_general_recommendations(self, input_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Get general recommendations based on overall profile"""
        general_recs = [
            {
                'title': 'Build Credit History',
                'description': 'A longer, consistent credit history strengthens your financial profile.',
                'action_item': 'Maintain existing credit accounts and use credit responsibly over time.',
                'category': 'credit',
                'priority': 0.5
            },
            {
                'title': 'Maintain Stable Income',
                'description': 'Consistent income documentation helps in credit assessments.',
                'action_item': 'Keep detailed records of all income sources and maintain stable employment.',
                'category': 'income',
                'priority': 0.4
            }
        ]
        
        return general_recs
