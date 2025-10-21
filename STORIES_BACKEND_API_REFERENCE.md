# Stories Backend API Reference - Google Cloud Run

## Base Configuration

```swift
// From APIConfig.swift
static let baseURL = "YOUR_GRC_URL"  // e.g., https://lyoapp-api-xxxxx-uc.a.run.app
static let requestTimeout: TimeInterval = 30
static let uploadTimeout: TimeInterval = 60
```

---

## Authentication

All API requests require Bearer token authentication:

```http
Authorization: Bearer {token}
```

Token is retrieved from:
```swift
AuthenticationService.shared.currentToken
```

---

## API Endpoints

### 1. Fetch All Stories

Retrieves stories for the authenticated user's feed (from followed users + own stories).

**Request:**
```http
GET /api/v1/stories
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "stories": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user": {
        "id": "user-uuid",
        "username": "johndoe",
        "displayName": "John Doe",
        "profilePicture": "https://storage.googleapis.com/...",
        "isVerified": true
      },
      "segments": [
        {
          "id": "segment-uuid",
          "type": "photo",
          "mediaURL": "https://storage.googleapis.com/...",
          "duration": 5.0,
          "backgroundColor": null,
          "text": null,
          "textColor": null
        }
      ],
      "createdAt": "2025-01-15T10:30:00Z",
      "expiresAt": "2025-01-16T10:30:00Z",
      "isViewed": false,
      "viewCount": 42
    }
  ],
  "count": 10
}
```

**Swift Model:**
```swift
struct StoriesResponse: Codable {
    let stories: [StoryContent]
    let count: Int
}
```

---

### 2. Fetch User Stories

Retrieves all stories from a specific user.

**Request:**
```http
GET /api/v1/stories/user/:userId
Authorization: Bearer {token}
```

**Parameters:**
- `userId` (path) - UUID of the user

**Response (200 OK):**
```json
{
  "stories": [...],
  "count": 3
}
```

---

### 3. Create Story

Creates a new story with one or more segments. Media files must be uploaded first (see Upload Media endpoint).

**Request:**
```http
POST /api/v1/stories
Authorization: Bearer {token}
Content-Type: application/json
```

**Body:**
```json
{
  "segments": [
    {
      "id": "segment-uuid-1",
      "type": "photo",
      "mediaURL": "https://storage.googleapis.com/lyoapp-stories/abc123.jpg",
      "duration": 5.0,
      "backgroundColor": null,
      "text": null,
      "textColor": null
    },
    {
      "id": "segment-uuid-2",
      "type": "text",
      "mediaURL": null,
      "duration": 5.0,
      "backgroundColor": "#6C5CE7",
      "text": "Hello World!",
      "textColor": "#FFFFFF"
    }
  ]
}
```

**Segment Types:**
- `photo` - Still image (requires `mediaURL`)
- `video` - Video clip (requires `mediaURL`)
- `text` - Text-only (requires `text`, `backgroundColor`, `textColor`)

**Response (201 Created):**
```json
{
  "story": {
    "id": "new-story-uuid",
    "user": {...},
    "segments": [...],
    "createdAt": "2025-01-15T11:00:00Z",
    "expiresAt": "2025-01-16T11:00:00Z",
    "isViewed": false,
    "viewCount": 0
  },
  "message": "Story created successfully"
}
```

**Swift Model:**
```swift
struct CreateStoryRequest: Codable {
    let segments: [StorySegment]
}

struct StoryResponse: Codable {
    let story: StoryContent
    let message: String?
}
```

---

### 4. Upload Media File

Uploads a photo or video file to cloud storage. Returns the URL to use in Create Story request.

**Request:**
```http
POST /api/v1/stories/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary
```

**Multipart Body:**
```
------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="story.jpg"
Content-Type: image/jpeg

{binary image data}
------WebKitFormBoundary
Content-Disposition: form-data; name="type"

photo
------WebKitFormBoundary--
```

**Parameters:**
- `file` (file) - Binary image/video data
- `type` (string) - "photo" or "video"

**Response (200 OK):**
```json
{
  "url": "https://storage.googleapis.com/lyoapp-stories/550e8400-e29b-41d4.jpg",
  "filename": "550e8400-e29b-41d4.jpg"
}
```

**Swift Implementation:**
```swift
func uploadMedia(fileURL: URL, type: StorySegmentType) async throws -> URL {
    let url = baseURL.appendingPathComponent("/api/v1/stories/upload")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addAuthHeader(token: authToken)
    
    // Create multipart body
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", 
                     forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // Add file data
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"story.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(try Data(contentsOf: fileURL))
    body.append("\r\n".data(using: .utf8)!)
    
    // Add type field
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
    body.append(type.rawValue.data(using: .utf8)!)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    let (data, response) = try await URLSession.shared.data(for: request)
    let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
    return uploadResponse.url
}
```

---

### 5. Mark Story as Viewed

Records that the current user has viewed a specific story.

**Request:**
```http
POST /api/v1/stories/:storyId/view
Authorization: Bearer {token}
```

**Parameters:**
- `storyId` (path) - UUID of the story

**Response (200 OK):**
```
(Empty body)
```

