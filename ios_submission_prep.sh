#!/bin/bash

# iOS App Store Submission Preparation Script
# This script prepares Lyo app for iOS App Store submission

echo "🚀 Starting iOS Submission Preparation for Lyo App..."
echo "=================================================="

# Set project directory
PROJECT_DIR="/Users/republicalatuya/Desktop/LyoApp July"
ASSETS_DIR="$PROJECT_DIR/LyoApp/Assets.xcassets/AppIcon.appiconset"

echo "📱 Project Directory: $PROJECT_DIR"
echo "🎨 Assets Directory: $ASSETS_DIR"

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: Project directory not found!"
    exit 1
fi

cd "$PROJECT_DIR"

echo ""
echo "1️⃣ Checking Xcode Project Structure..."
echo "======================================"

# Check if Xcode project exists
if [ -f "LyoApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project found"
else
    echo "❌ Xcode project not found!"
    exit 1
fi

# Check if app icons directory exists
if [ -d "$ASSETS_DIR" ]; then
    echo "✅ App icons directory found"
else
    echo "❌ App icons directory not found!"
    exit 1
fi

echo ""
echo "2️⃣ Generating App Icons with Quantum Lyo Branding..."
echo "===================================================="

# Note: In a real implementation, you would use tools like ImageMagick or a design tool
# For now, we'll create placeholder information and instructions

echo "📋 Required App Icon Sizes:"
echo "  • 1024×1024 (App Store)"
echo "  • 180×180 (iPhone 3x)"
echo "  • 120×120 (iPhone 2x)"
echo "  • 87×87 (iPhone Settings 3x)"
echo "  • 80×80 (iPhone Spotlight 2x)"
echo "  • 76×76 (iPad 1x)"
echo "  • 167×167 (iPad Pro 2x)"
echo "  • 152×152 (iPad 2x)"
echo "  • 60×60 (iPhone 1x)"
echo "  • 58×58 (iPhone Settings 2x)"
echo "  • 40×40 (iPhone Spotlight 1x)"
echo "  • 29×29 (iPhone Settings 1x)"

# List current icon files
echo ""
echo "📂 Current icon files in Assets:"
ls -la "$ASSETS_DIR"

echo ""
echo "3️⃣ Validating App Configuration..."
echo "=================================="

# Check Info.plist
if [ -f "LyoApp/Info.plist" ]; then
    echo "✅ Info.plist found"
    
    # Extract app name and version (basic check)
    if grep -q "CFBundleName" "LyoApp/Info.plist"; then
        echo "✅ App name configured"
    else
        echo "⚠️  App name needs verification"
    fi
    
    if grep -q "CFBundleVersion" "LyoApp/Info.plist"; then
        echo "✅ Version configured"
    else
        echo "⚠️  Version needs verification"
    fi
else
    echo "❌ Info.plist not found!"
fi

echo ""
echo "4️⃣ Building App for Testing..."
echo "==============================="

# Attempt to build the project
echo "🔨 Building Xcode project..."
if xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build > build.log 2>&1; then
    echo "✅ Build successful!"
    echo "📊 Build output saved to build.log"
else
    echo "❌ Build failed!"
    echo "📋 Last 20 lines of build log:"
    tail -20 build.log
    echo ""
    echo "💡 Please fix build errors before submission"
fi

echo ""
echo "5️⃣ iOS Submission Checklist..."
echo "==============================="

# Create submission checklist
cat << 'EOF'
📝 iOS App Store Submission Checklist:

🔴 CRITICAL (Must Complete):
[ ] App Icons - All sizes generated with quantum Lyo branding
[ ] Launch Screen - Professional launch screen implemented
[ ] Screenshots - App Store screenshots for all device sizes
[ ] App Description - Compelling description with keywords
[ ] Privacy Policy - Accessible URL with privacy information
[ ] Testing - Full testing on physical iOS devices
[ ] Build Archive - Successfully archived for distribution

🟡 IMPORTANT (Recommended):
[ ] Categories - Education (Primary), Productivity (Secondary)
[ ] Age Rating - 4+ rating confirmed
[ ] Performance - Launch time and memory usage optimized
[ ] Accessibility - VoiceOver and accessibility features tested

🟢 OPTIONAL (Nice to Have):
[ ] Localization - Multiple language support
[ ] Analytics - App analytics and crash reporting
[ ] Marketing - App preview video
[ ] Keywords - SEO-optimized App Store keywords

EOF

echo ""
echo "6️⃣ Next Steps for App Store Submission..."
echo "=========================================="

cat << 'EOF'
🎯 IMMEDIATE ACTIONS:

1. 📱 Generate App Icons:
   • Use the AppIconConfiguration in iOS_Submission_Preparation.swift
   • Export at all required sizes (see list above)
   • Replace placeholder icons in Assets.xcassets

2. 📸 Create Screenshots:
   • Capture app running on different device sizes
   • Show key features: Learning Hub, AI Assistant, Search
   • Add compelling captions highlighting benefits

3. 📄 Prepare App Store Metadata:
   • App name: "Lyo"
   • Subtitle: "AI-Powered Learning Hub"
   • Description: Use content from AppStoreMetadata
   • Keywords: learning, education, AI, courses, smart

4. 🔒 Privacy Policy:
   • Create privacy policy document
   • Host at accessible URL
   • Update App Store Connect with URL

5. 🧪 Final Testing:
   • Test on physical iPhone and iPad devices
   • Verify all features work in Release build
   • Test accessibility features
   • Check performance metrics

6. 📤 App Store Connect:
   • Create app listing in App Store Connect
   • Upload icons, screenshots, and metadata
   • Submit for App Store Review

EOF

echo ""
echo "✨ Lyo App iOS Submission Preparation Complete!"
echo "=============================================="
echo ""
echo "📧 For assistance with any step, refer to:"
echo "   • iOS_Submission_Preparation.swift - Technical implementation"
echo "   • AppIconConfiguration - Icon generation guide"
echo "   • AppStoreMetadata - Marketing copy and metadata"
echo ""
echo "🎉 Good luck with your App Store submission!"

# Optional: Open key files in default editor
if command -v code &> /dev/null; then
    echo ""
    echo "📝 Opening key files in VS Code..."
    code "iOS_Submission_Preparation.swift"
    code "LyoApp/LaunchScreenView.swift"
    code "LyoApp/Assets.xcassets/AppIcon.appiconset/Contents.json"
fi
