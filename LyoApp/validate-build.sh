#!/bin/bash

# LyoApp Build Validation Script
echo "🔍 Validating LyoApp Build Configuration..."
echo "=========================================="

PROJECT_DIR="/Users/republicalatuya/Desktop/LyoApp July/LyoApp"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_success() { echo -e "${GREEN}✅ $1${NC}"; }
echo_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_error() { echo -e "${RED}❌ $1${NC}"; }

# Check for duplicate APIEnvironment declarations
echo ""
echo "🔍 Checking for duplicate APIEnvironment declarations..."
api_env_count=$(grep -r "enum APIEnvironment" . --include="*.swift" | wc -l | tr -d ' ')
if [ "$api_env_count" -gt 1 ]; then
    echo_error "Multiple APIEnvironment declarations found ($api_env_count):"
    grep -r "enum APIEnvironment" . --include="*.swift"
    echo "This will cause compilation conflicts!"
else
    echo_success "APIEnvironment declaration is unique"
fi

# Check APIConfig dependencies
echo ""
echo "🔍 Checking APIConfig structure..."
if grep -q "struct APIConfig" APIConfig.swift; then
    echo_success "APIConfig struct found"
else
    echo_error "APIConfig struct not found in APIConfig.swift"
fi

# Check for proper environment references
echo ""
echo "🔍 Checking environment references..."
invalid_refs=$(grep -r "\.development\|\.production\|\.demo" . --include="*.swift" | grep -v "displayName" | grep -v "comment" || true)
if [ -n "$invalid_refs" ]; then
    echo_warning "Found potentially invalid environment references:"
    echo "$invalid_refs"
    echo "Should use .dev, .staging, .prod instead"
else
    echo_success "Environment references look correct"
fi

# Check AppIcon configuration
echo ""
echo "🔍 Checking AppIcon configuration..."
if [ -f "Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo_success "AppIcon Contents.json exists"
    
    # Check for orphaned icon files
    orphaned_icons=$(find Assets.xcassets/AppIcon.appiconset/ -name "*.png" -exec basename {} \; | while read icon; do
        if ! grep -q "$icon" Assets.xcassets/AppIcon.appiconset/Contents.json; then
            echo "$icon"
        fi
    done)
    
    if [ -n "$orphaned_icons" ]; then
        echo_warning "Orphaned icon files found:"
        echo "$orphaned_icons"
    else
        echo_success "No orphaned icon files"
    fi
else
    echo_error "AppIcon Contents.json missing"
fi

# Check for circular dependencies
echo ""
echo "🔍 Checking for circular dependencies..."
if grep -q "APIConfig" Core/Networking/APIEnvironment.swift; then
    echo_error "Circular dependency: APIEnvironment references APIConfig"
else
    echo_success "No circular dependencies in APIEnvironment"
fi

# Check key configuration files
echo ""
echo "🔍 Checking key configuration files..."
key_files=(
    "APIConfig.swift"
    "Core/Networking/APIEnvironment.swift" 
    "LyoApp.swift"
    "ProductionConfiguration.swift"
    "Package.swift"
)

for file in "${key_files[@]}"; do
    if [ -f "$file" ]; then
        echo_success "$file exists"
    else
        echo_error "$file missing"
    fi
done

# Final status
echo ""
echo "🎯 Build Configuration Summary:"
echo "================================"
echo "Project Directory: $PROJECT_DIR"
echo "Primary Backend URL: https://lyo-backend-830162750094.us-central1.run.app"
echo "Environment System: Core/Networking/APIEnvironment (.dev, .staging, .prod)"
echo "Configuration Manager: APIConfig (delegates to APIEnvironment)"
echo "Default Environment: Production for release builds, Development for debug builds"

echo ""
echo "🚀 To build the project:"
echo "  cd '$PROJECT_DIR'"
echo "  swift build"
echo ""
echo "📱 To run the project:"
echo "  swift run"
echo ""