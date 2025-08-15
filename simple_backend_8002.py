#!/usr/bin/env python3
"""
Professional-Grade LyoApp Backend
Enhanced with Messenger, AI Search, and Library functionality
"""

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import uvicorn
import json
import datetime
from uuid import uuid4

app = FastAPI(title="LyoApp Professional Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# === DATA MODELS ===

class LoginRequest(BaseModel):
    email: str
    password: str

class Message(BaseModel):
    id: str = None
    sender_id: str
    recipient_id: str
    content: str
    message_type: str = "text"  # text, image, video, file
    timestamp: str = None
    is_read: bool = False

class Conversation(BaseModel):
    id: str
    participants: List[str]
    last_message: Optional[Message] = None
    updated_at: str
    is_group: bool = False
    name: Optional[str] = None

class SearchQuery(BaseModel):
    query: str
    filters: Optional[Dict[str, Any]] = None
    limit: int = 20

class SearchResult(BaseModel):
    id: str
    title: str
    description: str
    content_type: str  # course, video, article, user
    url: Optional[str] = None
    relevance_score: float
    metadata: Dict[str, Any] = {}

class LibraryItem(BaseModel):
    id: str
    title: str
    description: str
    content_type: str  # course, video, article, bookmark
    url: Optional[str] = None
    tags: List[str] = []
    saved_at: str
    progress: float = 0.0  # 0-1 completion percentage
    metadata: Dict[str, Any] = {}

class SaveItemRequest(BaseModel):
    content_id: str
    content_type: str
    title: str
    description: Optional[str] = None
    url: Optional[str] = None

# === IN-MEMORY DATA STORAGE ===

# Mock data storage (replace with database in production)
users_db = {
    "1": {"id": "1", "name": "John Doe", "email": "john@example.com", "avatar_url": "https://i.pravatar.cc/150?img=1"},
    "2": {"id": "2", "name": "Jane Smith", "email": "jane@example.com", "avatar_url": "https://i.pravatar.cc/150?img=2"},
    "3": {"id": "3", "name": "Mike Johnson", "email": "mike@example.com", "avatar_url": "https://i.pravatar.cc/150?img=3"},
}

conversations_db = {}
messages_db = {}
library_db = {}

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket

    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]

    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections.values():
            await connection.send_text(message)

manager = ConnectionManager()

# === BASIC ENDPOINTS ===

@app.get("/api/v1/health")
async def health():
    return {
        "status": "healthy",
        "message": "LyoApp Professional Backend is running",
        "timestamp": datetime.datetime.now().isoformat(),
        "features": ["messenger", "ai_search", "library", "real_time_chat"]
    }

@app.post("/api/v1/auth/login")
async def login(request: LoginRequest):
    # Simple authentication (replace with proper auth in production)
    user_id = "1"  # Default user for demo
    user = users_db.get(user_id)
    
    return {
        "token": f"jwt_token_{uuid4()}",
        "user": user,
        "expires_in": 3600
    }

# === MESSENGER ENDPOINTS ===

@app.get("/api/v1/messenger/conversations")
async def get_conversations(user_id: str = "1"):
    """Get all conversations for a user"""
    user_conversations = [
        conv for conv in conversations_db.values() 
        if user_id in conv.get("participants", [])
    ]
    return {"conversations": user_conversations}

@app.get("/api/v1/messenger/conversations/{conversation_id}/messages")
async def get_messages(conversation_id: str, limit: int = 50):
    """Get messages for a specific conversation"""
    conv_messages = [
        msg for msg in messages_db.values()
        if msg.get("conversation_id") == conversation_id
    ]
    # Sort by timestamp
    conv_messages.sort(key=lambda x: x.get("timestamp", ""))
    return {"messages": conv_messages[-limit:]}

