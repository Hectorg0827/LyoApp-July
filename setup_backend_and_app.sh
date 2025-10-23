#!/bin/bash

# LyoApp Backend Setup & Configuration Script
# This script ensures the backend is properly configured with real API keys

set -e

BACKEND_DIR="/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend"
ENV_FILE="$BACKEND_DIR/.env"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     LyoApp Backend Configuration & Setup                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check if backend directory exists
echo "📂 [1/5] Checking backend directory..."
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend directory not found!"
    exit 1
fi
echo "✅ Backend directory found"

# Step 2: Check .env file
echo ""
echo "🔧 [2/5] Checking .env configuration..."
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found!"
    echo "   Creating from .env.sample..."
    cp "$BACKEND_DIR/.env.sample" "$ENV_FILE"
    echo "⚠️  Please edit $ENV_FILE and add your API keys"
fi
echo "✅ .env file exists"

# Step 3: Check for API keys
echo ""
echo "🔑 [3/5] Checking API configuration..."

HAS_GEMINI=$(grep -i "GEMINI_API_KEY" "$ENV_FILE" | grep -v "^#" || echo "")
HAS_OPENAI=$(grep -i "OPENAI_API_KEY" "$ENV_FILE" | grep -v "^#" | grep -v "your-openai-api-key" || echo "")

if [ -z "$HAS_GEMINI" ]; then
    echo "⚠️  GEMINI_API_KEY not configured"
    echo "   Adding GEMINI_API_KEY to .env..."
    echo "" >> "$ENV_FILE"
    echo "# Google Gemini AI" >> "$ENV_FILE"
    echo "GEMINI_API_KEY=your-gemini-api-key-here" >> "$ENV_FILE"
    echo "GEMINI_MODEL=gemini-1.5-flash" >> "$ENV_FILE"
    echo ""
    echo "   ⚠️  ACTION REQUIRED: Edit $ENV_FILE and add your Gemini API key"
    echo "   Get it from: https://makersuite.google.com/app/apikey"
else
    echo "✅ GEMINI_API_KEY configured"
fi

if [ -z "$HAS_OPENAI" ]; then
    echo "⚠️  OPENAI_API_KEY not configured (optional)"
else
    echo "✅ OPENAI_API_KEY configured"
fi

# Step 4: Check if backend is running
echo ""
echo "🚀 [4/5] Checking backend server..."

if lsof -ti:8000 > /dev/null 2>&1; then
    echo "✅ Backend is running on port 8000"
    
    # Test health endpoint
    if curl -sf http://localhost:8000/api/v1/health > /dev/null 2>&1; then
        echo "✅ Backend health check passed"
    else
        echo "⚠️  Backend running but not responding"
        echo "   You may need to restart it"
    fi
else
    echo "⚠️  Backend is NOT running"
    echo ""
    echo "   To start the backend:"
    echo "   cd '$BACKEND_DIR'"
    echo "   python start_dev.py"
    echo ""
    
    read -p "   Start backend now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   Starting backend..."
        cd "$BACKEND_DIR"
        python start_dev.py &
        BACKEND_PID=$!
        echo "   Backend started with PID: $BACKEND_PID"
        echo "   Waiting for backend to be ready..."
        sleep 5
        
        if curl -sf http://localhost:8000/api/v1/health > /dev/null 2>&1; then
            echo "✅ Backend is now running and healthy"
        else
            echo "❌ Backend failed to start properly"
            echo "   Check logs in $BACKEND_DIR"
        fi
    fi
fi

# Step 5: Summary
echo ""
echo "📊 [5/5] Configuration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Backend Directory: $BACKEND_DIR"
echo "Environment File: $ENV_FILE"
echo ""

if [ -n "$HAS_GEMINI" ]; then
    echo "✅ Gemini API: Configured"
else
    echo "❌ Gemini API: NOT configured"
fi

if [ -n "$HAS_OPENAI" ]; then
    echo "✅ OpenAI API: Configured"
else
    echo "⚠️  OpenAI API: NOT configured (optional)"
fi

if lsof -ti:8000 > /dev/null 2>&1; then
    echo "✅ Backend Server: Running"
else
    echo "❌ Backend Server: NOT running"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Final recommendations
echo "📝 Next Steps:"
echo ""

if [ -z "$HAS_GEMINI" ]; then
    echo "1. ⚠️  ADD GEMINI API KEY:"
    echo "   - Get key from: https://makersuite.google.com/app/apikey"
    echo "   - Edit: $ENV_FILE"
    echo "   - Set: GEMINI_API_KEY=your-actual-key"
    echo ""
fi

if ! lsof -ti:8000 > /dev/null 2>&1; then
    echo "2. 🚀 START BACKEND:"
    echo "   cd '$BACKEND_DIR'"
    echo "   python start_dev.py"
    echo ""
fi

echo "3. 🏗️  REBUILD & RUN APP:"
echo "   - Open LyoApp.xcodeproj in Xcode"
echo "   - Press Cmd+R to run"
echo "   - Real AI generation will now work!"
echo ""

echo "4. ✅ VERIFY IN APP:"
echo "   - Go to Learn tab"
echo "   - Try creating a course with AI"
echo "   - Check '3D Classroom' tab for Unity"
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Configuration Complete!                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
