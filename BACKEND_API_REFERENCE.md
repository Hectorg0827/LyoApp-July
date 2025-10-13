# 🚀 LyoBackend API Reference

**Base URL**: `https://lyo-backend-830162750094.us-central1.run.app`

**Last Updated**: October 7, 2025

---

## 📋 Quick Links

- **Interactive Docs**: https://lyo-backend-830162750094.us-central1.run.app/docs
- **Health Check**: https://lyo-backend-830162750094.us-central1.run.app/health
- **OpenAPI Spec**: https://lyo-backend-830162750094.us-central1.run.app/openapi.json

---

## 🎯 Priority Endpoints for LyoApp

### 🤖 AI Avatar & Course Generation

#### **Generate Complete Course** ⭐ NEW!
```http
POST /api/content/generate-course
Content-Type: application/json

{
  "topic": "Python Programming",
  "level": "beginner",              // beginner, intermediate, advanced
  "outcomes": [
    "Write basic programs",
    "Understand data structures"
  ],
  "teaching_style": "examples-first" // examples-first, theory-first, project-based, balanced
}

Response: {
  "course_id": "abc123",
  "title": "Python Programming",
  "modules": [...],                  // 5-7 modules
  "lessons": [...],                  // 25-40 lessons total
  "estimated_duration_hours": 40
}
```

#### **Assemble Rich Lesson Content** ⭐ NEW!
```http
POST /api/content/assemble-lesson
Content-Type: application/json

{
  "topic": "Python Variables",
  "level": "beginner",
  "learning_objectives": ["Understand variable types", "Practice assignments"],
  "content_preferences": {
    "prefer_video": true,
    "max_duration_minutes": 15
  }
}

Response: {
  "lesson_id": "lesson_123",
  "content": {
    "introduction": "...",
    "video_url": "https://youtube.com/...",
    "wikipedia_summary": "...",
    "examples": [...],
    "practice_exercises": [...]
  }
}
```

#### **AI Mentor Conversation**
```http
POST /api/v1/ai/mentor/conversation
Content-Type: application/json

{
  "user_id": 1,
  "message": "Help me learn Python",
  "model": "gemini-2.0-flash-exp",   // or "gpt-4", "claude-3"
  "context": {                        // optional
    "current_lesson": "Variables",
    "user_level": "beginner",
    "avatar_personality": "wise"
  }
}

Response: {
  "response": "...",
  "model_used": "gemini-2.0-flash-exp",
  "tokens_used": 150,
  "response_time_ms": 1200
}
```

#### **AI Chat WebSocket** 🔌 Real-Time
```javascript
const ws = new WebSocket('wss://lyo-backend-830162750094.us-central1.run.app/api/v1/ai/ws/{user_id}');

// Receive real-time AI responses
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // { type: "ai_response", message: "...", tokens: 50 }
};

// Send messages
ws.send(JSON.stringify({
  action: "chat",
  message: "Explain loops",
  context: { lesson: "Control Flow" }
}));
```

#### **Get Conversation History**
```http
GET /api/v1/ai/mentor/history?user_id=1&limit=50
```

#### **AI Health Check**
```http
GET /api/v1/ai/health

Response: {
  "status": "healthy",
  "available_models": ["gpt-4", "claude-3", "gemini-2.0-flash-exp"],
  "response_time_ms": 45
}
```

#### **Content Engine Health**
```http
GET /api/content/health

Response: {
  "status": "healthy",
  "services": {
    "wikipedia": true,
    "youtube": true,
    "gemini_ai": true
  }
}
```

---

### 📚 Learning System

#### **List Courses**
```http
GET /api/v1/learning/courses?user_id=1
```

#### **Get Course Details**
```http
GET /api/v1/learning/courses/{course_id}
```

#### **Enroll in Course**
```http
POST /api/v1/learning/enroll
Content-Type: application/json

{
  "user_id": 1,
  "course_id": "abc123"
}
```

#### **Track Progress**
```http
GET /api/v1/learning/progress?user_id=1&course_id=abc123

Response: {
  "course_id": "abc123",
  "completion_percentage": 45,
  "lessons_completed": 12,
  "lessons_total": 27,
  "time_spent_minutes": 340,
  "current_lesson": "lesson_13"
}
```

