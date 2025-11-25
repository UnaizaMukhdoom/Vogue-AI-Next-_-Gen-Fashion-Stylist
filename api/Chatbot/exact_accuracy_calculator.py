# Chatbot/exact_accuracy_calculator.py
# Calculate EXACT Training vs Testing Accuracy
# Uses the EXACT same feature processing as the trained model

import numpy as np
import pandas as pd
import pickle
import joblib
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
import os

def load_correct_data():
    """
    Load 384D embeddings and dataset
    Calculate EXACT accuracy using the same preprocessing as the model
    """
    print("="*60)
    print("EXACT ACCURACY CALCULATOR")
    print("="*60)
    
    # Try to load embeddings (if available)
    embedding_paths = [
        'fashion_embeddings_balanced.pkl',
        os.path.join('Chatbot', 'fashion_embeddings_balanced.pkl')
    ]
    
    embeddings = None
    for path in embedding_paths:
        if os.path.exists(path):
            try:
                with open(path, 'rb') as f:
                    embeddings = pickle.load(f)
                print(f"✓ Loaded embeddings from {path}")
                break
            except Exception as e:
                print(f"⚠ Could not load embeddings from {path}: {e}")
    
    # Load dataset
    dataset_paths = [
        'fashion_dataset_balanced.csv',
        'fashion_dataset_language_fixed.csv',
        os.path.join('Chatbot', 'fashion_dataset_balanced.csv'),
        os.path.join('Chatbot', 'fashion_dataset_language_fixed.csv'),
    ]
    
    df = None
    for path in dataset_paths:
        if os.path.exists(path):
            try:
                df = pd.read_csv(path)
                print(f"✓ Loaded dataset from {path}")
                break
            except Exception as e:
                print(f"⚠ Could not load dataset from {path}: {e}")
    
    if df is None:
        print("⚠ ERROR: Could not load dataset!")
        return
    
    # Normalize column names
    df.columns = df.columns.str.lower()
    
    required_cols = ['query', 'intent']
    if not all(col in df.columns for col in required_cols):
        print(f"⚠ Error: Dataset must have 'query' and 'intent' columns")
        print(f"Found columns: {df.columns.tolist()}")
        return
    
    queries = df['query'].astype(str).fillna('')
    intents = df['intent'].astype(str).fillna('')
    
    print(f"\nDataset Info:")
    print(f"  Total samples: {len(df)}")
    print(f"  Unique intents: {intents.nunique()}")
    print(f"  Intent distribution:")
    print(intents.value_counts().to_string())
    
    return queries, intents, embeddings

def preprocess_text_exact(text):
    """Exact same preprocessing as used in training"""
    import re
    text = str(text).lower()
    text = re.sub(r'[^a-z0-9\s]', '', text)
    text = ' '.join(text.split())
    return text

def calculate_exact_accuracy():
    """
    Calculate exact training and testing accuracy
    Uses the same preprocessing and train/test split as the model
    """
    queries, intents, embeddings = load_correct_data()
    
    if queries is None:
        return
    
    # Load trained model and vectorizer
    model_paths = [
        os.path.join('Chatbot', 'intent_classifier.pkl'),
        'intent_classifier.pkl'
    ]
    vectorizer_paths = [
        os.path.join('Chatbot', 'vectorizer.pkl'),
        'vectorizer.pkl'
    ]
    
    model = None
    vectorizer = None
    
    for path in model_paths:
        if os.path.exists(path):
            model = joblib.load(path)
            print(f"\n✓ Loaded model from {path}")
            break
    
    for path in vectorizer_paths:
        if os.path.exists(path):
            vectorizer = joblib.load(path)
            print(f"✓ Loaded vectorizer from {path}")
            break
    
    if model is None or vectorizer is None:
        print("\n⚠ ERROR: Could not load model files!")
        print("Please train the model first using train_intent_classifier.py")
        return
    
    # Preprocess queries (EXACT same as training)
    print("\nPreprocessing queries (same as training)...")
    processed_queries = [preprocess_text_exact(q) for q in queries]
    
    # Use same random_state as training
    X_train, X_test, y_train, y_test = train_test_split(
        processed_queries, intents,
        test_size=0.2,
        random_state=42,
        stratify=intents
    )
    
    print(f"\nData Split:")
    print(f"  Training: {len(X_train)} samples")
    print(f"  Testing: {len(X_test)} samples")
    
    # Vectorize (using the same vectorizer)
    print("\nVectorizing (using trained vectorizer)...")
    X_train_vec = vectorizer.transform(X_train)
    X_test_vec = vectorizer.transform(X_test)
    
    # Predict
    print("\nMaking predictions...")
    y_pred_train = model.predict(X_train_vec)
    y_pred_test = model.predict(X_test_vec)
    
    # Calculate accuracies
    train_accuracy = accuracy_score(y_train, y_pred_train)
    test_accuracy = accuracy_score(y_test, y_pred_test)
    
    print("\n" + "="*60)
    print("EXACT ACCURACY RESULTS")
    print("="*60)
    print(f"\nTraining Accuracy: {train_accuracy:.6f} ({train_accuracy*100:.4f}%)")
    print(f"Testing Accuracy: {test_accuracy:.6f} ({test_accuracy*100:.4f}%)")
    
    print("\n" + "-"*60)
    print("TRAINING SET DETAILS")
    print("-"*60)
    print(classification_report(y_train, y_pred_train))
    
    print("\n" + "-"*60)
    print("TESTING SET DETAILS")
    print("-"*60)
    print(classification_report(y_test, y_pred_test))
    
    print("\n" + "="*60)
    print("CALCULATION COMPLETE")
    print("="*60)

if __name__ == '__main__':
    calculate_exact_accuracy()

