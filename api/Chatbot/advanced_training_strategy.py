# Chatbot/advanced_training_strategy.py
# Advanced training strategies for improving chatbot performance

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, VotingClassifier
from sklearn.metrics import accuracy_score, classification_report, f1_score
import joblib
import os

class AdvancedTrainingStrategy:
    """
    Advanced training strategies for fashion chatbot
    Includes ensemble methods, hyperparameter tuning, and data augmentation
    """
    
    def __init__(self, dataset_path=None):
        self.dataset = None
        self.models = {}
        self.best_model = None
        self.best_vectorizer = None
        
        if dataset_path:
            self.load_dataset(dataset_path)
    
    def load_dataset(self, path):
        """Load and prepare dataset"""
        try:
            self.dataset = pd.read_csv(path)
            self.dataset.columns = self.dataset.columns.str.lower()
            print(f"✓ Loaded dataset with {len(self.dataset)} samples")
        except Exception as e:
            print(f"⚠ Error loading dataset: {e}")
    
    def preprocess_text(self, text):
        """Preprocess text"""
        import re
        text = str(text).lower()
        text = re.sub(r'[^a-z0-9\s]', '', text)
        text = ' '.join(text.split())
        return text
    
    def train_ensemble_model(self, test_size=0.2, random_state=42):
        """
        Train ensemble model using multiple classifiers
        """
        if self.dataset is None:
            print("⚠ No dataset loaded!")
            return None, None
        
        print("\n" + "="*60)
        print("ADVANCED TRAINING: ENSEMBLE MODEL")
        print("="*60)
        
        # Prepare data
        queries = self.dataset['query'].astype(str).fillna('')
        intents = self.dataset['intent'].astype(str).fillna('')
        
        processed_queries = [self.preprocess_text(q) for q in queries]
        
        # Split
        X_train, X_test, y_train, y_test = train_test_split(
            processed_queries, intents,
            test_size=test_size,
            random_state=random_state,
            stratify=intents
        )
        
        # Vectorize
        print("\nCreating vectorizer...")
        vectorizer = TfidfVectorizer(
            max_features=5000,
            ngram_range=(1, 2),
            min_df=2,
            max_df=0.95
        )
        
        X_train_vec = vectorizer.fit_transform(X_train)
        X_test_vec = vectorizer.transform(X_test)
        
        # Train multiple models
        print("\nTraining individual models...")
        
        # Model 1: Naive Bayes
        print("  1. Training Multinomial Naive Bayes...")
        nb_model = MultinomialNB(alpha=1.0)
        nb_model.fit(X_train_vec, y_train)
        nb_score = accuracy_score(y_test, nb_model.predict(X_test_vec))
        print(f"     Accuracy: {nb_score:.4f}")
        
        # Model 2: Logistic Regression
        print("  2. Training Logistic Regression...")
        lr_model = LogisticRegression(max_iter=1000, random_state=random_state)
        lr_model.fit(X_train_vec, y_train)
        lr_score = accuracy_score(y_test, lr_model.predict(X_test_vec))
        print(f"     Accuracy: {lr_score:.4f}")
        
        # Model 3: Random Forest
        print("  3. Training Random Forest...")
        rf_model = RandomForestClassifier(n_estimators=100, random_state=random_state, n_jobs=-1)
        rf_model.fit(X_train_vec, y_train)
        rf_score = accuracy_score(y_test, rf_model.predict(X_test_vec))
        print(f"     Accuracy: {rf_score:.4f}")
        
        # Create ensemble (voting classifier)
        print("\nCreating ensemble model...")
        ensemble = VotingClassifier(
            estimators=[
                ('nb', nb_model),
                ('lr', lr_model),
                ('rf', rf_model)
            ],
            voting='hard'
        )
        
        ensemble.fit(X_train_vec, y_train)
        ensemble_score = accuracy_score(y_test, ensemble.predict(X_test_vec))
        
        print(f"\n{'='*60}")
        print("ENSEMBLE RESULTS")
        print(f"{'='*60}")
        print(f"Naive Bayes:      {nb_score:.4f}")
        print(f"Logistic Reg:     {lr_score:.4f}")
        print(f"Random Forest:    {rf_score:.4f}")
        print(f"Ensemble:         {ensemble_score:.4f}")
        print(f"\nBest model: Ensemble (improvement: {ensemble_score - max(nb_score, lr_score, rf_score):.4f})")
        
        self.models = {
            'nb': nb_model,
            'lr': lr_model,
            'rf': rf_model,
            'ensemble': ensemble
        }
        
        self.best_model = ensemble
        self.best_vectorizer = vectorizer
        
        return ensemble, vectorizer
    
    def hyperparameter_tuning(self, test_size=0.2, random_state=42):
        """
        Perform hyperparameter tuning using GridSearchCV
        """
        if self.dataset is None:
            print("⚠ No dataset loaded!")
            return None, None
        
        print("\n" + "="*60)
        print("HYPERPARAMETER TUNING")
        print("="*60)
        
        # Prepare data
        queries = self.dataset['query'].astype(str).fillna('')
        intents = self.dataset['intent'].astype(str).fillna('')
        
        processed_queries = [self.preprocess_text(q) for q in queries]
        
        # Split
        X_train, X_test, y_train, y_test = train_test_split(
            processed_queries, intents,
            test_size=test_size,
            random_state=random_state,
            stratify=intents
        )
        
        # Vectorize
        vectorizer = TfidfVectorizer(
            max_features=5000,
            ngram_range=(1, 2),
            min_df=2,
            max_df=0.95
        )
        
        X_train_vec = vectorizer.fit_transform(X_train)
        X_test_vec = vectorizer.transform(X_test)
        
        # Grid search for Naive Bayes
        print("\nTuning Naive Bayes hyperparameters...")
        param_grid = {
            'alpha': [0.1, 0.5, 1.0, 2.0]
        }
        
        nb = MultinomialNB()
        grid_search = GridSearchCV(
            nb, param_grid, cv=5,
            scoring='accuracy', n_jobs=-1
        )
        
        grid_search.fit(X_train_vec, y_train)
        
        print(f"Best parameters: {grid_search.best_params_}")
        print(f"Best CV score: {grid_search.best_score_:.4f}")
        
        # Test on test set
        best_model = grid_search.best_estimator_
        test_score = accuracy_score(y_test, best_model.predict(X_test_vec))
        print(f"Test accuracy: {test_score:.4f}")
        
        self.best_model = best_model
        self.best_vectorizer = vectorizer
        
        return best_model, vectorizer
    
    def save_best_model(self, model_path='best_model.pkl', vectorizer_path='best_vectorizer.pkl'):
        """Save the best trained model"""
        if self.best_model is None or self.best_vectorizer is None:
            print("⚠ No model trained yet!")
            return
        
        model_dir = 'Chatbot'
        if not os.path.exists(model_dir):
            os.makedirs(model_dir)
        
        model_full_path = os.path.join(model_dir, model_path)
        vectorizer_full_path = os.path.join(model_dir, vectorizer_path)
        
        joblib.dump(self.best_model, model_full_path)
        joblib.dump(self.best_vectorizer, vectorizer_full_path)
        
        print(f"\n✓ Saved best model to {model_full_path}")
        print(f"✓ Saved vectorizer to {vectorizer_full_path}")

def main():
    """Main function to run advanced training"""
    print("="*60)
    print("ADVANCED TRAINING STRATEGIES")
    print("="*60)
    
    # Find dataset
    dataset_paths = [
        'fashion_dataset_balanced.csv',
        os.path.join('Chatbot', 'fashion_dataset_balanced.csv'),
    ]
    
    dataset_path = None
    for path in dataset_paths:
        if os.path.exists(path):
            dataset_path = path
            break
    
    if not dataset_path:
        print("⚠ Dataset not found!")
        return
    
    # Initialize strategy
    strategy = AdvancedTrainingStrategy(dataset_path)
    
    # Choose training method
    print("\nChoose training strategy:")
    print("1. Ensemble Model (recommended)")
    print("2. Hyperparameter Tuning")
    
    choice = input("\nEnter choice (1 or 2): ").strip()
    
    if choice == '1':
        strategy.train_ensemble_model()
        strategy.save_best_model('ensemble_model.pkl', 'ensemble_vectorizer.pkl')
    elif choice == '2':
        strategy.hyperparameter_tuning()
        strategy.save_best_model('tuned_model.pkl', 'tuned_vectorizer.pkl')
    else:
        print("Invalid choice!")

if __name__ == '__main__':
    main()

