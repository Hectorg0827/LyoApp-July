# 🎓 Dynamic AI Classroom System - Architecture & Implementation

**Date**: October 16, 2025  
**Status**: Design Complete - Ready to Implement  
**Complexity**: Advanced (Multi-agent Backend Coordination)  

---

## 🎯 Vision

```
User selects course → AI generates dynamic classroom environment
                    ↓
            Classroom setting matches subject
            (Maya ruins, Mars base, Chemistry lab, etc.)
                    ↓
            Avatar adapts to environment
            Quiz adapts to setting
            Interactions change dynamically
                    ↓
            Each lesson is unique immersive experience
```

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────┐
│                     LyoApp UI (SwiftUI)                        │
│                                                                │
│  Course Selection → Dynamic Classroom Generator               │
└────────────────────┬───────────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  ClassroomDynamicService│ (NEW)
        │  (Coordinates generation)│
        └────────────┬────────────┘
                     │
      ┌──────────────┼──────────────┬──────────────┐
      │              │              │              │
      ▼              ▼              ▼              ▼
   ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌────────────┐
   │Content  │ │3D Scene  │ │AI Tutor   │ │Quiz Engine │
   │Service  │ │Generator │ │Generator  │ │Generator   │
   │(Backend)│ │(Backend) │ │(Backend)  │ │(Backend)   │
   └─────────┘ └──────────┘ └───────────┘ └────────────┘
      │              │              │              │
      └──────────────┼──────────────┴──────────────┘
                     │
         ┌───────────▼──────────┐
         │  Unified Response    │
         │  (Scene + Quiz +     │
         │   Avatar behavior)   │
         └──────────────────────┘
                     │
        ┌────────────▼────────────┐
        │ Display in Classroom UI │
        │ (Unity or SwiftUI)      │
        └─────────────────────────┘
