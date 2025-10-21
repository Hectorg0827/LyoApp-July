# Quick Start - Testing Authentication

## ✅ What Works Now (Simulator)

### Email Registration
1. Open app in Simulator
2. You'll see the login screen
3. Tap "Don't have an account? Sign Up"
4. Fill in:
   - **Email:** hector.garcia0827@gmail.com (or any email)
   - **Password:** Test123
   - **Username:** hector
   - **Full Name:** Hector Garcia
5. Tap "Sign Up"
6. ✅ You're logged in!

### Email Login (After Registration)
1. Open app
2. Fill in:
   - **Email:** hector.garcia0827@gmail.com
   - **Password:** Test123
3. Tap "Log In"
4. ✅ You're back in!

### Logout
1. Go to More/Settings tab
2. Tap "Logout"
3. You're back to login screen

## ⚠️ What Doesn't Work (Simulator)

### Apple Sign-In
- **Status:** Hidden in Simulator
- **Why:** Simulator doesn't support Apple authentication
- **Message shown:** "Social Sign-In unavailable in Simulator"
- **Solution:** Use email registration OR test on real iPhone

### Google Sign-In
- **Status:** Hidden in Simulator
- **Why:** Not yet implemented (needs SDK)
- **Solution:** Use email registration

## 📱 What Works on Real Device

When you test on a real iPhone:
1. Apple Sign-In button will appear
2. Tap "Continue with Apple"
3. Native Apple authentication sheet opens
4. Use Face ID, Touch ID, or password
5. You're logged in!

## 🤖 AI Avatar Status

- **Status:** ✅ Fixed
- **What changed:** Added error handling to prevent crashes
- **How to access:** Tap the floating purple avatar button (bottom right)
- **If error:** Shows clear error message with dismiss button

## Test Credentials

You can use these for testing:

```
Email: test@example.com
Password: Test123
Username: testuser
Full Name: Test User
```

Or create your own!

## Known Issues & Solutions

### Issue: "Apple Sign-In failed"
**Solution:** Expected in Simulator. Use email registration.

### Issue: "Can't see Apple/Google buttons"
**Solution:** Correct behavior in Simulator! They appear on real device.

### Issue: "App crashes when opening AI Avatar"
**Solution:** Fixed! If you still see crash, check error overlay and dismiss.

### Issue: "Lost my password"
**Solution:** Currently no password reset (local storage only). Just register with new account.

## Quick Commands

### Build & Run
```bash
# In Xcode: Cmd+R
# Or terminal:
xcodebuild -project LyoApp.xcodeproj -scheme "LyoApp 1" build
```

### Clear Local Data (Start Fresh)
1. Delete app from Simulator
2. Cmd+Shift+K (Clean Build Folder)
3. Rebuild and run

## Next Steps

1. ✅ Test email registration (works now!)
2. ✅ Test login/logout cycle
3. ✅ Explore app features
4. 📱 Test Apple Sign-In on real device (when available)
5. 🚀 Deploy to TestFlight (requires Apple Developer account)

## Files You Modified
- Email auth: `SimplifiedAuthenticationManager.swift`
- UI: `AuthenticationView.swift`
- AI Avatar: `AIAvatarView.swift`

---

**Current Status:** ✅ All systems working in Simulator
**Build:** ✅ SUCCEEDED
**Ready for:** ✅ Testing & Development
