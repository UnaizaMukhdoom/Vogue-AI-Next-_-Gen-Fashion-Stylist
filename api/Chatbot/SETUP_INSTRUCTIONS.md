# 🚀 Chatbot Setup Instructions

## Step 1: Get Your Dataset

You need to get the dataset CSV file from your Chatbot_VogueAI repository:

### Option A: Download from GitHub
1. Go to: https://github.com/UnaizaMukhdoom/Chatbot_VogueAI
2. Navigate to the `Chatbot` folder
3. Download `fashion_dataset_balanced.csv` (or similar dataset file)
4. Place it in this directory: `api/Chatbot/`

### Option B: Clone the Repository
```bash
cd ..
git clone https://github.com/UnaizaMukhdoom/Chatbot_VogueAI.git
# Copy the dataset file
cp Chatbot_VogueAI/Chatbot/fashion_dataset_balanced.csv api/Chatbot/
```

### Dataset Format Required:
The CSV should have these columns:
- `Query` or `query` - User questions
- `Intent` or `intent` - Intent categories
- `Response` or `response` - Bot responses

## Step 2: Get Model Files (If You Have Trained Models)

If you already have trained models from your chatbot repository:

### Download These Files:
- `intent_classifier.pkl` - Trained classification model
- `vectorizer.pkl` - TF-IDF vectorizer
- `fashion_embeddings_balanced.pkl` - Optional: embeddings for RAG

### Place Them Here:
```
api/Chatbot/
├── intent_classifier.pkl
├── vectorizer.pkl
└── fashion_embeddings_balanced.pkl (optional)
```

## Step 3: Train the Model (If You Don't Have Model Files)

If you don't have trained model files yet:

```bash
cd api/Chatbot
python train_intent_classifier.py
```

This will generate:
- `intent_classifier.pkl`
- `vectorizer.pkl`

## Step 4: Test Locally

### Test the Standalone Chatbot:
```bash
cd api/Chatbot
python app.py
```

### Test the Flask API:
```bash
cd api
python app.py
```

In another terminal, test the endpoint:
```bash
curl -X POST http://localhost:5000/chatbot/chat -H "Content-Type: application/json" -d "{\"message\": \"What colors suit me?\"}"
```

## Step 5: Prepare for Railway Deployment

### Check Files to Deploy:
- ✅ `api/chatbot_helper.py`
- ✅ `api/app.py`
- ✅ `api/Chatbot/` directory with all Python files
- ✅ `api/Chatbot/intent_classifier.pkl` (if trained)
- ✅ `api/Chatbot/vectorizer.pkl` (if trained)
- ✅ `api/requirements.txt` (already has all dependencies)

### Important Notes:
1. **Model Files Size**: If `.pkl` files are large (>50MB), consider using Railway's file storage or .gitignore them and upload separately
2. **Dataset**: The dataset CSV is only needed for training. For deployment, you only need the `.pkl` model files
3. **Fallback Mode**: The chatbot will work in fallback mode even without model files (uses keyword-based responses)

## Step 6: Deploy to Railway

1. **Commit and Push:**
   ```bash
   git add api/Chatbot/
   git add api/chatbot_helper.py
   git commit -m "Add chatbot integration"
   git push
   ```

2. **Railway will auto-deploy** if connected to GitHub

3. **Check Logs:**
   - Go to Railway dashboard
   - Check deployment logs
   - Look for: `✓ Chatbot model loaded from...`

4. **Test Deployment:**
   ```bash
   curl https://your-railway-url.railway.app/chatbot/health
   ```

## Step 7: Update Flutter App (If Railway URL Changed)

If your Railway URL changed, update `lib/services/chatbot_service.dart`:

```dart
static const String baseUrl = 'https://your-new-url.railway.app';
```

## Troubleshooting

### Model Not Loading on Railway:
- Check that `.pkl` files are in `api/Chatbot/` directory
- Verify file paths in `chatbot_helper.py`
- Check Railway logs for errors

### Dataset Not Found:
- Make sure CSV file is in `api/Chatbot/` directory
- Check filename matches what's in training scripts
- Verify CSV has correct columns (Query, Intent, Response)

### Training Errors:
- Install dependencies: `pip install -r ../requirements.txt`
- Check CSV file format
- Ensure enough memory for training

## Next Steps After Setup:

1. ✅ Dataset added
2. ✅ Models trained/added
3. ✅ Tested locally
4. ✅ Deployed to Railway
5. ✅ Test in Flutter app - Open app → Tap "AI Stylist" → Chat!

