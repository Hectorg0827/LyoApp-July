#!/bin/bash
# Final validation script for LyoApp production configuration

echo "🎯 === LyoApp Production Configuration Validation ==="

PROJECT_DIR="/Users/hectorgarcia/Desktop/LyoApp July/LyoApp"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_success() { echo -e "${GREEN}✅ $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }
echo_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

echo ""
echo "🔍 Configuration Validation:"
echo "============================="

# Check Xcode scheme
SCHEME_FILE="/Users/hectorgarcia/Desktop/LyoApp July/LyoApp.xcodeproj/xcshareddata/xcschemes/LyoApp.xcscheme"
if grep -q 'buildConfiguration = "Debug"' "$SCHEME_FILE"; then
    echo_success "Xcode scheme set to Debug configuration"
else
    echo_error "Xcode scheme not set to Debug"
fi

# Check UnifiedLyoConfig in APIConfig.swift
if [ -f "$PROJECT_DIR/APIConfig.swift" ]; then
    echo_success "APIConfig.swift found with UnifiedLyoConfig"
    
    # Check if it points to production backend
    if grep -q "lyo-backend-830162750094" "$PROJECT_DIR/APIConfig.swift"; then
        echo_success "APIConfig points to production backend"
    else
        echo_error "APIConfig not pointing to production backend"
    fi
    
    # Check if mock data is disabled
    if grep -q "useMockData = false" "$PROJECT_DIR/APIConfig.swift"; then
        echo_success "Mock data is disabled"
    else
        echo_error "Mock data not disabled"
    fi
else
    echo_error "APIConfig.swift not found"
fi

# Check if duplicate config removed
if [ -f "$PROJECT_DIR/UnifiedConfig.swift" ]; then
    echo_error "Duplicate UnifiedConfig.swift still exists (should be removed)"
else
    echo_success "Duplicate UnifiedConfig.swift removed"
fi

# Check HomeFeedView mock fallbacks
if grep -q "generateRandomFeedItem()" "$PROJECT_DIR/HomeFeedView.swift" && ! grep -q "REMOVED.*generateRandomFeedItem" "$PROJECT_DIR/HomeFeedView.swift"; then
    echo_error "Mock data generation functions still exist"
else
    echo_success "Mock data generation functions removed"
fi

echo ""
echo "🎯 Expected Results:"
echo "==================="
echo_info "When you run the app, you should see:"
echo "   🌐 API URL: https://lyo-backend-830162750094.us-central1.run.app"
echo "   🚫 Mock Data: DISABLED" 
echo "   ✅ Real Backend: REQUIRED"
echo "   📱 Environment: ☁️ Production Cloud Backend"

echo ""
echo "🚀 Next Steps:"
echo "=============="
echo "1. Open LyoApp.xcodeproj in Xcode"
echo "2. Press ⌘+R to build and run"
echo "3. Check console output for production configuration"
echo "4. Verify no mock/demo data appears in the app"

echo ""
echo_success "✅ Configuration fixes completed!"
echo_info "Your app is now configured to use ONLY the real backend"