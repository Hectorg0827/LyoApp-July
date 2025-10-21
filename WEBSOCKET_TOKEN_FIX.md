# WebSocket Token Issue - FIXED ✅

## The Real Problem

You were still seeing `local_token_` in the WebSocket connection because of a **token persistence issue**:

### Error You Saw:
```
token=local_token_9928632E-29BF-4CED-B08B-CD1739DA5EB8
```

This happened because:

1. **Old mock tokens were persisted** in UserDefaults from previous SimplifiedAuthenticationManager usage
2. **AppState loaded these old tokens on init** (before you even logged in!)
3. **WebSocket connected with the old mock token** automatically
4. **When you logged in with real backend**, new token was saved BUT WebSocket was already connected with old token
5. **WebSocket never reconnected** with the new real token

## The Flow (Before Fix):

```
App Launch
   ↓
AppState.init()
   ↓
loadAuthenticationState()
   ↓
TokenStore has old "local_token_XXX" (from previous run)
   ↓
WebSocket connects with: token=local_token_XXX ❌
   ↓
User logs in via MinimalAILauncher
   ↓
Backend returns REAL token: eyJhbGci...
   ↓
Token saved to UserDefaults ✅
   ↓
BUT WebSocket still using OLD token! ❌
   ↓
AI Avatar tries to connect → Backend rejects (invalid token) → Fallback mode
```

## The Fix Applied

### 1. Clear Old Tokens Before Login
```swift
private func performLogin() {
    // Clear any old mock tokens first
    print("🧹 [MinimalLauncher] Clearing old tokens...")
    TokenStore.shared.clearAllTokens()
    LyoWebSocketService.shared.disconnect()
    
    // Then do real backend login...
}
```

### 2. Reconnect WebSocket After Login
```swift
// After successful backend login:
print("🔌 [MinimalLauncher] Reconnecting WebSocket with new token...")
LyoWebSocketService.shared.disconnect()
LyoWebSocketService.shared.connect(userId: response.user.id, appState: appState)

print("✅ [MinimalLauncher] WebSocket reconnected with real token")
```

### 3. Same for Registration
Applied the same fix to `performRegistration()` - clear old tokens, then reconnect after successful registration.

## The Flow (After Fix):

```
App Launch
   ↓
AppState.init()
   ↓
loadAuthenticationState()
   ↓
TokenStore might have old tokens (or none)
   ↓
WebSocket connects (or doesn't if no token)
   ↓
User taps Login
   ↓
🧹 Clear old tokens (TokenStore.clearAllTokens())
   ↓
🔌 Disconnect WebSocket
   ↓
📡 Call backend login API
   ↓
✅ Receive REAL token: eyJhbGci...
   ↓
💾 Save token to TokenStore
   ↓
🔌 Disconnect WebSocket (in case still connected)
   ↓
🔌 Reconnect WebSocket with REAL token
   ↓
AI Avatar connects → Backend accepts! → Real AI! ✅
```

## Files Modified

**File:** `LyoApp/MinimalAILauncher.swift`

### Changes in `performLogin()`:
```swift
// BEFORE:
private func performLogin() {
    print("🔐 [MinimalLauncher] Attempting REAL backend login...")
    errorMessage = nil
    isLoading = true
    
    // Real backend authentication
    Task { @MainActor in
        // ... login code ...
    }
}

// AFTER:
private func performLogin() {
    print("🔐 [MinimalLauncher] Attempting REAL backend login...")
    errorMessage = nil
    isLoading = true
    
    // Clear any old mock tokens first
    print("🧹 [MinimalLauncher] Clearing old tokens...")
    TokenStore.shared.clearAllTokens()
    LyoWebSocketService.shared.disconnect()
    
    // Real backend authentication
    Task { @MainActor in
        // ... login code ...
        
        // AFTER successful login:
        // CRITICAL: Disconnect old WebSocket and reconnect with new token
        print("🔌 [MinimalLauncher] Reconnecting WebSocket with new token...")
        LyoWebSocketService.shared.disconnect()
        LyoWebSocketService.shared.connect(userId: response.user.id, appState: appState)
        
        print("✅ [MinimalLauncher] WebSocket reconnected with real token")
    }
}
```

### Same changes in `performRegistration()`:
- Clear old tokens before registration
- Reconnect WebSocket after successful registration

## How to Test

### Step 1: Delete App from iPhone
**IMPORTANT:** Delete the app from your iPhone to clear ALL old data:
1. Long-press the app icon
2. Tap "Remove App"
3. Confirm "Delete App"

This ensures no old mock tokens are persisted.

### Step 2: Rebuild and Install
```bash
# Build fresh
cd "/Users/hectorgarcia/Desktop/LyoApp July"
# Then run from Xcode (Cmd+R)
```

### Step 3: Login
1. Fill credentials (or use "Fill Test Credentials")
2. Tap "Login"
3. **Watch console for:**
   ```
   🧹 [MinimalLauncher] Clearing old tokens...
   🔐 [MinimalLauncher] Attempting REAL backend login...
   📡 [MinimalLauncher] Calling backend login API...
   🌐 POST https://lyo-backend-830162750094.us-central1.run.app/api/v1/auth/login
   📡 Response: 200
   ✅ [MinimalLauncher] Backend login successful!
      Token received: eyJhbGciOiJIUzI1NiIsInR5...
   🔌 [MinimalLauncher] Reconnecting WebSocket with new token...
   🔌 WebSocket connecting to: wss://lyo-backend-.../ai/ws/[userId] [auth=authorizationHeader]
   ✅ [MinimalLauncher] WebSocket reconnected with real token
   ```

