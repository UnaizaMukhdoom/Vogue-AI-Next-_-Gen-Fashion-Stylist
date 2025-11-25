# Chatbot/llama_enhanced_rag.py
# Enhanced RAG (Retrieval-Augmented Generation) for Fashion Chatbot
# Uses embeddings for better context understanding

import numpy as np
import pandas as pd
import pickle
import os
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer

class EnhancedRAG:
    """
    Enhanced RAG system for fashion chatbot
    Uses TF-IDF or embeddings for semantic search
    """
    
    def __init__(self, dataset_path=None, embeddings_path=None):
        self.dataset = None
        self.embeddings = None
        self.vectorizer = None
        self.embedding_matrix = None
        
        # Load dataset
        if dataset_path:
            self.load_dataset(dataset_path)
        
        # Load embeddings if available
        if embeddings_path and os.path.exists(embeddings_path):
            self.load_embeddings(embeddings_path)
        elif self.dataset is not None:
            # Create TF-IDF vectorizer as fallback
            self.create_vectorizer()
    
    def load_dataset(self, path):
        """Load fashion dataset"""
        try:
            self.dataset = pd.read_csv(path)
            # Normalize column names
            self.dataset.columns = self.dataset.columns.str.lower()
            print(f"✓ Loaded dataset with {len(self.dataset)} samples")
        except Exception as e:
            print(f"⚠ Error loading dataset: {e}")
    
    def load_embeddings(self, path):
        """Load pre-computed embeddings"""
        try:
            with open(path, 'rb') as f:
                self.embeddings = pickle.load(f)
            print(f"✓ Loaded embeddings from {path}")
            
            # Convert to numpy array if needed
            if isinstance(self.embeddings, dict):
                # Assume it's a dict with query embeddings
                self.embedding_matrix = np.array(list(self.embeddings.values()))
            else:
                self.embedding_matrix = np.array(self.embeddings)
                
        except Exception as e:
            print(f"⚠ Error loading embeddings: {e}")
            self.create_vectorizer()
    
    def create_vectorizer(self):
        """Create TF-IDF vectorizer as fallback"""
        if self.dataset is None:
            return
        
        try:
            queries = self.dataset['query'].astype(str).fillna('')
            self.vectorizer = TfidfVectorizer(
                max_features=5000,
                ngram_range=(1, 2),
                min_df=2,
                max_df=0.95
            )
            self.embedding_matrix = self.vectorizer.fit_transform(queries).toarray()
            print("✓ Created TF-IDF vectorizer")
        except Exception as e:
            print(f"⚠ Error creating vectorizer: {e}")
    
    def get_relevant_context(self, query, top_k=3):
        """
        Retrieve most relevant context for a query
        Returns top_k most similar queries and their responses
        """
        if self.embedding_matrix is None or self.dataset is None:
            return []
        
        try:
            # Vectorize query
            if self.vectorizer:
                query_vec = self.vectorizer.transform([query]).toarray()
            else:
                # If using pre-computed embeddings, need to compute query embedding
                # This would require the same model that created embeddings
                print("⚠ Cannot compute query embedding without vectorizer")
                return []
            
            # Calculate cosine similarity
            similarities = cosine_similarity(query_vec, self.embedding_matrix)[0]
            
            # Get top_k indices
            top_indices = np.argsort(similarities)[-top_k:][::-1]
            
            # Return relevant contexts
            contexts = []
            for idx in top_indices:
                if similarities[idx] > 0.1:  # Minimum similarity threshold
                    row = self.dataset.iloc[idx]
                    contexts.append({
                        'query': row.get('query', ''),
                        'intent': row.get('intent', ''),
                        'response': row.get('response', ''),
                        'similarity': float(similarities[idx])
                    })
            
            return contexts
        
        except Exception as e:
            print(f"⚠ Error retrieving context: {e}")
            return []
    
    def generate_enhanced_response(self, query, base_response, top_k=3):
        """
        Generate enhanced response using RAG
        Combines base response with relevant context
        """
        contexts = self.get_relevant_context(query, top_k)
        
        if not contexts:
            return base_response
        
        # Use the most similar context's response
        # Or combine multiple contexts for richer responses
        if contexts[0]['similarity'] > 0.7:
            # High similarity - use that response
            enhanced_response = contexts[0]['response']
        else:
            # Moderate similarity - combine with base response
            enhanced_response = f"{base_response}\n\nBased on similar queries, {contexts[0]['response'].lower()}"
        
        return enhanced_response

def main():
    """Test the enhanced RAG system"""
    print("="*60)
    print("ENHANCED RAG SYSTEM - FASHION CHATBOT")
    print("="*60)
    
    # Try to find dataset
    dataset_paths = [
        'fashion_dataset_balanced.csv',
        'fashion_dataset_language_fixed.csv',
        os.path.join('Chatbot', 'fashion_dataset_balanced.csv'),
    ]
    
    dataset_path = None
    for path in dataset_paths:
        if os.path.exists(path):
            dataset_path = path
            break
    
    if not dataset_path:
        print("⚠ Dataset not found. Please ensure dataset CSV exists.")
        return
    
    # Try to find embeddings
    embedding_paths = [
        'fashion_embeddings_balanced.pkl',
        os.path.join('Chatbot', 'fashion_embeddings_balanced.pkl')
    ]
    
    embedding_path = None
    for path in embedding_paths:
        if os.path.exists(path):
            embedding_path = path
            break
    
    # Initialize RAG
    rag = EnhancedRAG(dataset_path, embedding_path)
    
    # Test queries
    test_queries = [
        "What colors suit me?",
        "How do I style a blazer?",
        "What should I wear to a wedding?",
        "Help me with outfit suggestions"
    ]
    
    print("\n" + "="*60)
    print("TESTING ENHANCED RAG")
    print("="*60)
    
    for query in test_queries:
        print(f"\nQuery: {query}")
        contexts = rag.get_relevant_context(query, top_k=2)
        if contexts:
            print(f"Found {len(contexts)} relevant contexts:")
            for i, ctx in enumerate(contexts, 1):
                print(f"  {i}. Similarity: {ctx['similarity']:.3f}")
                print(f"     Intent: {ctx['intent']}")
                print(f"     Response: {ctx['response'][:100]}...")
        else:
            print("  No relevant contexts found")

if __name__ == '__main__':
    main()

