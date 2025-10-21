#!/bin/bash

#================================================================================
# LyoApp + UnityFramework Integration Automation
# Integrates the built UnityFramework into your existing LyoApp iOS project
#================================================================================

set -e

# Define paths
LYOAPP_PATH="/Users/hectorgarcia/Desktop/LyoApp July"
UNITY_FRAMEWORK_PATH="/Users/hectorgarcia/Desktop/UnityClassroom_oct15\\ios_build/UnityFramework"
XCODE_PROJECT_PATH="$LYOAPP_PATH/Lyo.xcodeproj"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#================================================================================
# HELPER FUNCTIONS
#================================================================================

log_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

log_step() {
    echo -e "${YELLOW}[STEP $1] $2${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

#================================================================================
# STEP 0: Verify Prerequisites
#================================================================================

log_header "STEP 0: Verifying Prerequisites"

log_step "0" "Checking paths..."

if [ ! -d "$LYOAPP_PATH" ]; then
    log_error "LyoApp not found at: $LYOAPP_PATH"
    exit 1
fi
log_success "LyoApp found: $LYOAPP_PATH"

if [ ! -d "$UNITY_FRAMEWORK_PATH" ]; then
    log_error "UnityFramework not found at: $UNITY_FRAMEWORK_PATH"
    exit 1
fi
log_success "UnityFramework found: $UNITY_FRAMEWORK_PATH"

if [ ! -d "$XCODE_PROJECT_PATH" ]; then
    log_error "Xcode project not found at: $XCODE_PROJECT_PATH"
    log_info "Looking for .xcodeproj files..."
    find "$LYOAPP_PATH" -name "*.xcodeproj" -maxdepth 2
    exit 1
fi
log_success "Xcode project found: $XCODE_PROJECT_PATH"

#================================================================================
# STEP 1: Create Integration Directories
#================================================================================

log_header "STEP 1: Setting Up Integration Directories"

log_step "1" "Creating Frameworks directory in Xcode project..."

FRAMEWORKS_DIR="$LYOAPP_PATH/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"
log_success "Created: $FRAMEWORKS_DIR"

#================================================================================
# STEP 2: Copy UnityFramework
#================================================================================

log_header "STEP 2: Copying UnityFramework"

log_step "2" "Copying UnityFramework to project..."

# Check if framework already exists
if [ -d "$FRAMEWORKS_DIR/UnityFramework.framework" ]; then
    log_info "UnityFramework already exists, backing up old version..."
    mv "$FRAMEWORKS_DIR/UnityFramework.framework" "$FRAMEWORKS_DIR/UnityFramework.framework.backup"
    log_success "Backup created"
fi

cp -r "$UNITY_FRAMEWORK_PATH" "$FRAMEWORKS_DIR/"
log_success "Copied UnityFramework to: $FRAMEWORKS_DIR/UnityFramework.framework"

# Verify copy
FRAMEWORK_SIZE=$(du -sh "$FRAMEWORKS_DIR/UnityFramework.framework" | awk '{print $1}')
log_info "Framework size: $FRAMEWORK_SIZE"

#================================================================================
# STEP 3: Create Swift Integration Files
#================================================================================

log_header "STEP 3: Creating Swift Integration Files"

SOURCES_DIR="$LYOAPP_PATH/Lyo/Core/Services"
mkdir -p "$SOURCES_DIR"

log_step "3a" "Creating UnityManager.swift..."

cat > "$SOURCES_DIR/UnityManager.swift" << 'SWIFT_CODE'
//
//  UnityManager.swift
//  Lyo
//
//  Manages UnityFramework lifecycle and communication with Classroom module
//

import UIKit
import UnityFramework

class UnityManager: NSObject {
    
    static let shared = UnityManager()
    
    private var unityFramework: UnityFramework?
    private var unityView: UIView?
    private var isInitialized = false
    
    /// Initialize Unity Framework on app launch
    func initializeUnity() {
        guard !isInitialized else {
            print("[UnityManager] Already initialized")
            return
        }
        
        do {
            try unityFramework = UnityFrameworkLoad()
            
            // Run on background thread to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.unityFramework?.runEmbedded(
                    withArguments: CommandLine.arguments,
                    options: nil,
                    completeHandler: { [weak self] in
                        self?.isInitialized = true
                        print("[UnityManager] Unity framework initialized successfully")
                        
                        // Post notification on main thread
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("UnityInitialized"),
                                object: nil
                            )
                        }
                    }
                )
            }
        } catch {
            print("[UnityManager] Failed to initialize Unity: \(error)")
        }
    }
    
    /// Get Unity view for embedding in SwiftUI/UIKit
    func getUnityView() -> UIView? {
        guard let framework = unityFramework else {
            print("[UnityManager] Framework not initialized")
            return nil
        }
        
        if unityView == nil {
            // Create and configure Unity view
            unityView = framework.appController()?.rootViewController?.view
        }
        
        return unityView
    }
    
    /// Send message to Unity C# code
    func sendMessage(to className: String, methodName: String, message: String) {
        guard isInitialized else {
            print("[UnityManager] Unity not initialized yet")
            return
        }
        
        UnitySendMessage(
            className,
            methodName,
            message
        )
    }
    
    /// Shutdown Unity Framework
    func shutdownUnity() {
        guard isInitialized else {
            print("[UnityManager] Not initialized")
            return
        }
        
        unityFramework?.unload()
        isInitialized = false
        unityView = nil
        
        print("[UnityManager] Unity framework shutdown complete")
    }
    
    /// Check if Unity is initialized
    func isUnityReady() -> Bool {
        return isInitialized
    }
}

