# api/chatbot_helper.py
# Chatbot integration helper for VogueAI Chatbot
# This module handles loading and using the trained chatbot model

import os
import pickle
import re
import numpy as np

# Try to import chatbot dependencies - gracefully handle if not available
try:
    import joblib
    import pandas as pd
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.naive_bayes import MultinomialNB
    SKLEARN_AVAILABLE = True
except ImportError as e:
    joblib = None
    pd = None
    TfidfVectorizer = None
    MultinomialNB = None
    SKLEARN_AVAILABLE = False
    print(f"⚠ Warning: scikit-learn dependencies not available: {e}")

# Global variables for lazy loading
_chatbot_model = None
_chatbot_vectorizer = None
_chatbot_responses = {}
_chatbot_loaded = False

def load_chatbot_model():
    """
    Load the trained chatbot model and vectorizer
    This function will try to load model files from the chatbot repository
    """
    global _chatbot_model, _chatbot_vectorizer, _chatbot_responses, _chatbot_loaded
    
    if _chatbot_loaded:
        return _chatbot_model, _chatbot_vectorizer
    
    if not SKLEARN_AVAILABLE:
        print("⚠ scikit-learn not available - chatbot will use fallback mode")
        _chatbot_loaded = True
        return None, None
    
    try:
        # Try to load model files (adjust paths based on your actual model files)
        model_paths = [
            'intent_classifier.pkl',
            'chatbot_model.pkl',
            'model.pkl',
            'fashion_chatbot_model.pkl'
        ]
        
        vectorizer_paths = [
            'vectorizer.pkl',
            'tfidf_vectorizer.pkl',
            'vectorizer.pkl'
        ]
        
        # Load model
        for path in model_paths:
            if os.path.exists(path):
                _chatbot_model = joblib.load(path)
                print(f"✓ Chatbot model loaded from {path}")
                break
        
        # Load vectorizer
        for path in vectorizer_paths:
            if os.path.exists(path):
                _chatbot_vectorizer = joblib.load(path)
                print(f"✓ Chatbot vectorizer loaded from {path}")
                break
        
        # Load responses from dataset if available
        if pd is not None:
            dataset_paths = [
                'fashion_dataset_balanced.csv',
                'fashion_dataset_language_fixed.csv',
                'fashion_dataset_with_indices.csv'
            ]
            
            for path in dataset_paths:
                if os.path.exists(path):
                    try:
                        df = pd.read_csv(path)
                        # Extract responses based on your dataset structure
                        # This is a placeholder - adjust based on your actual dataset
                        if 'Response' in df.columns:
                            _chatbot_responses = df.set_index('Intent')['Response'].to_dict()
                        elif 'response' in df.columns:
                            _chatbot_responses = df.set_index('intent')['response'].to_dict()
                        print(f"✓ Chatbot responses loaded from {path}")
                        break
                    except Exception as e:
                        print(f"⚠ Could not load responses from {path}: {e}")
        
        _chatbot_loaded = True
        
        if _chatbot_model is None or _chatbot_vectorizer is None:
            print("⚠ Chatbot model files not found. Using fallback responses.")
        
    except Exception as e:
        print(f"⚠ Error loading chatbot model: {e}")
        _chatbot_loaded = True  # Mark as loaded to prevent repeated attempts
    
    return _chatbot_model, _chatbot_vectorizer

def preprocess_message(message):
    """Preprocess user message for chatbot"""
    # Convert to lowercase
    message = message.lower()
    # Remove special characters but keep spaces
    message = re.sub(r'[^a-z0-9\s]', '', message)
    # Remove extra spaces
    message = ' '.join(message.split())
    return message

def get_chatbot_response(user_message, context='fashion_styling'):
    """
    Get response from chatbot model
    Returns a fashion-related response based on user input
    """
    model, vectorizer = load_chatbot_model()
    
    # Preprocess message
    processed_message = preprocess_message(user_message)
    
    # If model is not loaded, use rule-based fallback
    if model is None or vectorizer is None:
        return get_fallback_response(user_message, context)
    
    try:
        # Vectorize user message
        message_vector = vectorizer.transform([processed_message])
        
        # Get prediction
        intent = model.predict(message_vector)[0]
        confidence = model.predict_proba(message_vector)[0].max()
        
        # Get response based on intent
        response = generate_response_from_intent(intent, user_message, confidence)
        
        return response
        
    except Exception as e:
        print(f"Error generating chatbot response: {e}")
        return get_fallback_response(user_message, context)

