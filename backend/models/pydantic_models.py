# backend/models/pydantic_models.py
"""
Pydantic Models for API Request/Response Validation

Defines all data models used for API endpoints with proper validation.
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class LoanIntent(str, Enum):
    """Loan intent enumeration"""
    PERSONAL = "personal"
    EDUCATION = "education"
    MEDICAL = "medical"
    VENTURE = "venture"
    HOMEIMPROVEMENT = "homeimprovement"
    DEBTCONSOLIDATION = "debtconsolidation"

class RiskCategory(str, Enum):
    """Risk category enumeration"""
    LOW = "Low Risk"
    MEDIUM = "Medium Risk"
    HIGH = "High Risk"

class LoanStatus(str, Enum):
    """Loan status enumeration"""
    APPROVED = "Approved"
    DENIED = "Denied"
    PENDING = "Pending"

# Request Models
class CreditApplicationRequest(BaseModel):
    """Credit application request model"""
    # Personal Information
    person_income: float = Field(..., ge=0, description="Annual income in currency units")
    person_emp_length: float = Field(..., ge=0, description="Employment length in years")
    age: int = Field(..., ge=18, le=100, description="Age of applicant")
    
    # Loan Information
    loan_amnt: float = Field(..., gt=0, description="Requested loan amount")
    loan_int_rate: float = Field(..., ge=0, le=100, description="Interest rate percentage")
    loan_intent: Optional[str] = Field(None, description="Purpose of loan")
    
    # Credit History
    cb_person_cred_hist_length: float = Field(..., ge=0, description="Credit history length in years")
    cb_person_default_on_file: Optional[int] = Field(0, ge=0, le=1, description="Historical default flag")
    
    # Alternative Data - Telecom
    estimated_monthly_income: Optional[float] = Field(None, ge=0, description="Estimated monthly income")
    monthly_airtime_spend: Optional[float] = Field(0, ge=0, description="Monthly airtime spending")
    monthly_data_usage_gb: Optional[float] = Field(0, ge=0, description="Monthly data usage in GB")
    avg_calls_per_day: Optional[float] = Field(0, ge=0, description="Average calls per day")
    avg_sms_per_day: Optional[float] = Field(0, ge=0, description="Average SMS per day")
    
    # Alternative Data - Digital Engagement
    digital_wallet_usage: Optional[int] = Field(0, ge=0, le=1, description="Digital wallet usage flag")
    monthly_digital_transactions: Optional[float] = Field(0, ge=0, description="Monthly digital transactions")
    avg_transaction_amount: Optional[float] = Field(0, ge=0, description="Average transaction amount")
    social_media_activity_score: Optional[float] = Field(0, ge=0, description="Social media activity score")
    mobile_banking_user: Optional[int] = Field(0, ge=0, le=1, description="Mobile banking user flag")
    digital_engagement_score: Optional[float] = Field(0, ge=0, description="Overall digital engagement score")
    financial_inclusion_score: Optional[float] = Field(0, ge=0, description="Financial inclusion score")
    
    # Alternative Data - Utility Bills
    electricity_bill_avg: Optional[float] = Field(0, ge=0, description="Average monthly electricity bill")
    water_bill_avg: Optional[float] = Field(0, ge=0, description="Average monthly water bill")
    gas_bill_avg: Optional[float] = Field(0, ge=0, description="Average monthly gas bill")
    total_utility_expense: Optional[float] = Field(0, ge=0, description="Total monthly utility expense")
    utility_to_income_ratio: Optional[float] = Field(0, ge=0, description="Utility to income ratio")
    on_time_payments_12m: Optional[int] = Field(0, ge=0, description="On-time payments in last 12 months")
    late_payments_12m: Optional[int] = Field(0, ge=0, description="Late payments in last 12 months")
    
    # Additional Risk Indicators
    credit_risk_score: Optional[float] = Field(None, ge=0, description="Existing credit risk score")
    
    @validator('loan_int_rate')
    def validate_interest_rate(cls, v):
        if v < 0 or v > 50:  # Reasonable interest rate bounds
            raise ValueError('Interest rate must be between 0 and 50 percent')
        return v
    
    @validator('utility_to_income_ratio')
    def validate_utility_ratio(cls, v):
        if v is not None and v > 1.0:
            raise ValueError('Utility to income ratio should not exceed 1.0 (100%)')
        return v
    
    class Config:
        schema_extra = {
            "example": {
                "person_income": 45000,
                "person_emp_length": 5.5,
                "age": 32,
                "loan_amnt": 15000,
                "loan_int_rate": 12.5,
                "loan_intent": "personal",
                "cb_person_cred_hist_length": 8.0,
                "cb_person_default_on_file": 0,
                "estimated_monthly_income": 3750,
                "monthly_airtime_spend": 45.50,
                "monthly_data_usage_gb": 5.2,
                "avg_calls_per_day": 8.0,
                "avg_sms_per_day": 12.0,
                "digital_wallet_usage": 1,
                "monthly_digital_transactions": 25.0,
                "avg_transaction_amount": 125.75,
                "social_media_activity_score": 65.0,
                "mobile_banking_user": 1,
                "digital_engagement_score": 75.5,
                "financial_inclusion_score": 680.0,
                "electricity_bill_avg": 85.30,
                "water_bill_avg": 35.20,
                "gas_bill_avg": 42.10,
                "total_utility_expense": 162.60,
                "utility_to_income_ratio": 0.043,
                "on_time_payments_12m": 11,
                "late_payments_12m": 1,
                "credit_risk_score": 720.0
            }
        }

class UserCreationRequest(BaseModel):
    """User creation request model"""
    user_id: str = Field(..., description="Unique user identifier")
    email: Optional[str] = Field(None, description="User email address")
    full_name: Optional[str] = Field(None, description="Full name of user")
    phone_number: Optional[str] = Field(None, description="Phone number")
    created_at: Optional[datetime] = Field(default_factory=datetime.now)
    
    class Config:
        schema_extra = {
            "example": {
                "user_id": "user_12345",
                "email": "john.doe@example.com",
                "full_name": "John Doe",
                "phone_number": "+1234567890"
            }
        }

# Response Models
class PredictionResult(BaseModel):
    """Credit risk prediction result"""
    loan_status: LoanStatus = Field(..., description="Loan approval status")
    risk_probability: float = Field(..., ge=0, le=1, description="Risk probability (0-1)")
    risk_category: RiskCategory = Field(..., description="Risk category classification")
    confidence: float = Field(..., ge=0, le=1, description="Model confidence")
    prediction_timestamp: str = Field(..., description="Timestamp of prediction")
    model_version: str = Field(..., description="Version of the model used")
    
    class Config:
        schema_extra = {
            "example": {
                "loan_status": "Approved",
                "risk_probability": 0.25,
                "risk_category": "Low Risk",
                "confidence": 0.87,
                "prediction_timestamp": "2024-01-15T10:30:00",
                "model_version": "1.0"
            }
        }

class ApplicationResponse(BaseModel):
    """Credit application response"""
    application_id: str = Field(..., description="Unique application identifier")
    user_id: str = Field(..., description="User identifier")
    prediction_result: PredictionResult
    submitted_at: datetime = Field(..., description="Application submission timestamp")
    
    class Config:
        schema_extra = {
            "example": {
                "application_id": "app_67890",
                "user_id": "user_12345",
                "prediction_result": {
                    "loan_status": "Approved",
                    "risk_probability": 0.25,
                    "risk_category": "Low Risk",
                    "confidence": 0.87,
                    "prediction_timestamp": "2024-01-15T10:30:00",
                    "model_version": "1.0"
                },
                "submitted_at": "2024-01-15T10:30:00"
            }
        }

class FeatureContribution(BaseModel):
    """Individual feature contribution in explanation"""
    shap_value: float = Field(..., description="SHAP value for this feature")
    feature_value: float = Field(..., description="Actual value of the feature")
    impact: str = Field(..., description="Impact on risk (increases_risk/decreases_risk)")

class ExplanationResponse(BaseModel):
    """SHAP explanation response"""
    application_id: str = Field(..., description="Application identifier")
    top_features: Dict[str, FeatureContribution] = Field(..., description="Top contributing features")
    base_value: float = Field(..., description="Model base prediction value")
    prediction_value: float = Field(..., description="Final prediction value")
    total_shap_contribution: float = Field(..., description="Total SHAP contribution")
    readable_explanation: List[str] = Field(..., description="Human-readable explanations")
    generated_at: datetime = Field(default_factory=datetime.now)

class UserApplicationsResponse(BaseModel):
    """User's application history response"""
    user_id: str = Field(..., description="User identifier")
    applications: List[ApplicationResponse] = Field(..., description="List of applications")
    total_applications: int = Field(..., description="Total number of applications")

class HealthCheckResponse(BaseModel):
    """Health check response"""
    status: str = Field(..., description="Service status")
    timestamp: datetime = Field(default_factory=datetime.now)
    version: str = Field(..., description="API version")

class ErrorResponse(BaseModel):
    """Error response model"""
    error: str = Field(..., description="Error message")
    detail: Optional[str] = Field(None, description="Detailed error information")
    timestamp: datetime = Field(default_factory=datetime.now)
