# backend/scripts/split_clients.py
"""
Client Data Splitting Script for Federated Learning Simulation

Splits the main processed dataset into multiple client datasets 
to simulate a federated learning environment.
"""

import pandas as pd
import numpy as np
import os
from pathlib import Path
import logging
from typing import List

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def split_data_for_clients(
    input_csv: str,
    output_dir: str,
    num_clients: int = 5,
    random_state: int = 42
) -> List[str]:
    """
    Split the main dataset into client datasets for federated learning simulation.

    Args:
        input_csv: Full path to the main processed dataset.
        output_dir: Full path to save client datasets.
        num_clients: Number of clients to simulate.
        random_state: Random seed for reproducibility.

    Returns:
        List of paths to created client dataset CSVs.
    """
    try:
        # Check if input file exists
        if not os.path.exists(input_csv):
            raise FileNotFoundError(f"❌ Input file not found: {input_csv}")

        # Create output directory if it doesn't exist
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        logger.info(f"Loading dataset from {input_csv}")
        df = pd.read_csv(input_csv)
        logger.info(f"📊 Loaded dataset: {len(df)} rows, {len(df.columns)} columns.")

        # Shuffle data
        df_shuffled = df.sample(frac=1, random_state=random_state).reset_index(drop=True)
        logger.info("🔀 Shuffled dataset for random distribution.")

        # Split into N parts
        client_files = []
        client_datasets = np.array_split(df_shuffled, num_clients)

        for i, client_df in enumerate(client_datasets, 1):
            client_filename = f"client_{i}.csv"
            client_filepath = output_path / client_filename
            client_df.to_csv(client_filepath, index=False)

            logger.info(f"✅ Client {i}: {len(client_df)} rows saved -> {client_filepath}")
            if 'target' in client_df.columns:
                logger.info(f"   🎯 Target distribution: {client_df['target'].value_counts().to_dict()}")

            client_files.append(str(client_filepath))

        print_split_summary(df, client_datasets, output_dir)
        return client_files

    except Exception as e:
        logger.error(f"❌ Error splitting data: {str(e)}")
        raise

def print_split_summary(original_df: pd.DataFrame, client_datasets: List[pd.DataFrame], output_dir: str):
    """Prints a summary of the client split results."""
    print("\n" + "="*60)
    print("📈 CLIENT DATA SPLITTING SUMMARY")
    print("="*60)

    print(f"Original dataset: {len(original_df)} rows, {len(original_df.columns)} columns")
    print(f"Number of clients: {len(client_datasets)}")
    print(f"Output directory: {output_dir}")

    if 'target' in original_df.columns:
        print(f"Original target distribution: {original_df['target'].value_counts().to_dict()}")

    print("\nClient Details:")
    for i, client_data in enumerate(client_datasets, 1):
        print(f"Client {i}:")
        print(f"  - Rows: {len(client_data)}")
        print(f"  - Percent of total: {len(client_data) / len(original_df) * 100:.2f}%")
        if 'target' in client_data.columns:
            print(f"  - Target dist: {client_data['target'].value_counts().to_dict()}")
        print()

    print("📂 Files Created:")
    for i in range(len(client_datasets)):
        print(f"  - client_{i+1}.csv")

    print("="*60 + "\n")

def validate_client_data(output_dir: str, num_clients: int) -> bool:
    """Validates that each client CSV file was created successfully."""
    try:
        output_path = Path(output_dir)
        total_rows = 0

        for i in range(1, num_clients + 1):
            filepath = output_path / f"client_{i}.csv"
            if not filepath.exists():
                logger.error(f"❌ Missing file: {filepath}")
                return False
            df = pd.read_csv(filepath)
            logger.info(f"✅ Client {i} file valid with {len(df)} rows.")
            total_rows += len(df)

        logger.info(f"✅ All client files present. Total rows in split: {total_rows}")
        return True

    except Exception as e:
        logger.error(f"❌ Error validating client data: {str(e)}")
        return False

def merge_client_data(client_dir: str, output_file: str, num_clients: int) -> int:
    """Merges client CSVs back into a single file to verify."""
    try:
        client_path = Path(client_dir)
        combined = []

        for i in range(1, num_clients + 1):
            file = client_path / f"client_{i}.csv"
            if file.exists():
                df = pd.read_csv(file)
                combined.append(df)

        if combined:
            merged_df = pd.concat(combined, ignore_index=True)
            merged_df.to_csv(output_file, index=False)
            logger.info(f"🧩 Merged file created: {output_file} with {len(merged_df)} rows.")
            return len(merged_df)
        else:
            logger.warning("⚠️ No files found to merge.")
            return 0

    except Exception as e:
        logger.error(f"❌ Error merging client data: {str(e)}")
        return 0

# 🔧 MAIN RUN CONFIGURATION
if __name__ == "__main__":
    # Absolute Paths (Windows - escaped with raw string)
    INPUT_CSV = r"F:\Atharva\flutter_projects\kredai\backend\data\processed_data.csv"
    OUTPUT_DIR = r"F:\Atharva\flutter_projects\kredai\backend\data\client_data"
    NUM_CLIENTS = 5

    print("🚀 Starting Client Data Split Script")
    print(f"👉 Input File: {INPUT_CSV}")
    print(f"👉 Output Dir: {OUTPUT_DIR}")
    print(f"👉 Clients to Create: {NUM_CLIENTS}")
    print("--------------------------------------------------")

    try:
        client_files = split_data_for_clients(INPUT_CSV, OUTPUT_DIR, NUM_CLIENTS)

        if validate_client_data(OUTPUT_DIR, NUM_CLIENTS):
            print("✅ All client files created and validated successfully.")

            # Merge (Optional)
            VERIFICATION_FILE = os.path.join(str(Path(OUTPUT_DIR).parent), "merged_output.csv")
            merged_rows = merge_client_data(OUTPUT_DIR, VERIFICATION_FILE, NUM_CLIENTS)
            print(f"🔄 Merged check complete. Total rows: {merged_rows}")

        else:
            print("❌ Some files are missing or invalid.")

    except Exception as e:
        print(f"❌ Script crashed: {e}")
