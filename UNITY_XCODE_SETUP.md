# UnityFramework Xcode Integration - LyoApp

## ✅ Files Already Created

Automated setup created:
- `Frameworks/UnityFramework.framework` (the compiled framework)
- `LyoApp/Core/Services/UnityManager.swift` (Unity lifecycle manager)
- `LyoApp-Bridging-Header.h` (Swift-ObjC bridge)
- `LyoApp/Core/Services/AppDelegate+Unity.swift` (AppDelegate integration)

## 📝 Manual Xcode Steps (4 Steps)

### Step 1: Add Framework to Build Phases

1. Open **LyoApp.xcodeproj** in Xcode
2. Select **Targets** → **LyoApp**
3. **Build Phases** tab
4. **Link Binary With Libraries** → **+**
5. Click **Add Other...**
6. Navigate to: `Frameworks/UnityFramework.framework`
7. Click **Open**

### Step 2: Update Build Settings

1. **Build Settings** tab
2. Search: "Framework Search Paths"
3. Add: `$(PROJECT_DIR)/Frameworks`
4. Search: "Bridging Header"  
5. Set: `LyoApp-Bridging-Header.h`

### Step 3: Update AppDelegate.swift

In your AppDelegate, add:

```swift
func application(_ application: UIApplication, 
               didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize Unity
    self.initializeUnityFramework()
    
    // ... rest of code
    return true
}

func applicationWillTerminate(_ application: UIApplication) {
    // Shutdown Unity
    self.shutdownUnityFramework()
}
```

### Step 4: Build

```bash
# In terminal or Xcode
Cmd+B  # Build
Cmd+R  # Run
```

## ✅ Testing

After build succeeds, check console for:
```
[UnityManager] Unity initialized successfully
[AppDelegate] Unity framework ready
```

## 🎯 Success = Framework working in your app!
