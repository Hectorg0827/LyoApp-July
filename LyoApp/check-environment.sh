#!/bin/bash

# Environment Configuration Checker
echo "🔍 LyoApp Environment Configuration Check"
echo "========================================"

PROJECT_DIR="/Users/republicalatuya/Desktop/LyoApp July/LyoApp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
echo_success() { echo -e "${GREEN}✅ $1${NC}"; }
echo_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }

# Check Xcode scheme configuration
echo ""
echo_info "Checking Xcode Scheme Configuration..."
SCHEME_FILE="$PROJECT_DIR/../LyoApp.xcodeproj/xcshareddata/xcschemes/LyoApp.xcscheme"

if [ -f "$SCHEME_FILE" ]; then
    LAUNCH_CONFIG=$(grep "buildConfiguration" "$SCHEME_FILE" | grep "LaunchAction" -A 1 | grep "buildConfiguration" | sed 's/.*buildConfiguration = "\([^"]*\)".*/\1/')
    TEST_CONFIG=$(grep "buildConfiguration" "$SCHEME_FILE" | grep "TestAction" -A 1 | grep "buildConfiguration" | sed 's/.*buildConfiguration = "\([^"]*\)".*/\1/')
    
    echo_success "Scheme file found: LyoApp.xcscheme"
    echo "  • LaunchAction (Run): $LAUNCH_CONFIG"
    echo "  • TestAction (Test): $TEST_CONFIG"
    
    if [ "$LAUNCH_CONFIG" = "Debug" ]; then
        echo_success "✅ LaunchAction uses Debug - Good for development!"
    else
        echo_warning "⚠️ LaunchAction uses $LAUNCH_CONFIG - This might use demo mode"
    fi
else
    echo_error "Scheme file not found at expected location"
fi

# Check environment configuration in code
echo ""
echo_info "Checking Environment Configuration in Code..."

# Check APIEnvironment.swift
API_ENV_FILE="$PROJECT_DIR/Core/Networking/APIEnvironment.swift"
if [ -f "$API_ENV_FILE" ]; then
    echo_success "APIEnvironment.swift found"
    
    # Check what DEBUG points to
    DEBUG_ENV=$(grep -A 2 "#if DEBUG" "$API_ENV_FILE" | grep "return" | head -1 | sed 's/.*return \.\([^[:space:]]*\).*/\1/')
    RELEASE_ENV=$(grep -A 2 "#else" "$API_ENV_FILE" | grep "return" | head -1 | sed 's/.*return \.\([^[:space:]]*\).*/\1/')
    
    echo "  • DEBUG builds → .$DEBUG_ENV"
    echo "  • RELEASE builds → .$RELEASE_ENV"
    
    # Check URLs
    PROD_URL=$(grep -A 5 "case .prod:" "$API_ENV_FILE" | grep "URL(" | sed 's/.*URL(string: "\([^"]*\)").*/\1/')
    DEV_URL=$(grep -A 5 "case .dev:" "$API_ENV_FILE" | grep "URL(" | sed 's/.*URL(string: "\([^"]*\)").*/\1/')
    
    echo "  • Production URL: $PROD_URL"
    echo "  • Development URL: $DEV_URL"
    
    if [[ "$PROD_URL" == *"lyo-backend-830162750094.us-central1.run.app"* ]]; then
        echo_success "✅ Production URL points to your Cloud Run backend"
    else
        echo_warning "⚠️ Production URL doesn't match expected Cloud Run domain"
    fi
else
    echo_warning "APIEnvironment.swift not found at expected location"
fi

# Check APIConfig.swift
API_CONFIG_FILE="$PROJECT_DIR/APIConfig.swift"
if [ -f "$API_CONFIG_FILE" ]; then
    echo_success "APIConfig.swift found"
    
    # Check what DEBUG returns in APIConfig
    DEBUG_CONFIG=$(grep -A 5 "#if DEBUG" "$API_CONFIG_FILE" | grep "return" | head -1 | sed 's/.*return \.\([^[:space:]]*\).*/\1/')
    echo "  • APIConfig DEBUG builds → .$DEBUG_CONFIG"
else
    echo_warning "APIConfig.swift not found"
fi

# Final assessment
echo ""
echo_info "Final Assessment:"
echo "================="

if [ "$LAUNCH_CONFIG" = "Debug" ] && [ "$DEBUG_ENV" = "prod" ]; then
    echo_success "🎯 PERFECT SETUP!"
    echo "   • Xcode Run button uses Debug configuration"
    echo "   • Debug builds point to .prod environment"
    echo "   • .prod points to your Cloud Run backend"
    echo ""
    echo_success "✅ When you press RUN in Xcode, you'll get:"
    echo "   📱 Debug build with full debugging"
    echo "   🌐 Connected to: https://lyo-backend-830162750094.us-central1.run.app"
    echo "   🚫 NO demo/mock data"
elif [ "$LAUNCH_CONFIG" = "Release" ]; then
    echo_warning "⚠️ POTENTIAL ISSUE:"
    echo "   • Xcode Run button uses Release configuration"
    echo "   • This might point to demo/mock mode"
    echo ""
    echo "💡 SOLUTION: Change LaunchAction to Debug in LyoApp.xcscheme"
else
    echo_info "Current configuration detected. Check the details above."
fi

echo ""
echo_info "To test your setup:"
echo "1. Open Xcode: open '$PROJECT_DIR/../LyoApp.xcodeproj'"
echo "2. Press Run (Cmd+R)"
echo "3. Check console output for environment information"
echo "4. Verify API calls go to Cloud Run, not mock data"

echo ""
echo_info "Environment switching (in DEBUG builds):"
echo "• More tab → Environment picker"
echo "• Switch between Development, Staging, Production"
echo "• Changes take effect immediately"