#### **Mark Lesson Complete**
```http
POST /api/v1/learning/complete
Content-Type: application/json

{
  "user_id": 1,
  "lesson_id": "lesson_123",
  "time_spent_minutes": 25,
  "score": 85               // optional quiz score
}
```

#### **Get Recommendations**
```http
GET /api/v1/learning/recommendations?user_id=1&current_topic=python

Response: {
  "courses": [...],
  "lessons": [...],
  "resources": [...]
}
```

#### **Search Learning Content**
```http
GET /api/v1/learning/search?q=python+loops&user_id=1
```

---

### 🎮 Gamification

#### **Get User Profile**
```http
GET /api/v1/gamification/profile?user_id=1

Response: {
  "user_id": 1,
  "level": 12,
  "xp": 4250,
  "xp_to_next_level": 750,
  "rank": "Advanced Learner",
  "total_achievements": 15
}
```

#### **Log Activity (Earn XP)**
```http
POST /api/v1/gamification/activity
Content-Type: application/json

{
  "user_id": 1,
  "activity_type": "lesson_completed",  // lesson_completed, quiz_passed, daily_login, streak_milestone
  "metadata": {
    "lesson_id": "lesson_123",
    "score": 90
  }
}

Response: {
  "xp_earned": 50,
  "new_level": false,
  "new_achievements": []
}
```

#### **Get Achievements**
```http
GET /api/v1/gamification/achievements?user_id=1

Response: {
  "unlocked": [
    { "id": "first_lesson", "name": "Getting Started", "icon": "🎓", "unlocked_at": "..." }
  ],
  "locked": [
    { "id": "streak_7", "name": "Week Warrior", "icon": "🔥", "progress": 5, "requirement": 7 }
  ]
}
```

#### **Get Leaderboard**
```http
GET /api/v1/gamification/leaderboard?scope=global&limit=100

// scope: global, friends, course

Response: {
  "rankings": [
    { "rank": 1, "user_id": 42, "username": "john_doe", "xp": 12500, "level": 25 }
  ],
  "user_rank": 15
}
```

#### **Get Streak**
```http
GET /api/v1/gamification/streak?user_id=1

Response: {
  "current_streak": 7,
  "longest_streak": 21,
  "last_activity_date": "2025-10-07"
}
```

#### **Complete Daily Challenge**
```http
POST /api/v1/gamification/challenge/complete
Content-Type: application/json

{
  "user_id": 1,
  "challenge_id": "daily_oct_7",
  "proof": { "lessons_completed": 3 }
}
```

---

### 💬 Real-Time Messaging

#### **List Conversations**
```http
GET /api/v1/social/messenger/conversations?user_id=1

Response: {
  "conversations": [
    {
      "id": "conv_123",
      "type": "direct",           // direct or group
      "participants": [...],
      "last_message": "...",
      "unread_count": 3,
      "updated_at": "..."
    }
  ]
}
```

#### **Create Conversation**
```http
POST /api/v1/social/messenger/conversations
Content-Type: application/json

{
  "user_id": 1,
  "participant_ids": [2, 3],
  "type": "group",
  "name": "Python Study Group"
}
```

#### **Send Message**
```http
POST /api/v1/social/messenger/conversations/{conv_id}/messages
Content-Type: application/json

{
  "user_id": 1,
  "content": "Hello!",
  "type": "text",              // text, image, file
  "media_url": null            // optional
}
```

#### **Mark as Read**
```http
PUT /api/v1/social/messenger/messages/{message_id}/read
Content-Type: application/json

{
  "user_id": 1
}
```

#### **Messaging WebSocket** 🔌
```javascript
const ws = new WebSocket('wss://lyo-backend-830162750094.us-central1.run.app/api/v1/social/messenger/ws/{user_id}');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // { type: "new_message", conversation_id: "...", message: {...} }
  // { type: "typing", conversation_id: "...", user_id: 2 }
  // { type: "read_receipt", message_id: "...", user_id: 2 }
};
```

---

