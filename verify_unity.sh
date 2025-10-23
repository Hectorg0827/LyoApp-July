#!/bin/bash

# Unity Integration Verification Script
# Tests if Unity is properly integrated into LyoApp

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           Unity Integration Verification Tool                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="/Users/hectorgarcia/Desktop/LyoApp July"
FRAMEWORK_PATH="$PROJECT_DIR/Frameworks/UnityFramework.framework"
DATA_PATH="$PROJECT_DIR/LyoApp/UnityData"
XCODE_PROJECT="$PROJECT_DIR/LyoApp.xcodeproj"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

check_item() {
    local name="$1"
    local test_cmd="$2"
    
    printf "%-50s " "$name"
    
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((pass_count++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((fail_count++))
        return 1
    fi
}

echo "🔍 Checking Unity Integration..."
echo ""

# Check 1: UnityFramework.framework exists
check_item "UnityFramework.framework exists" "[ -d '$FRAMEWORK_PATH' ]"

# Check 2: UnityData folder exists
check_item "Unity Data folder exists" "[ -d '$DATA_PATH' ]"

# Check 3: Framework is in Xcode project
check_item "Framework referenced in Xcode project" "grep -q 'UnityFramework.framework' '$XCODE_PROJECT/project.pbxproj'"

# Check 4: Data folder in Xcode project
check_item "Data folder in Xcode project" "grep -q 'UnityData' '$XCODE_PROJECT/project.pbxproj'"

# Check 5: UnityBridge exists
check_item "UnityBridge.swift exists" "[ -f '$PROJECT_DIR/LyoApp/Unity/UnityBridge.swift' ]"

# Check 6: UnityContainerView exists
check_item "UnityContainerView.swift exists" "[ -f '$PROJECT_DIR/LyoApp/Views/UnityContainerView.swift' ]"

# Check 7: Build succeeds
echo ""
echo "⏳ Testing build (this may take a moment)..."
check_item "Xcode project builds successfully" "cd '$PROJECT_DIR' && xcodebuild -project LyoApp.xcodeproj -scheme LyoApp -destination 'platform=iOS Simulator,name=iPhone 17' build -quiet"

echo ""
echo "════════════════════════════════════════════════════════════════"

if [ -d "$FRAMEWORK_PATH" ] && [ -d "$DATA_PATH" ]; then
    echo -e "${GREEN}✅ UNITY IS INTEGRATED${NC}"
    echo ""
    echo "Unity Status: ACTIVE"
    echo "Framework: $FRAMEWORK_PATH"
    echo "Data: $DATA_PATH"
    echo ""
    
    # Show framework info
    if [ -f "$FRAMEWORK_PATH/Info.plist" ]; then
        echo "Framework Details:"
        /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$FRAMEWORK_PATH/Info.plist" 2>/dev/null | sed 's/^/  Bundle ID: /'
        /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$FRAMEWORK_PATH/Info.plist" 2>/dev/null | sed 's/^/  Version: /'
    fi
    
    # Show data size
    data_size=$(du -sh "$DATA_PATH" 2>/dev/null | cut -f1)
    echo "  Data Size: $data_size"
    
elif [ ! -d "$FRAMEWORK_PATH" ] && [ ! -d "$DATA_PATH" ]; then
    echo -e "${YELLOW}⚠️  UNITY NOT YET INTEGRATED${NC}"
    echo ""
    echo "Unity Status: PENDING EXPORT"
    echo ""
    echo "Next steps:"
    echo "  1. Export Unity project from Unity Editor"
    echo "  2. Run: ./integrate_unity.sh"
    echo ""
    echo "See UNITY_INTEGRATION_GUIDE.md for detailed instructions"
else
    echo -e "${RED}⚠️  PARTIAL INTEGRATION${NC}"
    echo ""
    if [ -d "$FRAMEWORK_PATH" ]; then
        echo "✅ Framework found"
    else
        echo "❌ Framework missing"
    fi
    
    if [ -d "$DATA_PATH" ]; then
        echo "✅ Data found"
    else
        echo "❌ Data missing"
    fi
    echo ""
    echo "Run: ./integrate_unity.sh to fix"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Results: ${GREEN}$pass_count passed${NC}, ${RED}$fail_count failed${NC}"
echo "════════════════════════════════════════════════════════════════"

# Exit with appropriate code
if [ $fail_count -eq 0 ]; then
    exit 0
else
    exit 1
fi
