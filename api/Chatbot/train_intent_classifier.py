# Chatbot/train_intent_classifier.py
# Train intent classifier for fashion chatbot

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib
import pickle
import os

def load_and_prepare_data(csv_path='fashion_dataset_balanced.csv'):
    """
    Load and prepare dataset for training
    """
    print(f"Loading dataset from {csv_path}...")
    
    if not os.path.exists(csv_path):
        print(f"⚠ Error: Dataset file '{csv_path}' not found!")
        print("Please ensure the dataset CSV file is in the Chatbot directory.")
        return None, None
    
    try:
        df = pd.read_csv(csv_path)
        
        # Check for required columns (handle various naming conventions)
        df.columns = df.columns.str.strip()  # Remove whitespace
        
        # Try different column name patterns
        query_col = None
        intent_col = None
        response_col = None
        
        # Look for query column (various names)
        for col in df.columns:
            col_lower = col.lower()
            if col_lower in ['query', 'user_query', 'question', 'text']:
                query_col = col
                break
        
        # Look for intent column
        for col in df.columns:
            col_lower = col.lower()
            if col_lower in ['intent', 'label', 'category']:
                intent_col = col
                break
        
        # Look for response column (various names)
        for col in df.columns:
            col_lower = col.lower()
            if col_lower in ['response', 'bot_response', 'answer', 'reply']:
                response_col = col
                break
        
        if query_col is None or intent_col is None:
            print(f"⚠ Error: Dataset must have query and intent columns")
            print(f"Found columns: {df.columns.tolist()}")
            print(f"Looking for: query/user_query, intent, response/bot_response")
            return None, None
        
        queries = df[query_col].astype(str).fillna('')
        intents = df[intent_col].astype(str).fillna('')
        
        print(f"✓ Loaded {len(df)} samples")
        print(f"✓ Found {intents.nunique()} unique intents: {sorted(intents.unique())}")
        
        return queries, intents
    
    except Exception as e:
        print(f"⚠ Error loading dataset: {e}")
        return None, None

def preprocess_text(text):
    """Preprocess text for training"""
    import re
    # Convert to lowercase
    text = str(text).lower()
    # Remove special characters but keep spaces
    text = re.sub(r'[^a-z0-9\s]', '', text)
    # Remove extra spaces
    text = ' '.join(text.split())
    return text

def train_model(queries, intents, test_size=0.2, random_state=42):
    """
    Train the intent classifier model
    """
    print("\n" + "="*50)
    print("TRAINING INTENT CLASSIFIER")
    print("="*50)
    
    # Preprocess queries
    print("Preprocessing queries...")
    processed_queries = [preprocess_text(q) for q in queries]
    
    # Split data
    print(f"Splitting data (test_size={test_size})...")
    X_train, X_test, y_train, y_test = train_test_split(
        processed_queries, intents, 
        test_size=test_size, 
        random_state=random_state,
        stratify=intents
    )
    
    print(f"Training samples: {len(X_train)}")
    print(f"Test samples: {len(X_test)}")
    
    # Vectorize
    print("\nCreating TF-IDF vectorizer...")
    vectorizer = TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        min_df=2,
        max_df=0.95
    )
    
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)
    
    print(f"✓ Feature matrix shape: {X_train_vec.shape}")
    
    # Train model
    print("\nTraining Multinomial Naive Bayes classifier...")
    model = MultinomialNB(alpha=1.0)
    model.fit(X_train_vec, y_train)
    
    # Evaluate
    print("\nEvaluating model...")
    y_pred_train = model.predict(X_train_vec)
    y_pred_test = model.predict(X_test_vec)
    
    train_accuracy = accuracy_score(y_train, y_pred_train)
    test_accuracy = accuracy_score(y_test, y_pred_test)
    
    print(f"\n{'='*50}")
    print("TRAINING RESULTS")
    print(f"{'='*50}")
    print(f"Training Accuracy: {train_accuracy:.4f} ({train_accuracy*100:.2f}%)")
    print(f"Test Accuracy: {test_accuracy:.4f} ({test_accuracy*100:.2f}%)")
    
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred_test))
    
    return model, vectorizer, {
        'train_accuracy': train_accuracy,
        'test_accuracy': test_accuracy,
        'X_test': X_test,
        'y_test': y_test,
        'y_pred': y_pred_test
    }

def save_model(model, vectorizer, model_path='intent_classifier.pkl', vectorizer_path='vectorizer.pkl'):
    """
    Save trained model and vectorizer
    """
    print(f"\nSaving model to {model_path}...")
    joblib.dump(model, model_path)
    print(f"✓ Model saved")
    
    print(f"Saving vectorizer to {vectorizer_path}...")
    joblib.dump(vectorizer, vectorizer_path)
    print(f"✓ Vectorizer saved")

def main():
    """
    Main training function
    """
    print("="*50)
    print("FASHION CHATBOT - INTENT CLASSIFIER TRAINING")
    print("="*50)
    
    # Try to find dataset in current directory or Chatbot directory
    dataset_paths = [
        'fashion_dataset_balanced.csv',
        'fashion_dataset_language_fixed.csv',
        'fashion_dataset_with_indices.csv',
        os.path.join('Chatbot', 'fashion_dataset_balanced.csv'),
        os.path.join('Chatbot', 'fashion_dataset_language_fixed.csv'),
    ]
    
    queries = None
    intents = None
    
    for path in dataset_paths:
        if os.path.exists(path):
            queries, intents = load_and_prepare_data(path)
            if queries is not None:
                break
    
    if queries is None:
        print("\n⚠ ERROR: Could not find dataset file!")
        print("Please ensure one of these files exists:")
        for path in dataset_paths:
            print(f"  - {path}")
        return
    
    # Train model
    model, vectorizer, results = train_model(queries, intents)
    
    # Save model to current directory (Chatbot folder)
    model_dir = os.path.dirname(os.path.abspath(__file__))
    
    model_path = os.path.join(model_dir, 'intent_classifier.pkl')
    vectorizer_path = os.path.join(model_dir, 'vectorizer.pkl')
    
    save_model(model, vectorizer, model_path, vectorizer_path)
    
    print("\n" + "="*50)
    print("TRAINING COMPLETE!")
    print("="*50)
    print(f"\nModel files saved to:")
    print(f"  - {model_path}")
    print(f"  - {vectorizer_path}")
    print("\nYou can now use these files in your Flask API!")

if __name__ == '__main__':
    main()