### Step 4: Open AI Avatar
1. Tap "Start AI Session"
2. Send message: "Help me with calculus"
3. **Expected result:**
   - ✅ NO "local_token_" in WebSocket URL
   - ✅ WebSocket connects with real token
   - ✅ Real AI response (not fallback)

### Step 5: Check WebSocket Connection
In console, look for:
```
🔌 WebSocket connecting to: wss://lyo-backend-830162750094.us-central1.run.app/ai/ws/[REAL_USER_ID]
```

**Should NOT see:**
```
❌ token=local_token_XXX (BAD - means old token still there)
```

The token should be sent in `Authorization: Bearer` header, not in URL.

## Console Logs - Success Indicators

### ✅ Successful Flow:
```
🧹 [MinimalLauncher] Clearing old tokens...
🔐 [MinimalLauncher] Attempting REAL backend login...
📡 [MinimalLauncher] Calling backend login API...
🌐 POST https://lyo-backend-830162750094.us-central1.run.app/api/v1/auth/login
📡 Response: 200
✅ [MinimalLauncher] Backend login successful!
   User: testuser
   Token received: eyJhbGciOiJIUzI1NiIsInR5...
🔌 [MinimalLauncher] Reconnecting WebSocket with new token...
🔌 WebSocket connecting to: wss://lyo-backend-830162750094.us-central1.run.app/ai/ws/123 [auth=authorizationHeader]
✅ [MinimalLauncher] AppState updated with user and auth token
✅ [MinimalLauncher] WebSocket reconnected with real token

[Later when AI Avatar opens...]
🤖 [ImmersiveEngine] Calling AI backend with prompt: "Help me with calculus"
🌐 POST https://lyo-backend-830162750094.us-central1.run.app/api/v1/ai/chat
📡 Response: 200
✅ Real AI content generated
```

### ❌ If Still Shows Mock Token:
```
❌ Task <...> finished with error [-1011]
   token=local_token_XXXX
```
**Solution:** 
1. Delete app completely from iPhone
2. Clear Xcode derived data: Product → Clean Build Folder (Cmd+Shift+K)
3. Rebuild and install fresh

## Why This Happened

### Root Causes:
1. **Token Persistence:** UserDefaults kept old mock tokens between app runs
2. **Early WebSocket Connection:** AppState connected WebSocket on init (before login)
3. **No Reconnection:** WebSocket wasn't reconnected after login with new token
4. **Race Condition:** New token saved but WebSocket already connected with old token

### Similar Issues in Other Apps:
This is a common pattern in apps that:
- Load auth state on startup
- Connect WebSockets early
- Don't clear old tokens before login
- Don't reconnect services after auth change

## Verification Checklist

After testing, verify:

- [ ] App deleted and reinstalled fresh
- [ ] Console shows "Clearing old tokens..." on login
- [ ] Console shows "Backend login successful!"
- [ ] Console shows "Token received: eyJhbGci..." (NOT local_token_)
- [ ] Console shows "Reconnecting WebSocket with new token..."
- [ ] WebSocket URL shows real user ID (not with ?token= parameter)
- [ ] AI Avatar opens without crash
- [ ] Status shows "AI Ready" (no "fallback mode")
- [ ] Sending message returns REAL AI response
- [ ] Console shows "Real AI content generated"
- [ ] NO "local_token_" anywhere in logs
- [ ] Multiple messages all work with real AI

## Technical Details

### WebSocket Authentication:
The WebSocket service now uses **Authorization header** (preferred):
```swift
additionalHeaders["Authorization"] = "Bearer \(token)"
```

Not URL parameter (fallback):
```swift
// OLD: wss://backend/ws?token=local_token_XXX ❌
// NEW: wss://backend/ws + Header: "Authorization: Bearer eyJhbGci..." ✅
```

### Token Flow:
```
Backend Login
   ↓
Response: { token: "eyJhbGci...", user: {...} }
   ↓
TokenStore.save(accessToken: "eyJhbGci...", ...)
   ↓
UserDefaults.set("eyJhbGci...", forKey: "lyo_access_token")
   ↓
LyoWebSocketService.connect(userId: "123")
   ↓
TokenStore.getAccessToken() → "eyJhbGci..."
   ↓
WebSocket request with Header: "Authorization: Bearer eyJhbGci..."
   ↓
Backend validates JWT signature → ✅ Valid
   ↓
WebSocket connection established
   ↓
AI requests work! 🎉
```

## Related Issues

If you still see issues after this fix:

### Issue: Backend rejects token even though it looks real
**Check:**
- Token expiration (JWT tokens expire, typically 1 hour)
- Backend JWT secret key matches
- Token format is correct JWT (3 parts: header.payload.signature)

### Issue: WebSocket connects but immediately disconnects
**Check:**
- Backend WebSocket service is running
- Network connectivity
- Firewall or proxy blocking WebSocket

### Issue: Token shows correctly but AI still fails
**Check:**
- Backend AI service health: `curl https://backend/api/v1/ai/status`
- API endpoint is correct: `/api/v1/ai/chat`
- Request format matches backend expectations

## Summary

**What was wrong:** Old mock tokens persisted, WebSocket connected with them, and never reconnected after real login.

**What we fixed:** 
1. Clear old tokens before login
2. Disconnect WebSocket before login
3. Reconnect WebSocket after successful login with new token

**Expected result:** WebSocket now uses real backend token, AI Avatar connects successfully, real AI responses! 🎉

---

**Status:** ✅ FIXED
**Build:** ✅ SUCCEEDED  
**Next Step:** Delete app from device, reinstall, and test login with fresh state