@app.post("/api/v1/messenger/conversations/{conversation_id}/messages")
async def send_message(conversation_id: str, message: Message):
    """Send a message in a conversation"""
    message_id = str(uuid4())
    message_data = {
        "id": message_id,
        "conversation_id": conversation_id,
        "sender_id": message.sender_id,
        "content": message.content,
        "message_type": message.message_type,
        "timestamp": datetime.datetime.now().isoformat(),
        "is_read": False
    }
    
    messages_db[message_id] = message_data
    
    # Send real-time notification via WebSocket
    await manager.send_personal_message(
        json.dumps({"type": "new_message", "data": message_data}),
        message.recipient_id
    )
    
    return {"message": message_data, "status": "sent"}

@app.post("/api/v1/messenger/conversations")
async def create_conversation(participants: List[str], name: Optional[str] = None):
    """Create a new conversation"""
    conv_id = str(uuid4())
    conversation = {
        "id": conv_id,
        "participants": participants,
        "name": name,
        "is_group": len(participants) > 2,
        "created_at": datetime.datetime.now().isoformat(),
        "updated_at": datetime.datetime.now().isoformat()
    }
    
    conversations_db[conv_id] = conversation
    return {"conversation": conversation}

# === AI-POWERED SEARCH ENDPOINTS ===

@app.post("/api/v1/search")
async def ai_search(search_request: SearchQuery):
    """AI-powered intelligent search"""
    query = search_request.query.lower()
    
    # Mock AI search results with relevance scoring
    mock_results = [
        {
            "id": f"course_{uuid4()}",
            "title": f"Advanced {query.title()} Programming",
            "description": f"Master {query} with hands-on projects and real-world applications",
            "content_type": "course",
            "url": f"/courses/advanced-{query}",
            "relevance_score": 0.95,
            "metadata": {
                "duration": "6 hours",
                "difficulty": "intermediate",
                "rating": 4.8,
                "instructor": "Dr. Sarah Johnson"
            }
        },
        {
            "id": f"video_{uuid4()}",
            "title": f"{query.title()} Fundamentals Explained",
            "description": f"A comprehensive video tutorial covering {query} basics",
            "content_type": "video",
            "url": f"/videos/{query}-fundamentals",
            "relevance_score": 0.87,
            "metadata": {
                "duration": "45 minutes",
                "views": 12500,
                "rating": 4.6
            }
        },
        {
            "id": f"article_{uuid4()}",
            "title": f"Best Practices for {query.title()}",
            "description": f"Industry-standard practices and tips for {query}",
            "content_type": "article",
            "url": f"/articles/{query}-best-practices",
            "relevance_score": 0.82,
            "metadata": {
                "read_time": "8 minutes",
                "author": "Alex Chen",
                "published": "2024-01-15"
            }
        }
    ]
    
    return {
        "query": search_request.query,
        "results": mock_results[:search_request.limit],
        "total_results": len(mock_results),
        "search_time_ms": 145
    }

@app.get("/api/v1/search/suggestions")
async def get_search_suggestions(q: str):
    """Get AI-powered search suggestions"""
    suggestions = [
        f"{q} fundamentals",
        f"{q} advanced techniques",
        f"{q} best practices",
        f"{q} tutorial",
        f"{q} certification"
    ]
    return {"suggestions": suggestions[:5]}

# === LIBRARY ENDPOINTS ===

@app.get("/api/v1/library")
async def get_library(user_id: str = "1", category: Optional[str] = None):
    """Get user's saved library content"""
    user_library = [
        item for item in library_db.values()
        if item.get("user_id") == user_id
    ]
    
    if category and category != "all":
        user_library = [
            item for item in user_library
            if item.get("content_type") == category
        ]
    
    # Sort by saved date (most recent first)
    user_library.sort(key=lambda x: x.get("saved_at", ""), reverse=True)
    
    return {
        "library": user_library,
        "categories": ["all", "courses", "videos", "articles", "bookmarks"],
        "total_items": len(user_library)
    }