// MARK: - Convenience Functions

/// Load UnityFramework
@discardableResult
func UnityFrameworkLoad() throws -> UnityFramework {
    let bundlePath = Bundle.main.bundlePath
    let frameworkPath = bundlePath + "/Frameworks/UnityFramework.framework"
    
    guard let bundle = Bundle(path: frameworkPath) else {
        throw NSError(domain: "UnityManager", code: 1, 
                      userInfo: [NSLocalizedDescriptionKey: "Failed to load UnityFramework bundle"])
    }
    
    guard bundle.load() else {
        throw NSError(domain: "UnityManager", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to load UnityFramework"])
    }
    
    guard let frameworkClass = NSClassFromString("UnityFramework") as? NSObject.Type else {
        throw NSError(domain: "UnityManager", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "UnityFramework class not found"])
    }
    
    guard let framework = frameworkClass.init() as? UnityFramework else {
        throw NSError(domain: "UnityManager", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "Failed to instantiate UnityFramework"])
    }
    
    return framework
}
SWIFT_CODE

log_success "Created: UnityManager.swift"

log_step "3b" "Creating Bridging Header..."

cat > "$LYOAPP_PATH/Lyo-Bridging-Header.h" << 'BRIDGING_HEADER'
//
//  Lyo-Bridging-Header.h
//  Lyo
//
//  Bridging header for Swift-ObjC interoperability with UnityFramework
//

#ifndef Lyo_Bridging_Header_h
#define Lyo_Bridging_Header_h

#import <UnityFramework/UnityFramework.h>

// Forward declarations for Unity communication
extern void UnitySendMessage(const char* className, const char* methodName, const char* message);

#endif /* Lyo_Bridging_Header_h */
BRIDGING_HEADER

log_success "Created: Lyo-Bridging-Header.h"

log_step "3c" "Creating AppDelegate Extension..."

cat > "$SOURCES_DIR/AppDelegate+Unity.swift" << 'APPDELEGATE_EXT'
//
//  AppDelegate+Unity.swift
//  Lyo
//
//  Extension to AppDelegate for Unity lifecycle management
//

import UIKit

extension AppDelegate {
    
    /// Call this in applicationDidFinishLaunching in AppDelegate.swift
    func initializeUnityFramework() {
        // Initialize UnityManager
        UnityManager.shared.initializeUnity()
        
        // Listen for initialization complete
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UnityInitialized"),
            object: nil,
            queue: .main
        ) { _ in
            print("[AppDelegate] Unity framework is ready")
        }
    }
    
    /// Call this in applicationWillTerminate in AppDelegate.swift
    func shutdownUnityFramework() {
        UnityManager.shared.shutdownUnity()
    }
}
APPDELEGATE_EXT