**Backend Logic:**
- Create record in `story_views` table
- Increment `view_count` on story
- Do NOT create duplicate view records (same user + story)
- Update `viewed_at` timestamp if view already exists

---

### 6. Add Reaction to Story

Adds an emoji reaction to a story.

**Request:**
```http
POST /api/v1/stories/:storyId/reactions
Authorization: Bearer {token}
Content-Type: application/json
```

**Parameters:**
- `storyId` (path) - UUID of the story

**Body:**
```json
{
  "emoji": "❤️"
}
```

**Supported Emojis:**
- ❤️ Heart
- 🔥 Fire
- 😂 Laughing
- 😮 Surprised
- 😢 Sad
- 👏 Clapping

**Response (200 OK):**
```
(Empty body)
```

**Backend Logic:**
- Create record in `story_reactions` table
- Allow multiple reactions from same user (different emojis)
- Store `reacted_at` timestamp
- Optionally send push notification to story creator

---

### 7. Reply to Story (via DM)

Sends a direct message reply to a story creator.

**Request:**
```http
POST /api/v1/stories/:storyId/reply
Authorization: Bearer {token}
Content-Type: application/json
```

**Parameters:**
- `storyId` (path) - UUID of the story

**Body:**
```json
{
  "message": "Love this!"
}
```

**Response (200 OK):**
```
(Empty body)
```

**Backend Logic:**
- Create record in `story_replies` table
- Create or update DM conversation between viewer and creator
- Add message to conversation thread
- Include story reference in message metadata
- Send push notification to story creator
- Mark conversation as unread for creator

---

### 8. Get Story Analytics

Retrieves detailed analytics for a story (only accessible by story creator).

**Request:**
```http
GET /api/v1/stories/:storyId/analytics
Authorization: Bearer {token}
```

**Parameters:**
- `storyId` (path) - UUID of the story

**Response (200 OK):**
```json
{
  "storyId": "550e8400-e29b-41d4-a716-446655440000",
  "viewCount": 142,
  "viewers": [
    {
      "userId": "viewer-uuid-1",
      "username": "janedoe",
      "viewedAt": "2025-01-15T11:05:00Z"
    },
    {
      "userId": "viewer-uuid-2",
      "username": "bobsmith",
      "viewedAt": "2025-01-15T11:10:00Z"
    }
  ],
  "reactions": [
    {
      "userId": "reactor-uuid-1",
      "username": "alice",
      "emoji": "❤️",
      "reactedAt": "2025-01-15T11:06:00Z"
    },
    {
      "userId": "reactor-uuid-2",
      "username": "charlie",
      "emoji": "🔥",
      "reactedAt": "2025-01-15T11:12:00Z"
    }
  ],
  "replyCount": 8
}
```

**Swift Model:**
```swift
struct StoryAnalytics: Codable {
    let storyId: UUID
    let viewCount: Int
    let viewers: [StoryViewer]
    let reactions: [StoryReaction]
    let replyCount: Int
}

struct StoryViewer: Codable {
    let userId: UUID
    let username: String
    let viewedAt: Date
}

struct StoryReaction: Codable {
    let userId: UUID
    let username: String
    let emoji: String
    let reactedAt: Date
}
```

**Authorization:**
- Only story creator can access analytics
- Return `403 Forbidden` if requester is not creator

---

### 9. Delete Story

Deletes a story (only accessible by story creator).

**Request:**
```http
DELETE /api/v1/stories/:storyId
Authorization: Bearer {token}
```

**Parameters:**
- `storyId` (path) - UUID of the story

**Response (204 No Content):**
```
(Empty body)
```

**Backend Logic:**
- Verify requester is story creator (403 if not)
- Delete all related records:
  - Story segments
  - Story views
  - Story reactions
  - Story replies
- Delete media files from cloud storage
- Return 204 on success

---

### 10. Add Story to Highlights

Saves a story to user's profile highlights (permanent).

**Request:**
```http
POST /api/v1/stories/:storyId/highlight
Authorization: Bearer {token}
Content-Type: application/json
```

**Parameters:**
- `storyId` (path) - UUID of the story

**Body:**
```json
{
  "name": "Travel"
}
```

**Highlight Names Examples:**
- "Travel"
- "Food"
- "Friends"
- "Workouts"
- "Art"

**Response (200 OK):**
```
(Empty body)
```

**Backend Logic:**
- Create record in `story_highlights` table
- Link story to user's profile
- Story remains visible even after 24-hour expiration
- Remove `expires_at` timestamp for highlighted story
- Organize by highlight name/category

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid request",
  "message": "Missing required field: segments"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

### 403 Forbidden
```json
{
  "error": "Forbidden",
  "message": "You do not have permission to access this resource"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Story not found"
}
```

