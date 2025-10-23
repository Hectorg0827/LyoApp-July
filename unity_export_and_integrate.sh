#!/bin/bash

# Unity Export and Integration - FULL AUTOMATION
# This script guides you through Unity export and automatically integrates everything

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
UNITY_PROJECT="/Users/hectorgarcia/Downloads/UnityClassroom_oct 15"
EXPECTED_EXPORT="/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export"
LYOAPP_DIR="/Users/hectorgarcia/Desktop/LyoApp July"
INTEGRATION_SCRIPT="${LYOAPP_DIR}/integrate_unity.sh"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    Unity Export & Integration - FULL AUTOMATION        ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo ""

# Step 1: Check if Unity is already exported
echo -e "${BLUE}[1/5] Checking for existing Unity export...${NC}"
if [ -d "${EXPECTED_EXPORT}/UnityFramework.framework" ]; then
    echo -e "${GREEN}✅ Unity export found!${NC}"
    echo -e "   Location: ${EXPECTED_EXPORT}"
    UNITY_EXPORTED=true
else
    echo -e "${YELLOW}⚠️  Unity export NOT found${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ACTION REQUIRED: Export Unity Project${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Follow these steps in Unity Editor:${NC}"
    echo ""
    echo -e "  1️⃣  Open Unity Hub"
    echo -e "  2️⃣  Click 'Open' → Navigate to:"
    echo -e "      ${UNITY_PROJECT}"
    echo ""
    echo -e "  3️⃣  Wait for Unity to open (may take 2-3 minutes)"
    echo ""
    echo -e "  4️⃣  In Unity Editor menu:"
    echo -e "      ${GREEN}File → Build Settings${NC}"
    echo ""
    echo -e "  5️⃣  In Build Settings window:"
    echo -e "      • Select ${GREEN}iOS${NC} platform (left panel)"
    echo -e "      • Click ${GREEN}'Switch Platform'${NC} if needed"
    echo -e "      • ${RED}✅ CHECK${NC} the box: ${GREEN}'Export Project'${NC}"
    echo -e "      • ${RED}DO NOT${NC} check 'Development Build'"
    echo ""
    echo -e "  6️⃣  Click ${GREEN}'Export'${NC} button (bottom right)"
    echo ""
    echo -e "  7️⃣  Save dialog appears:"
    echo -e "      • Navigate to: /Users/hectorgarcia/Downloads/"
    echo -e "      • Name it: ${GREEN}UnityClassroom_oct_15_iOS_Export${NC}"
    echo -e "      • Click ${GREEN}'Save'${NC}"
    echo ""
    echo -e "  8️⃣  Wait for export (5-10 minutes)"
    echo -e "      Unity will show progress bar"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}After export completes, come back and run this script again:${NC}"
    echo -e "${GREEN}./unity_export_and_integrate.sh${NC}"
    echo ""
    exit 0
fi

# Step 2: Verify export structure
echo ""
echo -e "${BLUE}[2/5] Verifying Unity export structure...${NC}"

if [ ! -d "${EXPECTED_EXPORT}/UnityFramework.framework" ]; then
    echo -e "${RED}❌ UnityFramework.framework not found${NC}"
    exit 1
fi

if [ ! -d "${EXPECTED_EXPORT}/Data" ]; then
    echo -e "${YELLOW}⚠️  Data folder not found - checking alternative locations...${NC}"
    # Sometimes Data folder is nested
    DATA_FOLDER=$(find "${EXPECTED_EXPORT}" -name "Data" -type d | head -1)
    if [ -z "${DATA_FOLDER}" ]; then
        echo -e "${RED}❌ Could not locate Data folder${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Found Data folder at: ${DATA_FOLDER}${NC}"
else
    echo -e "${GREEN}✅ Data folder found${NC}"
fi

echo -e "${GREEN}✅ Unity export structure verified${NC}"

# Step 3: Run integration script
echo ""
echo -e "${BLUE}[3/5] Running Unity integration...${NC}"

if [ ! -f "${INTEGRATION_SCRIPT}" ]; then
    echo -e "${RED}❌ Integration script not found: ${INTEGRATION_SCRIPT}${NC}"
    exit 1
fi

chmod +x "${INTEGRATION_SCRIPT}"

echo -e "${CYAN}Executing: ${INTEGRATION_SCRIPT}${NC}"
echo ""

# Run integration
"${INTEGRATION_SCRIPT}"

# Step 4: Verify integration
echo ""
echo -e "${BLUE}[4/5] Verifying integration...${NC}"

VERIFY_SCRIPT="${LYOAPP_DIR}/verify_unity.sh"
if [ -f "${VERIFY_SCRIPT}" ]; then
    chmod +x "${VERIFY_SCRIPT}"
    "${VERIFY_SCRIPT}"
else
    echo -e "${YELLOW}⚠️  Verification script not found, skipping...${NC}"
fi

# Step 5: Build test
echo ""
echo -e "${BLUE}[5/5] Testing build...${NC}"

cd "${LYOAPP_DIR}"

echo -e "${CYAN}Running xcodebuild...${NC}"
if xcodebuild -project LyoApp.xcodeproj -scheme LyoApp build -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo ""
    echo -e "${GREEN}✅ BUILD SUCCEEDED${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🎉 UNITY INTEGRATION COMPLETE!${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo ""
    echo -e "  1️⃣  Open Xcode:"
    echo -e "     ${GREEN}open LyoApp.xcodeproj${NC}"
    echo ""
    echo -e "  2️⃣  Run the app (Cmd+R)"
    echo ""
    echo -e "  3️⃣  Check console for:"
    echo -e "     ${GREEN}✅ Unity initialized successfully${NC}"
    echo ""
    echo -e "  4️⃣  Test Unity integration in app"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}❌ BUILD FAILED${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Check Xcode for specific errors"
    echo -e "  2. Clean build: xcodebuild clean"
    echo -e "  3. Try building in Xcode directly"
    echo ""
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All done!${NC}"
echo ""