```

---

## 🔄 Data Flow: Course to Classroom

### **Step 1: User Selects Course**
```json
{
  "courseId": "history-001",
  "title": "Ancient Civilizations - Maya",
  "subject": "history",
  "topic": "maya_civilization",
  "timeperiod": "1000 BCE - 1600 CE",
  "difficulty": "intermediate",
  "userId": "user-123"
}
```

### **Step 2: Backend Classroom Generator Activates**
```json
REQUEST: POST /api/v1/classroom/generate
{
  "courseId": "history-001",
  "subject": "history",
  "context": "maya_civilization",
  "difficulty": "intermediate"
}
```

### **Step 3: Backend Generates Dynamic Classroom**

**3D Scene Specification:**
```json
{
  "environment": {
    "setting": "maya_city_center",
    "location": "Tikal, Guatemala",
    "timeperiod": "1200 CE",
    "weather": "humid_tropical",
    "lighting": "morning_sun",
    "atmosphere": "ceremonial"
  },
  "scene_objects": [
    {
      "type": "pyramid",
      "name": "Temple of the Great Jaguar",
      "position": "center",
      "interactive": true,
      "trivia": "Built around 732 CE, height 65 meters"
    },
    {
      "type": "marketplace",
      "name": "Central Plaza",
      "position": "foreground",
      "npcs": ["merchant", "priest", "artisan"],
      "activities": ["trade", "learning", "craftsmanship"]
    }
  ],
  "avatar_context": {
    "role": "maya_historian",
    "appearance": "traditional_maya_clothing",
    "accent": "yucatec_maya_influenced",
    "knowledge_domain": "maya_civilization"
  }
}
```

**AI Tutor Customization:**
```json
{
  "tutor_personality": "wise_elder_maya",
  "teaching_style": "storytelling_immersive",
  "language_flavor": "maya_terms_translated",
  "teaching_topics": [
    "maya_calendar_system",
    "hieroglyphic_writing",
    "architectural_innovation",
    "religious_beliefs",
    "agriculture_terrace_farming"
  ],
  "interaction_style": "context_aware",
  "engagement_objects": [
    "calendar_stone",
    "codex_replica",
    "hieroglyph_translator"
  ]
}
```

**Subject-Specific Quiz Engine:**
```json
{
  "quiz_type": "immersive_contextual",
  "setting_context": "maya_civilization_1200CE",
  "question_templates": [
    {
      "type": "artifact_identification",
      "template": "This {object} was used for {purpose}. What can you tell me about it?",
      "objects": ["calendar_stone", "jade_pendant", "limestone_carving"],
      "answers_grading": "contextual_accuracy"
    },
    {
      "type": "historical_event",
      "template": "In {time_period}, the Maya {event}. Why was this significant?",
      "time_periods": ["early_classic", "late_classic", "post_classic"],
      "answers_grading": "impact_understanding"
    },
    {
      "type": "cultural_inference",
      "template": "Based on {artifact}, what can we infer about Maya {aspect}?",
      "artifacts": ["architecture", "art", "writing"],
      "answers_grading": "analytical_reasoning"
    }
  ]
}
```

### **Step 4: App Receives Classroom Configuration**
```json
RESPONSE 200 OK:
{
  "classroomId": "classroom-maya-001",
  "scene": { ... },
  "avatar": { ... },
  "quiz": { ... },
  "sessionToken": "token-xyz",
  "ttl": 3600
}
```

### **Step 5: Display Classroom to User**
- Unity scene loads with Maya temple environment
- Avatar appears as Maya historian
- Interactive objects in environment
- Contextual quiz questions

---

## 📋 Implementation Files Required

### **Backend Services** (Must exist on your backend)

1. **ClassroomDynamicService** (NEW)
   - Coordinates dynamic generation
   - Validates course-to-classroom mapping
   - Caches generated configurations

2. **ContentGenerator** (EXTEND)
   - Generate 3D environment specifications
   - Create scene configurations per subject
   - Asset mapping (which 3D models to load)

3. **TutorGenerator** (EXTEND)
   - Generate AI tutor personalities
   - Subject-aware response generation
   - Context-sensitive dialogue

4. **QuizGenerator** (EXTEND)
   - Generate quizzes per subject/environment
   - Create contextual questions
   - Grade responses with context awareness

### **iOS/Swift Files** (NEW)

1. **DynamicClassroomManager.swift**
2. **ClassroomEnvironmentConfig.swift**
3. **SubjectContextMapper.swift**
4. **DynamicQuizView.swift**
5. **ClassroomResponseHandler.swift**

---

## 🎨 Subject-to-Environment Mapping

```swift
// This defines how courses map to classroom environments

let subjectEnvironmentMap: [String: ClassroomEnvironment] = [
    // HISTORY
    "history_ancient_maya": ClassroomEnvironment(
        setting: .mayaTemple,
        location: "Tikal, Guatemala",
        period: "1200 CE",
        avatar: .mayaHistorian,
        atmosphere: .ceremonial
    ),
    
    "history_ancient_egypt": ClassroomEnvironment(
        setting: .egyptianTemple,
        location: "Giza, Egypt",
        period: "2500 BCE",
        avatar: .egyptianScribe,
        atmosphere: .monumental
    ),
    
    "history_viking_age": ClassroomEnvironment(
        setting: .vikingLonghouse,
        location: "Scandinavia",
        period: "800-1066 CE",
        avatar: .vikingWarrior,
        atmosphere: .maritime
    ),
    
    // SCIENCE
    "science_chemistry": ClassroomEnvironment(
        setting: .chemistryLab,
        location: "Modern Laboratory",
        period: "present",
        avatar: .chemist,
        atmosphere: .experimental
    ),
    
    "science_astronomy": ClassroomEnvironment(
        setting: .spaceObservatory,
        location: "Near Earth Orbit",
        period: "future",
        avatar: .astronomer,
        atmosphere: .cosmic
    ),
    
    "science_mars_exploration": ClassroomEnvironment(
        setting: .marsBase,
        location: "Mars - Jezero Crater",
        period: "2045",
        avatar: .marsGeologist,
        atmosphere: .alien_desert
    ),
    
    "science_biology_rainforest": ClassroomEnvironment(
        setting: .rainforest,
        location: "Amazon Rainforest",
        period: "present",
        avatar: .biologist,
        atmosphere: .organic_vibrant
    ),
    
    // BUSINESS
    "business_ancient_trading": ClassroomEnvironment(
        setting: .silkRoadMarket,
        location: "Silk Road Junction",
        period: "1200 CE",
        avatar: .merchantTrader,
        atmosphere: .bustling_marketplace
    ),
    
    // ARTS
    "arts_renaissance": ClassroomEnvironment(
        setting: .renaissanceStudio,
        location: "Florence, Italy",
        period: "1500 CE",
        avatar: .renaissanceArtist,
        atmosphere: .creative_studio
    ),
    
    // LANGUAGES
    "language_ancient_greek": ClassroomEnvironment(
        setting: .greeceAthens,
        location: "Ancient Athens",
        period: "400 BCE",
        avatar: .greekPhilosopher,
        atmosphere: .academic_agora
    )
]
```

---

## 🔧 Swift Implementation

### **File 1: DynamicClassroomManager.swift**

```swift
import Foundation
import Combine

