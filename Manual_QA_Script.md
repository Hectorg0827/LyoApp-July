# LyoApp iOS Frontend - Manual QA Verification Script

This script outlines the manual testing steps to verify that all the implemented components work correctly according to the specification requirements.

## Prerequisites

- App installed on iOS device or simulator
- Backend server running (or mocked)
- Network connectivity for testing various scenarios

## Test Cases

### 1. Course Generation & Rendering from Core Data

**Test Case 1.1: Complete Course Generation Flow**

1. Open the Course Generation Demo view
2. Enter topic: "iOS Development"
3. Enter interests: "Swift, SwiftUI, Xcode"
4. Tap "Generate Course"
5. **Expected**: Progress indicator shows with real-time updates
6. **Expected**: WebSocket connection established, progress events received
7. **Expected**: Course transitions through states: generating → partial (if items appear) → ready
8. **Expected**: Course screen renders from Core Data with proper states
9. **Expected**: Content items display with proper icons and metadata
10. **Expected**: Analytics events tracked: course_generate_requested, course_generate_running, course_generate_ready

**Test Case 1.2: Course Generation Error Handling**

1. Trigger a server error (disconnect network or use invalid topic)
2. **Expected**: Error state displayed with user-friendly message
3. **Expected**: Retry and "Keep in Background" buttons appear
4. **Expected**: Analytics event tracked: course_generate_error
5. Tap "Retry"
6. **Expected**: Returns to generating state, analytics event tracked

**Test Case 1.3: WebSocket Fallback to Polling**

1. Start course generation
2. Simulate WebSocket connection issues (network disruption)
3. **Expected**: Automatic fallback to polling after 3 missed pings
4. **Expected**: Progress continues via polling
5. **Expected**: Analytics event tracked: websocket_fallback

### 2. Cursor Pagination for Feeds & Community

**Test Case 2.1: Feed Pagination**

1. Navigate to Feeds view
2. Scroll to bottom of initial items
3. **Expected**: Next page automatically loads
4. **Expected**: No duplicate items appear
5. **Expected**: Loading indicator shows during fetch
6. **Expected**: Stops loading when no more pages available

**Test Case 2.2: Community Pagination**

1. Navigate to Community/Discussions view
2. Scroll through multiple pages
3. **Expected**: Cursor-based pagination works correctly
4. **Expected**: De-duplication prevents duplicate discussions
5. **Expected**: Analytics events tracked: feed_page_loaded, community_page_loaded

**Test Case 2.3: Pagination Error Handling**

1. Simulate 429 rate limit on feed endpoint
2. **Expected**: User sees "Things are busy" message
3. **Expected**: Automatic retry after delay
4. **Expected**: Feed continues loading after backoff

### 3. Error Presentation & User Experience

**Test Case 3.1: Network Error Messages**

1. Disconnect from internet
2. Try to perform various actions (course generation, feed loading)
3. **Expected**: User-friendly messages: "No internet connection. Please check your network."
4. **Expected**: Appropriate retry suggestions shown

**Test Case 3.2: API Error Messages**

1. Simulate various HTTP status codes:
   - 401: **Expected**: "Session expired. Please sign in again."
   - 403: **Expected**: "You don't have access to this."
   - 404: **Expected**: "Not found."
   - 422: **Expected**: "Please check your input."
   - 429: **Expected**: "Things are busy. We'll retry automatically."
   - 500: **Expected**: "Temporary server issue. Try again shortly."

**Test Case 3.3: Error Recovery**

1. Trigger retryable error (500, timeout)
2. **Expected**: Retry button appears with appropriate suggestion
3. Tap retry
4. **Expected**: Operation retries with exponential backoff
5. **Expected**: Analytics events tracked: retry_attempt, error_recovery

### 4. Analytics Events Tracking

**Test Case 4.1: Course Generation Analytics**

1. Generate a course and verify these events are logged:
   - `course_generate_requested` (with topic, interests)
   - `course_generate_running` (with progress updates)
   - `course_generate_ready` (with task_id, course_id, duration)

**Test Case 4.2: Content Interaction Analytics**

1. Open various content items
2. **Expected**: `content_item_opened` events logged with id, type, source

**Test Case 4.3: API Error Analytics**

