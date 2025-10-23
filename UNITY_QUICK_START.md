# Unity Integration - Quick Reference

## ⚡ TL;DR - Fast Track

### If Unity is NOT yet exported:
```bash
# 1. Export Unity project (do this in Unity Editor):
#    File > Build Settings > iOS > Export Project ✓ > Export
#    Save to: /Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export

# 2. Run integration script:
cd "/Users/hectorgarcia/Desktop/LyoApp July"
./integrate_unity.sh
```

### If Unity is already exported:
```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"
./integrate_unity.sh "/path/to/your/unity/export"
```

## 📋 Unity Export Checklist

In Unity Editor:
- [ ] File > Build Settings
- [ ] Select iOS platform
- [ ] ✅ CHECK "Export Project"
- [ ] Click Export (NOT Build!)
- [ ] Save to: `/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export`

## 🎯 What Gets Integrated

| Component | Source | Destination |
|-----------|--------|-------------|
| Framework | `UnityExport/UnityFramework/UnityFramework.framework` | `LyoApp/Frameworks/UnityFramework.framework` |
| Data | `UnityExport/Data/` | `LyoApp/LyoApp/UnityData/` |
| Bridge | Already in project ✅ | `LyoApp/LyoApp/Unity/UnityBridge.swift` |

## 🔍 Verification Commands

```bash
# Check if framework exists
ls -la "/Users/hectorgarcia/Desktop/LyoApp July/Frameworks/UnityFramework.framework"

# Check if Data folder exists
ls -la "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp/UnityData"

# Build and test
cd "/Users/hectorgarcia/Desktop/LyoApp July"
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 🚀 Expected Output

### Success:
```
✅ Framework copied to: Frameworks/UnityFramework.framework
✅ Data copied to: LyoApp/UnityData
✅ Xcode project updated
🎉 Unity Integration Complete!
```

### When app launches:
```
✅ Unity initialized successfully
```

## ❌ Common Issues

| Problem | Quick Fix |
|---------|-----------|
| Script can't find export | Check export path, must match exactly |
| Framework not found | Re-export from Unity with "Export Project" checked |
| Build fails | Open Xcode, clean build folder (Cmd+Shift+K), rebuild |
| Unity doesn't initialize | Check framework is "Embed & Sign" in Xcode |

## 📞 Manual Override

If automation fails, manual steps:

1. **Copy framework**:
   ```bash
   cp -R "/path/to/UnityFramework.framework" "Frameworks/"
   ```

2. **Copy data**:
   ```bash
   cp -R "/path/to/Data" "LyoApp/UnityData"
   ```

3. **In Xcode**:
   - Add framework: Target > General > + > Add Other
   - Set to "Embed & Sign"
   - Add Data: Right-click LyoApp > Add Files > UnityData

## 🎮 Using Unity in Your App

The UnityBridge is already set up. To use Unity:

```swift
// In any SwiftUI view:
import SwiftUI

struct MyUnityView: View {
    var body: some View {
        UnityContainerView()  // This view is already created!
            .edgesIgnoringSafeArea(.all)
    }
}
```

Or check if available:
```swift
if UnityBridge.shared.isAvailable() {
    // Unity is integrated!
}
```

## 📂 File Locations

| File | Purpose | Location |
|------|---------|----------|
| Integration Script | Automates everything | `integrate_unity.sh` |
| Full Guide | Detailed instructions | `UNITY_INTEGRATION_GUIDE.md` |
| UnityBridge | Swift Unity interface | `LyoApp/Unity/UnityBridge.swift` |
| Unity Container View | SwiftUI wrapper | `LyoApp/Views/UnityContainerView.swift` |

## 🏁 Final Check

Before considering integration complete:

- [ ] `integrate_unity.sh` executed successfully
- [ ] Framework visible in Xcode project
- [ ] Data folder visible in Xcode project (blue icon)
- [ ] Build succeeds with no errors
- [ ] App launches and Unity initializes
- [ ] Unity scene renders in app

---

**Current Status**: 
- ✅ LyoApp builds successfully
- ✅ UnityBridge implemented and tested
- ✅ Integration automation ready
- ⏳ **Next**: Export Unity project from Unity Editor
