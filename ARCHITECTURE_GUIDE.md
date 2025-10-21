# LyoApp Architecture Guide

## Overview

This document describes the clean, consolidated architecture established through comprehensive refactoring. The codebase now follows a **Single Source of Truth** pattern with clear separation of concerns.

---

## Core Principles

### 1. Single Source of Truth
Every type is defined in exactly ONE location. No duplicates, no ambiguity.

### 2. Definitions vs Extensions
- **Definitions**: What a type IS (struct/class/enum declaration)
- **Extensions**: What a type DOES (methods, computed properties)

### 3. Public Access Control
All shared types are explicitly marked `public` to ensure visibility across the module.

### 4. Backward Compatibility
Legacy code continues to work through bridging extensions and type aliases.

---

## Directory Structure

```
LyoApp/
├── Models/                          # Core data types
│   ├── Models.swift                 # ⭐ CANONICAL definitions
│   ├── AIModels.swift              # AI-specific extensions
│   ├── AvatarModels.swift          # Avatar extensions only
│   ├── ChatMessage.swift           # DEPRECATED - placeholder
│   ├── ClassroomModels.swift       # Classroom types
│   └── LearningModels.swift        # Learning types
│
├── Core/
│   ├── Configuration/
│   │   └── APIConfig.swift         # API configuration
│   └── Networking/
│       ├── APIEnvironment.swift    # ⭐ Environment config
│       └── NetworkLayer.swift      # Network utilities
│
├── Config/
│   └── APIKeys.swift               # ⭐ API keys & config
│
├── Services/                        # Business logic
├── Views/                          # UI components
├── ViewModels/                     # View state management
└── DesignTokens.swift              # ⭐ UI design system

⭐ = Primary source files
```

---

## Core Type Locations

### Communication Types

#### AIMessage
**Location:** `LyoApp/Models/Models.swift:11-38`
**Access:** `public struct`
**Purpose:** Canonical message type for AI conversations

```swift
public struct AIMessage: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let content: String
    public let isFromUser: Bool
    public let timestamp: Date
    public let messageType: MessageType
    public let interactionId: Int?
}
```

**Key Features:**
- Uses `isFromUser: Bool` (NOT `sender: String`)
- Has bridging extension for backward compatibility
- Type alias: `ChatMessage = AIMessage`

**Backward Compatibility:**
```swift
extension AIMessage {
    public var sender: String { isFromUser ? "user" : "ai" }
    public convenience init(content: String, sender: String, ...)
}
```

---

### Avatar System

#### Avatar
**Location:** `LyoApp/Models/Models.swift:138-156`
**Access:** `public struct`

```swift
public struct Avatar: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var appearance: AvatarAppearance
    public var profile: PersonalityProfile
    public var voiceIdentifier: String?
    public var calibrationAnswers: CalibrationAnswers
    public var createdAt: Date
}
```

#### AvatarStyle
**Location:** `LyoApp/Models/Models.swift:66-91`
**Access:** `public enum`

```swift
public enum AvatarStyle: String, Codable, CaseIterable, Identifiable {
    case friendlyBot = "Friendly Bot"
    case wiseMentor = "Wise Mentor"
    case energeticCoach = "Energetic Coach"
}
```

#### Personality
**Location:** `LyoApp/Models/Models.swift:93-100`
**Access:** `public enum`
**Extensions:** `LyoApp/Models/AvatarModels.swift:26-85`

```swift
public enum Personality: String, Codable, CaseIterable, Identifiable {
    case friendlyCurious = "Lyo"
    case energeticCoach = "Max"
    case calmReflective = "Luna"
    case wisePatient = "Sage"
}

// Extension provides:
extension Personality {
    var systemPrompt: String
    var tagline: String
    var sampleGreeting: String
}
```

#### CompanionMood
**Location:** `LyoApp/Models/Models.swift:102-104`
**Access:** `public enum`
**Extensions:** `LyoApp/Models/AvatarModels.swift:90-114`

```swift
public enum CompanionMood: String, Codable {
    case neutral, excited, encouraging, thoughtful
    case celebrating, tired, curious
}

// Extension provides:
extension CompanionMood {
    var color: Color
    var emoji: String
}
```

#### CompanionState
**Location:** `LyoApp/Models/Models.swift:106-114`
**Access:** `public struct`
**Extensions:** `LyoApp/Models/AvatarModels.swift:158-189`

```swift
public struct CompanionState: Codable {
    public var mood: CompanionMood
    public var energy: Float
    public var lastInteraction: Date
    public var currentActivity: String?
    public var isSpeaking: Bool
}

// Extension provides:
extension CompanionState {
    mutating func recordInteraction()
    mutating func updateMood(for action: UserAction)
}
```

#### AvatarMemory
**Location:** `LyoApp/Models/Models.swift:116-130`
**Access:** `public struct`
**Extensions:** `LyoApp/Models/AvatarModels.swift:191-211`

