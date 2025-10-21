# 🚨 URGENT FIX: Enable Production Backend

## Current Problem

Your screenshot shows:
- ❌ **"AI Ready (fallback mode)"**
- ❌ **"I'm having trouble connecting to my AI brain..."**

**Reason:** App is trying to use `localhost:8000` (not running) instead of production backend.

**Confirmed by check:** `LYO_ENV` is **NOT** set in Xcode scheme.

---

## Fix in 60 Seconds

### Step 1: Open Xcode Scheme Editor

Click on the **scheme dropdown** next to the run button:

```
┌─────────────────────────────────────┐
│  LyoApp 1  ▼  │  Your iPhone  ▼    │  ← Click here
└─────────────────────────────────────┘
```

Then click: **Edit Scheme...**

Or use keyboard: **Product → Scheme → Edit Scheme...**

### Step 2: Navigate to Environment Variables

In the scheme editor window:

1. Click **Run** (left sidebar) - should already be selected
2. Click **Arguments** tab (top)
3. Scroll down to **Environment Variables** section
4. Click the **+** button

### Step 3: Add the Variable

A new row appears. Fill in:

| Name | Value | Enabled |
|------|-------|---------|
| `LYO_ENV` | `prod` | ✓ |

**IMPORTANT:** Make sure the checkbox is **✓ CHECKED**!

### Step 4: Save and Close

Click **Close** button (bottom right of scheme editor)

### Step 5: Clean and Rebuild

1. **Delete app** from iPhone (long-press icon → Remove App)
2. In Xcode: **Product → Clean Build Folder** (Cmd+Shift+K)
3. **Run** app again (Cmd+R)

---

## Verify It Worked

### In Xcode Console (Cmd+Shift+Y):

Look for this at app startup:

```
✅ CORRECT (Production Backend):
🔒 APIEnvironment.current: PRODUCTION MODE (ENV VAR)
🌐 URL: https://lyo-backend-830162750094.us-central1.run.app
🚀 LyoApp started
🌐 Backend: https://lyo-backend-830162750094.us-central1.run.app
✅ Using PRODUCTION backend
```

```
❌ WRONG (Still Using Local):
🛠️ APIEnvironment.current: LOCAL DEVELOPMENT MODE
🌐 URL: http://localhost:8000 (LyoBackendJune)
⚠️ Using LOCAL backend
```

### On iPhone:

After login and opening AI Avatar:

**Before (Wrong):**
- Status: "AI Ready (fallback mode)" ❌
- Response: "I'm having trouble connecting..." ❌

**After (Correct):**
- Status: "AI Ready" ✅ (no "fallback mode")
- Response: Real AI answers! ✅

---

## Test the AI

Once fixed, send these test messages:

1. **"What is 25 * 37?"**
   - Expected: `925` (proves real AI, not mock)

2. **"Explain quantum physics"**
   - Expected: Real detailed explanation

3. **"Help me learn calculus"**
   - Expected: Learning plan, not fallback

If you get **real contextual answers** = SUCCESS! 🎉

---

## Still Having Issues?

### Console shows "LOCAL DEVELOPMENT MODE"?
→ You didn't add `LYO_ENV=prod` correctly
→ Go back to Step 1 and try again
→ Make sure checkbox is ✓ checked!

### Console shows "PRODUCTION MODE" but still fallback?
→ Check WebSocket logs for `local_token_`
→ If you see it, delete app and reinstall
→ Old tokens still cached

### Can't find scheme editor?
→ Top toolbar: Click on "LyoApp 1" dropdown
→ Bottom of menu: "Edit Scheme..."
→ Or: Product menu → Scheme → Edit Scheme

---

## Quick Command to Verify

Run this in terminal:

```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"
./check-backend-config.sh
```

Should show:
- ✅ LYO_ENV found in scheme
- ✅ Using PRODUCTION backend

---

## Summary

**What you need to do RIGHT NOW:**

1. ✅ Open Xcode
2. ✅ Product → Scheme → Edit Scheme
3. ✅ Run → Arguments → Environment Variables
4. ✅ Add: `LYO_ENV` = `prod` (with ✓ checked)
5. ✅ Close
6. ✅ Delete app from iPhone
7. ✅ Run again (Cmd+R)
8. ✅ Test AI with real questions

**Time needed:** 60 seconds

**Result:** Real AI responses! 🎉

---

**Status:** ⚠️ WAITING FOR YOU TO SET `LYO_ENV=prod`

**This is the ONLY thing blocking you from getting real AI!**
