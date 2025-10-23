# AI Avatar & Unity Integration Guide

## 🎯 Current Status Overview

### ✅ What's Working
- **Unity Project**: Fully integrated at `Lyo-Classroom-Unity/`
- **Unity Framework**: Available in `Frameworks/UnityFramework.framework`
- **Unity Tab**: Accessible from the main app (if framework is detected)
- **Backend URLs**: All services configured to production backend
- **AI Avatar Service**: Code is ready and configured

### ⚠️ What Needs Attention
- **AI Avatar Authentication**: Requires user login to function
- **Test Users**: Need backend credentials to activate AI features

---

## 🗂️ Unity Project Location

### **Unity Source Project**
```
📁 /Users/hectorgarcia/Desktop/LyoApp July/Lyo-Classroom-Unity/
```

**To Access the Unity Project:**

1. **Open in Unity Hub:**
   ```bash
   # From terminal
   cd "/Users/hectorgarcia/Desktop/LyoApp July/Lyo-Classroom-Unity"
   open -a "Unity Hub" .
   ```

2. **Or manually:**
   - Open Unity Hub
   - Click "Add" or "Open"
   - Navigate to: `/Users/hectorgarcia/Desktop/LyoApp July/Lyo-Classroom-Unity`
   - Select the folder

### **Unity Framework (Already Integrated)**
```
📁 /Users/hectorgarcia/Desktop/LyoApp July/Frameworks/UnityFramework.framework
```

This is the compiled Unity build that's already linked to your iOS app.

---

## 🤖 AI Avatar System Architecture

### **How the AI Avatar Works**

```
┌─────────────────────────────────────────────────────────────┐
│                        User Opens App                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  App Checks Authentication Status (AuthenticationService)   │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┴──────────────┐
        │                              │
        ▼                              ▼
┌──────────────┐              ┌──────────────────┐
│ NOT LOGGED   │              │  LOGGED IN       │
│ IN           │              │  ✅ Has Token    │
└──────┬───────┘              └────────┬─────────┘
       │                               │
       │                               ▼
       │                  ┌────────────────────────────┐
       │                  │ AI Avatar Connects to      │
       │                  │ Backend API                │
       │                  │                            │
       │                  │ Endpoints:                 │
       │                  │ - /ai/avatar/context       │
       │                  │ - /ai/avatar/message       │
       │                  │ - /ai/generate-course      │
       │                  └────────────────────────────┘
       │                               │
       │                               ▼
       │                  ┌────────────────────────────┐
       │                  │ AI Avatar Features Active: │
       │                  │ • Chat Functionality       │
       │                  │ • Course Generation        │
       │                  │ • Personalized Learning    │
       │                  │ • Voice Interaction        │
       │                  └────────────────────────────┘
       │
       ▼
┌────────────────────────────────────────────┐
│ AI Avatar Shows "Disconnected" Status      │
│ • Can't generate courses                   │
│ • Can't chat                               │
│ • No personalization                       │
└────────────────────────────────────────────┘
```

### **Key Files**

1. **`AIAvatarIntegration.swift`**
   - Main service: `AIAvatarService`
   - Handles backend communication
   - Manages chat messages
   - Requires authentication token

2. **`AIAvatarView.swift`**
   - UI for the floating AI avatar
   - Chat interface
   - Connection status display

3. **`AuthenticationService.swift`**
   - Manages user login/logout
   - Stores auth tokens in Keychain
   - **CRITICAL**: AI Avatar won't work without valid token

4. **`AICourseGenerationService.swift`**
   - Generates AI-powered courses
   - Requires authentication
   - Communicates with backend `/ai/generate-course` endpoint

---

## 🔧 How to Enable AI Avatar Functionality

### **Option 1: Test with Backend Credentials** (Recommended for Development)

You need to create a test user on your backend or use existing credentials.

**Step 1: Check Backend Status**
```bash
curl https://lyo-backend-830162750094.us-central1.run.app/api/v1/health
```

Expected response:
```json
{
  "status": "healthy",
  "message": "Backend is running",
  "timestamp": 1729622400.0
}
```

**Step 2: Create a Test Login UI**

The app currently doesn't have a visible login screen in the main flow. You need to either:

A. **Add a login button temporarily** to test the AI Avatar:

Create this file to add a quick login flow:

```swift
// File: LyoApp/Views/QuickLoginView.swift
import SwiftUI

struct QuickLoginView: View {
    @State private var email = "test@example.com"
    @State private var password = "password123"
    @State private var isLoading = false
    @State private var message = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quick Login for Testing")
                .font(.title)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Login") {
                Task {
                    await login()
                }
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
            }
            
            Text(message)
                .foregroundColor(message.contains("✅") ? .green : .red)
        }
        .padding()
    }
    
    func login() async {
        isLoading = true
        message = "Logging in..."
        
        let success = await AuthenticationService.shared.signIn(
            email: email,
            password: password
        )
        
        isLoading = false
        
        if success {
            message = "✅ Login successful! AI Avatar is now active."
        } else {
            message = "❌ Login failed. Check credentials."
        }
    }
}
```