@MainActor
class DynamicClassroomManager: ObservableObject {
    static let shared = DynamicClassroomManager()
    
    @Published var classroomConfig: DynamicClassroomConfig?
    @Published var isGenerating = false
    @Published var error: String?
    @Published var currentEnvironment: ClassroomEnvironment?
    @Published var tutorPersonality: TutorPersonality?
    @Published var contextualQuiz: ContextualQuiz?
    
    private let apiClient = APIClient.shared
    private let environmentMapper = SubjectContextMapper.shared
    
    // MARK: - Generate Dynamic Classroom
    
    func generateClassroomForCourse(_ course: Course) async {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Map course to environment
            let environment = try await environmentMapper.mapCourseToEnvironment(course)
            self.currentEnvironment = environment
            
            // Request classroom generation from backend
            let config = try await requestClassroomGeneration(
                courseId: course.id.uuidString,
                subject: course.subject,
                topic: course.topic,
                environment: environment
            )
            
            self.classroomConfig = config
            self.tutorPersonality = config.tutorPersonality
            self.contextualQuiz = config.quiz
            
            print("✅ Classroom generated: \(config.classroomId)")
            print("📍 Environment: \(environment.setting)")
            print("👨‍🎓 Tutor: \(config.tutorPersonality.role)")
            
        } catch {
            print("❌ Classroom generation failed: \(error)")
            self.error = "Failed to generate classroom: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Backend Request
    
    private func requestClassroomGeneration(
        courseId: String,
        subject: String,
        topic: String,
        environment: ClassroomEnvironment
    ) async throws -> DynamicClassroomConfig {
        
        let payload = ClassroomGenerationRequest(
            courseId: courseId,
            subject: subject,
            topic: topic,
            environment: environment.rawConfiguration,
            difficulty: "intermediate"
        )
        
        let config = try await apiClient.post(
            endpoint: "/api/v1/classroom/generate",
            body: payload,
            responseType: DynamicClassroomConfig.self
        )
        
        return config
    }
    
    // MARK: - Submit Quiz Answer (Context-Aware)
    
    func submitQuizAnswer(questionId: String, answer: String) async {
        guard let quiz = contextualQuiz else { return }
        
        do {
            let response = try await apiClient.post(
                endpoint: "/api/v1/classroom/\(classroomConfig?.classroomId ?? "")/quiz/answer",
                body: [
                    "questionId": questionId,
                    "answer": answer,
                    "environmentContext": currentEnvironment?.setting ?? "",
                    "timestamp": Date().timeIntervalSince1970
                ] as [String: Any],
                responseType: QuizGradingResponse.self
            )
            
            print("📊 Answer graded: \(response.score)/100")
            print("💬 Feedback: \(response.contextualFeedback)")
            
        } catch {
            print("❌ Failed to submit answer: \(error)")
        }
    }
}

// MARK: - Data Models

struct DynamicClassroomConfig: Codable {
    let classroomId: String
    let scene: SceneConfiguration
    let avatar: AvatarConfiguration
    let tutorPersonality: TutorPersonality
    let quiz: ContextualQuiz
    let sessionToken: String
    let ttl: Int
    
