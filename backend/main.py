# backend/main.py
"""
Credit Risk Assessment API - FastAPI Backend

Main FastAPI application with all endpoints for credit risk assessment,
federated learning integration, and explainable AI.
"""

from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import uuid
from datetime import datetime
from typing import List, Dict, Any
import asyncio

# Import services and models
from services.prediction_service import PredictionService
from services.explainability_service import ExplainabilityService
from services.firebase_service import FirebaseService
from models.pydantic_models import (
    CreditApplicationRequest,
    UserCreationRequest,
    PredictionResult,
    ApplicationResponse,
    ExplanationResponse,
    UserApplicationsResponse,
    HealthCheckResponse,
    ErrorResponse
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Credit Risk Assessment API",
    description="API for credit risk assessment using federated learning and explainable AI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
prediction_service = PredictionService()
explainability_service = ExplainabilityService()
firebase_service = FirebaseService()

# Exception handler for better error responses
@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc),
            "timestamp": datetime.now().isoformat()
        }
    )

# Health check endpoint
@app.get("/", response_model=HealthCheckResponse, tags=["Health"])
async def root():
    """Root endpoint - health check"""
    return HealthCheckResponse(
        status="Credit Risk Assessment API is running",
        version="1.0.0"
    )

@app.get("/health", response_model=HealthCheckResponse, tags=["Health"])
async def health_check():
    """Detailed health check"""
    try:
        # Check if services are loaded
        model_loaded = prediction_service.model is not None
        explainer_loaded = explainability_service.explainer is not None
        
        status = "healthy" if model_loaded and explainer_loaded else "degraded"
        
        return HealthCheckResponse(
            status=f"API Status: {status} | Model: {'OK' if model_loaded else 'Error'} | Explainer: {'OK' if explainer_loaded else 'Error'}",
            version="1.0.0"
        )
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail="Service unavailable")