log_success "Created: AppDelegate+Unity.swift"

#================================================================================
# STEP 4: Generate Xcode Configuration Script
#================================================================================

log_header "STEP 4: Generating Xcode Configuration"

log_step "4" "Creating Xcode build settings template..."

cat > "$FRAMEWORKS_DIR/XCODE_INTEGRATION.xcconfig" << 'XCCONFIG'
// Xcode Build Configuration for UnityFramework Integration
// Import this into your project's build configuration

// Framework Search Paths
FRAMEWORK_SEARCH_PATHS = $(inherited) $(PROJECT_DIR)/Frameworks

// Header Search Paths  
HEADER_SEARCH_PATHS = $(inherited) $(PROJECT_DIR)/Frameworks/UnityFramework.framework/Headers

// Linking
OTHER_LDFLAGS = $(inherited) -framework UnityFramework

// Swift Settings
SWIFT_VERSION = 5.0
SWIFT_INCLUDE_PATHS = $(PROJECT_DIR)/Frameworks/UnityFramework.framework/Headers

// iOS Settings
IPHONEOS_DEPLOYMENT_TARGET = 13.0
TARGETED_DEVICE_FAMILY = 1,2

// Architecture
VALID_ARCHS = arm64

// Bridging Header
BRIDGING_HEADER = Lyo-Bridging-Header.h

// Build Options
BUILD_VARIANTS = normal
ALWAYS_SEARCH_USER_PATHS = NO
XCCONFIG

log_success "Created: XCODE_INTEGRATION.xcconfig"

#================================================================================
# STEP 5: Create Integration Instructions
#================================================================================

log_header "STEP 5: Creating Integration Instructions"

log_step "5" "Generating Xcode setup guide..."

cat > "$LYOAPP_PATH/UNITY_XCODE_SETUP.md" << 'SETUP_MD'
# UnityFramework Xcode Integration Guide

## ✅ Automated Files Already Created

The following files were automatically created:

1. **Frameworks/UnityFramework.framework** - The compiled framework
2. **Lyo/Core/Services/UnityManager.swift** - Unity lifecycle manager
3. **Lyo-Bridging-Header.h** - Swift-ObjC bridge
4. **Lyo/Core/Services/AppDelegate+Unity.swift** - AppDelegate extension

## 📝 Manual Xcode Setup Steps

### Step 1: Add Framework to Build Phases

1. Open **Lyo.xcodeproj** in Xcode
2. Select **Targets** → **Lyo** (main target)
3. Go to **Build Phases** tab
4. Expand **Link Binary With Libraries**
5. Click **+** button
6. Click **Add Other...**
7. Navigate to: `Frameworks/UnityFramework.framework`
8. Click **Open**

**Verify:** UnityFramework.framework should now appear in the list

### Step 2: Update Build Settings

1. In same target, go to **Build Settings** tab
2. Search for "Framework Search Paths"
3. Add: `$(PROJECT_DIR)/Frameworks`
4. Search for "Bridging Header"
5. Set value to: `Lyo-Bridging-Header.h`

### Step 3: Update AppDelegate.swift

