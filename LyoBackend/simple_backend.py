#!/usr/bin/env python3
"""
Simplified LyoApp Backend for Testing
Provides essential endpoints for app functionality
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
from dotenv import load_dotenv
import google.generativeai as genai

# Load .env file
load_dotenv()

# Initialize Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if GEMINI_API_KEY and GEMINI_API_KEY != "your-gemini-api-key-here":
    genai.configure(api_key=GEMINI_API_KEY)
    print(f"✅ Gemini AI configured successfully")
else:
    print(f"⚠️  Gemini API key not configured")

app = FastAPI(title="LyoApp Backend", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class LoginRequest(BaseModel):
    email: str
    password: str

class SignUpRequest(BaseModel):
    email: str
    password: str
    name: str

class User(BaseModel):
    id: int
    email: str
    name: str
    created_at: str

class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    user: User

class AvatarMessageRequest(BaseModel):
    message: str
    session_id: Optional[str] = None

class AvatarMessageResponse(BaseModel):
    text: str
    timestamp: float
    detected_topics: Optional[List[str]] = None

class AvatarContextResponse(BaseModel):
    topics_covered: List[str]
    learning_goals: List[str]
    current_module: Optional[str] = None
    engagement_level: float
    last_interaction: float

class CourseGenerationRequest(BaseModel):
    title: str
    description: str
    targetAudience: Optional[str] = "general"
    learningObjectives: Optional[List[str]] = []
    difficultyLevel: Optional[str] = "intermediate"
    estimatedDurationHours: Optional[int] = 10

class LessonData(BaseModel):
    title: str
    description: str
    topics: List[str]
    activities: List[str]
    content_type: str = "mixed"
    outcomes: List[str]
    estimated_duration: Optional[int] = 30

class CourseOutlineData(BaseModel):
    lessons: List[LessonData]
    personalization_applied: Optional[dict] = None

class CourseGenerationResponse(BaseModel):
    task_id: str
    status: str
    user_id: Optional[int] = None
    timestamp: str
    outline: CourseOutlineData
    title: str
    description: str
    difficulty_level: str
    estimated_duration_hours: int
    target_audience: str
    learning_objectives: List[str]
    processing_time_ms: Optional[float] = None
    model_used: Optional[str] = "gemini-1.5-flash"

# Simple in-memory user storage (for testing only)
users_db = {}
sessions_db = {}

# Routes
@app.get("/api/v1/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "gemini_configured": bool(GEMINI_API_KEY and GEMINI_API_KEY != "your-gemini-api-key-here")
    }

@app.post("/api/v1/auth/signup")
async def signup(request: SignUpRequest):
    """Create a new user account"""
    if request.email in users_db:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    from datetime import datetime
    import secrets
    
    user_id = len(users_db) + 1
    user = User(
        id=user_id,
        email=request.email,
        name=request.name,
        created_at=datetime.utcnow().isoformat() + "Z"
    )
    
    users_db[request.email] = {
        "user": user,
        "password": request.password  # In production, hash this!
    }
    
    # Generate tokens
    access_token = f"token_{secrets.token_urlsafe(32)}"
    refresh_token = f"refresh_{secrets.token_urlsafe(32)}"
    
    sessions_db[access_token] = user_id
    
    print(f"✅ User signed up: {request.email}")
    
    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user
    )

@app.post("/api/v1/auth/login")
async def login(request: LoginRequest):
    """Login with email and password"""
    if request.email not in users_db:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    user_data = users_db[request.email]
    if user_data["password"] != request.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    import secrets
    
    # Generate tokens
    access_token = f"token_{secrets.token_urlsafe(32)}"
    refresh_token = f"refresh_{secrets.token_urlsafe(32)}"
    
    sessions_db[access_token] = user_data["user"].id
    
    print(f"✅ User logged in: {request.email}")
    
    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user_data["user"]
    )

@app.get("/api/v1/ai/avatar/context")
async def get_avatar_context():
    """Get AI avatar context"""
    import time
    return AvatarContextResponse(
        topics_covered=["Swift", "iOS Development", "AI Integration"],
        learning_goals=["Master SwiftUI", "Build AI-powered apps"],
        current_module="AI Avatar Integration",
        engagement_level=0.85,
        last_interaction=time.time()
    )

@app.post("/api/v1/ai/avatar/message")
async def send_avatar_message(request: AvatarMessageRequest):
    """Send message to AI avatar"""
    if not GEMINI_API_KEY or GEMINI_API_KEY == "your-gemini-api-key-here":
        # Fallback response
        import time
        return AvatarMessageResponse(
            text=f"I received your message: '{request.message}'. However, Gemini AI is not configured. Please add your API key to .env file.",
            timestamp=time.time(),
            detected_topics=["ai", "configuration"]
        )
    
    try:
        import time
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        prompt = f"""You are Lyo, a friendly AI learning assistant. Respond to this student message in a helpful, encouraging way (keep it under 100 words):

Student: {request.message}

