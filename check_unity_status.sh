#!/bin/bash

# Quick Unity Export Status Checker

EXPECTED_EXPORT="/Users/hectorgarcia/Downloads/UnityClassroom_oct_15_iOS_Export"

echo ""
echo "🔍 Checking Unity Export Status..."
echo ""

if [ -d "${EXPECTED_EXPORT}/UnityFramework.framework" ]; then
    echo "✅ Unity IS exported and ready!"
    echo ""
    echo "   Location: ${EXPECTED_EXPORT}"
    echo ""
    echo "🚀 Next step: Run integration"
    echo ""
    echo "   cd '/Users/hectorgarcia/Desktop/LyoApp July'"
    echo "   ./integrate_unity.sh"
    echo ""
else
    echo "⏳ Unity NOT yet exported"
    echo ""
    echo "📋 To export Unity:"
    echo ""
    echo "   1. Open Unity Hub"
    echo "   2. Open: /Users/hectorgarcia/Downloads/UnityClassroom_oct 15"
    echo "   3. File → Build Settings → iOS"
    echo "   4. ✅ Check 'Export Project'"
    echo "   5. Click 'Export'"
    echo "   6. Save as: UnityClassroom_oct_15_iOS_Export"
    echo ""
    echo "⚡ OR run the full automation:"
    echo ""
    echo "   cd '/Users/hectorgarcia/Desktop/LyoApp July'"
    echo "   ./unity_export_and_integrate.sh"
    echo ""
fi
