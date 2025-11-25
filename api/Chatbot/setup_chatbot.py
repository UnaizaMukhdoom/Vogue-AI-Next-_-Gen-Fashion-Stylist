#!/usr/bin/env python3
"""
Chatbot Setup Script
Helps set up the chatbot by downloading/cloning the dataset and model files
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def print_step(step, message):
    print(f"\n{'='*60}")
    print(f"STEP {step}: {message}")
    print('='*60)

def check_file_exists(filepath):
    """Check if a file exists"""
    return os.path.exists(filepath)

def download_dataset_instructions():
    """Provide instructions for downloading dataset"""
    print("\n📥 DATASET DOWNLOAD INSTRUCTIONS:")
    print("-" * 60)
    print("You need to get the dataset from your Chatbot_VogueAI repository:")
    print("\nOption 1: Clone the repository")
    print("  git clone https://github.com/UnaizaMukhdoom/Chatbot_VogueAI.git")
    print("  Then copy the dataset file to api/Chatbot/")
    print("\nOption 2: Download directly from GitHub")
    print("  Go to: https://github.com/UnaizaMukhdoom/Chatbot_VogueAI")
    print("  Navigate to Chatbot folder")
    print("  Download fashion_dataset_balanced.csv")
    print("  Place it in: api/Chatbot/")
    print("\nOption 3: Use the template (limited functionality)")
    print("  Use DATASET_TEMPLATE.csv as a starting point")

def check_setup():
    """Check what's already set up"""
    print_step(1, "CHECKING CURRENT SETUP")
    
    chatbot_dir = Path(__file__).parent
    current_dir = Path.cwd()
    
    print(f"Current directory: {current_dir}")
    print(f"Chatbot directory: {chatbot_dir}")
    
    # Check for dataset
    dataset_files = [
        'fashion_dataset_balanced.csv',
        'fashion_dataset_language_fixed.csv',
        'fashion_dataset_with_indices.csv',
        'DATASET_TEMPLATE.csv'
    ]
    
    print("\n📊 Checking for dataset files...")
    found_dataset = False
    for dataset in dataset_files:
        dataset_path = chatbot_dir / dataset
        if check_file_exists(dataset_path):
            print(f"  ✓ Found: {dataset}")
            if dataset != 'DATASET_TEMPLATE.csv':
                found_dataset = True
        else:
            print(f"  ✗ Missing: {dataset}")
    
    # Check for model files
    model_files = [
        'intent_classifier.pkl',
        'vectorizer.pkl',
        'fashion_embeddings_balanced.pkl'
    ]
    
    print("\n🤖 Checking for model files...")
    found_models = 0
    for model in model_files:
        model_path = chatbot_dir / model
        if check_file_exists(model_path):
            print(f"  ✓ Found: {model}")
            if model in ['intent_classifier.pkl', 'vectorizer.pkl']:
                found_models += 1
        else:
            print(f"  ✗ Missing: {model}")
    
    # Summary
    print("\n" + "-" * 60)
    print("SETUP STATUS:")
    print("-" * 60)
    print(f"Dataset: {'✓ Ready' if found_dataset else '✗ Need to add'}")
    print(f"Models: {'✓ Ready' if found_models >= 2 else '✗ Need to train/add'}")
    
    return found_dataset, found_models >= 2

def main():
    """Main setup function"""
    print("=" * 60)
    print("VOGUE AI CHATBOT - SETUP SCRIPT")
    print("=" * 60)
    
    # Check current setup
    has_dataset, has_models = check_setup()
    
    # Provide next steps
    print_step(2, "NEXT STEPS")
    
    if not has_dataset:
        print("\n❌ Dataset not found!")
        download_dataset_instructions()
        print("\n📝 After adding the dataset, run this script again to train the model.")
    else:
        print("\n✅ Dataset found!")
        
        if not has_models:
            print("\n⚠️  Model files not found!")
            print("\n📚 Training the model...")
            print("   Run: python train_intent_classifier.py")
            print("\n   Or download model files from your repository:")
            print("   - intent_classifier.pkl")
            print("   - vectorizer.pkl")
        else:
            print("\n✅ Model files found!")
            print("\n🎉 Setup complete! You can now:")
            print("   1. Test locally: python app.py")
            print("   2. Deploy to Railway")
            print("   3. Use in Flutter app")
    
    print("\n" + "=" * 60)
    print("For detailed instructions, see: SETUP_INSTRUCTIONS.md")
    print("=" * 60)

if __name__ == '__main__':
    main()

