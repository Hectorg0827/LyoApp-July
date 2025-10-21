# 🎮 Unity 3D Avatar Setup GuideZ

Complete guide for integrating Unity 3D avatars into your LyoApp iOS application.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Unity Project Setup](#unity-project-setup)
3. [iOS Integration](#ios-integration)
4. [Asset Pipeline](#asset-pipeline)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

### Required Software

- **Unity 2022.3 LTS** or newer
- **Xcode 15+**
- **iOS 16.0+** target deployment
- **CocoaPods** (for iOS dependencies)

### Unity Packages Required

Install these via Unity Package Manager (Window → Package Manager):

1. **Universal Render Pipeline (URP)** v14.0+
2. **Addressables** v1.21+
3. **Unity as a Library** (iOS Export)
4. **TextMeshPro** (for UI)

Optional (Recommended):
- **OVR LipSync** for advanced lip sync
- **VRM Unity Package** for VRM avatar support

---

## 🎨 Unity Project Setup

### Step 1: Create New Unity Project

```bash
# Create project directory
mkdir -p ~/UnityProjects/LyoAvatars
cd ~/UnityProjects/LyoAvatars

# Unity will create the project structure
```

In Unity Hub:
1. Click "New Project"
2. Select **3D (URP)** template
3. Name: `LyoAvatars`
4. Location: `~/UnityProjects/LyoAvatars`
5. Click "Create Project"

### Step 2: Configure Project Settings

#### Build Settings
1. Go to **File → Build Settings**
2. Switch platform to **iOS**
3. Click "Switch Platform"

#### Player Settings
1. Go to **Edit → Project Settings → Player**
2. Configure iOS settings:

```
iOS Settings:
├── Company Name: "Your Company"
├── Product Name: "LyoAvatars"
├── Bundle Identifier: "com.yourcompany.lyoavatars"
├── Target iOS Version: 16.0
├── Architecture: ARM64
└── Camera Usage Description: "For AR avatar features"
```

3. **Other Settings**:
   - Scripting Backend: **IL2CPP**
   - API Compatibility Level: **.NET Standard 2.1**
   - Target Architectures: **ARM64** only

#### Graphics Settings
1. Go to **Edit → Project Settings → Graphics**
2. Set Scriptable Render Pipeline to **UniversalRenderPipelineAsset**
3. Configure URP Asset:

```
URP Settings:
├── Rendering
│   ├── Rendering Path: Forward
│   ├── Depth Texture: Enabled
│   └── Opaque Texture: Disabled (for performance)
├── Quality
│   ├── HDR: Disabled (mobile optimization)
│   ├── MSAA: 4x
│   └── Render Scale: 1.0
└── Lighting
    ├── Main Light: Per Pixel
    └── Additional Lights: Per Pixel (max 4)
```

### Step 3: Import Scripts

Copy the provided scripts into your Unity project:

```bash
# From the LyoApp directory
cp Unity/Assets/Scripts/*.cs ~/UnityProjects/LyoAvatars/Assets/Scripts/
```

Scripts included:
- `AvatarManager.cs` - Main avatar controller
- `AvatarBlendshapeController.cs` - Facial expressions
- `AvatarLipSyncController.cs` - Lip sync animation

### Step 4: Set Up Addressables

1. Install Addressables package:
   - Window → Package Manager
   - Search "Addressables"
   - Click "Install"

2. Initialize Addressables:
   - Window → Asset Management → Addressables → Groups
   - Click "Create Addressables Settings"

3. Create Asset Groups:

```
Addressables Groups:
├── Avatars_Bodies
│   └── Content Packing: Pack Together
├── Avatars_Hair
│   └── Content Packing: Pack Together
├── Avatars_Outfits
│   └── Content Packing: Pack Together
└── Avatars_Accessories
    └── Content Packing: Pack Separately
```

4. Configure build path:
   - Addressables Settings → Profile → Default
   - Set Local Build Path: `[BuildTarget]/[BuildTarget]`
   - Set Remote Build Path: `ServerData/[BuildTarget]`

### Step 5: Create Avatar Scene

1. Create new scene: **File → New Scene**
2. Save as `Scenes/AvatarScene.unity`

3. Set up scene hierarchy:

```
AvatarScene
├── Directional Light
├── Main Camera
│   └── Position: (0, 1.5, -3)
│   └── Rotation: (0, 0, 0)
└── AvatarRoot
    ├── Avatar (GameObject)
    │   ├── Body (SkinnedMeshRenderer)
    │   ├── Head (SkinnedMeshRenderer)
    │   │   └── Face (with blendshapes)
    │   ├── Hair (SkinnedMeshRenderer)
    │   ├── Outfit (SkinnedMeshRenderer)
    │   └── Accessories (Empty GameObject)
    ├── AvatarManager (Script)
    ├── AvatarBlendshapeController (Script)
    └── AvatarLipSyncController (Script)
```

4. Add components to AvatarRoot:
   - Add **AvatarManager** script
   - Add **Animator** component
   - Configure references in inspector

### Step 6: Create Animation Controller

1. Right-click in Project → Create → Animator Controller
2. Name it `AvatarAnimatorController`
3. Open Animator window (Window → Animation → Animator)

4. Create animation states:

```
Animation States:
├── Idle (default state)
├── Mood_neutral
├── Mood_happy
├── Mood_excited
├── Mood_concerned
├── Mood_thinking
├── Mood_encouraging
├── Mood_calm
├── Mood_celebrating
├── Speaking
└── LevelUp (celebration)
```

5. Create parameters:
   - **IsSpeaking** (Bool)
   - Triggers for each mood (e.g., `Mood_happy`)

6. Create transitions between states

---

## 📱 iOS Integration

### Step 1: Export Unity as Framework

1. In Unity: **File → Build Settings**
2. Select **iOS** platform
3. Check **"Export as Xcode Project"**
4. Click **"Build"**
5. Choose export location: `LyoApp July/UnityExport/`

### Step 2: Integrate with Xcode

#### A. Copy UnityFramework

```bash
cd "LyoApp July"

# Copy UnityFramework to Xcode project
cp -R UnityExport/iOS/UnityFramework.framework ./Frameworks/
```

#### B. Update Xcode Project

1. Open `LyoApp.xcodeproj` in Xcode
2. Add UnityFramework:
   - Select project root
   - Go to "General" tab
   - Under "Frameworks, Libraries, and Embedded Content"
   - Click "+" → Add Other → Add Files
   - Select `UnityFramework.framework`
   - Set to **"Embed & Sign"**

3. Update Build Settings:
   - Search for "Framework Search Paths"
   - Add: `$(PROJECT_DIR)/Frameworks`

4. Update Info.plist:

```xml
<key>UIApplicationSupportsIndirectInputEvents</key>
<true/>
<key>UnityFramework</key>
<string>UnityFramework.framework</string>
```

### Step 3: Create Swift Bridge

Create file: `LyoApp/Unity/UnityBridge.swift`

```swift
import Foundation
import UIKit
import UnityFramework

class UnityBridge: NSObject {
    static let shared = UnityBridge()

    private var unityFramework: UnityFramework?
    private var hostMainWindow: UIWindow?

    private override init() {
        super.init()
    }

    func initializeUnity() {
        guard unityFramework == nil else { return }

        let bundlePath = Bundle.main.path(forResource: "UnityFramework", ofType: "framework")!
        let bundle = Bundle(path: bundlePath)!

        if let framework = bundle.principalClass?.getInstance() {
            unityFramework = framework
            framework.setDataBundleId("com.unity3d.framework")

            framework.runEmbedded(
                withArgc: CommandLine.argc,
                argv: CommandLine.unsafeArgv,
                appLaunchOpts: nil
            )
        }
    }

    func getUnityView() -> UIView {
        guard let framework = unityFramework else {
            print("[UnityBridge] ERROR: Unity not initialized")
            return UIView()
        }

        return framework.appController()?.rootView ?? UIView()
    }

    func sendMessage(objectName: String, methodName: String, message: String) {
        unityFramework?.sendMessageToGO(
            withName: objectName,
            functionName: methodName,
            message: message
        )
    }

    func pause() {
        unityFramework?.appController()?.pause()
    }

    func resume() {
        unityFramework?.appController()?.resume()
    }

    func unload() {
        unityFramework?.unloadApplication()
    }
}
```

### Step 4: Create SwiftUI Wrapper

Create file: `LyoApp/Unity/UnityAvatarView.swift`

```swift
import SwiftUI

struct UnityAvatarView: UIViewRepresentable {
    let avatar: Avatar
    let mood: CompanionMood
    let isSpeaking: Bool

    func makeUIView(context: Context) -> UIView {
        // Initialize Unity on first use
        UnityBridge.shared.initializeUnity()

        let unityView = UnityBridge.shared.getUnityView()

        // Send initial avatar config
        UnityBridge.shared.sendMessage(
            objectName: "AvatarRoot",
            methodName: "LoadAvatar",
            message: avatar.toUnityJSON()
        )

        return unityView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update mood
        UnityBridge.shared.sendMessage(
            objectName: "AvatarRoot",
            methodName: "SetMood",
            message: mood.rawValue
        )

        // Update speaking state
        UnityBridge.shared.sendMessage(
            objectName: "AvatarRoot",
            methodName: "SetSpeaking",
            message: isSpeaking ? "true" : "false"
        )
    }
}

// Usage in SwiftUI
struct AvatarPreviewView: View {
    @EnvironmentObject var avatarStore: AvatarStore

    var body: some View {
        UnityAvatarView(
            avatar: avatarStore.avatar!,
            mood: avatarStore.currentMood,
            isSpeaking: avatarStore.state.isSpeaking
        )
        .frame(height: 400)
        .cornerRadius(20)
    }
}
```

---

## 🎨 Asset Pipeline

### Creating 3D Avatar Assets

#### Option 1: Using VRoid Studio (Recommended for Beginners)

1. **Download VRoid Studio**: https://vroid.com/en/studio
2. Create your avatar
3. Export as VRM file
4. Import VRM into Unity using VRM Unity Package

#### Option 2: Using Blender (Advanced)

1. Model character in Blender
2. Ensure humanoid rig structure
3. Add blend shapes for facial expressions:
   - Blink_L, Blink_R
   - Smile
   - Mouth_Open, Mouth_Wide, Mouth_Pucker
   - Eyebrow_Up_L, Eyebrow_Up_R, Eyebrow_Down
   - Eye_Wide

4. Export as FBX with settings:
   - Include: Armature, Mesh
   - Apply Modifiers: Yes
   - Bake Animation: No

5. Import FBX into Unity

#### Option 3: Ready Player Me Integration

```csharp
// Coming soon: Ready Player Me SDK integration
// Allows users to create photorealistic avatars
```

### Creating Addressable Assets

1. Import your 3D models into Unity
2. For each model:
   - Right-click → Addressables → Mark as Addressable
   - Set Address to: `Avatars/[Category]/[Name]`
   - Example: `Avatars/Hair/Style_1`

3. Assign to appropriate group

4. Build addressables:
   - Window → Asset Management → Addressables → Build
   - Select "Default Build Script"

### Material Setup

Create materials for customization:

```
Materials/
├── Skin/
│   ├── SkinTone_Light.mat
│   ├── SkinTone_Medium.mat
│   ├── SkinTone_Tan.mat
│   └── SkinTone_Dark.mat
├── Hair/
│   ├── HairColor_Black.mat
│   ├── HairColor_Brown.mat
│   ├── HairColor_Blonde.mat
│   └── HairColor_Red.mat
└── Outfit/
    └── (various outfit materials)
```

---

## 🧪 Testing

### Test in Unity Editor

1. Enter Play Mode
2. In Console, type:

```javascript
// Test commands (via Unity Debug Console)
AvatarManager.SetMood("happy");
AvatarManager.SetSpeaking("true");
AvatarManager.PlayAnimation("LevelUp");
```

### Test in iOS Simulator

```bash
# Build and run
cd "LyoApp July"
xcodebuild -scheme LyoApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

### Test on Device

1. Connect iPhone via USB
2. Select device in Xcode
3. Click Run (⌘R)

### Performance Testing

Monitor these metrics:
- **Frame Rate**: Should maintain 60fps
- **Memory**: Unity heap < 200MB
- **Battery**: < 5% per minute of usage
- **Load Time**: < 2 seconds for avatar spawn

Use Xcode Instruments:
1. Product → Profile
2. Select "Time Profiler" or "Allocations"
3. Run tests

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Unity view is black/empty

**Solution:**
1. Check UnityFramework is properly embedded
2. Verify UnityBridge initialization
3. Check Unity scene has proper lighting

```swift
// Add debug logging
UnityBridge.shared.initializeUnity()
print("Unity initialized: \(UnityBridge.shared.getUnityView())")
```

#### Issue: Avatar doesn't load

**Solution:**
1. Verify Addressables are built
2. Check asset addresses match code
3. Look for errors in Unity console

```csharp
// Add debug logging in AvatarManager.cs
Debug.Log($"Loading asset: {addressableKey}");
```

#### Issue: Lip sync not working

**Solution:**
1. Verify blendshape indices are correct
2. Check audio source is assigned
3. Test with procedural mode first

```csharp
// In Unity inspector, test manually
faceMesh.SetBlendShapeWeight(3, 50f); // Should open mouth
```

#### Issue: Build fails with "UnityFramework not found"

**Solution:**
1. Clean build folder: Product → Clean Build Folder
2. Re-export Unity project
3. Verify framework is in Xcode project

#### Issue: App crashes on launch

**Solution:**
1. Check deployment target matches (iOS 16.0+)
2. Verify IL2CPP is enabled
3. Check for missing Unity plugins

```bash
# View crash logs
cd ~/Library/Logs/DiagnosticReports
ls -lt | head
```

### Performance Optimization

If experiencing lag:

1. **Reduce Draw Calls**:
   - Combine meshes
   - Use texture atlases
   - Reduce material count

2. **Optimize Animations**:
   - Lower keyframe count
   - Reduce blend tree complexity
   - Use animation compression

3. **Reduce Particle Count**:
   ```csharp
   // In AvatarManager.cs
   var emission = moodGlow.emission;
   emission.rateOverTime = 20f; // Reduce from 50f
   ```

4. **Lower Render Quality**:
   - Edit → Project Settings → Quality
   - Select "Medium" or "Low" preset for iOS

---

## 📚 Additional Resources

### Unity Documentation
- [Unity as a Library](https://docs.unity3d.com/Manual/UnityasaLibrary.html)
- [Addressables Guide](https://docs.unity3d.com/Manual/com.unity.addressables.html)
- [URP Best Practices](https://docs.unity3d.com/Manual/urp-docfx-landing-page.html)

### Avatar Creation Tools
- [VRoid Studio](https://vroid.com/en/studio)
- [Ready Player Me](https://readyplayer.me/)
- [Mixamo](https://www.mixamo.com/) (animations)

### Unity Packages
- [VRM Unity Package](https://github.com/vrm-c/UniVRM)
- [OVR LipSync](https://developer.oculus.com/downloads/package/oculus-lipsync-unity/)
- [Final IK](https://assetstore.unity.com/packages/tools/animation/final-ik-14290)

### iOS Integration
- [Unity-iPhone Integration](https://docs.unity3d.com/Manual/UnityasaLibrary-iOS.html)
- [SwiftUI + Unity](https://github.com/Unity-Technologies/uaal-example)

---

## 🎯 Next Steps

1. ✅ Complete Unity project setup
2. ✅ Export and integrate with iOS
3. 🔄 Create initial avatar models
4. 🔄 Build addressables
5. ⏭️ Test on device
6. ⏭️ Optimize performance
7. ⏭️ Add OVR LipSync
8. ⏭️ Implement cloud asset delivery

---

## 💬 Support

For questions or issues:
- Check [AI_AVATAR_CREATOR_TECHNICAL_SPEC.md](../AI_AVATAR_CREATOR_TECHNICAL_SPEC.md)
- Unity Forums: https://forum.unity.com
- iOS Integration: Apple Developer Forums

**Happy Avatar Building! 🎨🤖**