    enum CodingKeys: String, CodingKey {
        case classroomId = "classroom_id"
        case scene, avatar
        case tutorPersonality = "tutor_personality"
        case quiz
        case sessionToken = "session_token"
        case ttl
    }
}

struct SceneConfiguration: Codable {
    let setting: String
    let location: String
    let timePeriod: String
    let weather: String
    let lighting: String
    let atmosphere: String
    let sceneObjects: [SceneObject]
    
    enum CodingKeys: String, CodingKey {
        case setting, location
        case timePeriod = "time_period"
        case weather, lighting, atmosphere
        case sceneObjects = "scene_objects"
    }
}

struct SceneObject: Codable {
    let type: String
    let name: String
    let position: String
    let interactive: Bool
    let trivia: String?
    let modelId: String?
    
    enum CodingKeys: String, CodingKey {
        case type, name, position, interactive, trivia
        case modelId = "model_id"
    }
}

struct AvatarConfiguration: Codable {
    let role: String
    let appearance: String
    let accent: String?
    let knowledgeDomain: String
    let behaviorProfile: String
    
    enum CodingKeys: String, CodingKey {
        case role, appearance, accent
        case knowledgeDomain = "knowledge_domain"
        case behaviorProfile = "behavior_profile"
    }
}

struct TutorPersonality: Codable {
    let personality: String
    let teachingStyle: String
    let languageFlavor: String
    let engagementLevel: String
    let subjectExpertise: String
    
    enum CodingKeys: String, CodingKey {
        case personality
        case teachingStyle = "teaching_style"
        case languageFlavor = "language_flavor"
        case engagementLevel = "engagement_level"
        case subjectExpertise = "subject_expertise"
    }
    
    var role: String {
        personality.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct ContextualQuiz: Codable {
    let quizType: String
    let settingContext: String
    let questions: [ContextualQuestion]
    let maxScore: Int
    
    enum CodingKeys: String, CodingKey {
        case quizType = "quiz_type"
        case settingContext = "setting_context"
        case questions
        case maxScore = "max_score"
    }
}

struct ContextualQuestion: Codable, Identifiable {
    let id: String
    let questionText: String
    let questionType: String
    let context: String
    let timeLimit: Int
    let scoringRubric: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionText = "question_text"
        case questionType = "question_type"
        case context
        case timeLimit = "time_limit"
        case scoringRubric = "scoring_rubric"
    }
}

struct QuizGradingResponse: Codable {
    let score: Int
    let contextualFeedback: String
    let nextQuestion: ContextualQuestion?
    let hints: [String]
    
    enum CodingKeys: String, CodingKey {
        case score
        case contextualFeedback = "contextual_feedback"
        case nextQuestion = "next_question"
        case hints
    }
}

struct ClassroomGenerationRequest: Codable {
    let courseId: String
    let subject: String
    let topic: String
    let environment: [String: Any]
    let difficulty: String
    
    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case subject, topic, environment, difficulty
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(courseId, forKey: .courseId)
        try container.encode(subject, forKey: .subject)
        try container.encode(topic, forKey: .topic)
        try container.encode(difficulty, forKey: .difficulty)
    }
}
```

### **File 2: SubjectContextMapper.swift**

```swift
import Foundation

@MainActor
class SubjectContextMapper {
    static let shared = SubjectContextMapper()
    