@app.post("/api/v1/library/save")
async def save_to_library(save_request: SaveItemRequest, user_id: str = "1"):
    """Save content to user's library"""
    item_id = str(uuid4())
    library_item = {
        "id": item_id,
        "user_id": user_id,
        "content_id": save_request.content_id,
        "title": save_request.title,
        "description": save_request.description,
        "content_type": save_request.content_type,
        "url": save_request.url,
        "saved_at": datetime.datetime.now().isoformat(),
        "progress": 0.0,
        "tags": [],
        "metadata": {}
    }
    
    library_db[item_id] = library_item
    
    return {"item": library_item, "status": "saved"}

@app.delete("/api/v1/library/{item_id}")
async def remove_from_library(item_id: str, user_id: str = "1"):
    """Remove item from user's library"""
    if item_id in library_db and library_db[item_id].get("user_id") == user_id:
        del library_db[item_id]
        return {"status": "removed"}
    
    raise HTTPException(status_code=404, detail="Library item not found")

@app.put("/api/v1/library/{item_id}/progress")
async def update_progress(item_id: str, progress: float, user_id: str = "1"):
    """Update progress for a library item"""
    if item_id in library_db and library_db[item_id].get("user_id") == user_id:
        library_db[item_id]["progress"] = max(0.0, min(1.0, progress))
        return {"status": "updated", "progress": library_db[item_id]["progress"]}
    
    raise HTTPException(status_code=404, detail="Library item not found")

# === REAL-TIME WEBSOCKET ===

@app.websocket("/api/v1/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for real-time features"""
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Handle different message types
            if message_data.get("type") == "heartbeat":
                await websocket.send_text(json.dumps({"type": "heartbeat_ack"}))
            elif message_data.get("type") == "typing":
                # Broadcast typing status to conversation participants
                await manager.broadcast(json.dumps({
                    "type": "user_typing",
                    "user_id": user_id,
                    "conversation_id": message_data.get("conversation_id")
                }))
            
    except WebSocketDisconnect:
        manager.disconnect(user_id)

# === AI AVATAR CONTEXT ===

@app.get("/api/v1/ai/avatar/context")
async def get_avatar_context():
    return {
        "contextId": f"ctx_{uuid4()}",
        "personalityType": "friendly_tutor", 
        "currentTopic": "Getting Started",
        "difficulty": "beginner",
        "userProgress": {
            "completedLessons": 0,
            "currentStreak": 1,
            "totalHours": 0.5
        },
        "capabilities": [
            "natural_conversation",
            "personalized_learning",
            "progress_tracking",
            "real_time_assistance"
        ]
    }

# === AUTHENTICATION & USER MANAGEMENT ===

@app.post("/api/v1/auth/register")
async def register_user(user_data: dict):
    # Simple registration for demo purposes
    user_id = str(len(users_db) + 1)
    new_user = {
        "id": user_id,
        "username": user_data.get("username", f"user_{user_id}"),
        "email": user_data.get("email", f"user{user_id}@example.com"),
        "name": user_data.get("name", f"User {user_id}"),
        "avatar": user_data.get("avatar", "https://api.dicebear.com/7.x/avataaars/svg?seed=default"),
        "bio": user_data.get("bio", "New LyoApp user"),
        "created_at": "2024-01-01T00:00:00Z"
    }
    users_db[user_id] = new_user
    
    return {
        "success": True,
        "message": "User registered successfully",
        "token": f"token_{user_id}",
        "user": new_user
    }

@app.get("/api/v1/users/me")
async def get_current_user(authorization: str = None):
    # Extract user from token (simplified for demo)
    user_id = "1"  # Default user for demo
    user = users_db.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": user["id"],
        "username": user["username"],
        "email": user["email"],
        "name": user["name"],
        "avatar": user["avatar"],
        "bio": user["bio"],
        "preferences": {
            "learning_style": "visual",
            "difficulty_level": "intermediate",
            "notification_settings": {
                "daily_reminders": True,
                "progress_updates": True
            }
        },
        "stats": {
            "total_courses": 12,
            "completed_courses": 3,
            "learning_streak": 7,
            "total_learning_time": 156.5
        }
    }