1. Trigger various API errors
2. **Expected**: `api_error` events logged with endpoint, method, status_code, error

### 5. Background Task Management

**Test Case 5.1: Background Course Completion**

1. Start course generation
2. Background the app for 20+ minutes (use device or simulator)
3. **Expected**: Background task scheduled
4. Return to foreground
5. **Expected**: Course completed in background
6. **Expected**: Local notification shown
7. **Expected**: Course instantly available from cache
8. **Expected**: Analytics events tracked: background_task_scheduled, background_task_completed

**Test Case 5.2: Deep Link to Completed Course**

1. Generate course in background
2. Tap push notification "Course Ready"
3. **Expected**: App opens directly to completed course
4. **Expected**: Course loads instantly from cache (< 1.5s)

### 6. WebSocket Ping/Pong & Fallback

**Test Case 6.1: WebSocket Health Monitoring**

1. Start course generation with WebSocket monitoring
2. Monitor console for ping/pong messages (every 25 seconds)
3. **Expected**: Regular ping/pong activity
4. **Expected**: Connection remains stable

**Test Case 6.2: Automatic Fallback**

1. Start course generation
2. Simulate network interruption (airplane mode toggle)
3. **Expected**: After 3 missed pings (75 seconds), fallback to polling
4. **Expected**: Progress continues seamlessly
5. **Expected**: User not aware of fallback

### 7. API Rate Limiting (429 Handling)

**Test Case 7.1: GET Request Auto-Retry**

1. Simulate 429 error on GET requests (feeds, course details)
2. **Expected**: Automatic retry after Retry-After header delay
3. **Expected**: Only one retry attempt
4. **Expected**: User sees temporary "busy" message

**Test Case 7.2: Non-GET Request Handling**

1. Simulate 429 error on POST request (course generation)
2. **Expected**: Error shown to user immediately
3. **Expected**: No automatic retry
4. **Expected**: User can manually retry

### 8. Performance & Quality Requirements

**Test Case 8.1: Course Rendering Performance**

1. Generate course with many items
2. Navigate to course view
3. **Expected**: P95 "course ready → first render" < 1.5s (from cache)
4. **Expected**: Smooth scrolling through content items

**Test Case 8.2: Feed Performance**

1. Load feed with 100+ items across multiple pages
2. **Expected**: No duplicate items across all pages
3. **Expected**: Smooth pagination with no stuttering
4. **Expected**: Memory usage stays reasonable

**Test Case 8.3: Error Resilience**

1. Generate course with malformed items in response
2. **Expected**: App never crashes
3. **Expected**: Valid items still display
4. **Expected**: Invalid items gracefully filtered out

## Test Data Setup

### Sample Topics for Course Generation:
- "Machine Learning Fundamentals"
- "iOS Development with SwiftUI"
- "Python Data Science"
- "Web Development Basics"
- "Digital Marketing Strategy"

### Sample Interests:
- ["Python", "Pandas", "Jupyter"]
- ["Swift", "iOS", "Xcode", "App Store"]
- ["React", "JavaScript", "HTML", "CSS"]
- ["Analytics", "SEO", "Social Media"]

## Success Criteria

- ✅ All test cases pass without crashes
- ✅ User-friendly error messages shown for all error conditions
- ✅ Performance metrics met (< 1.5s course render, smooth pagination)
- ✅ Analytics events properly tracked for all interactions
- ✅ Background tasks complete reliably
- ✅ WebSocket fallback works seamlessly
- ✅ Rate limiting handled gracefully
- ✅ Cursor pagination works without duplicates

## Failure Scenarios to Test

1. **Network Issues**: Airplane mode, poor connectivity, DNS issues
2. **Server Errors**: 500s, timeouts, malformed responses
3. **Rate Limiting**: Rapid API calls, concurrent requests
4. **Memory Pressure**: Large feeds, many course items
5. **Background Limits**: Long-running tasks, app suspension
6. **Edge Cases**: Empty responses, null fields, invalid data

## Debug Tools

- Console logs for analytics events
- Network debugging for API calls
- Memory profiler for performance testing
- Background task debugging
- WebSocket connection monitoring

---

**Note**: This QA script should be run on both iOS Simulator and physical device to ensure compatibility and performance across different hardware configurations.