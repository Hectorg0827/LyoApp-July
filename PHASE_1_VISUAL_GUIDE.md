# 🎨 Co-Creative AI Mentor - Visual Flow Guide

## Complete User Journey (Phase 1)

```
┌─────────────────────────────────────────────────────────────────┐
│                        LAUNCH SCREEN                            │
│                     (Existing Feature)                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 1.3b: AVATAR SELECTION                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  "Choose Your Learning Companion"                       │   │
│  │                                                         │   │
│  │  [😊]  [⚡]  [🧙]  [🤹]  [👔]  [🎨]                      │   │
│  │  Friendly  Energetic  Wise  Playful  Pro  Creative     │   │
│  │                                                         │   │
│  │  Name: [________________]                              │   │
│  │                                                         │   │
│  │  [Continue →]                    [Skip for now]        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                 QuickAvatarPickerView (inline)                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│       PHASE 1.6: DIAGNOSTIC DIALOGUE (60/40 SPLIT)              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ PROGRESS BAR (TopProgressBar)                            │  │
│  │ ┌──────────────────────────────────────────────────────┐ │  │
│  │ │ [😊] Building Your Path    Question 2 of 6    [33%] │ │  │
│  │ │ ▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░              │ │  │
│  │ └──────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────┬─────────────────────────────────┐   │
│  │  CONVERSATION (60%)  │  BLUEPRINT PREVIEW (40%)       │   │
│  │  ┌────────────────┐  │  ┌──────────────────────────┐  │   │
│  │  │ AI:            │  │  │   Your Learning Path     │  │   │
│  │  │ "What would    │  │  │                          │  │   │
│  │  │  you love to   │  │  │      ┌─────────┐         │  │   │
│  │  │  learn?"       │  │  │      │ Python  │         │  │   │
│  │  └────────────────┘  │  │      │ (Topic) │         │  │   │
│  │                      │  │      └────┬────┘         │  │   │
│  │  ┌────────────────┐  │  │           │              │  │   │
│  │  │ You:           │  │  │      ┌────▼────┐         │  │   │
│  │  │ "I want to     │  │  │      │  Build  │         │  │   │
│  │  │  learn Python" │  │  │      │  Apps   │         │  │   │
│  │  └────────────────┘  │  │      │ (Goal)  │         │  │   │
│  │                      │  │      └─────────┘         │  │   │
│  │  ┌────────────────┐  │  │                          │  │   │
│  │  │ AI:            │  │  │  Nodes: 2 | Connections: 1│  │   │
│  │  │ "Great! What's │  │  └──────────────────────────┘  │   │
│  │  │  your main     │  │                                │   │
│  │  │  goal?"        │  │  ConversationBubbleView (left) │   │
│  │  └────────────────┘  │  LiveBlueprintPreview (right)  │   │
│  │                      │                                │   │
│  │  [💼 Career] [🎨 Interest]                           │   │
│  │  [🔨 Build Something] [🧩 Solve Problems]            │   │
│  │                      │                                │   │
│  │  Type your answer... │                                │   │
│  │  [________________]  │                                │   │
│  └──────────────────────┴────────────────────────────────┘   │
│           DiagnosticDialogueView (main container)             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                   (After 6 Questions)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               COURSE GENERATION (Existing)                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🌟 Generating Your Personalized Course...             │   │
│  │                                                         │   │
│  │  Topic: Python Programming                             │   │
│  │  Based on your blueprint:                              │   │
│  │  • Goal: Build mobile apps                             │   │
│  │  • Pace: 3-5 hours/week                                │   │
│  │  • Style: Hands-on projects                            │   │
│  │  • Level: Beginner                                     │   │
│  │                                                         │   │
│  │  [████████████░░░░░░░░] 65%                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                    GenesisScreenView                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  AI CLASSROOM (Existing)                        │
│             Interactive Learning Experience                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Breakdown: DiagnosticDialogueView

### Layout Structure
```
DiagnosticDialogueView (GeometryReader)
│
├── VStack (Full height)
│   │
│   ├── TopProgressBar (Height: 80pt)
│   │   └── VStack
│   │       ├── HStack (Avatar + Info + Badge)
│   │       │   ├── Circle (50x50, mood color + emoji)
│   │       │   ├── VStack (Text)
│   │       │   │   ├── "Building Your Path" (16pt, bold)
│   │       │   │   └── "Question X of 6" (12pt, regular)
│   │       │   ├── Spacer
│   │       │   └── Percentage Badge (Capsule, blue bg)
│   │       │
│   │       └── Progress Bar (Height: 4pt)
│   │           └── Animated Capsule (blue→purple gradient)
│   │
│   └── HStack (Remaining height)
│       │
│       ├── ConversationBubbleView (60% width)
│       │   └── VStack
│       │       ├── ScrollView (Message bubbles)
│       │       │   └── ForEach(conversationHistory)
│       │       │       ├── AI messages (gray, left)
│       │       │       └── User messages (blue, right)
│       │       │
│       │       ├── Suggested Chips (if any)
│       │       │   └── FlowLayout
│       │       │       └── ForEach(suggestedResponses)
│       │       │           └── Capsule buttons
│       │       │
│       │       └── Input Bar
│       │           ├── TextField
│       │           └── Send Button
│       │
│       ├── Divider (1pt vertical)
│       │
│       └── LiveBlueprintPreview (40% width)
│           └── VStack
│               ├── "Your Learning Path" (Header)
│               ├── Canvas (Blueprint visualization)
│               │   └── ForEach(blueprint.nodes)
│               │       ├── Node circles (colored by type)
│               │       └── Connection lines
│               │
│               └── Stats: "Nodes: X | Connections: Y"
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INPUT                               │
│              (Tap chip or type message)                         │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                  DiagnosticViewModel                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ processUserResponse(_ response: String) async            │  │
│  │   1. Append user message to conversationHistory          │  │
│  │   2. Clear suggestedResponses                            │  │
│  │   3. Call updateBlueprintFromResponse()                  │  │
│  │   4. Increment currentStep                               │  │
│  │   5. Delay 500ms (natural feel)                          │  │
│  │   6. Call askNextQuestion()                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
                ┌──────────┴────────┐
                ↓                   ↓