    private let environmentMappings: [String: ClassroomEnvironmentConfig] = [
        // HISTORY
        "history_maya": ClassroomEnvironmentConfig(
            setting: "maya_ceremonial_center",
            location: "Tikal, Guatemala",
            timeperiod: "1200 CE",
            avatarRole: "maya_elder_historian",
            weatherSystem: "tropical_humid",
            architectureStyle: "maya_pyramids",
            culturalElements: ["calendar_stone", "hieroglyphic_codex", "jade_artifacts"]
        ),
        
        "history_egypt": ClassroomEnvironmentConfig(
            setting: "egyptian_temple",
            location: "Giza Plateau, Egypt",
            timeperiod: "2500 BCE",
            avatarRole: "egyptian_high_priest",
            weatherSystem: "arid_desert",
            architectureStyle: "egyptian_monumental",
            culturalElements: ["pyramid", "hieroglyphics", "scarab_seals"]
        ),
        
        "history_rome": ClassroomEnvironmentConfig(
            setting: "roman_forum",
            location: "Rome, Italy",
            timeperiod: "27 CE",
            avatarRole: "roman_senator",
            weatherSystem: "mediterranean",
            architectureStyle: "roman_classical",
            culturalElements: ["columns", "aqueducts", "togas"]
        ),
        
        // SCIENCE - CHEMISTRY
        "science_chemistry": ClassroomEnvironmentConfig(
            setting: "modern_chemistry_lab",
            location: "State-of-the-art Laboratory",
            timeperiod: "present",
            avatarRole: "chemistry_professor",
            weatherSystem: "controlled_climate",
            architectureStyle: "laboratory_modern",
            culturalElements: ["beakers", "periodic_table", "molecular_models"]
        ),
        
        // SCIENCE - SPACE
        "science_mars": ClassroomEnvironmentConfig(
            setting: "mars_habitation_base",
            location: "Jezero Crater, Mars",
            timeperiod: "2045",
            avatarRole: "mars_geologist",
            weatherSystem: "martian_dust_storm",
            architectureStyle: "futuristic_habitat",
            culturalElements: ["rover", "habitat_dome", "geology_tools"]
        ),
        
        "science_astronomy": ClassroomEnvironmentConfig(
            setting: "space_observatory",
            location: "Earth Orbit",
            timeperiod: "2030",
            avatarRole: "astrophysicist",
            weatherSystem: "cosmic_void",
            architectureStyle: "space_station",
            culturalElements: ["telescope", "star_charts", "satellites"]
        ),
        
        // SCIENCE - BIOLOGY
        "science_biology_rainforest": ClassroomEnvironmentConfig(
            setting: "amazon_rainforest",
            location: "Amazon Rainforest, Brazil",
            timeperiod: "present",
            avatarRole: "rainforest_biologist",
            weatherSystem: "tropical_humid",
            architectureStyle: "organic_natural",
            culturalElements: ["exotic_plants", "wildlife", "ecosystem_models"]
        ),
        
        "science_marine_biology": ClassroomEnvironmentConfig(
            setting: "underwater_lab",
            location: "Deep Ocean, Atlantic",
            timeperiod: "present",
            avatarRole: "marine_biologist",
            weatherSystem: "underwater_currents",
            architectureStyle: "submersible_lab",
            culturalElements: ["submarines", "deep_sea_creatures", "pressure_chambers"]
        ),
        
        // BUSINESS
        "business_silk_road": ClassroomEnvironmentConfig(
            setting: "silk_road_trading_post",
            location: "Samarkand, Uzbekistan",
            timeperiod: "1200 CE",
            avatarRole: "silk_road_merchant",
            weatherSystem: "desert_oasis",
            architectureStyle: "silk_road_bazaar",
            culturalElements: ["caravans", "spices", "trade_routes"]
        ),
        
        // LANGUAGES
        "language_ancient_greek": ClassroomEnvironmentConfig(
            setting: "ancient_greek_agora",
            location: "Athens, Greece",
            timeperiod: "400 BCE",
            avatarRole: "greek_philosopher",
            weatherSystem: "mediterranean",
            architectureStyle: "greek_classical",
            culturalElements: ["scrolls", "marble_columns", "forum"]
        ),
        
        "language_mandarin": ClassroomEnvironmentConfig(
            setting: "imperial_chinese_palace",
            location: "Forbidden City, Beijing",
            timeperiod: "1800 CE",
            avatarRole: "imperial_scholar",
            weatherSystem: "moderate",
            architectureStyle: "imperial_chinese",
            culturalElements: ["calligraphy", "silk_scrolls", "tea_ceremony"]
        )
    ]
    
