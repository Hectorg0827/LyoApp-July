# Authentication Debugging Guide

## How to Test Registration & Login

### Step 1: Check Console Logs
When you run the app in Xcode, open the console (Cmd+Shift+Y) to see debug output.

### Step 2: Test Registration

1. **Open app in Simulator or Device**
2. **Tap "Sign Up" if you're on login screen**
3. **Fill in ALL fields:**
   ```
   Email: test@example.com
   Password: Test123
   Confirm Password: Test123  
   Username: testuser
   Full Name: Test User
   ```

4. **Check button state:**
   - Button should be ENABLED (not grayed out)
   - If disabled, check that:
     - Email has @ and domain
     - Password is at least 6 characters
     - Passwords match
     - All fields are filled

5. **Tap "Create Account" button**

6. **Watch console for:**
   ```
   🔐 performAuthentication called
   🔐 isLoginMode: false
   🔐 Attempting registration...
   🔐   username: testuser
   🔐   email: test@example.com
   🔐   fullName: Test User
   💾 Saved user locally: test@example.com
   ✅ Registration successful: testuser
   ✅ Setting authenticated user
   ✅ User authenticated, isAuthenticated: true
   ```

7. **Expected result:**
   - App should navigate to main screen
   - You should see the home feed

### Step 3: Test Login

1. **If logged in, logout first:**
   - Go to More tab → Tap Logout

2. **On login screen, fill in:**
   ```
   Email: test@example.com
   Password: Test123
   ```

3. **Tap "Sign In" button**

4. **Watch console for:**
   ```
   🔐 performAuthentication called
   🔐 isLoginMode: true
   🔐 Attempting login...
   ✅ Login successful: testuser
   ✅ Setting authenticated user
   ✅ User authenticated, isAuthenticated: true
   ```

5. **Expected result:**
   - App should navigate to main screen

## Common Issues & Solutions

### Issue: Button is Disabled (Grayed Out)

**For Registration:**
Check that ALL of these are true:
- ✅ Email field has valid format (contains @ and domain)
- ✅ Password is at least 6 characters
- ✅ Confirm Password matches Password exactly
- ✅ Username is not empty
- ✅ Full Name is not empty

**For Login:**
Check that:
- ✅ Email field has valid format
- ✅ Password is not empty

### Issue: "User not found" Error

**Solution:** 
- You need to register first
- Tap "Sign Up" and create account
- Then login with same credentials

### Issue: "Invalid password" Error

**Solution:**
- Make sure you're using the exact same password you registered with
- Passwords are case-sensitive

### Issue: "Email already registered" Error

**Solution:**
- This email was already used
- Either:
  - Login with that email instead
  - Use a different email for new account

### Issue: Button Tap Does Nothing

**Check console for:**
1. Is `performAuthentication` being called?
2. Are there any error messages?
3. Is `isFormValid` returning false?

**Try:**
- Clean build folder (Cmd+Shift+K)
- Rebuild and run
- Delete app from simulator
- Run again

### Issue: App Stays on Login Screen

**Possible causes:**
1. `setAuthenticatedUser` not being called
2. `isAuthenticated` not being set to true
3. Navigation logic not working

**Check console for:**
```
✅ Setting authenticated user
✅ User authenticated, isAuthenticated: true
```

If you DON'T see these logs, there's an issue in the auth flow.

## Manual Testing Checklist

### Registration Flow:
- [ ] Fill all fields correctly
- [ ] Button becomes enabled
- [ ] Tap "Create Account"
- [ ] See console logs
- [ ] Navigate to main app
- [ ] Can see home feed

### Login Flow:
- [ ] Enter registered email
- [ ] Enter correct password
- [ ] Button becomes enabled
- [ ] Tap "Sign In"
- [ ] See console logs
- [ ] Navigate to main app

### Logout Flow:
- [ ] Go to More tab
- [ ] Tap Logout button
- [ ] Return to login screen
- [ ] Try login again

### Session Persistence:
- [ ] Login successfully
- [ ] Force quit app (swipe up in app switcher)
- [ ] Reopen app
- [ ] Should still be logged in

## Console Log Reference

### Successful Registration:
```
🔐 performAuthentication called
🔐 isLoginMode: false
🔐 email: test@example.com
🔐 password: filled
🔐 Attempting registration...
🔐   username: testuser
🔐   email: test@example.com
🔐   fullName: Test User
🔐 performRegistration: calling authManager.register
💾 Saved user locally: test@example.com
✅ Local registration successful: testuser
🔐 performRegistration: got result
✅ Registration successful: testuser
✅ Setting authenticated user
✅ User authenticated, isAuthenticated: true
```

### Successful Login:
```
🔐 performAuthentication called
🔐 isLoginMode: true
🔐 email: test@example.com
🔐 password: filled
🔐 Attempting login...
🔐 performLogin: calling authManager.login
✅ Local login successful: testuser
🔐 performLogin: got result
✅ Login successful: testuser
✅ Setting authenticated user
✅ User authenticated, isAuthenticated: true
```

### Failed Login (User Not Found):
```
🔐 performAuthentication called
🔐 isLoginMode: true
🔐 Attempting login...
🔐 performLogin: calling authManager.login
❌ Login failed: User not found
❌ Authentication error: invalidCredentials
```

### Failed Registration (Validation):
```
🔐 performAuthentication called
🔐 isLoginMode: false
🔐 Attempting registration...
🔐 performRegistration: calling authManager.register
❌ Registration failed: passwordTooShort (or other error)
❌ Authentication error: ...
```

## Quick Test Commands

### Clear All User Data (Start Fresh):
```bash
# In Xcode, with simulator running:
# 1. Stop app
# 2. Delete app from simulator (long press, delete)
# 3. Run app again
```

### View Stored Users:
Add this temporarily to SimplifiedAuthenticationManager:
```swift
func debugPrintUsers() {
    let users = loadAllUsers()
    print("📋 Stored users: \(users.count)")
    for user in users {
        print("  - \(user.email) (\(user.username))")
    }
}
```

Call it in your code to see what's stored.

## Expected Behavior Summary

1. **First Time User:**
   - Sees login screen
   - Taps "Sign Up"
   - Fills all fields
   - Creates account
   - Navigates to main app

2. **Returning User:**
   - Opens app
   - Already logged in (session persists)
   - Sees main app immediately

3. **After Logout:**
   - Sees login screen
   - Enters credentials
   - Logs in
   - Navigates to main app

---

## If Nothing Works

Try these in order:

1. **Clean Build:**
   ```
   Cmd+Shift+K (Clean Build Folder)
   Cmd+B (Build)
   Cmd+R (Run)
   ```

2. **Delete Derived Data:**
   ```
   Xcode → Preferences → Locations
   Click arrow next to Derived Data
   Delete LyoApp folder
   Rebuild
   ```

3. **Reset Simulator:**
   ```
   Simulator → Device → Erase All Content and Settings
   Run app again
   ```

4. **Check Console:**
   - Open Console (Cmd+Shift+Y)
   - Look for any error messages
   - Share console output for debugging

---

**Status:** Debug logging added
**Build:** ✅ SUCCEEDED
**Next:** Run app and check console output