def generate_response_from_intent(intent, user_message, confidence):
    """Generate response based on intent classification"""
    
    # Check if we have a stored response for this intent
    if intent in _chatbot_responses:
        return _chatbot_responses[intent]
    
    # Intent-based responses
    intent_responses = {
        'greeting': [
            "Hello! I'm your AI fashion stylist. How can I help you today?",
            "Hi there! Ready to discover your perfect style?",
            "Hey! I'm here to help you look amazing. What can I assist you with?"
        ],
        'outfit_suggestion': [
            "Based on your style profile, I'd recommend trying a combination of classic pieces with modern touches. Consider pairing a well-fitted blazer with comfortable jeans and statement accessories.",
            "For a versatile look, try mixing neutral colors with one pop of color. A white shirt with dark denim and a colorful scarf or bag can create a balanced, stylish outfit.",
            "I suggest creating a capsule wardrobe with pieces that can be mixed and matched. Start with basics in neutral colors and add statement pieces gradually."
        ],
        'color_advice': [
            "Colors that complement your skin tone can enhance your natural features. Consider trying colors that create contrast with your undertone for a more vibrant look.",
            "The best colors for you depend on your skin tone and personal preferences. Warm undertones work well with earth tones, while cool undertones shine with jewel tones.",
            "Experiment with colors that make you feel confident! Sometimes the best color is the one that makes you smile when you wear it."
        ],
        'style_tips': [
            "Here are some style tips: focus on fit first - well-fitted clothes look more expensive. Accessorize thoughtfully, and don't be afraid to express your personality through your style.",
            "Great style comes from confidence! Choose pieces that make you feel comfortable and authentic. Remember, trends come and go, but personal style is timeless.",
            "Build your wardrobe around versatile basics, then add statement pieces. Quality over quantity - invest in pieces you'll wear for years."
        ],
        'goodbye': [
            "Thanks for chatting! Feel free to come back anytime for style advice.",
            "It was great helping you! Come back soon for more fashion tips.",
            "See you later! Keep experimenting with your style."
        ],
        'question': [
            "I'm here to help with all your fashion questions! What would you like to know?",
            "Feel free to ask me anything about fashion, styling, or color coordination!",
            "What fashion question can I answer for you today?"
        ]
    }
    
    # Get response based on intent
    if intent in intent_responses:
        responses = intent_responses[intent]
        return responses[hash(user_message) % len(responses)]
    
    # Default response
    return "I'm here to help with fashion advice. Could you tell me more about what you're looking for?"

def get_fallback_response(user_message, context):
    """Fallback responses when model is not available"""
    message_lower = user_message.lower()
    
    # Keyword-based responses
    if any(word in message_lower for word in ['hello', 'hi', 'hey', 'greetings']):
        return "Hello! I'm your AI fashion stylist. How can I help you today?"
    
    if any(word in message_lower for word in ['color', 'colours', 'what color']):
        return "Great question about colors! The best colors for you depend on your skin tone. Have you completed your color analysis? I can help you find colors that complement your natural features."
    
    if any(word in message_lower for word in ['outfit', 'what to wear', 'suggestion']):
        return "I'd love to help you with outfit suggestions! Consider your occasion, personal style, and body type. Would you like specific recommendations for a particular event?"
    
    if any(word in message_lower for word in ['style', 'styling', 'fashion tips']):
        return "Here are some style tips: focus on fit first, choose colors that complement your skin tone, and don't be afraid to express your personality. What specific style advice are you looking for?"
    
    if any(word in message_lower for word in ['bye', 'goodbye', 'thanks', 'thank you']):
        return "You're welcome! Feel free to come back anytime for more fashion advice. Have a stylish day!"
    
    # Default fallback
    return "I'm here to help with fashion and styling advice! You can ask me about colors, outfit suggestions, style tips, or anything fashion-related. What would you like to know?"

def is_chatbot_available():
    """Check if chatbot model is loaded and available"""
    if not SKLEARN_AVAILABLE:
        return False
    model, vectorizer = load_chatbot_model()
    return model is not None and vectorizer is not None

