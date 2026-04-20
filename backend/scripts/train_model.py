# backend/scripts/train_model.py
"""
Federated Learning Simulation and Model Training Script

This script simulates a federated learning environment by:
1. Loading the main processed dataset
2. Partitioning data into virtual "client" datasets
3. Training local models on each client's data
4. Aggregating insights into a global model
5. Creating and saving SHAP explainer for interpretability
"""

import pandas as pd
import numpy as np
import os
import joblib
from pathlib import Path
import logging
from typing import List, Tuple
from lightgbm import LGBMClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, roc_auc_score
import shap

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class FederatedLearningSimulator:
    def __init__(self, data_path: str = r"F:\Atharva\flutter_projects\kredai\backend\data\processed_data.csv", n_clients: int = 5):
        self.data_path = data_path
        self.n_clients = n_clients
        self.models_dir = Path("trained_models")
        self.models_dir.mkdir(exist_ok=True)
        
        # Model configuration
        self.model_params = {
            'objective': 'binary',
            'metric': 'binary_logloss',
            'boosting_type': 'gbdt',
            'num_leaves': 31,
            'learning_rate': 0.05,
            'feature_fraction': 0.9,
            'bagging_fraction': 0.8,
            'bagging_freq': 5,
            'verbose': 0,
            'random_state': 42
        }
        
    def load_and_prepare_data(self) -> pd.DataFrame:
        """Load and prepare the main dataset"""
        logger.info(f"Loading data from {self.data_path}")
    
        if not os.path.exists(self.data_path):
            raise FileNotFoundError(f"Dataset not found at {self.data_path}")
    
        df = pd.read_csv(self.data_path)
        logger.info(f"Loaded dataset with {len(df)} records and {len(df.columns)} columns")

        # 🎯 Map 0.0 or 0.21 → class 0, 1.0 → class 1
        df['target'] = df['target'].map({0.0: 0, 0.21: 0, 1.0: 1})
        df.dropna(subset=['target'], inplace=True)  # In case target mapping fails
        df['target'] = df['target'].astype(int)

        # ✅ Target column check (informational, can be kept)
        if 'target' not in df.columns:
            raise ValueError("Target column 'target' not found in dataset")

        return df
    
    def partition_data_for_clients(self, df: pd.DataFrame) -> List[pd.DataFrame]:
        """Partition dataset into client datasets for federated simulation"""
        logger.info(f"Partitioning data into {self.n_clients} client datasets")
        
        # Shuffle data for random distribution
        df_shuffled = df.sample(frac=1, random_state=42).reset_index(drop=True)
        
        # Create client partitions
        client_datasets = []
        partition_size = len(df_shuffled) // self.n_clients
        
        for i in range(self.n_clients):
            start_idx = i * partition_size
            if i == self.n_clients - 1:  # Last client gets remaining data
                end_idx = len(df_shuffled)
            else:
                end_idx = (i + 1) * partition_size
                
            client_data = df_shuffled.iloc[start_idx:end_idx].copy()
            client_datasets.append(client_data)
            
            # Save client data
            client_dir = Path("data/client_data")
            client_dir.mkdir(exist_ok=True)
            client_data.to_csv(client_dir / f"client_{i+1}.csv", index=False)
            
            logger.info(f"Client {i+1}: {len(client_data)} records")
            
        return client_datasets
    
    def prepare_features_and_target(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        """Prepare features and target variable"""
        # Select relevant features for credit risk modeling
        feature_cols = [
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
        
        # Filter available features
        available_features = [col for col in feature_cols if col in df.columns]
        logger.info(f"Using {len(available_features)} features for training")
        
        X = df[available_features].fillna(0)  # Simple imputation for demo
        y = df['target']
        
        return X, y
    
    def train_client_models(self, client_datasets: List[pd.DataFrame]) -> List[LGBMClassifier]:
        """Train local models for each client"""
        logger.info("Training local models for each client")
        
        client_models = []
        client_performances = []
        
        for i, client_data in enumerate(client_datasets):
            logger.info(f"Training model for Client {i+1}")
            
            # Prepare client data
            X_client, y_client = self.prepare_features_and_target(client_data)
            
            # Split client data for local validation
            X_train, X_val, y_train, y_val = train_test_split(
                X_client, y_client, test_size=0.2, random_state=42, stratify=y_client
            )
            
            # Train local model
            client_model = LGBMClassifier(**self.model_params)
            client_model.fit(X_train, y_train)
            
            # Evaluate local model
            y_pred = client_model.predict(X_val)
            y_prob = client_model.predict_proba(X_val)[:, 1]
            
            accuracy = accuracy_score(y_val, y_pred)
            auc = roc_auc_score(y_val, y_prob)
            
            client_performances.append({
                'client_id': i+1,
                'accuracy': accuracy,
                'auc': auc,
                'train_samples': len(X_train),
                'val_samples': len(X_val)
            })
            
            client_models.append(client_model)
            logger.info(f"Client {i+1} - Accuracy: {accuracy:.4f}, AUC: {auc:.4f}")
        
        # Log overall client performance
        avg_accuracy = np.mean([p['accuracy'] for p in client_performances])
        avg_auc = np.mean([p['auc'] for p in client_performances])
        logger.info(f"Average client performance - Accuracy: {avg_accuracy:.4f}, AUC: {avg_auc:.4f}")
        
        return client_models
    
    def create_global_model(self, df: pd.DataFrame) -> LGBMClassifier:
        """Create global model using complete dataset (simulating federated aggregation)"""
        logger.info("Creating global model from complete dataset")
        
        # Prepare full dataset
        X, y = self.prepare_features_and_target(df)
        
        # Split for training and testing
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Train global model
        global_model = LGBMClassifier(**self.model_params)
        global_model.fit(X_train, y_train)
        
        # Evaluate global model
        y_pred = global_model.predict(X_test)
        y_prob = global_model.predict_proba(X_test)[:, 1]
        
        accuracy = accuracy_score(y_test, y_pred)
        auc = roc_auc_score(y_test, y_prob)
        
        logger.info(f"Global model performance - Accuracy: {accuracy:.4f}, AUC: {auc:.4f}")
        logger.info(f"Classification Report:\n{classification_report(y_test, y_pred)}")
        
        return global_model, X_train
    
    def create_shap_explainer(self, model: LGBMClassifier, X_train: pd.DataFrame) -> shap.TreeExplainer:
        """Create SHAP explainer for model interpretability"""
        logger.info("Creating SHAP explainer")
        
        # Create TreeExplainer for LightGBM
        explainer = shap.TreeExplainer(model)
        
        # Calculate SHAP values for a sample of training data
        sample_size = min(100, len(X_train))
        X_sample = X_train.sample(n=sample_size, random_state=42)
        shap_values = explainer.shap_values(X_sample)
        
        logger.info(f"SHAP explainer created with sample size: {sample_size}")
        
        return explainer
    
    def save_models(self, global_model: LGBMClassifier, explainer: shap.TreeExplainer):
        """Save trained models and explainer"""
        logger.info("Saving models and explainer")
        
        # Save global model
        model_path = self.models_dir / "global_credit_model.pkl"
        joblib.dump(global_model, model_path)
        logger.info(f"Global model saved to {model_path}")
        
        # Save SHAP explainer
        explainer_path = self.models_dir / "shap_explainer.pkl"
        joblib.dump(explainer, explainer_path)
        logger.info(f"SHAP explainer saved to {explainer_path}")
    
    def run_federated_simulation(self):
        """Run complete federated learning simulation"""
        logger.info("Starting federated learning simulation")
        
        try:
            # Load data
            df = self.load_and_prepare_data()
            
            # Partition data for clients
            client_datasets = self.partition_data_for_clients(df)
            
            # Train client models (simulation step)
            client_models = self.train_client_models(client_datasets)
            
            # Create global model (practical aggregation for demo)
            global_model, X_train = self.create_global_model(df)
            
            # Create SHAP explainer
            explainer = self.create_shap_explainer(global_model, X_train)
            
            # Save models
            self.save_models(global_model, explainer)
            
            logger.info("Federated learning simulation completed successfully!")
            
        except Exception as e:
            logger.error(f"Error during federated simulation: {str(e)}")
            raise


def main():
    """Main execution function"""
    simulator = FederatedLearningSimulator()
    simulator.run_federated_simulation()


if __name__ == "__main__":
    main()