### 413 Payload Too Large
```json
{
  "error": "File too large",
  "message": "Maximum file size is 50MB"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

---

## Swift Error Handling

```swift
enum StoriesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case uploadFailed
    case viewUpdateFailed
    case reactionFailed
    case replyFailed
    case analyticsFailed
    case deleteFailed
    case highlightFailed
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error (\(statusCode))"
        case .uploadFailed:
            return "Failed to upload media"
        case .viewUpdateFailed:
            return "Failed to mark story as viewed"
        case .reactionFailed:
            return "Failed to add reaction"
        case .replyFailed:
            return "Failed to send reply"
        case .analyticsFailed:
            return "Failed to fetch analytics"
        case .deleteFailed:
            return "Failed to delete story"
        case .highlightFailed:
            return "Failed to add to highlights"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        }
    }
}
```

---

## Rate Limiting

Recommended rate limits:

- **Create Story:** 20 per hour per user
- **Upload Media:** 50 per hour per user
- **Mark Viewed:** 100 per hour per user
- **Add Reaction:** 50 per hour per user
- **Reply to Story:** 30 per hour per user
- **Fetch Stories:** 100 per hour per user

**Rate Limit Response (429 Too Many Requests):**
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again in 15 minutes.",
  "retryAfter": 900
}
```

---

## Media Specifications

### Photos
- **Format:** JPEG, PNG
- **Max Size:** 10 MB
- **Max Dimensions:** 1920x1080 px
- **Compression:** Applied server-side

### Videos
- **Format:** MP4, MOV
- **Max Size:** 50 MB
- **Max Duration:** 30 seconds
- **Max Dimensions:** 1920x1080 px
- **Compression:** Applied server-side

### Text Stories
- **Max Length:** 500 characters
- **Font:** System default
- **Colors:** 15 predefined options (see StoryCreationView.swift)

---

## Google Cloud Storage Configuration

**Bucket Name:** `lyoapp-stories`

**File Naming Convention:**
```
{uuid}.{extension}
Example: 550e8400-e29b-41d4-a716-446655440000.jpg
```

**Public Access:** Yes (read-only)

**Lifecycle Policy:**
- Delete files older than 30 days
- Auto-delete when story is deleted

**CORS Configuration:**
```json
[
  {
    "origin": ["*"],
    "method": ["GET"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

---

## Testing with cURL

### Fetch Stories
```bash
curl -X GET \
  https://YOUR_GRC_URL/api/v1/stories \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Story (Text Only)
```bash
curl -X POST \
  https://YOUR_GRC_URL/api/v1/stories \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "segments": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "type": "text",
        "text": "Hello World!",
        "backgroundColor": "#6C5CE7",
        "textColor": "#FFFFFF",
        "duration": 5.0
      }
    ]
  }'
```

### Upload Photo
```bash
curl -X POST \
  https://YOUR_GRC_URL/api/v1/stories/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/photo.jpg" \
  -F "type=photo"
```

### Add Reaction
```bash
curl -X POST \
  https://YOUR_GRC_URL/api/v1/stories/550e8400-e29b-41d4-a716-446655440000/reactions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"emoji": "❤️"}'
```

---

## Backend Implementation Checklist

### Phase 1: Core Endpoints
- [ ] GET /api/v1/stories (fetch stories)
- [ ] POST /api/v1/stories (create story)
- [ ] POST /api/v1/stories/upload (upload media)
- [ ] POST /api/v1/stories/:id/view (mark viewed)
- [ ] DELETE /api/v1/stories/:id (delete story)

### Phase 2: Social Features
- [ ] POST /api/v1/stories/:id/reactions (reactions)
- [ ] POST /api/v1/stories/:id/reply (replies)
- [ ] GET /api/v1/stories/:id/analytics (analytics)

### Phase 3: Advanced Features
- [ ] POST /api/v1/stories/:id/highlight (highlights)
- [ ] GET /api/v1/stories/user/:userId (user stories)

### Database Setup
- [ ] Create `stories` table
- [ ] Create `story_segments` table
- [ ] Create `story_views` table
- [ ] Create `story_reactions` table
- [ ] Create `story_replies` table
- [ ] Create `story_highlights` table
- [ ] Add foreign key constraints
- [ ] Add indexes for performance

### Cloud Storage
- [ ] Create GCS bucket
- [ ] Configure CORS
- [ ] Set lifecycle policies
- [ ] Configure public read access
- [ ] Test file upload
- [ ] Test file retrieval

### Security
- [ ] Implement JWT token validation
- [ ] Add rate limiting
- [ ] Sanitize user input
- [ ] Validate file types
- [ ] Check file sizes
- [ ] Prevent duplicate views/reactions

### Testing
- [ ] Unit tests for each endpoint
- [ ] Integration tests
- [ ] Load testing
- [ ] Error handling tests
- [ ] Authentication tests

---

## Summary

This API provides complete backend support for:
- ✅ Story creation (photo/video/text)
- ✅ Media file upload to Google Cloud Storage
- ✅ Story viewing and tracking
- ✅ Social features (reactions, replies)
- ✅ Analytics for story creators
- ✅ Story deletion and highlights
- ✅ Bearer token authentication
- ✅ Comprehensive error handling

**Total Endpoints:** 9  
**Authentication:** Bearer Token  
**Storage:** Google Cloud Storage  
**Database:** PostgreSQL (recommended) or MySQL

---

**Last Updated:** October 15, 2025  
**API Version:** 1.0  
**Status:** ✅ Documented - Ready for Implementation
