# 🎯 Next Steps - Enable Real Features

**Status**: Backend processes cleared, configuration ready  
**Time**: ~5 minutes to complete

---

## Step 1: Get Gemini API Key (2 minutes)

1. Visit: **https://makersuite.google.com/app/apikey**
2. Click **"Create API Key"** or **"Get API Key"**
3. Copy the key (starts with `AIza...`)

---

## Step 2: Add API Key to Backend (1 minute)

Open the `.env` file:
```bash
nano "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend/.env"
```

Find this line near the bottom:
```env
GEMINI_API_KEY=your-gemini-api-key-here
```

Replace `your-gemini-api-key-here` with your actual API key:
```env
GEMINI_API_KEY=AIza...your-actual-key
```

**Save**: Press `Ctrl+X`, then `Y`, then `Enter`

---

## Step 3: Start Backend (30 seconds)

```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend"
python start_dev.py
```

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

**Keep this terminal open!**

---

## Step 4: Rebuild App in Xcode (2 minutes)

1. Open Xcode: 
   ```bash
   open "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj"
   ```

2. In Xcode:
   - Press **Cmd+Shift+K** (Clean Build Folder)
   - Press **Cmd+B** (Build)
   - Press **Cmd+R** (Run)

---

## Step 5: Test Real Features

### Test AI Course Generation:
1. Open app in simulator
2. Go to **Learn** tab
3. Create a new course with AI
4. Wait 5-10 seconds
5. ✅ Should see real generated content (not mock data)

### Test Unity 3D Classroom:
1. Look for **"3D Classroom"** tab (cube icon)
2. Tap it
3. ✅ Should see Unity environment loading

### Verify No Mock Data:
1. Check Xcode console
2. Should see: `✅ Backend health check passed`
3. Should NOT see: `⚠️ API failed, using mock data`

---

## ✅ Success Checklist

- [ ] Got Gemini API key from Google
- [ ] Added key to `LyoBackend/.env`
- [ ] Started backend with `python start_dev.py`
- [ ] Backend shows "Uvicorn running on http://127.0.0.1:8000"
- [ ] Rebuilt app in Xcode (Clean + Build + Run)
- [ ] App shows "3D Classroom" tab
- [ ] AI course generation works (real content)
- [ ] Console shows "Backend health check passed"

---

## 🐛 Quick Troubleshooting

### Backend won't start?
```bash
# Make sure old processes are gone
lsof -ti:8000 | xargs kill -9

# Install dependencies if needed
cd "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend"
pip install -r requirements.txt

# Try again
python start_dev.py
```

### Still seeing mock data?
- Check console for error messages
- Verify backend is responding: `curl http://localhost:8000/api/v1/health`
- Make sure API key is correct (no extra spaces)

### Unity tab not showing?
- Unity framework is integrated
- Tab shows conditionally (check console for "Unity not available")
- Rebuild app to see changes

---

**Ready?** Start with Step 1! 🚀
