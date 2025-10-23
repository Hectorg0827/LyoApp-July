# 🎯 Quick Reference - Enable Real Features

## Current Status ✅
- ✅ Unity integrated and tab added to app
- ✅ Backend frozen processes cleared
- ✅ `.env` file prepared with GEMINI_API_KEY placeholder
- ✅ Helper scripts created

---

## 📋 YOUR ACTION ITEMS (Do these now):

### ⚡ Quick Path (5 minutes total):

**1️⃣ Get Gemini API Key** (2 min)
- Browser opened to: https://makersuite.google.com/app/apikey
- Click "Create API Key" button
- Copy the key (starts with `AIza...`)

**2️⃣ Add API Key** (1 min)
```bash
nano "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend/.env"
```
- Scroll to bottom
- Find: `GEMINI_API_KEY=your-gemini-api-key-here`
- Replace with your actual key
- Save: `Ctrl+X` → `Y` → `Enter`

**3️⃣ Start Backend** (30 sec)
```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"
./start_backend.sh
```
- Should see: "🚀 Starting server on http://localhost:8000"
- **Keep this terminal running!**

**4️⃣ Open & Run App** (2 min)
```bash
open "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj"
```
- In Xcode: `Cmd+Shift+K` (clean)
- Then: `Cmd+R` (run)

---

## 🎉 What You'll See:

### In the App:
✅ New **"3D Classroom"** tab with cube icon  
✅ **Real AI-generated courses** (not mock data)  
✅ **Personalized content** from Gemini  

### In Xcode Console:
✅ `Backend health check passed`  
✅ `Production LearningAPIService initialized`  
❌ NO "using mock data" warnings  

---

## 🔧 Helper Commands:

### Start Backend:
```bash
./start_backend.sh
```

### Check Backend Status:
```bash
curl http://localhost:8000/api/v1/health
```

### Stop Backend:
```bash
lsof -ti:8000 | xargs kill -9
```

### View API Docs:
Open browser: http://localhost:8000/docs

---

## 📁 Key Files:

- **Backend Config**: `LyoBackend/.env`
- **Start Backend**: `./start_backend.sh`
- **Unity Tab**: `LyoApp/ContentView.swift` (updated)
- **Full Guide**: `ENABLE_REAL_FEATURES_GUIDE.md`
- **This Guide**: `QUICK_START.md`

---

## ✅ Success Checklist:

- [ ] Got Gemini API key
- [ ] Added to `.env` file
- [ ] Started backend (running in terminal)
- [ ] Opened Xcode project
- [ ] Cleaned & built app
- [ ] App running in simulator
- [ ] See "3D Classroom" tab
- [ ] AI generation works (real content)
- [ ] No mock data warnings

---

## 🎯 You Are Here:

```
┌─────────────────────────────────────┐
│ ✅ Unity Integrated                 │
│ ✅ Backend Config Ready             │
│ ✅ Helper Scripts Created           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ → GET GEMINI API KEY (you do this) │ ← YOU ARE HERE
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ → ADD KEY TO .env                   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ → START BACKEND                     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ → RUN APP IN XCODE                  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ ✨ REAL FEATURES WORKING!           │
└─────────────────────────────────────┘
```

---

**Next**: Get your API key from the browser, then follow steps 2-4 above! 🚀
