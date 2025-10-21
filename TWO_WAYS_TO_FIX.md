# Two Ways to Fix - Choose One

## Your Current Problem

The app shows **"fallback mode"** because it's trying to connect to `localhost:8000` instead of the production backend.

---

## ⚡ OPTION 1: Quick Code Fix (EASIEST - 30 seconds)

Change the default to **always use production**.

### File to Edit:
`LyoApp/Core/Networking/APIEnvironment.swift`

### Change Line 64 from:
```swift
let env = APIEnvironment.development
```

### To:
```swift
let env = APIEnvironment.prod
```

### Full Context (Lines 62-68):
```swift
// BEFORE:
#if DEBUG
let env = APIEnvironment.development  // ← Change this line
print("🛠️ APIEnvironment.current: LOCAL DEVELOPMENT MODE")
print("🌐 URL: http://localhost:8000 (LyoBackendJune)")
print("💡 Tip: Set LYO_ENV=prod in environment variables to use production in debug builds")

// AFTER:
#if DEBUG
let env = APIEnvironment.prod  // ← Now uses production by default!
print("🔒 APIEnvironment.current: PRODUCTION MODE")
print("🌐 URL: https://lyo-backend-830162750094.us-central1.run.app")
```

### Steps:
1. Open `APIEnvironment.swift` in Xcode
2. Go to line 64
3. Change `development` to `prod`
4. Save (Cmd+S)
5. Delete app from iPhone
6. Run (Cmd+R)

**Done!** App now uses production by default.

---

## 📋 OPTION 2: Set Environment Variable (More Flexible)

Keep code as-is, but tell Xcode to use production.

### Steps:
1. Xcode: **Product → Scheme → Edit Scheme...**
2. Click **Run** (left sidebar)
3. Click **Arguments** tab
4. Under **Environment Variables**, click **+**
5. Add:
   - Name: `LYO_ENV`
   - Value: `prod`
   - [✓] Check the box
6. Click **Close**
7. Delete app from iPhone
8. Run (Cmd+R)

**Advantage:** Can easily switch between local and production by changing the env var.

---

## 🎯 Recommendation: Use Option 1

**Why:** Simpler, faster, one change in code and you're done.

**When to use Option 2:** If you have a local backend running and want to test both.

---

## After Fixing

### You should see in console:
```
🔒 APIEnvironment.current: PRODUCTION MODE
🌐 URL: https://lyo-backend-830162750094.us-central1.run.app
✅ Using PRODUCTION backend
```

### On iPhone:
- Status: "AI Ready" (no "fallback mode") ✅
- Real AI responses! ✅

### Test with:
- "What is 25 * 37?" → Should get `925`
- "Explain calculus" → Should get real explanation

---

## Which Should You Choose?

| Option | Time | Difficulty | Flexibility |
|--------|------|------------|-------------|
| **Option 1** (code change) | 30 sec | ⭐ Easy | Low |
| **Option 2** (env var) | 60 sec | ⭐⭐ Medium | High |

**My recommendation:** Go with **Option 1** - it's faster and simpler!

---

## Do Option 1 NOW:

```swift
// File: LyoApp/Core/Networking/APIEnvironment.swift
// Line 64:

// Change from:
let env = APIEnvironment.development

// To:
let env = APIEnvironment.prod
```

Save, delete app, run. **That's it!** 🎉
