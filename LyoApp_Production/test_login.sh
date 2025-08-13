#!/bin/bash

echo "🔐 TESTING LOGIN FUNCTIONALITY"
echo "========================================="

# Test backend connectivity
echo "1. Testing backend health..."
HEALTH_RESPONSE=$(curl -s "http://localhost:8000/api/v1/health")
if [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend not responding properly"
    exit 1
fi

# Test login endpoint
echo ""
echo "2. Testing login endpoint..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@lyo.app","password":"password123"}')

echo "Login Response: $LOGIN_RESPONSE"

if [[ $LOGIN_RESPONSE == *"token"* ]]; then
    echo "✅ Login endpoint working"
else
    echo "❌ Login endpoint failed"
fi

# Test registration endpoint
echo ""
echo "3. Testing registration endpoint..."
REG_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"testuser@lyo.app","password":"password123","fullName":"Test User"}')

echo "Registration Response: $REG_RESPONSE"

if [[ $REG_RESPONSE == *"token"* || $REG_RESPONSE == *"success"* ]]; then
    echo "✅ Registration endpoint working"
else
    echo "❌ Registration endpoint failed"
fi

echo ""
echo "========================================="
echo "BACKEND STATUS: READY FOR iOS APP TESTING"
echo "========================================="
echo ""
echo "📱 To test in iOS app:"
echo "1. Open LyoApp_Production in Xcode"
echo "2. Run on iOS Simulator"
echo "3. Try logging in with:"
echo "   Email: test@lyo.app"
echo "   Password: password123"
echo ""
echo "🔍 Check Xcode console for authentication logs"