# User management endpoints
@app.post("/users/", response_model=Dict[str, str], tags=["Users"])
async def create_user(user_data: UserCreationRequest):
    """Create a new user profile"""
    try:
        # Store user in Firebase
        user_doc = {
            "user_id": user_data.user_id,
            "email": user_data.email,
            "full_name": user_data.full_name,
            "phone_number": user_data.phone_number,
            "created_at": user_data.created_at,
            "applications": []
        }
        
        firebase_service.create_user(user_data.user_id, user_doc)
        
        logger.info(f"User created: {user_data.user_id}")
        return {
            "message": "User created successfully",
            "user_id": user_data.user_id
        }
        
    except Exception as e:
        logger.error(f"Error creating user: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

# Credit application endpoints
@app.post("/applications/", response_model=ApplicationResponse, tags=["Applications"])
async def submit_credit_application(
    application: CreditApplicationRequest,
    background_tasks: BackgroundTasks,
    user_id: str = "anonymous"  # In production, extract from JWT token
):
    """Submit credit application and get immediate risk assessment"""
    try:
        # Generate application ID
        application_id = str(uuid.uuid4())
        
        logger.info(f"Processing credit application: {application_id}")
        
        # Convert application to dictionary for prediction
        application_data = application.dict()
        
        # Calculate derived features
        if application.loan_amnt and application.person_income:
            application_data["loan_percent_income"] = application.loan_amnt / application.person_income
        else:
            application_data["loan_percent_income"] = 0
        
        # Make prediction
        prediction_result = prediction_service.predict(application_data)
        
        # Create application record
        application_record = {
            "application_id": application_id,
            "user_id": user_id,
            "application_data": application_data,
            "prediction_result": prediction_result,
            "submitted_at": datetime.now(),
            "status": "completed"
        }
        
        # Store in Firebase (background task)
        background_tasks.add_task(
            store_application_async,
            user_id,
            application_id,
            application_record
        )
        
        # Create response
        response = ApplicationResponse(
            application_id=application_id,
            user_id=user_id,
            prediction_result=PredictionResult(**prediction_result),
            submitted_at=datetime.now()
        )
        
        logger.info(f"Application processed: {application_id} - Status: {prediction_result['loan_status']}")
        return response
        
    except Exception as e:
        logger.error(f"Error processing application: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

async def store_application_async(user_id: str, application_id: str, application_record: Dict[str, Any]):
    """Background task to store application in Firebase"""
    try:
        firebase_service.store_application(user_id, application_id, application_record)
        logger.info(f"Application stored in Firebase: {application_id}")
    except Exception as e:
        logger.error(f"Error storing application in Firebase: {str(e)}")

@app.get("/applications/{user_id}/", response_model=UserApplicationsResponse, tags=["Applications"])
async def get_user_applications(user_id: str, limit: int = 10, offset: int = 0):
    """Retrieve user's application history"""
    try:
        # Get applications from Firebase
        applications = firebase_service.get_user_applications(user_id, limit, offset)
        
        # Convert to response format
        application_responses = []
        for app_data in applications:
            app_response = ApplicationResponse(
                application_id=app_data["application_id"],
                user_id=app_data["user_id"],
                prediction_result=PredictionResult(**app_data["prediction_result"]),
                submitted_at=app_data["submitted_at"]
            )
            application_responses.append(app_response)
        
        return UserApplicationsResponse(
            user_id=user_id,
            applications=application_responses,
            total_applications=len(application_responses)
        )
        
    except Exception as e:
        logger.error(f"Error retrieving applications for user {user_id}: {str(e)}")
        raise HTTPException(status_code=404, detail="User applications not found")

# Explainability endpoints
@app.get("/explain/{application_id}/", response_model=ExplanationResponse, tags=["Explainability"])
async def get_application_explanation(application_id: str, top_features: int = 10):
    """Get SHAP explanation for a specific application"""
    try:
        # Get application data from Firebase
        application_data = firebase_service.get_application(application_id)
        
        if not application_data:
            raise HTTPException(status_code=404, detail="Application not found")
        
        # Get original input data
        input_data = application_data["application_data"]
        
        # Generate SHAP explanation
        explanation = explainability_service.explain_prediction(input_data, top_features)
        
        # Create response
        response = ExplanationResponse(
            application_id=application_id,
            top_features=explanation["top_features"],
            base_value=explanation["base_value"],
            prediction_value=explanation["prediction_value"],
            total_shap_contribution=explanation["total_shap_contribution"],
            readable_explanation=explanation["readable_explanation"]
        )
        
        logger.info(f"Explanation generated for application: {application_id}")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating explanation: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/explain/batch/", response_model=List[ExplanationResponse], tags=["Explainability"])
async def explain_batch_predictions(
    application_data_list: List[CreditApplicationRequest],
    top_features: int = 10
):
    """Get explanations for multiple predictions (batch processing)"""
    try:
        explanations = []
        
        for i, application in enumerate(application_data_list):
            application_data = application.dict()
            
            # Calculate derived features
            if application.loan_amnt and application.person_income:
                application_data["loan_percent_income"] = application.loan_amnt / application.person_income
            else:
                application_data["loan_percent_income"] = 0
            
            # Generate explanation
            explanation = explainability_service.explain_prediction(application_data, top_features)
            
            # Create response
            response = ExplanationResponse(
                application_id=f"batch_{i}",
                top_features=explanation["top_features"],
                base_value=explanation["base_value"],
                prediction_value=explanation["prediction_value"],
                total_shap_contribution=explanation["total_shap_contribution"],
                readable_explanation=explanation["readable_explanation"]
            )
            
            explanations.append(response)
        
        logger.info(f"Batch explanations generated for {len(explanations)} applications")
        return explanations
        
    except Exception as e:
        logger.error(f"Error in batch explanation: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

# Model information endpoints
@app.get("/model/info", tags=["Model"])
async def get_model_info():
    """Get information about the loaded model"""
    try:
        feature_importance = prediction_service.get_feature_importance()
        
        return {
            "model_version": "1.0",
            "model_type": "LightGBM Classifier",
            "training_approach": "Federated Learning Simulation",
            "total_features": len(feature_importance),
            "top_features": dict(list(feature_importance.items())[:10]) if feature_importance else {},
            "last_updated": "2024-01-15"
        }
        
    except Exception as e:
        logger.error(f"Error getting model info: {str(e)}")
        raise HTTPException(status_code=500, detail="Error retrieving model information")

@app.get("/model/features", tags=["Model"])
async def get_model_features():
    """Get list of all model features and their importance"""
    try:
        feature_importance = prediction_service.get_feature_importance()
        
        return {
            "features": feature_importance,
            "total_features": len(feature_importance)
        }
        
    except Exception as e:
        logger.error(f"Error getting model features: {str(e)}")
        raise HTTPException(status_code=500, detail="Error retrieving model features")

# Administrative endpoints
@app.post("/admin/retrain", tags=["Admin"])
async def trigger_model_retraining(background_tasks: BackgroundTasks):
    """Trigger model retraining (admin only)"""
    try:
        # Add retraining as background task
        background_tasks.add_task(retrain_model_async)
        
        return {
            "message": "Model retraining initiated",
            "status": "started",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error initiating model retraining: {str(e)}")
        raise HTTPException(status_code=500, detail="Error initiating retraining")

async def retrain_model_async():
    """Background task for model retraining"""
    try:
        logger.info("Starting model retraining...")
        # Import training script and run
        from scripts.train_model import FederatedLearningSimulator
        
        simulator = FederatedLearningSimulator()
        simulator.run_federated_simulation()
        
        # Reload services with new models
        global prediction_service, explainability_service
        prediction_service = PredictionService()
        explainability_service = ExplainabilityService()
        
        logger.info("Model retraining completed successfully")
        
    except Exception as e:
        logger.error(f"Error during model retraining: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