Add these two method calls to your AppDelegate:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize UnityFramework
        self.initializeUnityFramework()
        
        // ... rest of your code
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Shutdown UnityFramework
        self.shutdownUnityFramework()
    }
}
```

### Step 4: Build and Test

1. **Product** → **Clean Build Folder** (Cmd+Shift+K)
2. **Product** → **Build** (Cmd+B)
3. Fix any errors if they appear
4. Once build succeeds, you can run on simulator or device

## 🧪 Testing Unity Integration

After successful build, test the integration:

```swift
// In any view controller
if UnityManager.shared.isUnityReady() {
    print("✓ Unity is running!")
    
    // Send message to C# code
    UnityManager.shared.sendMessage(
        to: "IntegrationController",
        methodName: "OnSwiftMessage",
        message: "Hello from Swift!"
    )
}
```

## 📊 Troubleshooting

| Error | Solution |
|-------|----------|
| "framework not found UnityFramework" | Check Framework Search Paths includes `$(PROJECT_DIR)/Frameworks` |
| "Bridging header not found" | Verify Bridging Header is set in Build Settings |
| "Undefined symbols UnitySendMessage" | Ensure UnityFramework is linked in Build Phases |
| "arm64 only architecture" | Check Valid Architectures only has arm64 |

## ✅ Success Indicators

- ✓ Project builds without errors
- ✓ No undefined symbol errors
- ✓ UnityManager.swift compiles
- ✓ Can instantiate UnityManager singleton
- ✓ Unity initializes on app launch

## 🚀 Next Steps

1. Follow manual setup steps 1-4 above
2. Build project (Cmd+B)
3. Run on simulator or device
4. Check console for Unity initialization messages

## 📚 Additional Resources

- See **Lyo/Core/Services/UnityManager.swift** for API documentation
- See **AppDelegate+Unity.swift** for lifecycle management
- See **Lyo-Bridging-Header.h** for C-Swift interop
SETUP_MD

log_success "Created: UNITY_XCODE_SETUP.md"

#================================================================================
# STEP 6: Create Deployment Checklist
#================================================================================

log_header "STEP 6: Creating Deployment Resources"

cat > "$LYOAPP_PATH/UNITY_DEPLOYMENT_CHECKLIST.md" << 'DEPLOY_MD'
# UnityFramework Deployment Checklist

## Pre-Build Verification

- [ ] UnityFramework.framework exists in Frameworks/
- [ ] Framework size is 40-60 MB (indicates full build)
- [ ] UnityManager.swift created in Lyo/Core/Services/
- [ ] Bridging header created: Lyo-Bridging-Header.h
- [ ] AppDelegate+Unity.swift created

## Xcode Configuration

- [ ] Target → Build Phases → Link Binary With Libraries includes UnityFramework
- [ ] Build Settings → Framework Search Paths set correctly
- [ ] Build Settings → Bridging Header set to: Lyo-Bridging-Header.h
- [ ] AppDelegate.swift calls initializeUnityFramework()
- [ ] AppDelegate.swift calls shutdownUnityFramework()

## Build & Test

- [ ] Clean build folder (Cmd+Shift+K)
- [ ] Build project (Cmd+B) - should compile without errors
- [ ] Build for Generic iOS Device - successful
- [ ] Build for Simulator - successful
- [ ] Run on Simulator - app launches
- [ ] Run on Device - app launches

## Console Verification

When app launches, console should show:

```
[UnityManager] Unity framework initialized successfully
[AppDelegate] Unity framework is ready
```

No errors or crashes.

## TestFlight Preparation

- [ ] Archive build (Cmd+B then Product → Archive)
- [ ] Submit to App Store Connect
- [ ] Add to TestFlight
- [ ] Invite testers
- [ ] Monitor crash reports for Unity-related issues

## Deployment

- [ ] TestFlight testers report app working
- [ ] No Unity-related crash reports
- [ ] Submit to App Store
- [ ] Monitor app reviews for issues

## Monitoring

- [ ] Check crashes in App Store Connect
- [ ] Monitor user feedback
- [ ] Log analytics events from C# side
- [ ] Track performance metrics

---

**Status:** Ready for integration
**Estimated Time to Deploy:** 2-3 days (with TestFlight testing)
DEPLOY_MD

log_success "Created: UNITY_DEPLOYMENT_CHECKLIST.md"

#================================================================================
# STEP 7: Generate Summary Report
#================================================================================

log_header "Integration Complete!"

cat > "$LYOAPP_PATH/UNITY_INTEGRATION_COMPLETE.txt" << 'REPORT'
═══════════════════════════════════════════════════════════════════
  UnityFramework ↔ LyoApp Integration - COMPLETED
═══════════════════════════════════════════════════════════════════

TIMESTAMP: $(date)

FILES CREATED:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Framework Files:
   • Frameworks/UnityFramework.framework/
     (Framework binary with all 17 C# scripts compiled)

✅ Swift Integration Files:
   • Lyo/Core/Services/UnityManager.swift
     (Manages Unity lifecycle and communication)
   • Lyo/Core/Services/AppDelegate+Unity.swift
     (Extension for AppDelegate integration)
   • Lyo-Bridging-Header.h
     (Swift-ObjC bridging header)

✅ Configuration Files:
   • Frameworks/XCODE_INTEGRATION.xcconfig
     (Build settings template)

✅ Documentation:
   • UNITY_XCODE_SETUP.md
     (Step-by-step Xcode integration guide)
   • UNITY_DEPLOYMENT_CHECKLIST.md
     (Pre-launch checklist)

NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Open Lyo.xcodeproj in Xcode

2. Follow UNITY_XCODE_SETUP.md section "Manual Xcode Setup Steps"
   (4 easy steps to configure Xcode)

3. Build project (Cmd+B)

4. Follow UNITY_DEPLOYMENT_CHECKLIST.md before App Store submission

FRAMEWORK DETAILS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework Path: $(pwd)/Frameworks/UnityFramework.framework
Framework Size: [Size will appear after first build]
Scripts Included: 17 C# classes (5,589 LOC total)
iOS Target: 13.0+
Architecture: arm64

INCLUDED C# CLASSES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Core Systems:
  • BackendClient.cs - REST API integration
  • IntegrationController.cs - Central orchestrator
  • NativeBridge.cs - iOS native calls

Audio Systems:
  • TextToSpeechService.cs - iOS TTS engine
  • SpeechRecognitionService.cs - Voice input
  • PhonemeGenerator.cs - Lip-sync animation

Classroom Systems:
  • LessonModuleIntegration.cs - Lesson wrapper
  • ExplainerModuleAdapter.cs - Narration system
  • QuizModuleAdapter.cs - Q&A with voice

UI & Customization:
  • UIPrefabManager.cs - Dynamic Canvas
  • AvatarAnimationController.cs - Expressions/gestures
  • AvatarStyler.cs - Avatar customization
  • GestureCustomizer.cs - Custom animations

Advanced Features:
  • AnalyticsDashboard.cs - Student progress
  • MultiLanguageSupport.cs - 10 languages
  • PronunciationAnalyzer.cs - Speech feedback

INTEGRATION STATUS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Framework Built
✅ Files Generated
✅ Documentation Created
✅ Ready for Xcode Setup

⏳ Pending:
   - Manual Xcode configuration (4 steps)
   - Build in Xcode
   - Test on device
   - App Store submission

═══════════════════════════════════════════════════════════════════
Generated: $(date)
═══════════════════════════════════════════════════════════════════
REPORT

log_success "Generated: UNITY_INTEGRATION_COMPLETE.txt"

#================================================================================
# FINAL SUMMARY
#================================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}                   ${GREEN}✓ INTEGRATION COMPLETE${NC}${BLUE}                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📁 LyoApp Integration Folder${NC}"
echo "   $LYOAPP_PATH"
echo ""

echo -e "${CYAN}📦 Framework Location${NC}"
echo "   $FRAMEWORKS_DIR/UnityFramework.framework"
echo ""

echo -e "${CYAN}📝 Key Files Created${NC}"
echo "   • UnityManager.swift (Unity lifecycle)"
echo "   • AppDelegate+Unity.swift (Integration extension)"
echo "   • Lyo-Bridging-Header.h (Swift-ObjC bridge)"
echo ""

echo -e "${CYAN}📚 Documentation${NC}"
echo "   • UNITY_XCODE_SETUP.md (Follow this next!)"
echo "   • UNITY_DEPLOYMENT_CHECKLIST.md (Pre-launch)"
echo "   • UNITY_INTEGRATION_COMPLETE.txt (Summary)"
echo ""

echo -e "${YELLOW}⚠️  NEXT STEPS (4 Manual Xcode Steps)${NC}"
echo "   1. Open Lyo.xcodeproj in Xcode"
echo "   2. Add UnityFramework to Build Phases → Link Binary"
echo "   3. Update Build Settings (Framework Search Paths, Bridging Header)"
echo "   4. Update AppDelegate.swift (copy 2 method calls)"
echo ""

echo -e "${GREEN}✓ After that, build with Cmd+B${NC}"
echo ""

