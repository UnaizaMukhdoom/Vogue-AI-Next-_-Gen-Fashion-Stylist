# Fashion Chatbot - Training & Models

This directory contains all the chatbot training scripts, models, and datasets for the VogueAI Fashion Chatbot.

## 📁 Directory Structure

```
Chatbot/
├── train_intent_classifier.py      # Main training script
├── exact_accuracy_calculator.py    # Calculate exact accuracy metrics
├── llama_enhanced_rag.py           # Enhanced RAG implementation
├── advanced_training_strategy.py   # Advanced training (ensemble, tuning)
├── app.py                          # Standalone chatbot for testing
├── README.md                       # This file
├── fashion_dataset_balanced.csv    # Training dataset (add your dataset here)
├── intent_classifier.pkl           # Trained model (generated after training)
├── vectorizer.pkl                  # TF-IDF vectorizer (generated after training)
└── fashion_embeddings_balanced.pkl # Optional: Pre-computed embeddings
```

## 🚀 Quick Start

### 1. Prepare Dataset

Place your fashion dataset CSV file in this directory. The dataset should have columns:
- `Query` or `query` - User queries
- `Intent` or `intent` - Intent labels
- `Response` or `response` - Bot responses

**Example dataset structure:**
```csv
Query,Intent,Response
"What colors suit me?",color_advice,"Colors that complement your skin tone..."
"How do I style a blazer?",outfit_suggestion,"For a blazer, try pairing it with..."
```

### 2. Train the Model

```bash
cd api/Chatbot
python train_intent_classifier.py
```

This will:
- Load the dataset
- Preprocess the data
- Train the intent classifier
- Save `intent_classifier.pkl` and `vectorizer.pkl`

### 3. Test the Chatbot

**Standalone testing:**
```bash
python app.py
```

**Calculate exact accuracy:**
```bash
python exact_accuracy_calculator.py
```

## 📊 Training Options

### Basic Training

```bash
python train_intent_classifier.py
```

### Advanced Training (Ensemble Model)

```bash
python advanced_training_strategy.py
# Choose option 1 for ensemble
```

### Hyperparameter Tuning

```bash
python advanced_training_strategy.py
# Choose option 2 for tuning
```

## 🔧 Using the Model in Flask API

After training, the model files will be used automatically by `chatbot_helper.py` in the Flask API:

```python
from chatbot_helper import get_chatbot_response

response = get_chatbot_response("What colors suit me?")
print(response)
```

## 📈 Model Files

### Required Files (after training):
- `intent_classifier.pkl` - Trained intent classification model
- `vectorizer.pkl` - TF-IDF vectorizer for text processing

### Optional Files:
- `fashion_embeddings_balanced.pkl` - Pre-computed embeddings for RAG
- `ensemble_model.pkl` - Ensemble model from advanced training
- `tuned_model.pkl` - Hyperparameter-tuned model

## 🧪 Testing

### Test Accuracy

```bash
python exact_accuracy_calculator.py
```

This calculates:
- Training accuracy
- Testing accuracy
- Classification report
- Confusion matrix

### Interactive Testing

```bash
python app.py
```

Start a conversation with the chatbot in the terminal.

## 📝 Adding Your Dataset

1. Prepare your CSV file with columns: `Query`, `Intent`, `Response`
2. Place it in the `Chatbot/` directory
3. Name it `fashion_dataset_balanced.csv` or update the path in training scripts
4. Run training

## 🔗 Integration with Flask API

The chatbot is integrated with the Flask API via `chatbot_helper.py`:

**Endpoints:**
- `POST /chatbot/chat` - Get chatbot response
- `GET /chatbot/health` - Check chatbot availability

**Example API call:**
```bash
curl -X POST http://localhost:5000/chatbot/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What colors suit me?", "context": "fashion_styling"}'
```

## 📦 Dependencies

All dependencies are in `api/requirements.txt`:
- scikit-learn
- pandas
- numpy
- joblib

## 🎯 Next Steps

1. ✅ Add your dataset CSV file
2. ✅ Train the model using `train_intent_classifier.py`
3. ✅ Test using `app.py`
4. ✅ Deploy to Railway with model files
5. ✅ Use in Flutter app via Flask API

## 📚 Files Description

- **train_intent_classifier.py**: Main training script with preprocessing, model training, and evaluation
- **exact_accuracy_calculator.py**: Calculate exact training/testing accuracy using same preprocessing
- **llama_enhanced_rag.py**: Enhanced RAG system using embeddings for better context retrieval
- **advanced_training_strategy.py**: Advanced training with ensemble models and hyperparameter tuning
- **app.py**: Standalone chatbot application for interactive testing

## ⚠️ Notes

- Make sure your dataset is balanced across intents for best results
- Model files (`.pkl`) should be committed to version control (or use Railway storage)
- The chatbot works in fallback mode even without trained models
- For production, use ensemble models for better accuracy