### 📸 Stories (24-Hour Social Stories)

#### **Get Active Stories**
```http
GET /api/v1/social/stories/?user_id=1

Response: {
  "stories": [
    {
      "id": "story_123",
      "user_id": 42,
      "username": "john_doe",
      "media_type": "image",       // image, video, text
      "media_url": "...",
      "text": "Learning Python today!",
      "view_count": 45,
      "created_at": "...",
      "expires_at": "..."
    }
  ]
}
```

#### **Create Story**
```http
POST /api/v1/social/stories/
Content-Type: application/json

{
  "user_id": 1,
  "media_type": "image",
  "media_url": "https://...",
  "text": "Just completed my first lesson!"
}
```

#### **Record Story View**
```http
POST /api/v1/social/stories/{story_id}/view
Content-Type: application/json

{
  "user_id": 1
}
```

#### **Get Story Viewers**
```http
GET /api/v1/social/stories/{story_id}/views

Response: {
  "view_count": 45,
  "viewers": [
    { "user_id": 2, "username": "jane_doe", "viewed_at": "..." }
  ]
}
```

---

### 📁 File Storage

#### **Upload File**
```http
POST /files/upload
Content-Type: multipart/form-data

file: <binary>
user_id: 1
file_type: avatar    // avatar, lesson_media, profile_image, document

Response: {
  "file_id": "file_abc123",
  "url": "https://storage.googleapis.com/...",
  "size_bytes": 1024000,
  "mime_type": "image/png"
}
```

#### **List Files**
```http
GET /files/?user_id=1
```

#### **Download File**
```http
GET /files/{file_id}

// Returns direct download URL or file binary
```

#### **Delete File**
```http
DELETE /files/{file_id}?user_id=1
```

---

### 🔐 Authentication

#### **Register**
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securepass123",
  "full_name": "John Doe"
}

Response: {
  "user_id": 1,
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

#### **Login**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepass123"
}

Response: {
  "user_id": 1,
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

#### **Refresh Token**
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJ..."
}
```

#### **Get Current User**
```http
GET /api/v1/auth/me
Authorization: Bearer <access_token>

Response: {
  "user_id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "full_name": "John Doe",
  "avatar_url": "...",
  "created_at": "..."
}
```

#### **Update Profile**
```http
PUT /api/v1/auth/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "full_name": "John Smith",
  "avatar_url": "...",
  "bio": "..."
}
```

---

### 🔔 Push Notifications

#### **Register Device**
```http
POST /api/v1/push/devices
Content-Type: application/json

{
  "user_id": 1,
  "device_token": "apns_token_here",
  "platform": "ios",         // ios or android
  "device_model": "iPhone 15 Pro",
  "os_version": "17.0"
}
```

#### **Update Preferences**
```http
PUT /api/v1/push/preferences
Content-Type: application/json

{
  "user_id": 1,
  "notifications_enabled": true,
  "preferences": {
    "lesson_reminders": true,
    "achievement_unlocked": true,
    "new_messages": true,
    "daily_streak": true
  }
}
```

---

### 🔍 Search & Discovery

#### **Global Search**
```http
GET /api/v1/search?q=python+loops&user_id=1

Response: {
  "users": [...],
  "courses": [...],
  "lessons": [...],
  "posts": [...]
}
```

#### **Search Autocomplete**
```http
GET /api/v1/search/suggestions?q=pyth&limit=10

Response: {
  "suggestions": [
    "python programming",
    "python for beginners",
    "python data structures"
  ]
}
```

#### **Trending Searches**
```http
GET /api/v1/search/trending?limit=20
```

---

### 👥 Community Features

#### **List Study Groups**
```http
GET /api/v1/community/study-groups?user_id=1
```

#### **Create Study Group**
```http
POST /api/v1/community/study-groups
Content-Type: application/json

{
  "name": "Python Masters",
  "description": "Advanced Python learners",
  "creator_id": 1,
  "is_private": false,
  "max_members": 50
}
```

#### **Join Group**
```http
POST /api/v1/community/study-groups/{group_id}/join
Content-Type: application/json

{
  "user_id": 1
}
```

#### **Create Event**
```http
POST /api/v1/community/events
Content-Type: application/json