Your response:"""
        
        response = model.generate_content(prompt)
        
        return AvatarMessageResponse(
            text=response.text.strip(),
            timestamp=time.time(),
            detected_topics=None
        )
    except Exception as e:
        import time
        print(f"❌ Error in avatar message: {e}")
        return AvatarMessageResponse(
            text=f"I'm here to help! I received: '{request.message}'",
            timestamp=time.time(),
            detected_topics=None
        )

@app.post("/api/v1/ai/generate-course")
@app.post("/api/v1/ai/curriculum/course-outline")
async def generate_course(request: CourseGenerationRequest):
    """Generate a course using Gemini AI"""
    
    if not GEMINI_API_KEY or GEMINI_API_KEY == "your-gemini-api-key-here":
        raise HTTPException(status_code=503, detail="Gemini API not configured")
    
    try:
        import time
        from datetime import datetime
        start_time = time.time()
        
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        prompt = f"""Generate a detailed course outline for: "{request.title}"

Description: {request.description}
Target Audience: {request.targetAudience}
Difficulty: {request.difficultyLevel}
Duration: {request.estimatedDurationHours} hours total
Learning Objectives: {', '.join(request.learningObjectives) if request.learningObjectives else 'General understanding'}

Please provide exactly 5 lessons. For each lesson provide:
- Title
- Description (2-3 sentences)
- 3-5 key topics
- 3-5 activities
- 2-3 learning outcomes

Format your response as:
LESSON 1:
Title: [lesson title]
Description: [lesson description]
Topics: [topic1], [topic2], [topic3]
Activities: [activity1], [activity2], [activity3]
Outcomes: [outcome1], [outcome2]

LESSON 2:
...
"""
        
        response = model.generate_content(prompt)
        text = response.text
        
        # Parse response
        lessons = []
        current_lesson = {}
        
        for line in text.strip().split('\n'):
            line = line.strip()
            if line.startswith("LESSON"):
                if current_lesson:
                    lessons.append(current_lesson)
                current_lesson = {}
            elif line.startswith("Title:"):
                current_lesson['title'] = line.replace("Title:", "").strip()
            elif line.startswith("Description:"):
                current_lesson['description'] = line.replace("Description:", "").strip()
            elif line.startswith("Topics:"):
                topics_str = line.replace("Topics:", "").strip()
                current_lesson['topics'] = [t.strip() for t in topics_str.split(',')]
            elif line.startswith("Activities:"):
                activities_str = line.replace("Activities:", "").strip()
                current_lesson['activities'] = [a.strip() for a in activities_str.split(',')]
            elif line.startswith("Outcomes:"):
                outcomes_str = line.replace("Outcomes:", "").strip()
                current_lesson['outcomes'] = [o.strip() for o in outcomes_str.split(',')]
        
        if current_lesson:
            lessons.append(current_lesson)
        
        # Ensure we have lessons
        if not lessons or len(lessons) < 3:
            # Fallback lessons
            lessons = []
            for i in range(5):
                lessons.append({
                    'title': f"{request.title} - Part {i + 1}",
                    'description': f"Learn key concepts about {request.title}",
                    'topics': [f"Topic {j+1}" for j in range(3)],
                    'activities': [f"Activity {j+1}" for j in range(3)],
                    'outcomes': [f"Outcome {j+1}" for j in range(2)]
                })
        
        # Create LessonData objects
        lesson_data_list = []
        for lesson in lessons[:5]:  # Take first 5
            lesson_data_list.append(LessonData(
                title=lesson.get('title', 'Untitled Lesson'),
                description=lesson.get('description', 'Learn key concepts'),
                topics=lesson.get('topics', ['Topic 1', 'Topic 2']),
                activities=lesson.get('activities', ['Activity 1', 'Activity 2']),
                content_type="mixed",
                outcomes=lesson.get('outcomes', ['Outcome 1']),
                estimated_duration=int(request.estimatedDurationHours * 60 / 5)  # Divide hours by lessons
            ))
        
        outline = CourseOutlineData(
            lessons=lesson_data_list,
            personalization_applied=None
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        course_response = CourseGenerationResponse(
            task_id=f"course_{int(time.time())}",
            status="completed",
            user_id=None,
            timestamp=datetime.utcnow().isoformat() + "Z",
            outline=outline,
            title=request.title,
            description=request.description,
            difficulty_level=request.difficultyLevel,
            estimated_duration_hours=request.estimatedDurationHours,
            target_audience=request.targetAudience,
            learning_objectives=request.learningObjectives or [],
            processing_time_ms=processing_time,
            model_used="gemini-1.5-flash"
        )
        
        print(f"✅ Generated course: {request.title}")
        return course_response
        
    except Exception as e:
        print(f"❌ Error generating course: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Failed to generate course: {str(e)}")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "LyoApp Backend API",
        "docs": "/docs",
        "health": "/api/v1/health"
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting simplified LyoApp Backend...")
    print("📊 API docs: http://localhost:8000/docs")
    print("💚 Health: http://localhost:8000/api/v1/health")
    uvicorn.run(app, host="0.0.0.0", port=8000)
