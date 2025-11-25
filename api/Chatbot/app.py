# Chatbot/app.py
# Standalone chatbot application for testing

import sys
import os

# Add parent directory to path to import chatbot_helper
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from chatbot_helper import get_chatbot_response, load_chatbot_model, is_chatbot_available

def main():
    """
    Interactive chatbot CLI for testing
    """
    print("="*60)
    print("VOGUE AI FASHION CHATBOT")
    print("="*60)
    print("\nLoading chatbot model...")
    
    # Load model
    load_chatbot_model()
    
    if is_chatbot_available():
        print("✓ Model loaded successfully!")
    else:
        print("⚠ Model not available, using fallback mode")
    
    print("\n" + "="*60)
    print("Chatbot ready! Type 'quit' or 'exit' to end the conversation.")
    print("="*60 + "\n")
    
    # Chat loop
    while True:
        try:
            user_input = input("You: ").strip()
            
            if user_input.lower() in ['quit', 'exit', 'bye']:
                print("\nChatbot: Goodbye! Have a stylish day! 👋")
                break
            
            if not user_input:
                continue
            
            # Get response
            response = get_chatbot_response(user_input)
            print(f"Chatbot: {response}\n")
        
        except KeyboardInterrupt:
            print("\n\nChatbot: Goodbye! Have a stylish day! 👋")
            break
        except Exception as e:
            print(f"\n⚠ Error: {e}\n")

if __name__ == '__main__':
    main()