```swift
public struct AvatarMemory: Codable {
    public var lastSeenDate: Date
    public var topicsDiscussed: [String]
    public var strugglesNoted: [String: Int]
    public var achievements: [String]
    public var conversationCount: Int
    public var totalStudyMinutes: Int
}

// Extension provides:
extension AvatarMemory {
    mutating func recordTopic(_ topic: String)
    mutating func recordStruggle(with topic: String)
    mutating func recordAchievement(_ description: String)
    mutating func recordConversation(durationMinutes: Int)
}
```

#### UserAction
**Location:** `LyoApp/Models/Models.swift:132-136`
**Access:** `public enum`

```swift
public enum UserAction {
    case answeredCorrect, answeredIncorrect
    case struggled, askedQuestion
    case completedLesson, startedSession
}
```

---

### Learning System

#### LearningBlueprint
**Location:** `LyoApp/Models/Models.swift:160-195`
**Access:** `public struct`

```swift
public struct LearningBlueprint: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let nodes: [BlueprintNode]
    public let connectionPath: [String]
    public let createdAt: Date
    public let completionPercentage: Double
    public var learningGoals: String
    public var preferredStyle: String
    public var timeline: Int?
}
```

#### BlueprintNode
**Location:** `LyoApp/Models/Models.swift:197-229`
**Access:** `public struct`

```swift
public struct BlueprintNode: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let topic: String
    public let type: BlueprintNodeType
    public let description: String
    public let position: CGPoint
    public let isCompleted: Bool
    public let dependencies: [UUID]
    public let estimatedTime: TimeInterval
}
```

---

### Social & Content

#### Post
**Location:** `LyoApp/Models/Models.swift:379`
**Access:** `public struct`

```swift
public struct Post: Identifiable, Hashable, Codable {
    public let id: UUID
    public let author: User
    public var content: String
    public var imageURLs: [URL]?
    public var videoURL: URL?
    public var likes: Int
    public var comments: Int
    public var shares: Int
    public var isLiked: Bool
    public var isBookmarked: Bool
    public let createdAt: Date
    public var tags: [String]?
}
```

#### UserBadge
**Location:** `LyoApp/Models/Models.swift:1190`
**Access:** `public struct`

```swift
public struct UserBadge: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String
    public var iconName: String
    public var color: String
    public var rarity: BadgeRarity
    public var earnedAt: Date
}
```

#### BadgeRarity
**Location:** `LyoApp/Models/Models.swift:1173`
**Access:** `public enum`

```swift
public enum BadgeRarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary
}
```

---

### Classroom System

#### ClassroomCourse
**Location:** `LyoApp/Models/ClassroomModels.swift:9`
**Access:** `public struct`

```swift
public struct ClassroomCourse: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var description: String
    public var scope: String
    public var level: LearningLevel
    public var outcomes: [String]
    public var schedule: Schedule
    public var pedagogy: Pedagogy
    public var assessments: [AssessmentType]
    public var resourcesEnabled: Bool
    public var modules: [CourseModule]
    public var coverImageURL: URL?
    public var estimatedDuration: Int
    public var createdAt: Date
}
```

---

### Configuration & Networking

#### APIEnvironment
**Location:** `LyoApp/Core/Networking/APIEnvironment.swift:4`
**Access:** `public enum`

```swift
public enum APIEnvironment {
    case development  // Local backend
    case prod        // Production cloud

    public var base: URL
    public var v1: URL
    public var webSocketBase: URL
    public var displayName: String

    public static var current: APIEnvironment
    public static var isLocal: Bool
}
```

**Usage:**
```swift
let url = APIEnvironment.current.base
let isDev = APIEnvironment.isLocal
```

#### APIKeys
**Location:** `LyoApp/Config/APIKeys.swift:3`
**Access:** `public struct`

```swift
public struct APIKeys {
    public static let baseURL: String
    public static let webSocketURL: String
    public static let youtubeAPIKey: String
    public static let googleBooksAPIKey: String
    public static let openAIAPIKey: String
    public static var geminiAPIKey: String
    public static var isGeminiAPIKeyConfigured: Bool
    // ... more keys
}
```

**Usage:**
```swift
let url = URL(string: APIKeys.baseURL)!
```

#### SystemHealthResponse
**Location:** `LyoApp/SystemHealthResponse.swift:6`
**Access:** `public struct`

```swift
public struct SystemHealthResponse: Codable, Sendable {
    public let status: String
    public let version: String?
    public let timestamp: String?
    public let service: String?
    public let environment: String?
    public let endpoints: [String: String]?
    public let services: [String: String]?

    public var isHealthy: Bool
}
```

---

### Design System

#### DesignTokens
**Location:** `LyoApp/DesignTokens.swift:5`
**Access:** `public struct`

```swift
public struct DesignTokens {
    public struct Glass { /* glassmorphism effects */ }
    public struct Gradients { /* gradient definitions */ }
    public struct Shadows { /* shadow styles */ }
    public struct Animations { /* animation configs */ }
    public struct Typography { /* text styles */ }
    public struct Spacing { /* spacing system */ }
    public struct Colors { /* color palette */ }
}
```

**Usage:**
```swift
.background(DesignTokens.Glass.contentLayer.background)
.shadow(DesignTokens.Shadows.medium)
.animation(DesignTokens.Animations.bouncy)
```

