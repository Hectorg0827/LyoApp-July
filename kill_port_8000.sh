#!/bin/bash

# Script to kill all processes running on port 8000

echo "🔍 Checking for processes on port 8000..."

# Method 1: Using lsof to find and kill processes
PIDS=$(lsof -ti :8000)
if [ ! -z "$PIDS" ]; then
    echo "📍 Found processes on port 8000: $PIDS"
    echo "🔥 Killing processes..."
    kill -9 $PIDS
    echo "✅ Processes killed successfully"
else
    echo "ℹ️  No processes found running on port 8000"
fi

# Method 2: Alternative approach using netstat
echo "🔍 Double-checking with netstat..."
NETSTAT_PIDS=$(netstat -tulpn 2>/dev/null | grep :8000 | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | uniq)
if [ ! -z "$NETSTAT_PIDS" ]; then
    echo "📍 Found additional processes: $NETSTAT_PIDS"
    for pid in $NETSTAT_PIDS; do
        if [ ! -z "$pid" ] && [ "$pid" != "-" ]; then
            echo "🔥 Killing process $pid"
            kill -9 $pid 2>/dev/null
        fi
    done
    echo "✅ Additional processes killed"
fi

# Method 3: Kill common server processes by name
echo "🔍 Checking for common server processes..."
pkill -f "uvicorn.*8000" 2>/dev/null && echo "🔥 Killed uvicorn server"
pkill -f "python.*8000" 2>/dev/null && echo "🔥 Killed Python server"
pkill -f "node.*8000" 2>/dev/null && echo "🔥 Killed Node.js server"
pkill -f "fastapi.*8000" 2>/dev/null && echo "🔥 Killed FastAPI server"

# Final verification
echo "🔍 Final verification..."
REMAINING=$(lsof -ti :8000)
if [ -z "$REMAINING" ]; then
    echo "✅ Port 8000 is now free"
else
    echo "⚠️  Some processes may still be running: $REMAINING"
fi

echo "🎉 Done!"
