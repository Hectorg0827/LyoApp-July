# Mock Data Elimination Plan

## Overview
This document outlines the complete removal of all mock data from LyoApp and replacement with real backend API integration.

## Files to Modify

### 1. SearchView.swift
**Location:** `LyoApp/Views/SearchView.swift`

**Current State:**
- Uses 4 mock data generation functions
- Returns hardcoded search results
- No real backend integration

**Required Changes:**
```swift
// REMOVE these functions:
private func generateMockSearchResults() -> SearchResults { ... }
private func generateMockUserResults() -> SearchResults { ... }
private func generateMockPostResults() -> SearchResults { ... }
private func generateMockCourseResults() -> SearchResults { ... }

// REPLACE WITH:
@StateObject private var searchService = RealSearchService.shared

func performSearch() async {
    await searchService.search(query: searchText)
    searchResults = searchService.results
}
```

**New Service Required:** `RealSearchService.swift`

---

### 2. AIOnboardingFlowView.swift
**Location:** `LyoApp/AIOnboardingFlowView.swift`

**Current State:**
- Falls back to mock course when API fails
- Hardcoded course data

**Required Changes:**
```swift
// REMOVE:
private func generateMockCourse() { ... }

// REPLACE WITH:
private func loadCourseRecommendations() async {
    do {
        let courses = try await APIClient.shared.fetchLearningResources()
        // Use real course data
    } catch {
        // Show error UI, DO NOT fallback to mock
        showError = true
    }
}
```

---

### 3. ProfessionalMessengerView.swift
**Location:** `LyoApp/ProfessionalMessengerView.swift`

**Current State:**
- Uses mock conversations and messages
- No real backend integration

**Required Changes:**
```swift
// REMOVE:
private func generateMockConversations() -> [MessengerConversation] { ... }
private func generateMockMessages(for conversationId: String) -> [ProfessionalMessengerMessage] { ... }

// REPLACE WITH:
@StateObject private var messengerService = RealMessengerService.shared

func loadConversations() async {
    await messengerService.loadConversations()
    conversations = messengerService.conversations
}

func loadMessages(for conversationId: String) async {
    await messengerService.loadMessages(conversationId: conversationId)
    messages = messengerService.messages
}
```

**New Service Required:** `RealMessengerService.swift`

---

### 4. RealTimeNotificationManager.swift
**Location:** `LyoApp/Services/RealTimeNotificationManager.swift`

**Current State:**
- Contains mockNotifications array
- Not loading from backend

**Required Changes:**
```swift
// REMOVE:
let mockNotifications = [ ... ]

// REPLACE WITH:
func loadNotifications() async {
    do {
        let response = try await APIClient.shared.getNotifications()
        self.notifications = response.notifications
    } catch {
        print("Failed to load notifications: \(error)")
    }
}
```

---

## New Services to Create

### RealSearchService.swift
```swift
import Foundation

@MainActor
class RealSearchService: ObservableObject {
    static let shared = RealSearchService()
    
    @Published var results: SearchResults?
    @Published var isLoading = false
    @Published var error: Error?
    
    func search(query: String) async {
        // Call /api/v1/search endpoint
    }
    
    func searchUsers(query: String) async {
        // Call /api/v1/search/users endpoint
    }
    
    func searchPosts(query: String) async {
        // Call /api/v1/search/posts endpoint
    }
    
    func searchCourses(query: String) async {
        // Call /api/v1/search/courses endpoint
    }
}
```

### RealMessengerService.swift
```swift
import Foundation

@MainActor
class RealMessengerService: ObservableObject {
    static let shared = RealMessengerService()
    
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    func loadConversations() async {
        // Call /api/v1/messages/conversations endpoint
    }
    
    func loadMessages(conversationId: String) async {
        // Call /api/v1/messages/\(conversationId) endpoint
    }
    
    func sendMessage(to conversationId: String, text: String) async {
        // Call POST /api/v1/messages endpoint
    }
}
```

### RealCourseService.swift
```swift
import Foundation

@MainActor
class RealCourseService: ObservableObject {
    static let shared = RealCourseService()
    
    @Published var courses: [Course] = []
    @Published var isLoading = false
    
    func loadCourses(query: String? = nil) async {
        // Call /api/v1/courses endpoint
    }
    
    func getCourseRecommendations() async {
        // Call /api/v1/courses/recommendations endpoint
    }
}
```

---

## Backend Endpoints Required

### Search Endpoints
- `GET /api/v1/search?q={query}` - Global search
- `GET /api/v1/search/users?q={query}` - Search users
- `GET /api/v1/search/posts?q={query}` - Search posts
- `GET /api/v1/search/courses?q={query}` - Search courses

### Messenger Endpoints
- `GET /api/v1/messages/conversations` - Get user conversations
- `GET /api/v1/messages/{conversationId}` - Get messages
- `POST /api/v1/messages` - Send message
- `WebSocket /ws/messages` - Real-time messages

### Notification Endpoints
- `GET /api/v1/notifications` - Get notifications
- `POST /api/v1/notifications/{id}/read` - Mark as read
- `WebSocket /ws/notifications` - Real-time notifications

### Course Endpoints (Already exist)
- `GET /api/v1/courses` - Get courses
- `GET /api/v1/courses/recommendations` - Get recommendations

---

## Testing Checklist

After implementing all changes:

- [ ] Search functionality returns real results
- [ ] No mock users appear in search
- [ ] No mock posts appear in search
- [ ] AI onboarding loads real courses
- [ ] Messenger shows real conversations
- [ ] Messages are sent/received via backend
- [ ] Notifications load from backend
- [ ] WebSocket connections work for real-time features
- [ ] App shows error UI when backend is unreachable
- [ ] NO mock data fallbacks anywhere

---

## Verification Commands

```bash
# Search for any remaining mock data
grep -r "mock\|Mock\|MOCK\|sample.*Data\|generate.*Mock" \
  --include="*.swift" LyoApp/ || echo "✅ No mock data found"

# Verify backend connectivity
curl https://lyo-backend-830162750094.us-central1.run.app/health

# Test authentication
curl -X POST https://lyo-backend-830162750094.us-central1.run.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@lyoapp.com", "password": "Demo123!"}'
```

---

## Success Criteria

✅ **Complete when:**
1. All mock data functions removed
2. All views use real backend services
3. Proper error handling for backend failures
4. WebSocket integration for real-time features
5. App builds and runs successfully
6. Manual testing confirms NO mock data appears
7. Backend connectivity verified

---

**Status:** Ready for implementation
**Estimated Time:** 2-3 hours
**Priority:** CRITICAL - Production Blocker

