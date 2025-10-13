#!/bin/bash

# ============================================================================
# LyoApp - Complete Mock Data Elimination Script
# This script removes ALL mock data and replaces with real backend integration
# ============================================================================

set -e  # Exit on error

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  LyoApp - Complete Mock Data Elimination & Backend Setup  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

PROJECT_DIR="/Users/hectorgarcia/Desktop/LyoApp July"
cd "$PROJECT_DIR"

# ============================================================================
# Step 1: Search for all mock data
# ============================================================================
echo -e "${YELLOW}Step 1: Scanning for mock data...${NC}"
echo ""

MOCK_FILES=(
    "LyoApp/Views/SearchView.swift"
    "LyoApp/AIOnboardingFlowView.swift"
    "LyoApp/ProfessionalMessengerView.swift"
    "LyoApp/Services/RealTimeNotificationManager.swift"
)

echo "Found mock data in the following files:"
for file in "${MOCK_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${RED}✗${NC} $file"
    fi
done
echo ""

# ============================================================================
# Step 2: Create backup
# ============================================================================
echo -e "${YELLOW}Step 2: Creating backup...${NC}"
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for file in "${MOCK_FILES[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/"
        echo -e "  ${GREEN}✓${NC} Backed up: $file"
    fi
done
echo ""

# ============================================================================
# Step 3: List all files that need modification
# ============================================================================
echo -e "${YELLOW}Step 3: Files requiring real backend integration:${NC}"
echo ""

echo "📝 Files with mock data to remove:"
echo "  1. SearchView.swift (4 mock functions)"
echo "  2. AIOnboardingFlowView.swift (1 mock function)"
echo "  3. ProfessionalMessengerView.swift (2 mock functions)"
echo "  4. RealTimeNotificationManager.swift (1 mock array)"
echo ""

echo "🔧 Files that need new real backend services:"
echo "  • RealSearchService.swift (NEW - for search functionality)"
echo "  • RealMessengerService.swift (NEW - for messenger)"
echo "  • RealNotificationService.swift (ENHANCE - remove mock data)"
echo "  • RealCourseService.swift (NEW - for course recommendations)"
echo ""

# ============================================================================
# Step 4: Verify backend connectivity
# ============================================================================
echo -e "${YELLOW}Step 4: Verifying backend connectivity...${NC}"
BACKEND_URL="https://lyo-backend-830162750094.us-central1.run.app"

echo -n "Testing health endpoint... "
if curl -s --max-time 5 "$BACKEND_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
    
    # Get backend status
    HEALTH_DATA=$(curl -s "$BACKEND_URL/health")
    echo "$HEALTH_DATA" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_DATA"
else
    echo -e "${RED}✗ Failed${NC}"
    echo "⚠️  Backend may be offline. Proceeding anyway..."
fi
echo ""

# ============================================================================
# Step 5: Summary of changes needed
# ============================================================================
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     CHANGES REQUIRED                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

cat << 'EOF'
┌─────────────────────────────────────────────────────────────┐
│ 1. SearchView.swift                                         │
├─────────────────────────────────────────────────────────────┤
│   REMOVE:                                                   │
│   • generateMockSearchResults()                             │
│   • generateMockUserResults()                               │
│   • generateMockPostResults()                               │
│   • generateMockCourseResults()                             │
│                                                             │
│   REPLACE WITH:                                             │
│   • RealSearchService.shared.searchAll(query)               │
│   • RealSearchService.shared.searchUsers(query)             │
│   • RealSearchService.shared.searchPosts(query)             │
│   • RealSearchService.shared.searchCourses(query)           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 2. AIOnboardingFlowView.swift                               │
├─────────────────────────────────────────────────────────────┤
│   REMOVE:                                                   │
│   • generateMockCourse()                                    │
│                                                             │
│   REPLACE WITH:                                             │
│   • RealCourseService.shared.getCourseRecommendations()     │
│   • Handle API errors with proper error UI                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 3. ProfessionalMessengerView.swift                          │
├─────────────────────────────────────────────────────────────┤
│   REMOVE:                                                   │
│   • generateMockConversations()                             │
│   • generateMockMessages()                                  │
│                                                             │
│   REPLACE WITH:                                             │
│   • RealMessengerService.shared.getConversations()          │
│   • RealMessengerService.shared.getMessages(conversationId) │
│   • WebSocket integration for real-time messages           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 4. RealTimeNotificationManager.swift                        │
├─────────────────────────────────────────────────────────────┤
│   REMOVE:                                                   │
│   • mockNotifications array                                 │
│                                                             │
│   REPLACE WITH:                                             │
│   • Load from /api/v1/notifications endpoint                │
│   • WebSocket integration for real-time notifications       │
└─────────────────────────────────────────────────────────────┘

EOF

echo ""
echo -e "${GREEN}✅ Scan complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "  1. Review the backup in: $BACKUP_DIR"
echo "  2. Run the Copilot tool to apply all changes"
echo "  3. Build and test the app"
echo "  4. Verify NO mock data appears"
echo ""
echo -e "${BLUE}Ready to proceed? Run Copilot to apply all changes.${NC}"
echo ""

# ============================================================================
# Step 6: Generate detailed change log
# ============================================================================
cat > MOCK_DATA_ELIMINATION_PLAN.md << 'ENDPLAN'
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

ENDPLAN

echo -e "${GREEN}✅ Elimination plan generated: MOCK_DATA_ELIMINATION_PLAN.md${NC}"
echo ""
echo "🚀 All preparations complete. Ready to eliminate mock data!"