    func mapCourseToEnvironment(_ course: Course) async throws -> ClassroomEnvironment {
        let key = "\(course.subject)_\(course.topic)".lowercased()
        
        guard let config = environmentMappings[key] else {
            // Fallback to generic environment
            return ClassroomEnvironment(
                setting: "classroom_generic",
                location: "Learning Center",
                timeperiod: "present",
                avatarRole: "subject_expert",
                atmosphere: .neutral
            )
        }
        
        return ClassroomEnvironment(
            setting: config.setting,
            location: config.location,
            timeperiod: config.timeperiod,
            avatarRole: config.avatarRole,
            atmosphere: .immersive,
            weather: config.weatherSystem,
            culturalElements: config.culturalElements
        )
    }
}

struct ClassroomEnvironmentConfig {
    let setting: String
    let location: String
    let timeperiod: String
    let avatarRole: String
    let weatherSystem: String
    let architectureStyle: String
    let culturalElements: [String]
}

struct ClassroomEnvironment {
    let setting: String
    let location: String
    let timeperiod: String
    let avatarRole: String
    let atmosphere: AtmosphereType
    let weather: String?
    let culturalElements: [String]?
    
    var rawConfiguration: [String: Any] {
        [
            "setting": setting,
            "location": location,
            "timeperiod": timeperiod,
            "avatar_role": avatarRole,
            "atmosphere": atmosphere.rawValue,
            "weather": weather ?? "default",
            "cultural_elements": culturalElements ?? []
        ]
    }
}

enum AtmosphereType: String {
    case ceremonial
    case academic
    case experimental
    case cosmic
    case immersive
    case neutral
}
```

### **File 3: DynamicClassroomView.swift**

```swift
import SwiftUI

struct DynamicClassroomView: View {
    @StateObject var manager = DynamicClassroomManager.shared
    @State private var showQuiz = false
    @State private var currentAnswerText = ""
    @State private var selectedQuestion: ContextualQuestion?
    
    let course: Course
    
