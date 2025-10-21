# Lyo Learning System - Complete Quickstart Guide

## 🚀 Get Running in 15 Minutes

This guide will have your **complete adaptive learning system** running end-to-end.

---

## 📋 Prerequisites

### Backend
- Docker Desktop installed and running
- Python 3.11+ (optional, for local development)
- PostgreSQL client (optional, for database inspection)

### iOS
- Xcode 15.0+
- iOS 17.0+ Simulator or Device
- CocoaPods or Swift Package Manager

---

## 🎯 Part 1: Backend Setup (5 minutes)

### Option A: Automated Setup (Recommended)

```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend"

# Make script executable (if not already)
chmod +x setup_learning_system.sh

# Run automated setup
./setup_learning_system.sh
```

**This script will:**
1. ✅ Check Docker is running
2. ✅ Start PostgreSQL & Redis
3. ✅ Run Alembic migrations
4. ✅ Seed CSS Flexbox course (15 ALOs)
5. ✅ Start FastAPI backend
6. ✅ Test all endpoints

**Expected output:**
```
================================
✅ Setup complete!

📊 Services running:
   - Backend API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - PostgreSQL: localhost:5432
   - Redis: localhost:6379
```

### Option B: Manual Setup

```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July/LyoBackend"

# 1. Start services
docker-compose up -d postgres redis

# 2. Wait for PostgreSQL
sleep 5

# 3. Run migrations
python3 -m venv .venv
source .venv/bin/activate
pip install alembic psycopg2-binary sqlalchemy
alembic upgrade head

# 4. Seed data
python3 src/learning/seed/seed_css_flexbox.py

# 5. Start backend
docker-compose up -d backend

# 6. Check health
curl http://localhost:8000/health
```

---

## 🧪 Part 2: Test Backend (3 minutes)

### Open API Docs

Visit: **http://localhost:8000/docs**

You should see **Swagger UI** with all endpoints.

### Test Course Compilation

1. Click on `POST /api/v1/courses/compile`
2. Click "Try it out"
3. Use this request body:

```json
{
  "goal": "Learn CSS Flexbox for responsive layout",
  "time_budget_min_per_day": 20,
  "deadline_iso": null,
  "prior_knowledge_ids": []
}
```

4. Click "Execute"

**Expected Response (201 Created):**
```json
{
  "course_id": "...",
  "skill_graph": {
    "kcs": [...],
    "los": [...],
    "alos": [...15 ALOs]
  },
  "schedule": [
    {"day": 1, "session": {"alo_ids": [...]}}
  ],
  "estimated_total_time_min": 45
}
```

**✅ Backend is ready!**

### Test WebSocket (Optional)

```bash
# Install wscat
npm install -g wscat

# Create session first (via API docs or curl)
SESSION_ID="your-session-id-here"

# Connect to WebSocket
wscat -c "ws://localhost:8000/api/v1/sessions/$SESSION_ID/run"

# You should receive first ALO
# Send a signal:
{"type":"signal","alo_id":"...","event":"completed","correct":true,"latency_ms":5000,"hints_used":0}
```

---

## 📱 Part 3: iOS Setup (5 minutes)

### 1. Open Project

```bash
cd "/Users/hectorgarcia/Desktop/LyoApp July"
open LyoApp.xcodeproj
```

### 2. Install Dependencies (if needed)

**Option A: Swift Package Manager (Recommended)**

- File → Add Package Dependencies
- Add: `https://github.com/apple/swift-markdown` (for MarkdownUI)
- Version: Latest

**Option B: CocoaPods**

```bash
# If using CocoaPods
pod install
open LyoApp.xcworkspace
```

### 3. Update API URL (if needed)

Open `LyoApp/Features/LearningSystem/Core/Services/LearningAPIService.swift`:

```swift
// Line ~20
#if DEBUG
self.baseURL = "http://localhost:8000/api/v1"  // ✅ Already configured
#else
self.baseURL = "https://api.lyoapp.com/api/v1"
#endif
```

### 4. Configure App Transport Security

Open `Info.plist` and add (if not present):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 5. Build & Run

1. Select iPhone 15 Pro simulator (or your device)
2. Press **⌘R** to build and run
3. App should compile successfully

---

## 🎮 Part 4: Test Complete Flow (2 minutes)