┌──────────────────────┐  ┌──────────────────────┐
│ updateBlueprint      │  │ askNextQuestion      │
│ FromResponse()       │  │                      │
│                      │  │ 1. Get next question │
│ Based on question:   │  │ 2. Add AI message    │
│ • interests → topic  │  │ 3. Set suggestions   │
│ • goals → goal node  │  │ 4. Update mood       │
│ • timeline → pace    │  │                      │
│ • style → skill node │  │                      │
│ • level → milestone  │  │                      │
│ • motivation → prop  │  │                      │
└──────────────────────┘  └──────────────────────┘
           ↓                         ↓
┌──────────────────────────────────────────────┐
│       @Published Properties Update           │
│                                              │
│ • conversationHistory (new messages)         │
│ • currentQuestion (next question)            │
│ • suggestedResponses (new chips)             │
│ • currentBlueprint (new nodes)               │
│ • currentStep (incremented)                  │
│ • currentMood (changed)                      │
└──────────────────────┬───────────────────────┘
                       ↓
┌──────────────────────────────────────────────┐
│          SwiftUI Re-renders                  │
│                                              │
│ • ConversationBubbleView (new messages)      │
│ • LiveBlueprintPreview (new nodes)           │
│ • TopProgressBar (updated progress)          │
│ • Suggested chips (new options)              │
└──────────────────────────────────────────────┘
```

---

## State Transitions

```
App Launch
    ↓
┌────────────────────┐
│ .selectingAvatar   │  (QuickAvatarPickerView)
└─────────┬──────────┘
          │ onComplete: { preset, name in
          │   selectedAvatar = preset
          │   avatarName = name
          │   currentState = .diagnosticDialogue
          │ }
          ↓
┌────────────────────┐
│ .diagnosticDialogue│  (DiagnosticDialogueView)
└─────────┬──────────┘
          │ onComplete: { blueprint in
          │   learningBlueprint = blueprint
          │   detectedTopic = blueprint.topic
          │   currentState = .generatingCourse
          │ }
          ↓
┌────────────────────┐
│ .generatingCourse  │  (GenesisScreenView)
└─────────┬──────────┘
          │ onCourseGenerated: { course in
          │   generatedCourse = course
          │   currentState = .classroomActive
          │ }
          ↓
┌────────────────────┐
│ .classroomActive   │  (AIClassroomView)
└────────────────────┘
```

---

## Blueprint Node Creation Logic

```
Question 1: "What would you love to learn?"
User: "Python programming"
    ↓
Blueprint Update:
    • topic = "Python programming"
    • Create TopicNode:
      - id: UUID()
      - title: "Python programming"
      - type: .topic
      - position: center (0.5, 0.3)
      - color: Blue

Question 2: "What's your main goal?"
User: "Build mobile apps"
    ↓
Blueprint Update:
    • goal = "Build mobile apps"
    • Create GoalNode:
      - id: UUID()
      - title: "Build mobile apps"
      - type: .goal
      - connections: [topicNode.id]
      - position: bottom (0.5, 0.7)
      - color: Green

Question 3: "Time per week?"
User: "3-5 hours"
    ↓
Blueprint Update:
    • pace = "3-5 hours"
    (No new node, property only)

Question 4: "How do you learn best?"
User: "Hands-on projects"
    ↓
Blueprint Update:
    • style = "Hands-on projects"
    • Create SkillNode:
      - id: UUID()
      - title: "Hands-on projects"
      - type: .skill
      - connections: [topicNode.id]
      - position: left (0.2, 0.5)
      - color: Purple

