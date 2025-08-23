# LyoApp iOS Frontend - Manual QA Verification Script

## Overview
This script verifies the course generation system with task orchestration, error handling, and user experience features implemented in LyoApp.

## Prerequisites
- iOS device or simulator with LyoApp installed
- Network connectivity for API tests
- Ability to simulate network conditions (for offline testing)

## Test Cases

### 1. Course Generation & Rendering from Core Data

**Test Case 1.1: Basic Course Generation**

1. Open CourseGenerationDemoView
2. Enter topic: "Swift Programming"
3. Enter interests: "iOS development, mobile apps, UI design"
4. Tap "Generate Course"
5. **Expected**: Progress bar shows with WebSocket real-time updates
6. **Expected**: Analytics event tracked: course_generate_requested
7. **Expected**: Task completes with course ID returned
8. **Expected**: Analytics event tracked: course_generate_ready

**Test Case 1.2: Course Generation Error Handling**

1. Disconnect from internet during course generation
2. **Expected**: WebSocket fails, automatic fallback to polling
3. **Expected**: User-friendly error message: "No internet connection. Please check your network."
4. **Expected**: Analytics event tracked: course_generate_error
5. Tap "Retry"
6. **Expected**: Returns to generating state, analytics event tracked

**Test Case 1.3: WebSocket Fallback to Polling**

1. Start course generation
2. Simulate WebSocket connection issues (network disruption)
3. **Expected**: Automatic fallback to polling after 3 missed pings
4. **Expected**: Progress continues via polling
5. **Expected**: Analytics event tracked: websocket_fallback

### 2. Task Orchestration & Progress Monitoring

**Test Case 2.1: WebSocket Real-time Updates**

1. Start course generation with stable network
2. **Expected**: WebSocket connection established
3. **Expected**: Real-time progress updates (10%, 25%, 50%, 75%, 100%)
4. **Expected**: Progress messages update dynamically
5. **Expected**: Terminal state (done/error) properly handled

**Test Case 2.2: Polling Fallback Mechanism**

1. Start course generation
2. Force WebSocket failure (network interruption)
3. **Expected**: Automatic switch to polling after timeout
4. **Expected**: Exponential backoff implemented (2s, 3.2s, 5.1s delays)
5. **Expected**: Maximum polling duration respected (10 minutes)
6. **Expected**: Progress continues smoothly

**Test Case 2.3: Task Timeout Handling**

1. Start course generation
2. Let task run for 10+ minutes without completion
3. **Expected**: Timeout error after maximum duration
4. **Expected**: User-friendly timeout message
5. **Expected**: Option to retry available

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

### 4. Analytics Integration

**Test Case 4.1: Course Generation Events**

1. Complete a full course generation cycle
2. **Expected Analytics Events**:
   - `course_generate_requested` (with task_id, provisional_course_id)
   - `course_generate_running` (with progress updates)
   - `course_generate_ready` (with result_id)

**Test Case 4.2: Error Analytics**

1. Trigger various errors during generation
2. **Expected Analytics Events**:
   - `course_generate_error` (with error details)
   - `websocket_fallback` (when WebSocket fails)
   - `retry_attempt` (when user retries)

### 5. UI/UX Validation

**Test Case 5.1: Course Generation Demo Interface**

1. Open CourseGenerationDemoView
2. **Expected**: Clean, professional interface with clear sections
3. **Expected**: Topic and interests fields properly labeled
4. **Expected**: Generate button disabled when topic is empty
5. **Expected**: Progress section shows during generation
6. **Expected**: Success section shows with course details

**Test Case 5.2: Progress Visualization**

1. Start course generation
2. **Expected**: Linear progress bar with percentage
3. **Expected**: Descriptive progress messages
4. **Expected**: Smooth progress updates (no jumping backwards)
5. **Expected**: Visual feedback for completion/error states

**Test Case 5.3: Error Display**

1. Trigger various errors
2. **Expected**: Error section with appropriate colors (red background)
3. **Expected**: Clear error messages in user-friendly language
4. **Expected**: Retry and dismiss buttons available
5. **Expected**: Error suggestions displayed when available

### 6. Performance & Resource Management

**Test Case 6.1: Memory Usage**

1. Generate multiple courses in sequence
2. **Expected**: No memory leaks from WebSocket connections
3. **Expected**: Proper cleanup of Task resources
4. **Expected**: Stable memory usage over time

**Test Case 6.2: Background Behavior**

1. Start course generation
2. Put app in background
3. Return to app
4. **Expected**: Generation continues or resumes appropriately
5. **Expected**: State properly maintained

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

### 8. Integration Testing

**Test Case 8.1: End-to-End Course Creation**

1. Complete course generation from start to finish
2. Verify course appears in library/courses list
3. **Expected**: Course data properly stored
4. **Expected**: Course accessible for learning

**Test Case 8.2: Authentication Integration**

1. Test course generation with various auth states
2. **Expected**: Proper handling of unauthenticated users
3. **Expected**: Session expiry handled gracefully
4. **Expected**: Reauthentication flow works correctly

## Pass/Fail Criteria

### ✅ PASS Requirements:
- All course generation flows complete successfully
- WebSocket + polling fallback works seamlessly
- All error messages are user-friendly
- Analytics events properly tracked
- No crashes or memory leaks
- Performance remains stable

### ❌ FAIL Conditions:
- Course generation fails without clear error message
- WebSocket fallback doesn't work
- Technical error messages shown to users
- Memory leaks or performance degradation
- App crashes during generation process
- Missing analytics events

## Reporting

For each test case, document:
1. **Status**: PASS/FAIL
2. **Actual Behavior**: What happened
3. **Screenshots**: For UI-related tests
4. **Logs**: Any relevant console output
5. **Notes**: Additional observations

## Test Environment Setup

1. Configure test backend or use mocks
2. Enable analytics logging
3. Prepare network simulation tools
4. Set up monitoring for memory/performance
5. Ensure proper device/simulator setup

---

## Notes
- This script focuses on the newly implemented course generation system
- Tests should be run in both development and production-like environments
- Consider automated testing for regression prevention
- Document any edge cases discovered during testing