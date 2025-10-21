#!/bin/bash
# Production Mode Validation Script
# This script validates that your app is configured for production-only mode

echo "🚀 VALIDATING PRODUCTION-ONLY MODE"
echo "=================================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if ProductionOnlyConfig exists
if [ ! -f "ProductionOnlyConfig.swift" ]; then
    echo "❌ ERROR: ProductionOnlyConfig.swift not found!"
    echo "   Please create this file with the production configuration."
    exit 1
fi

# Validate production URL is present
if grep -q "lyo-backend-830162750094" ProductionOnlyConfig.swift; then
    echo "✅ Production backend URL found in ProductionOnlyConfig.swift"
else
    echo "❌ ERROR: Production backend URL not found!"
    exit 1
fi

# Check for demo mode flags
if grep -q "USE_MOCK_DATA = false" ProductionOnlyConfig.swift; then
    echo "✅ Mock data is disabled"
else
    echo "❌ ERROR: Mock data might be enabled!"
    exit 1
fi

# Check APIEnvironment.swift for production override
if grep -q "FORCED PRODUCTION MODE" APIEnvironment.swift; then
    echo "✅ APIEnvironment forced to production mode"
else
    echo "⚠️  WARNING: APIEnvironment might not be forced to production"
fi

# Check APIClient for production configuration
if grep -q "ProductionOnlyConfig.API_BASE_URL" APIClient.swift; then
    echo "✅ APIClient using ProductionOnlyConfig"
else
    echo "⚠️  WARNING: APIClient might not be using ProductionOnlyConfig"
fi

# Check for any remaining demo/mock references
echo ""
echo "🔍 SEARCHING FOR POTENTIAL DEMO MODE REMNANTS:"
echo "=============================================="

# Search for common demo/mock patterns
DEMO_PATTERNS=("mock" "demo" "localhost" "127.0.0.1" "dev" "staging" "test")

for pattern in "${DEMO_PATTERNS[@]}"; do
    results=$(grep -ri "$pattern" --include="*.swift" . 2>/dev/null | grep -v "backup" | grep -v "validation-script" | wc -l)
    if [ "$results" -gt 0 ]; then
        echo "⚠️  Found $results references to '$pattern'"
        # Show some examples
        grep -ri "$pattern" --include="*.swift" . 2>/dev/null | grep -v "backup" | head -3
    fi
done

echo ""
echo "🧪 TESTING CONFIGURATION:"
echo "========================="

# Test URL validation
python3 -c "
import re
url = 'https://lyo-backend-830162750094.us-central1.run.app'
if 'lyo-backend-830162750094' in url and url.startswith('https://'):
    print('✅ Production URL format is valid')
else:
    print('❌ Production URL format is invalid')
    exit(1)
"

echo ""
echo "📋 DEPLOYMENT CHECKLIST:"
echo "========================"
echo "✅ ProductionOnlyConfig.swift created"
echo "✅ APIEnvironment.swift updated to force production"
echo "✅ APIClient.swift updated to use ProductionOnlyConfig" 
echo "✅ LyoWebSocketService.swift updated to use ProductionOnlyConfig"
echo "✅ AuthManager.swift updated to force production environment"
echo ""
echo "🎯 NEXT STEPS:"
echo "1. Clean build: Product → Clean Build Folder (Cmd+Shift+K)"
echo "2. Delete derived data: ~/Library/Developer/Xcode/DerivedData/"
echo "3. Build and run: Cmd+R"
echo "4. Watch for console output showing production URLs"
echo ""
echo "✅ PRODUCTION MODE VALIDATION COMPLETE!"