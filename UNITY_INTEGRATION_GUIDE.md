# Unity iOS Export and Integration Guide

## Overview
This guide explains how to export your Unity project for iOS and integrate it into the LyoApp Xcode project.

## Prerequisites
- Unity Editor installed (2021.3 or later recommended)
- iOS Build Support module installed in Unity
- Xcode installed on your Mac
- LyoApp project with UnityBridge already set up ✅

## Part 1: Export Unity Project for iOS

### Step 1: Open Unity Project
1. Launch Unity Hub
2. Open the project at: `/Users/hectorgarcia/Downloads/UnityClassroom_oct 15`
3. Wait for Unity to finish loading and compiling scripts

### Step 2: Configure iOS Build Settings
1. In Unity, go to **File > Build Settings**
2. Select **iOS** from the Platform list
3. Click **Switch Platform** (if not already on iOS)
4. Wait for Unity to reimport assets for iOS

### Step 3: Export Project Settings
Configure these settings in the Build Settings window:

**Important Settings:**
- ✅ **Export Project**: CHECK THIS BOX (This is crucial!)
- Development Build: Optional (check for debugging)
- Compression Method: LZ4 or LZ4HC (recommended)

### Step 4: Player Settings
Click **Player Settings** button and configure:

**iOS Settings:**
1. **Company Name**: Set your company name
2. **Product Name**: UnityClassroom
3. **Bundle Identifier**: com.yourcompany.unityclassroom
4. **Target Minimum iOS Version**: 13.0 or higher
5. **Architecture**: ARM64
6. **Metal Editor Support**: Enabled

**Other Settings:**
1. **Scripting Backend**: IL2CPP
2. **Target SDK**: Device SDK
3. **Api Compatibility Level**: .NET Standard 2.1

### Step 5: Export the Project
1. Click **Export** button (NOT Build!)
2. Choose export location: `/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export`
3. Click **Export**
4. Wait for Unity to export (may take 5-15 minutes)

### Step 6: Verify Export
After export completes, verify these files exist:
```
UnityClassroom_oct_15_iOS_Export/
├── Unity-iPhone.xcodeproj/
├── UnityFramework/
│   └── UnityFramework.framework/
├── Data/
│   ├── globalgamemanagers
│   ├── level0
│   └── ...
├── Classes/
└── Libraries/
```

## Part 2: Integrate Unity into LyoApp

### Option A: Automated Integration (Recommended)

Run the integration script:
```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"
./integrate_unity.sh "/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export"
```

The script will:
- ✅ Copy UnityFramework.framework to LyoApp/Frameworks/
- ✅ Copy Data folder to LyoApp/UnityData/
- ✅ Update Xcode project configuration
- ✅ Add framework search paths
- ✅ Configure build settings

### Option B: Manual Integration

If you prefer manual integration:

#### 1. Copy UnityFramework.framework
```bash
mkdir -p "/Users/hectorgarcia/Desktop/LyoApp July/Frameworks"
cp -R "/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export/UnityFramework/UnityFramework.framework" \
      "/Users/hectorgarcia/Desktop/LyoApp July/Frameworks/"
```

#### 2. Copy Data Folder
```bash
cp -R "/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export/Data" \
      "/Users/hectorgarcia/Desktop/LyoApp July/LyoApp/UnityData"
```

#### 3. Add Framework to Xcode
1. Open `LyoApp.xcodeproj` in Xcode
2. Select the **LyoApp** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** button
6. Click **Add Other** > **Add Files**
7. Navigate to `Frameworks/UnityFramework.framework`
8. Select it and click **Open**
9. **Important**: Set to **Embed & Sign**

#### 4. Add Data Folder to Resources
1. In Xcode, right-click on the **LyoApp** group
2. Select **Add Files to "LyoApp"**
3. Navigate to `LyoApp/UnityData`
4. **Important**: Select **Create folder references** (folder should be blue, not yellow)
5. Click **Add**

#### 5. Configure Framework Search Paths
1. Select **LyoApp** target
2. Go to **Build Settings** tab
3. Search for "Framework Search Paths"
4. Add: `$(PROJECT_DIR)/Frameworks`

#### 6. Add Other Linker Flags
1. Still in Build Settings
2. Search for "Other Linker Flags"
3. Add: `-ObjC`

## Part 3: Verify Integration

### 1. Build the Project
```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"
xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected output:
```
** BUILD SUCCEEDED **
```

### 2. Check UnityBridge Detection
The UnityBridge should automatically detect Unity:
- Look for this log when app launches: `"✅ Unity initialized successfully"`
- Or: `"⚠️ UnityFramework.framework not found"` if integration failed

### 3. Test Unity View
If you added Unity to a tab or view:
1. Run the app in simulator
2. Navigate to the Unity view
3. You should see your Unity scene rendering

## Part 4: Troubleshooting

### Problem: "UnityFramework.framework not found"
**Solution**: Verify framework is in `Frameworks/` folder and added to project

### Problem: "Data bundle not found"
**Solution**: Ensure Data folder is in bundle resources with folder references (blue icon)

### Problem: Build fails with "framework not found"
**Solution**: Check Framework Search Paths in Build Settings

### Problem: Unity scene doesn't load
**Solution**: Check Data folder structure and bundle identifier matches Unity export

### Problem: App crashes on Unity initialization
**Solution**: 
1. Check that framework is set to "Embed & Sign"
2. Verify minimum deployment target matches Unity export
3. Check console logs for specific error messages

## Part 5: Next Steps

After successful integration:

1. **Test all Unity features**: Navigate through all Unity scenes
2. **Test on device**: Build and run on a physical iOS device
3. **Performance testing**: Check frame rate and memory usage
4. **Optimize if needed**: Adjust Unity quality settings if performance is poor

## UnityBridge API

The UnityBridge in LyoApp provides these methods:

```swift
// Check if Unity is available
UnityBridge.shared.isAvailable() -> Bool

// Initialize Unity (call once at app start)
UnityBridge.shared.initializeUnity()

// Get Unity's view for embedding
UnityBridge.shared.getUnityView() -> UIView?

// Show/hide Unity
UnityBridge.shared.showUnity()

// Pause/Resume Unity
UnityBridge.shared.pauseUnity()
UnityBridge.shared.resumeUnity()

// Send messages to Unity
UnityBridge.shared.sendMessageToUnity(
    gameObject: "GameObjectName",
    methodName: "MethodName",
    message: "message"
)
```

## Support

If you encounter issues:
1. Check build logs in Xcode
2. Verify all paths are correct
3. Ensure Unity export completed successfully
4. Review UnityBridge implementation in `LyoApp/Unity/UnityBridge.swift`

---

**Status**: 
- ✅ UnityBridge ready
- ✅ Integration script ready
- ⏳ Waiting for Unity iOS export