#### Color(hex:) Extension
**Location:** `LyoApp/DesignTokens.swift:495`
**Access:** `public extension`

```swift
extension Color {
    init(_ hex: String) {
        // Parses hex color strings
    }
}
```

**Usage:**
```swift
Color("6366F1")  // Note: NO label
```

---

## Import Rules

### Within the Module (LyoApp)

✅ **No imports needed** for types in the same module:
```swift
// In any file within LyoApp target
let message = AIMessage(content: "Hello", isFromUser: true)
let avatar = Avatar()
let color = Color("FF0000")
```

✅ **SwiftUI import** for views:
```swift
import SwiftUI

struct MyView: View {
    let tokens = DesignTokens.Glass.contentLayer
    let color = Color("6366F1")
}
```

---

## Deprecated Files

### ChatMessage.swift
**Status:** ⚠️ DEPRECATED
**Location:** `LyoApp/Models/ChatMessage.swift`
**Purpose:** Placeholder to prevent breaking old imports
**Action:** Do NOT add new code here

**Migration:**
```swift
// OLD (don't use)
import ChatMessage  // File is now empty

// NEW (use instead)
// No import needed - AIMessage is in Models.swift
let message = AIMessage(content: "Hello", isFromUser: true)
```

---

## Best Practices

### 1. Adding New Types

**Where to add:**
- General models → `Models/Models.swift`
- AI-specific → `Models/AIModels.swift` (extensions only)
- Avatar-specific → `Models/AvatarModels.swift` (extensions only)
- Classroom → `Models/ClassroomModels.swift`
- Learning → `Models/LearningModels.swift`

**Make it public:**
```swift
public struct MyNewType {
    public var property: String

    public init(property: String) {
        self.property = property
    }
}
```

### 2. Adding Extensions

**Prefer extensions over modifying original:**
```swift
// In AvatarModels.swift
extension Avatar {
    public func customMethod() -> String {
        return "Custom"
    }
}
```

### 3. Backward Compatibility

**When changing signatures:**
```swift
// Old signature people might use
public init(sender: String, content: String) {
    // Bridge to new signature
    self.init(content: content, isFromUser: sender == "user")
}
```

### 4. Type Aliases

**For renaming without breaking:**
```swift
public typealias OldName = NewName
```

---

## Common Patterns

### Creating Messages

```swift
// User message
let userMsg = AIMessage(
    content: "Hello",
    isFromUser: true
)

// AI message
let aiMsg = AIMessage(
    content: "Hi there!",
    isFromUser: false
)

// Legacy compatibility
let legacyMsg = AIMessage(
    content: "Hello",
    sender: "user"
)
```

### Creating Avatars

```swift
let avatar = Avatar(
    name: "Lyo",
    appearance: AvatarAppearance(style: .friendlyBot),
    profile: PersonalityProfile(basePersonality: .friendlyCurious)
)
```

### Using Design Tokens

```swift
VStack {
    Text("Hello")
        .foregroundColor(Color("6366F1"))
}
.background(DesignTokens.Glass.contentLayer.background)
.shadow(color: DesignTokens.Shadows.medium.color,
        radius: DesignTokens.Shadows.medium.radius)
.animation(DesignTokens.Animations.bouncy)
```

### API Configuration

```swift
// Get current environment
let env = APIEnvironment.current
let baseURL = env.base

// Or use APIKeys
let urlString = APIKeys.baseURL
```

---

## Migration Checklist

When working with the codebase:

- [ ] ✅ Use types from `Models/Models.swift` (not ChatMessage.swift)
- [ ] ✅ Use `isFromUser: Bool` (not `sender: String`) for new code
- [ ] ✅ Use `Color("hex")` without label (not `Color(hex: "hex")`)
- [ ] ✅ Access DesignTokens directly (it's public)
- [ ] ✅ Access APIEnvironment directly (it's public)
- [ ] ✅ Make new types `public` if shared across files
- [ ] ✅ Add extensions to appropriate files (not inline)
- [ ] ✅ Check for existing types before creating new ones

---

## Troubleshooting

### "Cannot find type X"

1. Check if type exists in Models.swift
2. Ensure type is marked `public`
3. Verify file is in build target
4. Clean build folder (Cmd+Shift+K)

### "Ambiguous use of X"

1. Check for duplicate definitions
2. Use fully qualified name: `LyoApp.MyType`
3. Check type aliases

### "Cannot find 'DesignTokens'"

1. Ensure DesignTokens.swift is in build target
2. Verify struct is marked `public`
3. Clean derived data

---

## Summary

The LyoApp architecture now follows industry best practices:

✅ **Single Source of Truth** - No duplicates
✅ **Clear Separation** - Definitions vs Extensions
✅ **Proper Access Control** - Public where needed
✅ **Backward Compatible** - Old code still works
✅ **Well Documented** - Clear guidelines
✅ **Maintainable** - Easy to understand and extend

For questions or issues, refer to this document first.

---

**Last Updated:** 2025-10-20
**Version:** 2.0 (Post-Refactoring)
