# Local Backend Setup Guide

## Your Local Backend: LyoBackendJune

**Location:** `/Users/hectorgarcia/Desktop/LyoBackendJune`

## Current Configuration

Your iOS app is now configured to use your local backend when running in DEBUG mode:

- **Development (DEBUG):** `http://localhost:8000` → Your LyoBackendJune
- **Production (RELEASE):** `https://lyo-backend-830162750094.us-central1.run.app` → Cloud backend

## Starting Your Local Backend

1. **Navigate to your backend directory:**
   ```bash
   cd /Users/hectorgarcia/Desktop/LyoBackendJune
   ```

2. **Start the server** (assuming it's a Python/FastAPI backend):
   ```bash
   # If using Python/FastAPI:
   python main.py
   # or
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   
   # If using Node.js:
   npm start
   # or
   node server.js
   ```

3. **Verify the server is running:**
   ```bash
   curl http://localhost:8000/health
   ```

## Environment Variable Override

You can force the app to use production even in debug builds:

```bash
# In Xcode, add to your scheme's environment variables:
LYO_ENV=prod    # Use production backend
LYO_ENV=dev     # Use local backend (default in debug)
```

## Troubleshooting

### If you get network errors:

1. **Ensure your backend is running on port 8000**
2. **Check that the `/health` endpoint exists**
3. **Verify no firewall is blocking localhost:8000**

### Common Backend Commands:

```bash
# Check what's running on port 8000
lsof -i :8000

# Kill any process using port 8000
kill -9 $(lsof -t -i:8000)

# Test your backend endpoints
curl http://localhost:8000/health
curl http://localhost:8000/v1/health  # if using versioned API
```

## Network Security

Your app is configured to allow HTTP connections to localhost in development mode automatically. If you encounter any issues, you may need to add network security exceptions to your Info.plist.

## Backend Structure Expected

Your LyoBackendJune should have these endpoints:
- `GET /health` - Health check
- `POST /auth/login` - Authentication  
- `GET /feed` - Feed data
- `POST /ai/chat` - AI interactions
- `WebSocket /ai/ws/{userId}` - Real-time communication

## Next Steps

1. Start your local backend server
2. Run your iOS app in DEBUG mode
3. Check the Xcode console logs for connection confirmation
4. Test API calls to ensure they're hitting localhost:8000

**Your app will automatically switch to the cloud backend when built in RELEASE mode!**