B. **Use the backend to create a test user:**

If your backend has a signup endpoint, you can create a test user:

```bash
curl -X POST https://lyo-backend-830162750094.us-central1.run.app/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@lyoapp.com",
    "password": "TestPassword123!",
    "name": "Test User"
  }'
```

### **Option 2: Mock Authentication (For Quick Testing)**

Temporarily bypass authentication to test AI Avatar UI:

**Modify `AIAvatarService.swift`:**

```swift
// Around line 305 in AIAvatarIntegration.swift
func loadAvatarContext() async {
    // TEMPORARY: Comment out auth check for testing
    // guard apiClient.hasAuthToken() else {
    //     logger.warning("No auth token available for loading avatar context")
    //     return
    // }
    
    // For testing without backend:
    await MainActor.run {
        self.isConnected = true  // Fake connection
        self.currentContext = AvatarContextResponse(
            topicsCovered: ["Swift", "iOS Development"],
            learningGoals: ["Master SwiftUI"],
            currentModule: "AI Avatar Integration",
            engagementLevel: 0.8,
            lastInteraction: Date().timeIntervalSince1970
        )
    }
    return
    
    // ... rest of original code
}
```

⚠️ **WARNING**: This is only for UI testing. The AI won't generate real responses without backend.

---

## 🚀 Testing the Complete Flow

### **1. Build and Run the App**

```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"

# Clean build
xcodebuild -project LyoApp.xcodeproj \
  -scheme "LyoApp 1" \
  clean build \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Or use the VS Code task: "Build Xcode Project"
```

### **2. Access the Unity Project**

- In the app, look for the **"3D Classroom"** tab
- This tab only appears if `UnityFramework.framework` is detected
- It should show the Unity-rendered 3D environment

### **3. Access the AI Avatar**

The AI Avatar should be accessible from:
- **TopicGatheringView**: Floating AI button
- **EnhancedAIClassroomView**: AI assistant during lessons

**Current Trigger Points:**
```swift
// In TopicGatheringView.swift (line 29)
// Floating AI Avatar button appears

// In HomeFeedView.swift
// AI course generation requires authentication
```

### **4. Verify AI Avatar Connection**

Once logged in, check the console for:
```
✅ Backend health check passed: healthy - Backend is running
✅ Avatar context loaded successfully
```

If you see:
```
⚠️ No auth token available for loading avatar context
```
→ User is not logged in

---

## 📝 Next Steps to Make AI Avatar Fully Functional

### **Immediate Actions:**

1. **Add Login UI**
   - Create a simple login screen for testing
   - Or expose the existing `AuthenticationService` through a button

2. **Verify Backend Endpoints**
   ```bash
   # Test auth endpoint
   curl -X POST https://lyo-backend-830162750094.us-central1.run.app/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password"}'
   
   # Test AI avatar endpoint (requires auth token)
   curl https://lyo-backend-830162750094.us-central1.run.app/api/v1/ai/avatar/context \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

3. **Test AI Course Generation**
   - After login, navigate to "Learn" tab
   - Try creating a course
   - Check console for API calls

### **Backend Requirements:**

Your production backend must have these endpoints:

- ✅ `/api/v1/health` - Working
- ❓ `/api/v1/auth/login` - Needs verification
- ❓ `/api/v1/auth/signup` - Needs verification
- ❓ `/api/v1/ai/avatar/context` - Needs verification
- ❓ `/api/v1/ai/avatar/message` - Needs verification
- ❓ `/api/v1/ai/generate-course` - Needs verification

---

## 🐛 Troubleshooting

### **"AI Avatar shows disconnected"**
- Check if user is logged in
- Verify backend is reachable
- Check console for auth token errors

### **"Unity tab doesn't appear"**
- Verify `UnityFramework.framework` exists in `Frameworks/`
- Check Xcode project for framework linking
- Look for console message: `⚠️ UnityFramework.framework not found`

### **"AI doesn't respond to messages"**
- Verify authentication token is valid
- Check network requests in console
- Ensure backend endpoints are implemented

---

## 📚 Additional Resources

- **Unity Project**: `Lyo-Classroom-Unity/`
- **Integration Scripts**: `integrate_unity.sh`, `unity_export_and_integrate.sh`
- **Backend Config**: `APIConfig.swift` (production URL: `https://lyo-backend-830162750094.us-central1.run.app/`)
- **Documentation**: `AI_AVATAR_*.md` files in project root

---

**Summary**: Your AI Avatar infrastructure is complete, but it requires user authentication to function. Add a login flow or use the backend to create test credentials, then the AI Avatar will connect and provide full functionality.