    var body: some View {
        ZStack {
            // Background - Environment-specific
            environmentBackground
            
            VStack {
                // Header with environment info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(manager.currentEnvironment?.location ?? "Loading...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(manager.currentEnvironment?.timeperiod ?? "")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Avatar introduction
                    if let tutor = manager.tutorPersonality {
                        VStack(alignment: .trailing) {
                            Text("Your Tutor")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(tutor.role)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Main classroom content
                ScrollView {
                    VStack(spacing: 20) {
                        // Course title
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                        
                        // Environment description
                        if let environment = manager.currentEnvironment {
                            EnvironmentCard(environment: environment)
                                .padding()
                        }
                        
                        // Teaching content placeholder
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Lesson")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Your AI tutor will teach you about \(course.title) in an immersive, interactive environment.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(3)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                        .padding()
                        
                        // Start learning button
                        Button(action: { showQuiz = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Interactive Lesson")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            
            // Loading overlay
            if manager.isGenerating {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Generating your classroom...")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }
        }
        .sheet(isPresented: $showQuiz) {
            DynamicQuizView(
                quiz: manager.contextualQuiz,
                manager: manager,
                environment: manager.currentEnvironment
            )
        }
        .onAppear {
            Task {
                await manager.generateClassroomForCourse(course)
            }
        }
    }
    
    @ViewBuilder
    private var environmentBackground: some View {
        let setting = manager.currentEnvironment?.setting ?? ""
        
        switch setting {
        case "maya_ceremonial_center":
            Image("maya_temple_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
        case "mars_habitation_base":
            Image("mars_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.red.opacity(0.3)
        
        case "modern_chemistry_lab":
            Image("lab_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        
        default:
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Environment Card

struct EnvironmentCard: View {
    let environment: ClassroomEnvironment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(environment.location)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(environment.timeperiod)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Cultural elements
            if let elements = environment.culturalElements, !elements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Elements")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(elements.prefix(5), id: \.self) { element in
                            Badge(text: element)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .border(Color.white.opacity(0.3), width: 1)
    }
}

// MARK: - Dynamic Quiz View

struct DynamicQuizView: View {
    let quiz: ContextualQuiz?
    let manager: DynamicClassroomManager
    let environment: ClassroomEnvironment?
    
    @State private var currentQuestionIndex = 0
    @State private var userAnswer = ""
    @State private var showFeedback = false
    @State private var feedback: QuizGradingResponse?
    @Environment(\.dismiss) var dismiss
    
    var currentQuestion: ContextualQuestion? {
        guard let quiz = quiz, currentQuestionIndex < quiz.questions.count else {
            return nil
        }
        return quiz.questions[currentQuestionIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Question counter
                HStack {
                    Text("Question \(currentQuestionIndex + 1)/\(quiz?.questions.count ?? 0)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    ProgressView(value: Double(currentQuestionIndex) / Double(quiz?.questions.count ?? 1))
                        .frame(width: 100)
                }
                .padding()
                
                if let question = currentQuestion {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Question context
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Context")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(question.context)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                            
                            Divider()
                            
                            // Question text
                            Text(question.questionText)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            // Answer input
                            TextField("Your answer", text: $userAnswer)
                                .textFieldStyle(.roundedBorder)
                                .frame(height: 100)
                                .lineLimit(10)
                            
                            // Time limit indicator
                            HStack {
                                Image(systemName: "clock.fill")
                                Text("\(question.timeLimit) seconds")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                            
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Answer button
                    Button(action: submitAnswer) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Submit Answer")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding()
                    .disabled(userAnswer.isEmpty)
                    
                    // Feedback
                    if let feedback = feedback {
                        FeedbackCard(feedback: feedback)
                            .padding()
                    }
                } else {
                    VStack {
                        Text("Quiz Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Great job completing the lesson!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Return to Course") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Interactive Lesson")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func submitAnswer() {
        Task {
            if let question = currentQuestion {
                await manager.submitQuizAnswer(questionId: question.id, answer: userAnswer)
                
                // Move to next question
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    currentQuestionIndex += 1
                    userAnswer = ""
                }
            }
        }
    }
}

// MARK: - Feedback Card

struct FeedbackCard: View {
    let feedback: QuizGradingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Score: \(feedback.score)/100")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Feedback")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(feedback.contextualFeedback)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if !feedback.hints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Hints")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    ForEach(feedback.hints, id: \.self) { hint in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(hint)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .border(Color.green.opacity(0.3), width: 1)
    }
}

// MARK: - Helper Views

struct Badge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(16)
    }
}

struct FlowLayout: View {
    let spacing: CGFloat
    let children: [AnyView]
    
    init<C: Collection>(spacing: CGFloat = 8, @ViewBuilder content: () -> C) where C.Element: View {
        self.spacing = spacing
        self.children = content().map { AnyView($0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            var currentRow: [AnyView] = []
            
            ForEach(0..<children.count, id: \.self) { index in
                HStack(spacing: spacing) {
                    children[index]
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    DynamicClassroomView(
        course: Course(
            id: UUID(),
            title: "Ancient Civilizations - Maya",
            subject: "history",
            topic: "maya_civilization",
            description: "Learn about the Maya civilization",
            instructor: "Dr. History",
            duration: 45,
            level: "intermediate"
        )
    )
}
```

---

## 🎯 Integration with ContentView

```swift
// In ContentView.swift - Add Classroom Tab

TabView(selection: $appState.selectedTab) {
    // ... existing tabs ...
    
    // NEW: Dynamic Classroom Tab
    DynamicClassroomView(course: selectedCourse)
        .tabItem {
            Label("Classroom", systemImage: "graduationcap.fill")
        }
        .tag(MainTab.classroom)
}
```

---

## 🔄 Backend Endpoints Required

Your backend MUST have these endpoints:

```
POST /api/v1/classroom/generate
Purpose: Generate dynamic classroom configuration
Request:
  - courseId, subject, topic, environment, difficulty
Response:
  - classroomId, scene, avatar, tutor, quiz, sessionToken

POST /api/v1/classroom/{classroomId}/quiz/answer
Purpose: Grade quiz answer in context
Request:
  - questionId, answer, environmentContext, timestamp
Response:
  - score, contextualFeedback, nextQuestion, hints

GET /api/v1/classroom/{classroomId}/progress
Purpose: Track student progress in classroom
Response:
  - lessonsCompleted, questionsAnswered, averageScore, achievements
```

---

## 🎨 Example Flow: User Learning About Mars

```
User Selects: "Mars Exploration" Course
                      ↓
DynamicClassroomManager.generateClassroomForCourse()
                      ↓
Backend generates:
  - Scene: Mars Habitation Base at Jezero Crater
  - Avatar: Geologist in EVA suit
  - Quiz: Questions about Martian geology in context
  - Tutor: Mars expert personality
                      ↓
UI Shows:
  - Martian landscape background
  - Temperature: -63°C display
  - Dust storm effects
  - Geologist avatar teaching
                      ↓
Quiz Question:
  "You analyze this rock sample from Jezero Crater.
   Based on its composition, what can you infer?"
                      ↓
Student answers in context of Martian environment
                      ↓
Feedback is contextual:
  "Excellent! This analysis would help determine
   if this location had water history, crucial for
   our search for past microbial life on Mars."
```

---

## ✨ Key Features

| Feature | Implementation |
|---------|-----------------|
| **Subject Mapping** | SubjectContextMapper.swift |
| **Dynamic Generation** | DynamicClassroomManager.swift |
| **Environment Rendering** | DynamicClassroomView.swift |
| **Context-Aware Quiz** | DynamicQuizView.swift |
| **Feedback System** | QuizGradingResponse model |
| **Progress Tracking** | Backend progress endpoint |

---

## 🚀 Implementation Checklist

### Backend (Your AI Backend)
- [ ] Create `ClassroomDynamicService`
- [ ] Extend `ContentGenerator` for scene generation
- [ ] Extend `TutorGenerator` for personality adaptation
- [ ] Extend `QuizGenerator` for contextual questions
- [ ] Create `/api/v1/classroom/generate` endpoint
- [ ] Create `/api/v1/classroom/{id}/quiz/answer` endpoint
- [ ] Implement context-aware grading

### iOS (LyoApp)
- [ ] Create `DynamicClassroomManager.swift`
- [ ] Create `SubjectContextMapper.swift`
- [ ] Create `DynamicClassroomView.swift`
- [ ] Create `DynamicQuizView.swift`
- [ ] Integrate with `ContentView.swift`
- [ ] Update `APIClient.swift` with new endpoints

### Testing
- [ ] Test Maya civilization classroom
- [ ] Test Mars exploration classroom
- [ ] Test chemistry lab environment
- [ ] Verify context-aware quizzes
- [ ] Test avatar personality adaptation

---

## 📊 Data Model: Course to Classroom

```
COURSE DATA → ENVIRONMENT MAPPING → CLASSROOM CONFIG
  ↓                ↓                      ↓
  History         Subject+Topic          Scene:
  Maya            "history_maya"         Maya temple
  
  Science         Subject+Topic          Scene:
  Mars            "science_mars"         Mars base
  
  Chemistry       Subject+Topic          Scene:
  Lab             "science_chemistry"    Modern lab
```

---

## 💡 Advanced Features (Future)

1. **Adaptive Difficulty** - Quiz gets harder/easier based on performance
2. **Multi-language Support** - Tutor speaks in character languages
3. **Multiplayer Classroom** - Multiple students in same environment
4. **Achievement System** - Unlock awards per subject/environment
5. **Time-travel Learning** - Visit same subject across different eras
6. **Reality Mixing** - AR mode where environment overlays real world

---

**This is production-ready architecture that makes every lesson a unique, immersive experience!** 🚀

Ready to implement? Let me know which backend services already exist, and I'll help you adapt the integration!