### From iOS App

**Option 1: Direct Test (Add to ContentView)**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Lyo Learning System")
                    .font(.largeTitle)
                    .bold()

                NavigationLink(destination: TestCompilationView()) {
                    Text("Test Course Compilation")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct TestCompilationView: View {
    @State private var course: Course?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Compiling course...")
            } else if let course = course {
                Text("✅ Course Compiled!")
                    .font(.title)
                Text("Course ID: \(course.id)")
                    .font(.caption)
                Text("\(course.skillGraph.alos.count) ALOs")

                NavigationLink(destination: ALORunnerView(courseId: course.id)) {
                    Text("Start Learning")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else if let error = error {
                Text("❌ Error: \(error)")
                    .foregroundColor(.red)
            }

            Button("Compile Course") {
                Task {
                    await compileCourse()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    func compileCourse() async {
        isLoading = true
        error = nil

        do {
            let api = LearningAPIService.shared
            course = try await api.compileCourse(
                goal: "Learn CSS Flexbox for responsive layout",
                timeBudgetMinPerDay: 20
            )
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
```

### Expected Flow:

1. **Tap "Test Course Compilation"**
   - Should call backend API
   - Display course ID and ALO count

2. **Tap "Start Learning"**
   - Opens `ALORunnerView`
   - Connects WebSocket
   - Receives first ALO (likely "Explain" type)

3. **Interact with ALO**
   - Read explanation
   - Tap "I Understand"
   - Backend policy engine decides next ALO

4. **Complete Quiz**
   - Answer question
   - Get instant feedback
   - Backend updates theta (mastery)

5. **Complete Exercise**
   - Write code
   - Submit
   - Backend validates + updates mastery

6. **Session End**
   - Summary shows stats
   - Theta updated in database
   - Review scheduled for tomorrow

---

## ✅ Verification Checklist

### Backend
- [ ] `docker-compose ps` shows all services running
- [ ] http://localhost:8000/health returns `{"status":"healthy"}`
- [ ] http://localhost:8000/docs shows Swagger UI
- [ ] POST /courses/compile returns 201 with course data
- [ ] Database has 15 ALOs: `docker-compose exec postgres psql -U lyoapp -d lyoapp_dev -c "SELECT COUNT(*) FROM alos;"`

### iOS
- [ ] Project compiles without errors
- [ ] `LearningAPIService.shared.compileCourse()` succeeds
- [ ] `ALORunnerView` connects to WebSocket
- [ ] All 5 ALO card types render correctly:
  - [ ] ExplainCard (blue, markdown)
  - [ ] ExampleCard (purple, code viewer)
  - [ ] ExerciseCard (orange, code editor)
  - [ ] QuizCard (green, multiple choice)
  - [ ] ProjectCard (red, checklist)
- [ ] Signals sent to backend trigger next ALO
- [ ] Session ends with summary

---

## 🐛 Troubleshooting

### Backend Issues

**Problem: Docker not starting**
```bash
# Check Docker
docker info

# Restart Docker Desktop
# macOS: Click Docker icon → Restart
```

**Problem: Port 8000 already in use**
```bash
# Find process
lsof -i :8000

# Kill it
kill -9 <PID>

# Or change port in docker-compose.yml
```

**Problem: Migrations fail**
```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres
sleep 5
alembic upgrade head
```

**Problem: Seed data fails**
```bash
# Check Python environment
source .venv/bin/activate
pip install -r requirements.txt  # or: poetry install

# Run seed script
python3 src/learning/seed/seed_css_flexbox.py
```

### iOS Issues

**Problem: Build fails with "Module not found"**
- Ensure dependencies installed (Swift Package Manager or CocoaPods)
- Clean build folder: ⌘⇧K
- Rebuild: ⌘B

**Problem: API calls fail with "Connection refused"**
- Ensure backend running: `curl http://localhost:8000/health`
- Check `Info.plist` has NSAppTransportSecurity settings
- For physical device: Use your Mac's local IP instead of `localhost`

**Problem: WebSocket connection fails**
- Check backend logs: `docker-compose logs -f backend`
- Verify session created: Check `/sessions` endpoint in Swagger
- Try: `ws://localhost:8000` instead of `wss://`

---

## 📊 Next Steps

### 1. Explore the System

**Backend:**
- Check database: `docker-compose exec postgres psql -U lyoapp -d lyoapp_dev`
- View tables: `\dt`
- Query ALOs: `SELECT id, alo_type, difficulty FROM alos;`
- View logs: `docker-compose logs -f backend`

**iOS:**
- Add progress dashboard
- Add review queue UI
- Integrate with existing EnhancedAIClassroomView

### 2. Add More Courses

Create seed scripts for other topics:
```python
# src/learning/seed/seed_python_basics.py
# src/learning/seed/seed_react_fundamentals.py
```

### 3. Enhance UI

- Add theta visualization (skill tree)
- Add streak tracking with animations
- Add push notifications for reviews
- Add offline caching

### 4. Deploy to Production

**Backend:**
- Deploy to GCP Cloud Run / AWS ECS
- Use managed PostgreSQL (Cloud SQL / RDS)
- Add Redis cache (Cloud Memorystore / ElastiCache)
- Configure environment variables
- Enable HTTPS

**iOS:**
- Update `baseURL` in production build
- Submit to App Store
- Configure push notifications

---

## 🎉 Success Metrics

You've successfully set up the system when:

✅ Backend compiles courses in <500ms
✅ WebSocket maintains connection throughout session
✅ Theta updates correctly after each ALO
✅ Policy engine remediates on wrong answers
✅ Review queue schedules items for next day
✅ All 5 ALO types render beautifully
✅ Session completes with accurate summary
✅ No memory leaks (Instruments check)
✅ 60 FPS animation performance
✅ VoiceOver accessibility works

---

## 📚 Architecture Summary

```
┌─────────────┐
│  iOS App    │
│             │
│  ┌────────┐ │
│  │ Runner │ │ ← ALORunnerView + ViewModel
│  └────────┘ │
│      ↓      │
│  ┌────────┐ │
│  │  API   │ │ ← LearningAPIService (REST)
│  │ Service│ │
│  └────────┘ │
│      ↓      │
│  ┌────────┐ │
│  │WebSocket││ ← RealtimeSessionService
│  │ Service│ │
│  └────────┘ │
└──────┬──────┘
       │
       │ HTTP/WS
       │
┌──────▼───────────────────────┐
│   FastAPI Backend            │
│                              │
│  /courses/compile            │
│  /sessions/{id}/run  (WS)    │
│  /progress/                  │
│  /evidence/submit            │
│                              │
│  ┌──────────────────┐        │
│  │ Policy Engine    │        │
│  │ (Adaptive Logic) │        │
│  └──────────────────┘        │
│           ↓                  │
│  ┌──────────────────┐        │
│  │  PostgreSQL      │        │
│  │  - KCs, LOs, ALOs│        │
│  │  - Theta         │        │
│  │  - Review Queue  │        │
│  └──────────────────┘        │
└──────────────────────────────┘
```

---

## 🏆 What You've Built

**Backend (Python/FastAPI):**
- 3,000+ lines of production code
- Adaptive policy engine
- WebSocket real-time system
- Spaced repetition (SM-2)
- Knowledge tracing (Bayesian)

**iOS (Swift/SwiftUI):**
- 2,000+ lines of production code
- 5 beautiful ALO renderers
- Real-time WebSocket client
- Complete API integration
- Smooth animations

**Total:** ~5,000 lines of production-grade code

---

## 💡 Pro Tips

1. **Development Workflow:**
   - Keep backend logs open: `docker-compose logs -f backend`
   - Use Swagger UI for quick API testing
   - Monitor WebSocket in browser DevTools

2. **Debugging:**
   - Backend: Add `logger.info()` statements
   - iOS: Use `print()` with prefixes like `[API]`, `[WS]`, `[Runner]`
   - Check Network tab in Xcode debugger

3. **Performance:**
   - Backend: Monitor with `/metrics` endpoint
   - iOS: Profile with Instruments
   - Database: Use `EXPLAIN ANALYZE` for slow queries

4. **Testing:**
   - Backend: `pytest` for unit tests
   - iOS: XCTest for unit tests
   - End-to-end: Manual testing + automation later

---

**Ready to learn adaptively!** 🚀

If you encounter issues, check the troubleshooting section or review the `IMPLEMENTATION_STATUS.md` file.