# === LEARNING RESOURCES ===

# Mock learning resources data
learning_resources_db = [
    {
        "id": "lr_1",
        "title": "Introduction to Swift Programming",
        "description": "Learn the fundamentals of Swift programming language",
        "type": "course",
        "category": "Programming",
        "difficulty": "beginner",
        "duration": 120,
        "thumbnail": "https://example.com/swift-thumb.jpg",
        "tags": ["swift", "ios", "programming"],
        "rating": 4.8,
        "instructor": "Apple Developer Team",
        "lessons": [
            {"id": "lesson_1", "title": "Variables and Constants", "duration": 15},
            {"id": "lesson_2", "title": "Functions and Closures", "duration": 20},
            {"id": "lesson_3", "title": "Classes and Structures", "duration": 25}
        ]
    },
    {
        "id": "lr_2", 
        "title": "SwiftUI Fundamentals",
        "description": "Build beautiful iOS apps with SwiftUI",
        "type": "course",
        "category": "Mobile Development",
        "difficulty": "intermediate",
        "duration": 180,
        "thumbnail": "https://example.com/swiftui-thumb.jpg",
        "tags": ["swiftui", "ios", "ui"],
        "rating": 4.9,
        "instructor": "iOS Experts",
        "lessons": [
            {"id": "lesson_4", "title": "Views and Modifiers", "duration": 30},
            {"id": "lesson_5", "title": "State Management", "duration": 35},
            {"id": "lesson_6", "title": "Navigation", "duration": 25}
        ]
    },
    {
        "id": "lr_3",
        "title": "Data Structures & Algorithms",
        "description": "Master fundamental data structures and algorithms",
        "type": "course",
        "category": "Computer Science",
        "difficulty": "advanced",
        "duration": 240,
        "thumbnail": "https://example.com/algorithms-thumb.jpg",
        "tags": ["algorithms", "data-structures", "programming"],
        "rating": 4.7,
        "instructor": "CS Professors",
        "lessons": [
            {"id": "lesson_7", "title": "Arrays and Linked Lists", "duration": 40},
            {"id": "lesson_8", "title": "Trees and Graphs", "duration": 45},
            {"id": "lesson_9", "title": "Sorting Algorithms", "duration": 35}
        ]
    }
]

@app.get("/api/v1/learning-resources")
async def get_learning_resources(
    category: str = None,
    difficulty: str = None,
    search: str = None,
    limit: int = 20,
    offset: int = 0
):
    resources = learning_resources_db.copy()
    
    # Apply filters
    if category:
        resources = [r for r in resources if r["category"].lower() == category.lower()]
    if difficulty:
        resources = [r for r in resources if r["difficulty"].lower() == difficulty.lower()]
    if search:
        search_lower = search.lower()
        resources = [r for r in resources if 
                    search_lower in r["title"].lower() or 
                    search_lower in r["description"].lower() or
                    any(search_lower in tag for tag in r["tags"])]
    
    # Apply pagination
    total = len(resources)
    resources = resources[offset:offset + limit]
    
    return {
        "resources": resources,
        "total": total,
        "limit": limit,
        "offset": offset,
        "has_more": offset + limit < total
    }

@app.get("/api/v1/learning-resources/{resource_id}")
async def get_learning_resource_details(resource_id: str):
    resource = next((r for r in learning_resources_db if r["id"] == resource_id), None)
    if not resource:
        raise HTTPException(status_code=404, detail="Learning resource not found")
    
    # Add additional details for specific resource
    detailed_resource = resource.copy()
    detailed_resource.update({
        "enrollment_count": 1250,
        "completion_rate": 0.78,
        "prerequisites": ["Basic programming knowledge"],
        "learning_outcomes": [
            "Understand core programming concepts",
            "Build practical projects",
            "Prepare for advanced topics"
        ],
        "reviews": [
            {
                "id": "review_1",
                "user": "Alex Johnson",
                "rating": 5,
                "comment": "Excellent course structure and clear explanations!",
                "date": "2024-01-15"
            }
        ]
    })
    
    return detailed_resource

