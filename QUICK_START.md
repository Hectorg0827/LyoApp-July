# 🚀 Quick Start - 3 Steps

## Problem: App crashes immediately on launch ❌

## Solution: Already Fixed! ✅

Now just need to run it with production backend.

---

## Step 1️⃣: Set Environment Variable

In Xcode menu bar:
- **Product** → **Scheme** → **Edit Scheme...**

Then:
1. Click **Run** (left sidebar)
2. Click **Arguments** tab
3. Under **Environment Variables**, click **+**
4. Add:
   - Name: `LYO_ENV`
   - Value: `prod`
   - ✓ Check the box
5. Click **Close**

## Step 2️⃣: Delete Old App (Important!)

On your iPhone:
- Long-press the LyoApp icon
- Tap "Remove App" → "Delete App"

This clears all old mock tokens.

## Step 3️⃣: Run from Xcode

1. Select your **iPhone** from device dropdown (top toolbar)
2. Click **Run** button (▶️) or press **Cmd+R**
3. App installs and launches on your iPhone

---

## What You Should See

### In Xcode Console:
```
🚀 LyoApp started
🌐 Backend: https://lyo-backend-830162750094.us-central1.run.app
✅ Using PRODUCTION backend
```

### On iPhone:
- ✅ Login screen appears
- ✅ No crash!
- ✅ Can tap and interact

---

## Then Test:

1. **Login** (or register new account)
2. Tap **"Start AI Session"**
3. **Send message:** "Help me learn calculus"
4. **Expected:** Real AI response! 🎉

---

## Troubleshooting

### App still crashes?
- Clean: **Product → Clean Build Folder** (Cmd+Shift+K)
- Delete app from iPhone again
- Rebuild

### Shows "Using LOCAL backend"?
- You forgot step 1! Go set `LYO_ENV=prod`

### Can't find iPhone?
- Unlock iPhone
- Trust computer
- Check: Window → Devices and Simulators

---

**Status:** ✅ Ready!
**Action:** Set `LYO_ENV=prod` and run!
