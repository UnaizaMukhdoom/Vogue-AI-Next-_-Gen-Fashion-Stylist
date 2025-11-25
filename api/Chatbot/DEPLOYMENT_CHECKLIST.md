# 🚀 Railway Deployment Checklist

Use this checklist to ensure everything is ready for Railway deployment.

## Pre-Deployment Checklist

### ✅ Files Ready
- [ ] Dataset CSV file added to `api/Chatbot/` (if training)
- [ ] Model files (`intent_classifier.pkl`, `vectorizer.pkl`) in `api/Chatbot/`
- [ ] All Python files in `api/Chatbot/` directory
- [ ] `api/chatbot_helper.py` present
- [ ] `api/app.py` updated with chatbot endpoints

### ✅ Dependencies
- [ ] `api/requirements.txt` includes all dependencies
  - Flask, flask-cors
  - scikit-learn, joblib, pandas
  - numpy, scipy
  - gunicorn

### ✅ Testing
- [ ] Tested chatbot locally with `python api/Chatbot/app.py`
- [ ] Tested Flask API locally: `python api/app.py`
- [ ] Tested `/chatbot/chat` endpoint locally
- [ ] Tested `/chatbot/health` endpoint locally

### ✅ Configuration
- [ ] `api/Procfile` has correct start command
- [ ] `railway.toml` configured (if using)
- [ ] Model files committed (if < 50MB) or using Railway storage
- [ ] Railway URL updated in `lib/services/chatbot_service.dart` (if needed)

## Deployment Steps

### Step 1: Prepare Files
```bash
# Check what files will be deployed
cd api/Chatbot
python setup_chatbot.py
```

### Step 2: Commit Changes
```bash
# Add all chatbot files
git add api/Chatbot/
git add api/chatbot_helper.py
git add api/app.py

# Commit
git commit -m "Add chatbot integration for Railway deployment"

# Push to GitHub
git push
```

### Step 3: Deploy to Railway
- Railway should auto-deploy if connected to GitHub
- Or manually trigger deployment from Railway dashboard

### Step 4: Verify Deployment

#### Check Logs:
```bash
# View Railway logs
railway logs
```

Look for:
- `✓ Chatbot module loaded successfully`
- `✓ Chatbot model loaded from...` (if model files present)
- `⚠ Chatbot model files not found. Using fallback responses.` (if no models)

#### Test Endpoints:
```bash
# Test health endpoint
curl https://your-railway-url.railway.app/chatbot/health

# Test chat endpoint
curl -X POST https://your-railway-url.railway.app/chatbot/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "context": "fashion_styling"}'
```

### Step 5: Update Flutter App
- Update Railway URL in `lib/services/chatbot_service.dart` if needed
- Test in Flutter app: Home → AI Stylist → Chat

## Troubleshooting

### Model Not Loading
**Problem:** Logs show "Chatbot model files not found"

**Solutions:**
1. Check files are in `api/Chatbot/` directory
2. Verify `.pkl` files are committed (check git status)
3. Check file paths in `chatbot_helper.py`
4. Use Railway file storage for large files

### Import Errors
**Problem:** `ImportError: cannot import name 'get_chatbot_response'`

**Solutions:**
1. Check `chatbot_helper.py` is in `api/` directory
2. Verify all dependencies in `requirements.txt`
3. Check Railway build logs for installation errors

### API Not Responding
**Problem:** 503 Service Unavailable

**Solutions:**
1. Check Railway service is running
2. Verify PORT environment variable
3. Check gunicorn start command in Procfile
4. Review Railway logs for errors

## Post-Deployment

- [ ] Test chatbot in Flutter app
- [ ] Monitor Railway logs for errors
- [ ] Check Railway metrics (CPU, memory usage)
- [ ] Verify chatbot responses are correct
- [ ] Document Railway URL for team

## Success Indicators

✅ `/chatbot/health` returns status: "healthy" or "fallback_mode"  
✅ `/chatbot/chat` returns valid responses  
✅ Flutter app can connect and chat  
✅ No errors in Railway logs  
✅ Response times are reasonable (< 2 seconds)

---

**Need Help?**
- Check Railway logs: `railway logs`
- Review `SETUP_INSTRUCTIONS.md`
- Test locally first before deploying