# === USER PROGRESS TRACKING ===

# Mock user progress data
user_progress_db = [
    {
        "id": "progress_1",
        "user_id": "1",
        "resource_id": "lr_1",
        "progress": 0.65,
        "time_spent": 78.5,
        "completed_lessons": ["lesson_1", "lesson_2"],
        "current_lesson": "lesson_3",
        "last_accessed": "2024-01-20T15:30:00Z",
        "is_completed": False,
        "notes": "Great course so far, loving the hands-on examples"
    },
    {
        "id": "progress_2", 
        "user_id": "1",
        "resource_id": "lr_2",
        "progress": 0.33,
        "time_spent": 45.2,
        "completed_lessons": ["lesson_4"],
        "current_lesson": "lesson_5",
        "last_accessed": "2024-01-19T10:15:00Z",
        "is_completed": False,
        "notes": "SwiftUI is really intuitive"
    }
]

@app.get("/api/v1/users/progress")
async def get_user_progress(user_id: str = "1"):
    progress = [p for p in user_progress_db if p["user_id"] == user_id]
    return progress

@app.post("/api/v1/users/progress")
async def save_user_progress(progress_data: dict):
    # Create new progress entry
    progress_id = f"progress_{len(user_progress_db) + 1}"
    new_progress = {
        "id": progress_id,
        "user_id": progress_data.get("user_id", "1"),
        "resource_id": progress_data["resource_id"],
        "progress": progress_data.get("progress", 0.0),
        "time_spent": progress_data.get("time_spent", 0.0),
        "completed_lessons": progress_data.get("completed_lessons", []),
        "current_lesson": progress_data.get("current_lesson"),
        "last_accessed": progress_data.get("last_accessed", "2024-01-20T15:30:00Z"),
        "is_completed": progress_data.get("is_completed", False),
        "notes": progress_data.get("notes", "")
    }
    
    # Update existing progress or add new
    existing_index = next((i for i, p in enumerate(user_progress_db) 
                          if p["user_id"] == new_progress["user_id"] and 
                             p["resource_id"] == new_progress["resource_id"]), None)
    
    if existing_index is not None:
        user_progress_db[existing_index] = new_progress
    else:
        user_progress_db.append(new_progress)
    
    return {
        "success": True,
        "message": "Progress saved successfully",
        "progress": new_progress
    }

# === RECOMMENDATIONS ===

@app.get("/api/v1/recommendations")
async def get_recommendations(user_id: str = "1", limit: int = 10):
    # Simple recommendation logic based on user progress and preferences
    user_progress = [p for p in user_progress_db if p["user_id"] == user_id]
    completed_categories = set()
    
    # Get categories from completed or in-progress courses
    for progress in user_progress:
        resource = next((r for r in learning_resources_db if r["id"] == progress["resource_id"]), None)
        if resource:
            completed_categories.add(resource["category"])
    
    # Recommend resources from similar categories or next difficulty level
    recommendations = []
    for resource in learning_resources_db:
        # Skip if already in progress
        if any(p["resource_id"] == resource["id"] for p in user_progress):
            continue
            
        # Recommend based on category similarity or progression
        if (resource["category"] in completed_categories or 
            resource["difficulty"] == "beginner" or
            len(recommendations) < limit):
            recommendations.append(resource)
        
        if len(recommendations) >= limit:
            break
    
    return recommendations

if __name__ == "__main__":
    print("🚀 Starting LyoApp Professional Backend on http://localhost:8000")
    print("📱 Features: Professional Messenger, AI Search, Smart Library")
    print("🔗 WebSocket: ws://localhost:8000/api/v1/ws/{user_id}")
    print("📚 API Docs: http://localhost:8000/docs")
    uvicorn.run(app, host="0.0.0.0", port=8002)