{
  "title": "Python Workshop",
  "description": "Learn advanced concepts",
  "start_time": "2025-10-15T14:00:00Z",
  "duration_minutes": 120,
  "group_id": "group_123"
}
```

---

### 📊 Analytics

#### **Track Event**
```http
POST /api/v1/analytics/track
Content-Type: application/json

{
  "user_id": 1,
  "event_type": "lesson_viewed",
  "event_data": {
    "lesson_id": "lesson_123",
    "duration_seconds": 240
  }
}
```

#### **Get User Analytics**
```http
GET /api/v1/analytics/user/{user_id}?days=30

Response: {
  "total_time_minutes": 1250,
  "lessons_completed": 45,
  "average_session_minutes": 32,
  "most_active_day": "Monday",
  "engagement_trend": [...]
}
```

---

### 🛠️ System Endpoints

#### **Health Check**
```http
GET /health

Response: {
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-10-07T12:00:00Z"
}
```

#### **List Features**
```http
GET /api/v1/features

Response: {
  "features": [
    { "name": "ai_course_generation", "enabled": true },
    { "name": "real_time_chat", "enabled": true },
    { "name": "gamification", "enabled": true }
  ]
}
```

---

## 🔄 WebSocket Connections

### **1. AI Chat WebSocket**
```
wss://lyo-backend-830162750094.us-central1.run.app/api/v1/ai/ws/{user_id}
```

**Events:**
- `ai_response` - AI message response
- `ai_thinking` - AI is processing
- `ai_error` - Error occurred

### **2. Messaging WebSocket**
```
wss://lyo-backend-830162750094.us-central1.run.app/api/v1/social/messenger/ws/{user_id}
```

**Events:**
- `new_message` - New message received
- `typing` - User is typing
- `read_receipt` - Message read
- `online_status` - User online/offline

### **3. Notifications WebSocket**
```
wss://lyo-backend-830162750094.us-central1.run.app/api/v1/notifications/ws/{user_id}
```

**Events:**
- `notification` - New notification
- `badge_update` - Unread count changed

### **4. Task Progress WebSocket**
```
wss://lyo-backend-830162750094.us-central1.run.app/api/v1/ws/tasks/{task_id}
```

**Events:**
- `task_progress` - Long-running task progress
- `task_complete` - Task finished
- `task_error` - Task failed

---

## 🔑 Authentication Headers

All authenticated endpoints require:

```http
Authorization: Bearer <access_token>
```

Tokens expire after 1 hour. Use refresh token to get new access token.

---

## ⚠️ Rate Limits

- **Default**: 60 requests/minute per IP
- **AI Endpoints**: 20 requests/minute per user
- **File Uploads**: 10 requests/minute per user

Exceeded limits return `429 Too Many Requests`.

---

## 📦 Common Response Formats

### **Success**
```json
{
  "data": {...},
  "status": "success",
  "timestamp": "2025-10-07T12:00:00Z"
}
```

### **Error**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {...}
  },
  "status": "error",
  "timestamp": "2025-10-07T12:00:00Z"
}
```

---

## 🎯 Implementation Priority for LyoApp

### **Phase 1: Core Features** (Week 1)
1. ✅ Authentication (register, login, profile)
2. ✅ AI Course Generation (`/api/content/generate-course`)
3. ✅ Lesson Assembly (`/api/content/assemble-lesson`)
4. ✅ Progress Tracking

### **Phase 2: Real-Time Features** (Week 2)
1. ✅ AI Chat WebSocket
2. ✅ Messaging WebSocket
3. ✅ Push Notifications

### **Phase 3: Social Features** (Week 3)
1. ✅ Stories
2. ✅ Study Groups
3. ✅ Leaderboards

### **Phase 4: Advanced Features** (Week 4)
1. ✅ Gamification
2. ✅ Analytics
3. ✅ Search

---

## 📞 Support

- **API Issues**: Check `/docs` for latest schema
- **Health Status**: Monitor `/health` endpoint
- **WebSocket**: Ensure proper connection handling and reconnection logic

**Last Verified**: October 7, 2025
