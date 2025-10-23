#!/bin/bash

# Simple script to start the LyoApp backend server

echo "🚀 Starting LyoApp Backend..."
echo ""

cd "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend"

# Check if .env has a real API key
if grep -q "your-gemini-api-key-here" .env 2>/dev/null; then
    echo "⚠️  WARNING: Gemini API key not configured yet!"
    echo ""
    echo "To add your API key:"
    echo "1. Get key from: https://makersuite.google.com/app/apikey"
    echo "2. Edit: nano .env"
    echo "3. Replace 'your-gemini-api-key-here' with your actual key"
    echo ""
    echo "Press Ctrl+C to stop, or wait 5 seconds to start anyway..."
    sleep 5
fi

# Start the backend
echo "🔧 Starting server on http://localhost:8000"
echo "📊 API docs will be at: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python3 start_dev.py