Question 5: "Experience level?"
User: "Beginner"
    ↓
Blueprint Update:
    • level = "Beginner"
    • Create MilestoneNode:
      - id: UUID()
      - title: "Beginner"
      - type: .milestone
      - connections: [topicNode.id]
      - position: right (0.8, 0.5)
      - color: Pink

Question 6: "What motivates you?"
User: "Career growth"
    ↓
Blueprint Update:
    • motivation = "Career growth"
    (No new node, property only)
    
Final Blueprint:
    • 4 nodes (topic, goal, skill, milestone)
    • 3 connections
    • All properties filled
    • Ready for course generation
```

---

## Animation Timeline

```
User taps "Continue" from Avatar Selection
    ↓
t=0ms    DiagnosticDialogueView appears (.move(edge: .trailing))
t=100ms  TopProgressBar fades in
t=200ms  Avatar circle scales in
t=300ms  Progress bar draws from 0% → 0%
t=400ms  Conversation area ready
t=500ms  viewModel.startDiagnostic() called
    ↓
t=600ms  First AI message appears (fade in)
t=700ms  "What would you love to learn?"
t=800ms  Avatar mood changes to .friendly
t=900ms  Emoji animates (😊)
    ↓
User types "Python programming"
    ↓
t=0ms    User message appears (slide from right)
t=100ms  Message bubble expands
t=200ms  viewModel.processUserResponse() called
    ↓
t=300ms  Blueprint updates
t=400ms  Topic node appears (scale + fade)
t=500ms  Node title "Python programming" types
t=600ms  Node settles at position
    ↓
t=700ms  Delay 500ms (viewModel internal)
    ↓
t=1200ms Next AI message appears
t=1300ms "Great! What's your main goal?"
t=1400ms Suggested chips fade in
t=1500ms Avatar mood changes to .curious (🧐)
t=1600ms Progress bar animates to 33% (spring animation)
    ↓
[Repeat for all 6 questions]
    ↓
Final question answered
    ↓
t=0ms    Avatar mood changes to .excited (🤩)
t=100ms  Celebration message appears
t=200ms  "Perfect! I've created your path! 🎉"
t=300ms  Progress bar completes to 100%
t=400ms  Blueprint fully rendered
t=500ms  onComplete callback fires
    ↓
t=600ms  Transition to .generatingCourse
t=700ms  DiagnosticDialogueView slides out (.move(edge: .leading))
t=800ms  GenesisScreenView slides in
```

---

## Color Palette

### Node Types
- **Topic:** Blue (#007AFF)
- **Goal:** Green (#34C759)
- **Skill:** Purple (#AF52DE)
- **Milestone:** Pink (#FF2D55)

### UI Elements
- **Progress Bar:** Blue → Purple gradient
- **User Messages:** Blue (#007AFF)
- **AI Messages:** Gray (#E5E5EA)
- **Suggested Chips:** Blue outline, white background
- **Background:** System background (.systemBackground)

### Avatar Moods
- **Friendly:** Blue (#007AFF) 😊
- **Excited:** Orange (#FF9500) 🤩
- **Thinking:** Purple (#AF52DE) 🤔
- **Supportive:** Green (#34C759) 💪
- **Curious:** Cyan (#5AC8FA) 🧐
- **Empathetic:** Pink (#FF2D55) 🤗
- **Thoughtful:** Indigo (#5856D6) 💭
- **Engaged:** Teal (#30B0C7) ✨

---

## Responsive Breakpoints

### iPhone SE (Small - 375pt width)
- Conversation: 225pt (60%)
- Blueprint: 150pt (40%)
- Message bubbles: Max 200pt
- Node circles: 50pt diameter

### iPhone 15 Pro (Medium - 393pt width)
- Conversation: 235.8pt (60%)
- Blueprint: 157.2pt (40%)
- Message bubbles: Max 210pt
- Node circles: 60pt diameter

### iPhone 15 Pro Max (Large - 430pt width)
- Conversation: 258pt (60%)
- Blueprint: 172pt (40%)
- Message bubbles: Max 230pt
- Node circles: 70pt diameter

### iPad (Extra Large - 768pt+ width)
- Conversation: 460.8pt (60%)
- Blueprint: 307.2pt (40%)
- Message bubbles: Max 400pt
- Node circles: 80pt diameter

---

## Accessibility Features

### VoiceOver Support
- All buttons have labels
- Message bubbles read with context ("AI says...", "You said...")
- Progress bar announces percentage
- Node titles read with type ("Python programming, Topic node")

### Dynamic Type
- All text respects user font size settings
- Layout adapts to larger text
- Minimum touch targets: 44x44pt

### Color Contrast
- WCAG AA compliant
- Dark mode support
- High contrast mode tested

---

*Visual Guide Generated: October 6, 2025*  
*LyoApp Co-Creative AI Mentor - Complete Flow*
