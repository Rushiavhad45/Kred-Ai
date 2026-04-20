# backend/scripts/data_preprocessing.py
"""
Data Preprocessing Utilities

Contains functions for data cleaning, feature engineering, and preparation.
"""

import pandas as pd
import numpy as np
from pathlib import Path
import logging
from typing import Dict, List, Tuple, Optional
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split

logger = logging.getLogger(__name__)

class DataPreprocessor:
    """Main class for data preprocessing operations"""
    
    def __init__(self):
        self.scalers = {}
        self.encoders = {}
        self.feature_columns = []
        
    def load_data(self, file_path: str) -> pd.DataFrame:
        """Load data from CSV file"""
        try:
            path = Path(file_path)
            if not path.exists():
                raise FileNotFoundError(f"Data file not found: {file_path}")
            
            df = pd.read_csv(file_path)
            logger.info(f"Loaded data: {len(df)} rows, {len(df.columns)} columns from {file_path}")
            return df
        except Exception as e:
            logger.error(f"Error loading data: {str(e)}")
            raise
    
    def clean_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Clean the dataset by handling missing values and outliers"""
        logger.info("Starting data cleaning...")
        
        # Create a copy to avoid modifying original
        clean_df = df.copy()
        
        # Handle missing values
        numeric_columns = clean_df.select_dtypes(include=[np.number]).columns
        categorical_columns = clean_df.select_dtypes(include=['object']).columns
        
        # Fill numeric missing values with median
        for col in numeric_columns:
            if clean_df[col].isnull().any():
                median_val = clean_df[col].median()
                clean_df[col].fillna(median_val, inplace=True)
                logger.info(f"Filled {col} missing values with median: {median_val}")
        
        # Fill categorical missing values with mode
        for col in categorical_columns:
            if clean_df[col].isnull().any():
                mode_val = clean_df[col].mode().iloc[0] if not clean_df[col].mode().empty else 'Unknown'
                clean_df[col].fillna(mode_val, inplace=True)
                logger.info(f"Filled {col} missing values with mode: {mode_val}")
        
        # Remove duplicates
        initial_rows = len(clean_df)
        clean_df.drop_duplicates(inplace=True)
        removed_duplicates = initial_rows - len(clean_df)
        if removed_duplicates > 0:
            logger.info(f"Removed {removed_duplicates} duplicate rows")
        
        # Handle outliers using IQR method for key numeric fields
        outlier_columns = ['person_income', 'loan_amnt', 'loan_int_rate']
        for col in outlier_columns:
            if col in clean_df.columns:
                Q1 = clean_df[col].quantile(0.25)
                Q3 = clean_df[col].quantile(0.75)
                IQR = Q3 - Q1
                lower_bound = Q1 - 1.5 * IQR
                upper_bound = Q3 + 1.5 * IQR
                
                outliers_count = ((clean_df[col] < lower_bound) | (clean_df[col] > upper_bound)).sum()
                if outliers_count > 0:
                    # Cap outliers instead of removing them
                    clean_df[col] = np.clip(clean_df[col], lower_bound, upper_bound)
                    logger.info(f"Capped {outliers_count} outliers in {col}")
        
        logger.info(f"Data cleaning completed. Final shape: {clean_df.shape}")
        return clean_df
    
    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Create new features from existing data"""
        logger.info("Starting feature engineering...")
        
        feature_df = df.copy()
        
        # Calculate loan to income ratio
        if 'loan_amnt' in feature_df.columns and 'person_income' in feature_df.columns:
            feature_df['loan_to_income_ratio'] = feature_df['loan_amnt'] / feature_df['person_income']
            feature_df['loan_to_income_ratio'].fillna(0, inplace=True)
        
        # Calculate age groups
        if 'age' in feature_df.columns:
            feature_df['age_group'] = pd.cut(
                feature_df['age'], 
                bins=[0, 25, 35, 50, 100], 
                labels=['young', 'adult', 'middle_age', 'senior']
            )
        
        # Calculate employment stability score
        if 'person_emp_length' in feature_df.columns:
            feature_df['employment_stability'] = pd.cut(
                feature_df['person_emp_length'],
                bins=[-1, 1, 5, 10, 50],
                labels=['new', 'established', 'experienced', 'veteran']
            )
        
        # Calculate credit utilization indicator
        if all(col in feature_df.columns for col in ['loan_amnt', 'cb_person_cred_hist_length']):
            feature_df['credit_experience'] = (
                feature_df['cb_person_cred_hist_length'] * 
                np.log1p(feature_df['loan_amnt'])
            )
        
        # Digital engagement score
        digital_cols = ['digital_wallet_usage', 'mobile_banking_user', 'monthly_digital_transactions']
        available_digital_cols = [col for col in digital_cols if col in feature_df.columns]
        if available_digital_cols:
            feature_df['digital_score'] = feature_df[available_digital_cols].sum(axis=1)
        
        # Payment behavior score
        payment_cols = ['on_time_payments_12m', 'late_payments_12m']
        if all(col in feature_df.columns for col in payment_cols):
            total_payments = feature_df['on_time_payments_12m'] + feature_df['late_payments_12m']
            feature_df['payment_reliability'] = np.where(
                total_payments > 0,
                feature_df['on_time_payments_12m'] / total_payments,
                0.5  # Default neutral score
            )
        
        logger.info(f"Feature engineering completed. New shape: {feature_df.shape}")
        return feature_df
    
    def encode_categorical_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Encode categorical variables"""
        logger.info("Encoding categorical features...")
        
        encoded_df = df.copy()
        categorical_columns = encoded_df.select_dtypes(include=['object']).columns
        
        for col in categorical_columns:
            if col not in self.encoders:
                self.encoders[col] = LabelEncoder()
                encoded_df[col] = self.encoders[col].fit_transform(encoded_df[col].astype(str))
                logger.info(f"Encoded {col}: {len(self.encoders[col].classes_)} unique values")
            else:
                # Handle unseen categories
                unique_values = encoded_df[col].unique()
                known_values = set(self.encoders[col].classes_)
                new_values = set(unique_values) - known_values
                
                if new_values:
                    logger.warning(f"New categories found in {col}: {new_values}")
                    # Assign new categories to a default value (first class)
                    encoded_df[col] = encoded_df[col].map(
                        lambda x: 0 if x not in known_values else self.encoders[col].transform([x])[0]
                    )
                else:
                    encoded_df[col] = self.encoders[col].transform(encoded_df[col].astype(str))
        
        return encoded_df
    
    def scale_features(self, df: pd.DataFrame, feature_columns: List[str]) -> pd.DataFrame:
        """Scale numeric features"""
        logger.info("Scaling numeric features...")
        
        scaled_df = df.copy()
        
        for col in feature_columns:
            if col in scaled_df.columns and scaled_df[col].dtype in ['int64', 'float64']:
                if col not in self.scalers:
                    self.scalers[col] = StandardScaler()
                    scaled_df[col] = self.scalers[col].fit_transform(scaled_df[[col]])
                    logger.info(f"Fitted and transformed {col}")
                else:
                    scaled_df[col] = self.scalers[col].transform(scaled_df[[col]])
                    logger.info(f"Transformed {col}")
        
        return scaled_df
    
    def prepare_for_training(self, df: pd.DataFrame, target_column: str = 'target') -> Tuple[pd.DataFrame, pd.Series]:
        """Prepare data for model training"""
        logger.info("Preparing data for training...")
        
        if target_column not in df.columns:
            raise ValueError(f"Target column '{target_column}' not found in dataset")
        
        # Separate features and target
        X = df.drop(columns=[target_column])
        y = df[target_column]
        
        # Store feature columns for later use
        self.feature_columns = X.columns.tolist()
        
        logger.info(f"Training data prepared: {X.shape} features, {len(y)} samples")
        logger.info(f"Target distribution: {y.value_counts().to_dict()}")
        
        return X, y
    
    def split_data(self, X: pd.DataFrame, y: pd.Series, 
                   test_size: float = 0.2, random_state: int = 42) -> Tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series]:
        """Split data into training and testing sets"""
        logger.info(f"Splitting data: {1-test_size:.1%} train, {test_size:.1%} test")
        
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        logger.info(f"Train set: {X_train.shape}, Test set: {X_test.shape}")
        return X_train, X_test, y_train, y_test

def load_and_preprocess_data(file_path: str, target_column: str = 'target') -> Tuple[pd.DataFrame, pd.Series]:
    """Main function to load and preprocess data"""
    preprocessor = DataPreprocessor()
    
    # Load data
    df = preprocessor.load_data(file_path)
    
    # Clean data
    clean_df = preprocessor.clean_data(df)
    
    # Engineer features
    featured_df = preprocessor.engineer_features(clean_df)
    
    # Encode categorical features
    encoded_df = preprocessor.encode_categorical_features(featured_df)
    
    # Prepare for training
    X, y = preprocessor.prepare_for_training(encoded_df, target_column)
    
    return X, y

def save_processed_data(df: pd.DataFrame, output_path: str):
    """Save processed data to CSV"""
    try:
        df.to_csv(output_path, index=False)
        logger.info(f"Processed data saved to: {output_path}")
    except Exception as e:
        logger.error(f"Error saving processed data: {str(e)}")
        raise

if __name__ == "__main__":
    # Example usage
    input_file = "data/processed_data.csv"
    output_file = "data/preprocessed_data.csv"
    
    try:
        X, y = load_and_preprocess_data(input_file)
        
        # Combine X and y for saving
        final_df = X.copy()
        final_df['target'] = y
        
        save_processed_data(final_df, output_file)
        print(f"Preprocessing completed successfully!")
        
    except Exception as e:
        print(f"Error during preprocessing: {str(e)}")
