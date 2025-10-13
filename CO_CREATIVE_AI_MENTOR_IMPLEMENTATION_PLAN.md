# 🎓 Co-Creative AI Mentor - Implementation Plan

## 📋 Document Purpose
This document serves as a complete implementation guide for transforming the current AI Avatar into a Co-Creative AI Mentor. It includes detailed specifications, code structures, testing procedures, and error-checking protocols.

---

## 🎯 Vision Summary

**From:** Simple chatbot that answers questions
**To:** Co-creative learning companion that collaboratively designs learning paths and delivers lessons with personality and emotion

---

## 📊 Implementation Phases

### **Phase 1: Diagnostic Dialogue & Real-Time Blueprint Preview (Weeks 1-3)**
**Goal:** Replace simple topic gathering with an intelligent 6-question diagnostic that builds a visual learning blueprint in real-time.

#### **1.1 Component Structure**
```
DiagnosticDialogueView (Main Container)
├── AnimatedGradientBackground
├── AvatarHeadView (Top, 200pt height)
├── ConversationArea (Middle, GeometryReader)
│   ├── ConversationBubbleView (60% width)
│   │   ├── Message History (ScrollView)
│   │   ├── Current Question Display
│   │   └── Suggested Response Chips
│   └── LiveBlueprintPreview (40% width)
│       ├── Mini Mind Map Canvas
│       ├── Node Animations
│       └── Connection Lines
└── DiagnosticProgressBar (Bottom)
```

#### **1.2 Core Models**
- `DiagnosticViewModel` - Manages conversation flow and blueprint building
- `DiagnosticQuestion` - Question structure with type, text, options, follow-ups
- `ConversationMessage` - Chat message with timestamp and sender
- `SuggestedResponse` - Quick-tap response options
- `LearningBlueprint` - Central data model for user's learning plan
- `BlueprintNode` - Individual nodes in the mind map

#### **1.3 The 6 Diagnostic Questions**

**Q1: Interests (Open-ended)**
- "Hi! I'm Lyo, your learning companion. 👋 What would you like to learn today?"
- Follow-up: "That sounds fascinating! Tell me more about what drew you to {topic}?"
- **Blueprint Node Created:** Topic (center node, blue)

**Q2: Goals (Multiple Choice)**
- "What's your main goal with learning {topic}?"
- Options:
  - Pass an exam or certification
  - Build a personal project
  - Career advancement
  - Pure curiosity and fun
  - Teach it to someone else
- **Blueprint Node Created:** Goal (green, connected to topic)

**Q3: Timeline (Multiple Choice)**
- "How much time can you dedicate to learning?"
- Options:
  - 15-30 minutes daily
  - 1 hour, 3-4 times a week
  - Weekend deep dives (2-3 hours)
  - Flexible - I'll learn when I can
- **Blueprint Node Created:** Pace (orange, connected to goal)

**Q4: Learning Style (Multiple Choice)**
- "How do you learn best?"
- Options:
  - Visual (diagrams, videos, animations)
  - Hands-on (projects, experiments)
  - Step-by-step written guides
  - Audio explanations and discussions
  - Mix of everything
- **Blueprint Node Created:** Style (purple, connected to topic)

**Q5: Current Level (Multiple Choice)**
- "What's your current experience with {topic}?"
- Options:
  - Complete beginner - start from zero
  - I know the basics, want to go deeper
  - Intermediate - fill in gaps
  - Advanced - master specific topics
- **Blueprint Node Created:** Level (pink, connected to topic)

**Q6: Motivation (Multiple Choice)**
- "What keeps you motivated when learning?"
- Options:
  - Seeing real progress and milestones
  - Building actual projects
  - Earning badges and achievements
  - Competition and leaderboards
  - Personal satisfaction
- **Blueprint Node Created:** Motivation (cyan, connected to goal)

#### **1.4 Avatar Head Animations**

**Moods:**
- `friendly` - Gentle smile, relaxed posture
- `excited` - Wide eyes, big smile, slight bounce
- `thinking` - Hand to chin, looking up
- `encouraging` - Warm smile, nodding
- `celebrating` - Arms up, confetti effect

**Expressions:**
- `neutral` - Default state
- `smiling` - Happy, welcoming
- `talking` - Mouth moving (lip sync)
- `nodding` - Agreement animation
- `pointing` - Directing attention to blueprint

**Speaking Animation:**
- Mouth opens/closes every 0.1s
- Eyes blink randomly every 3-5s
- Subtle head movement (sway)
- Hand gestures based on context

#### **1.5 Implementation Steps**

**Step 1.1: Create Base Models**
- [x] File: `DiagnosticModels.swift`
- [x] Content: All data structures (DiagnosticQuestion, ConversationMessage, LearningBlueprint, BlueprintNode, AvatarMood, AvatarExpression)
- [x] Test: Build succeeds, no syntax errors

**Step 1.2: Create DiagnosticViewModel**
- [x] File: `DiagnosticViewModel.swift`
- [x] Content: ObservableObject with @Published properties, question flow logic, AI integration for intent extraction
- [x] Test: Mock conversation flow works, blueprint updates correctly

**Step 1.3: Create AvatarHeadView**
- [x] File: `AvatarHeadView.swift`
- [x] Content: Animated avatar with mood/expression states, speaking animation, gesture system
- [x] Test: Animations smooth, transitions work, no performance issues

**Step 1.4: Create LiveBlueprintPreview**
- [x] File: `LiveBlueprintPreview.swift`
- [x] Content: Mini mind map with nodes, connections, animations, auto-layout
- [x] Test: Nodes appear smoothly, connections draw correctly, layout is readable

**Step 1.5: Create ConversationBubbleView**
- [x] File: `ConversationBubbleView.swift`
- [x] Content: Chat UI with message bubbles, suggested response chips, typing indicator
- [x] Test: Messages scroll smoothly, chips are tappable, UI is responsive

**Step 1.6: Assemble DiagnosticDialogueView**
- [x] File: `DiagnosticDialogueView.swift`
- [x] Content: Main container with 60/40 layout, progress bar, navigation
- [x] Test: All components render, layout responds to screen size

**Step 1.7: Integrate with AIOnboardingFlowView**
- [x] Replace `TopicGatheringView` with `DiagnosticDialogueView`
- [x] Pass `LearningBlueprint` to next phase
- [x] Test: Full flow from AI Avatar → Diagnostic → Blueprint Complete

**Step 1.8: Error Checking & Polish**
- [x] Test all question types
- [x] Verify AI intent extraction works
- [x] Check memory usage with animations
- [x] Test on different screen sizes
- [x] Fix any layout or animation issues

---

### **Phase 2: Interactive Mind Map Blueprint Editor (Weeks 4-6)**
**Goal:** Let users edit, rearrange, and co-create their learning blueprint with drag-and-drop nodes and AI suggestions.

#### **2.1 Component Structure**
```
BlueprintEditorView (Main Container)
├── MindMapCanvasView (Full screen, interactive)
│   ├── Connection Lines (Bezier curves)
│   ├── BlueprintNodeView (Draggable, editable)
│   └── Node Connection Creator (Drag gesture)
├── FloatingAvatarAssistant (Bottom-right corner)
│   ├── Suggestion Bubble
│   ├── Accept/Reject Buttons
│   └── Animation (Appear/disappear)
└── BlueprintToolbar (Top)
    ├── Add Module Button
    ├── Save & Continue Button
    ├── Reset Button
    └── Undo/Redo Buttons
```

#### **2.2 Core Models**
- `BlueprintEditorViewModel` - Manages canvas state, node positions, AI suggestions
- `NodePosition` - Tracks node placement on canvas
- `AIModuleSuggestion` - Suggested modules with reasoning
- `CanvasGesture` - Drag, pinch, pan gesture states

#### **2.3 Node Types & Visual Encoding**

**Node Types:**
1. **Topic Node** (Center, Blue, Large)
   - Icon: `book.fill`
   - Size: 100x100pt
   - Always present, non-deletable

2. **Goal Node** (Green)
   - Icon: `target`
   - Size: 80x80pt
   - User's learning objective

3. **Module Node** (Purple)
   - Icon: `folder.fill`
   - Size: 80x80pt
   - Course sections/chapters

4. **Skill Node** (Orange)
   - Icon: `star.fill`
   - Size: 70x70pt
   - Specific competencies

5. **Milestone Node** (Pink)
   - Icon: `flag.fill`
   - Size: 70x70pt
   - Checkpoints and achievements

**Suggested Nodes:**
- Dotted border
- Orange glow
- Pulsing animation
- "Suggested" badge

#### **2.4 Interaction Patterns**

**Drag & Drop:**
- Long press (0.3s) to activate drag
- Node follows finger/cursor
- Other nodes repel slightly (physics)
- Drop updates position permanently

**Creating Connections:**
- Tap source node → Tap target node
- Line animates from source to target
- Validation: Prevent circular dependencies

**Editing Nodes:**
- Double-tap to edit title
- Swipe left to delete (with confirmation)
- Tap to select (shows details panel)

**AI Suggestions:**
- Appear after 5 seconds of inactivity
- Based on current blueprint structure
- Accept → Node appears with animation
- Reject → Suggestion disappears, new one suggested after 10s

#### **2.5 Auto-Layout Algorithm**

**Initial Layout:**
```
1. Place Topic node at center
2. Arrange first-level nodes in circle (radius 200pt)
3. Arrange second-level nodes in outer circle (radius 350pt)
4. Apply force-directed layout for 2 seconds
5. Snap to final positions
```

**Force-Directed Layout:**
- Repulsion: Nodes push each other away
- Attraction: Connected nodes pull together
- Center gravity: Prevent nodes from drifting off-screen
- Boundary collision: Keep within canvas bounds

#### **2.6 AI Module Suggestions**

**Suggestion Engine:**
```swift
func generateModuleSuggestion() -> AIModuleSuggestion {
    let prompt = """
    Current blueprint:
    - Topic: \(blueprint.topic)
    - Goal: \(blueprint.goal)
    - Level: \(blueprint.level)
    - Existing modules: \(blueprint.nodes.filter { $0.type == .module }.map { $0.title })
    
    Suggest ONE new module that would enhance this learning path.
    Consider prerequisites, logical progression, and goal alignment.
    
    Return JSON: { "title": "Module Name", "reasoning": "Why this helps", "position": "after_module_X" }
    """
    
    // Call Gemini AI
    // Parse response
    // Return suggestion
}
```

**Suggestion Timing:**
- First suggestion: After blueprint loads (5s delay)
- Subsequent: After user accepts/rejects (10s delay)
- Max: 5 suggestions per session
- Stop: When user taps "I'm done" or saves

#### **2.7 Implementation Steps**

**Step 2.1: Create BlueprintEditorViewModel**
- [ ] File: `BlueprintEditorViewModel.swift`
- [ ] Content: Canvas state, node positions, gesture handling, AI suggestion logic
- [ ] Test: State updates work, gestures register, AI calls succeed

**Step 2.2: Create MindMapCanvasView**
- [ ] File: `MindMapCanvasView.swift`
- [ ] Content: Canvas with nodes, connections, drag gestures, auto-layout
- [ ] Test: Nodes render, dragging works, layout is readable

**Step 2.3: Create BlueprintNodeView**
- [ ] File: `BlueprintNodeView.swift`
- [ ] Content: Individual node with type-specific styling, animations, gestures
- [ ] Test: All node types render correctly, animations smooth

**Step 2.4: Create ConnectionLine**
- [ ] File: `ConnectionLine.swift`
- [ ] Content: Bezier curve drawing between nodes, animation, selection state
- [ ] Test: Lines connect correctly, bezier curves look smooth

**Step 2.5: Create FloatingAvatarAssistant**
- [ ] File: `FloatingAvatarAssistant.swift`
- [ ] Content: Suggestion bubble with avatar, accept/reject buttons, animations
- [ ] Test: Appears/disappears smoothly, buttons work, suggestions display

**Step 2.6: Implement Force-Directed Layout**
- [ ] File: `ForceDirectedLayout.swift`
- [ ] Content: Physics simulation for node positioning
- [ ] Test: Nodes arrange nicely, no overlap, stable after 2s

**Step 2.7: Integrate AI Suggestion Engine**
- [ ] Update `BlueprintEditorViewModel`
- [ ] Add Gemini API call for suggestions
- [ ] Parse and display suggestions
- [ ] Test: Suggestions are relevant, timing works, acceptance adds nodes

**Step 2.8: Assemble BlueprintEditorView**
- [ ] File: `BlueprintEditorView.swift`
- [ ] Content: Canvas + toolbar + floating assistant
- [ ] Test: All components work together, layout responsive

**Step 2.9: Integrate with AIOnboardingFlowView**
- [ ] Add new flow state: `.editingBlueprint`
- [ ] Transition from diagnostic to editor
- [ ] Save finalized blueprint and continue to classroom
- [ ] Test: Full flow works, data persists

**Step 2.10: Error Checking & Polish**
- [ ] Test drag performance with 10+ nodes
- [ ] Verify layout algorithm on various blueprints
- [ ] Check AI suggestion quality
- [ ] Test undo/redo functionality
- [ ] Fix any gesture conflicts or layout issues

---

### **Phase 3: The Living Mentor Avatar (Weeks 7-10)**
**Goal:** Transform static lessons into dynamic, emotionally intelligent teaching sessions with an animated avatar that speaks, gestures, and adapts.

#### **3.1 Component Structure**
```
LivingMentorView (Main Container)
├── EnvironmentBackgroundView (Customizable theme)
├── Teaching Area (70% height)
│   ├── AnimatedAvatarView (30% width)
│   │   ├── 3D/2D Avatar Model
│   │   ├── Facial Expressions
│   │   ├── Body Gestures
│   │   ├── Lip Sync Animation
│   │   └── Props (pointer, book, etc.)
│   └── LessonContentInteractiveView (70% width)
│       ├── Text Content
│       ├── Virtual Whiteboard
│       ├── Interactive Exercises
│       ├── Code Editor
│       └── Visual Simulations
├── Progress & Resources (30% height)
│   ├── MotivationalProgressBar (10%)
│   │   ├── XP Counter
│   │   ├── Streak Flame
│   │   ├── Next Milestone
│   │   └── Animated Celebrations
│   └── ResourceCurationBar (20%)
│       └── (Reuse from Phase 3 - Step 3 complete)
└── Overlays
    ├── EmotionalCheckInOverlay
    ├── AchievementCelebrationView
    └── QuizOverlay
```

#### **3.2 Core Models**
- `LivingMentorViewModel` - Orchestrates entire teaching experience
- `AvatarState` - Position, mood, expression, gesture, customization
- `InteractiveLesson` - Lesson structure with multimedia content
- `EmotionalIntelligenceEngine` - Detects user state and adapts
- `WhiteboardState` - Manages virtual whiteboard content
- `ProgressTracker` - XP, streaks, achievements, milestones

#### **3.3 Avatar Animation System**

**Avatar Customization:**
```swift
struct AvatarCustomization {
    var skinTone: Color
    var hairStyle: String        // "short", "long", "curly", "pixie"
    var hairColor: Color
    var outfit: String            // "casual", "formal", "scientist", "artist"
    var accessories: [String]     // ["glasses", "hat", "badge"]
    var background: LearningEnvironment
}
```

**Unlockable Items (via XP):**
- **Level 1 (0 XP):** Basic casual outfit
- **Level 2 (500 XP):** Scientist lab coat, glasses
- **Level 3 (1000 XP):** Artist beret, palette
- **Level 4 (2000 XP):** Space suit, astronaut helmet
- **Level 5 (5000 XP):** Custom colors, all accessories

**Mood States:**
- `friendly` - Default teaching mode
- `excited` - When celebrating success
- `thinking` - When processing question
- `encouraging` - When user struggles
- `celebrating` - When milestone reached
- `curious` - When asking probing questions

**Expression Library:**
- `neutral` - Default face
- `smiling` - Happy, welcoming
- `talking` - Mouth moving (lip sync)
- `nodding` - Agreement
- `waving` - Greeting
- `pointing` - Directing attention
- `confused` - Eyebrows raised
- `excited` - Eyes wide, big smile
- `caring` - Soft eyes, gentle smile

**Gesture Library:**
- `idle` - Subtle breathing, blinking
- `pointing(at: WhiteboardElement)` - Points to specific content
- `writing(on: Whiteboard)` - Animates writing
- `celebrating` - Arms up, jumping
- `thinking` - Hand to chin, looking up
- `explaining` - Open palms, moving hands
- `encouraging` - Thumbs up, nodding

#### **3.4 Text-to-Speech & Lip Sync**

**Implementation:**
```swift
class AvatarSpeechEngine {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, mood: AvatarMood) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Adjust based on mood
        switch mood {
        case .excited:
            utterance.rate = 0.55
            utterance.pitchMultiplier = 1.2
        case .encouraging:
            utterance.rate = 0.48
            utterance.pitchMultiplier = 1.0
        case .friendly:
            utterance.rate = 0.50
            utterance.pitchMultiplier = 1.05
        default:
            utterance.rate = 0.50
            utterance.pitchMultiplier = 1.0
        }
        
        synthesizer.speak(utterance)
        
        // Sync lip animation
        startLipSync(duration: utterance.speechString.count * 0.08)
    }
    
    private func startLipSync(duration: TimeInterval) {
        // Animate mouth open/close every 0.1s
        // Stop when duration elapsed
    }
}
```

**Phoneme-Based Lip Sync (Advanced):**
- Use `AVSpeechSynthesizerDelegate` to get phoneme boundaries
- Map phonemes to mouth shapes
- Animate transitions between shapes

#### **3.5 Virtual Whiteboard System**

**Whiteboard Elements:**
```swift
enum WhiteboardElement {
    case text(String, position: CGPoint, style: TextStyle)
    case shape(ShapeType, position: CGPoint, size: CGSize, color: Color)
    case arrow(from: CGPoint, to: CGPoint, label: String?)
    case formula(String, position: CGPoint)
    case image(String, position: CGPoint, size: CGSize)
    case drawing(Path, color: Color, lineWidth: CGFloat)
}

enum ShapeType {
    case circle, rectangle, triangle, star
}
```

**Drawing Animation:**
- Avatar "writes" on whiteboard
- Elements appear progressively
- Avatar points to elements while explaining
- Elements can be highlighted/dimmed
- Interactive: User can tap elements for details

**Example Usage:**
```swift
// During lesson: "Let me show you how variables work"
whiteboard.addElement(.text("Variables store data", position: .init(x: 100, y: 100)))
avatar.gesture = .pointing(at: whiteboard.elements.last!)
avatar.speak("Think of a variable like a box with a label")

// Draw box
whiteboard.addElement(.rectangle(position: .init(x: 150, y: 150), size: .init(width: 80, height: 80)))
avatar.gesture = .writing(on: whiteboard)

// Add label
whiteboard.addElement(.text("name", position: .init(x: 190, y: 140)))
```

#### **3.6 Emotional Intelligence Engine**

**User State Detection:**

**Frustration Signals:**
- 3+ incorrect answers in a row
- Same question reopened multiple times
- Long pauses (>30s) without progress
- Rapid, erratic interactions

**Confusion Signals:**
- Skipping questions repeatedly
- Accessing hints immediately
- Hovering over help icon
- Revisiting previous lessons

**Mastery Signals:**
- 5+ correct answers in a row
- Fast completion times
- No hints used
- Optional challenges completed

**Adaptive Responses:**

**When Frustrated:**
```swift
avatar.mood = .encouraging
avatar.expression = .caring
avatar.speak("Hey, I noticed this part is tricky. Let me explain it a different way.")

// Offer alternative explanation
showAlternativeExplanation(currentConcept)

// Or suggest break
avatar.speak("You've been working hard! Want to take a 5-minute break?")
```

**When Confused:**
```swift
avatar.mood = .friendly
avatar.expression = .thinking
avatar.speak("Let's take a step back. Which part would you like me to clarify?")

// Show concept breakdown
showConceptBreakdown(currentLesson)
```

**When Mastering:**
```swift
avatar.mood = .celebrating
avatar.expression = .excited
avatar.gesture = .celebrating
avatar.speak("Yes! You're crushing it! 🎉")

// Award XP
awardXP(50)

// Show achievement
showAchievement(.init(title: "Concept Mastered!", xp: 50))
```

#### **3.7 Interactive Exercise Types**

**1. Multiple Choice Quiz:**
```swift
struct MultipleChoiceExercise: View {
    let question: String
    let options: [String]
    let correctIndex: Int
    let onAnswer: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question)
                .font(DesignTokens.Typography.headline)
            
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    let isCorrect = index == correctIndex
                    onAnswer(isCorrect)
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke())
                }
            }
        }
    }
}
```

**2. Fill in the Blank:**
```swift
struct FillInBlankExercise: View {
    let prompt: String
    let blanks: [String]
    let correctAnswers: [String]
    @State private var userAnswers: [String]
    
    // Implementation with TextField and validation
}
```

**3. Drag & Drop:**
```swift
struct DragDropExercise: View {
    let items: [DraggableItem]
    let targets: [DropTarget]
    let correctMappings: [String: String]
    
    // Implementation with drag gesture and drop zones
}
```

**4. Code Editor:**
```swift
struct CodeEditorExercise: View {
    let prompt: String
    let starterCode: String
    let testCases: [TestCase]
    @State private var code: String
    
    var body: some View {
        VStack {
            Text(prompt)
            
            // Code editor with syntax highlighting
            CodeEditorView(code: $code, language: .python)
            
            Button("Run Code") {
                runCodeAndTest()
            }
            
            TestResultsView(results: testResults)
        }
    }
}
```

#### **3.8 Learning Environments (Backgrounds)**

**Available Environments:**
1. **Cozy Library** (Default)
   - Warm lighting, bookshelves
   - Ambient sound: Pages turning, soft music

2. **Modern Lab**
   - Clean, white, scientific equipment
   - Ambient sound: Beeps, hums

3. **Space Station**
   - Futuristic, stars outside window
   - Ambient sound: Space ambience, beeps

4. **Beach Cafe**
   - Tropical, ocean view
   - Ambient sound: Waves, seagulls

5. **Forest Classroom**
   - Nature, trees, sunlight
   - Ambient sound: Birds, rustling leaves

**Unlocking:**
- Library: Default (0 XP)
- Lab: 500 XP
- Space: 1000 XP
- Beach: 2000 XP
- Forest: 5000 XP

#### **3.9 Implementation Steps**

**Step 3.1: Create LivingMentorViewModel**
- [ ] File: `LivingMentorViewModel.swift`
- [ ] Content: Orchestrates avatar, lessons, emotions, progress
- [ ] Test: State management works, no memory leaks

**Step 3.2: Create AnimatedAvatarView**
- [ ] File: `AnimatedAvatarView.swift`
- [ ] Content: Avatar rendering with moods, expressions, gestures
- [ ] Test: Animations smooth, transitions clean, 60fps

**Step 3.3: Implement AvatarSpeechEngine**
- [ ] File: `AvatarSpeechEngine.swift`
- [ ] Content: Text-to-speech with lip sync
- [ ] Test: Speech clear, lip sync accurate, timing correct

**Step 3.4: Create VirtualWhiteboard**
- [ ] File: `VirtualWhiteboard.swift`
- [ ] Content: Whiteboard canvas with element drawing/animation
- [ ] Test: Elements render, animations smooth, interactions work

**Step 3.5: Create EmotionalIntelligenceEngine**
- [ ] File: `EmotionalIntelligenceEngine.swift`
- [ ] Content: Pattern detection, adaptive responses
- [ ] Test: Detects user states accurately, responses appropriate

**Step 3.6: Create Interactive Exercise Components**
- [ ] Files: `MultipleChoiceExercise.swift`, `FillInBlankExercise.swift`, `DragDropExercise.swift`, `CodeEditorExercise.swift`
- [ ] Content: All exercise types with validation
- [ ] Test: All types work, validation accurate, UX smooth

**Step 3.7: Create LessonContentInteractiveView**
- [ ] File: `LessonContentInteractiveView.swift`
- [ ] Content: Combines text, whiteboard, exercises
- [ ] Test: Content renders, switches between types smoothly

**Step 3.8: Create EnvironmentBackgroundView**
- [ ] File: `EnvironmentBackgroundView.swift`
- [ ] Content: 5 themed backgrounds with animations
- [ ] Test: Themes render, switching smooth, performance good

**Step 3.9: Create MotivationalProgressBar**
- [ ] File: `MotivationalProgressBar.swift`
- [ ] Content: XP, streaks, milestones, celebrations
- [ ] Test: Progress updates, animations trigger, data persists

**Step 3.10: Integrate Achievement System**
- [ ] Create `AchievementCelebrationView.swift`
- [ ] Define achievement types and unlock conditions
- [ ] Test: Achievements trigger correctly, celebrations show

**Step 3.11: Assemble LivingMentorView**
- [ ] File: `LivingMentorView.swift`
- [ ] Content: Avatar + lesson content + progress + resources
- [ ] Test: 70/30 layout works, all components integrated

**Step 3.12: Generate Lessons with Gemini**
- [ ] Update lesson generation prompt
- [ ] Parse AI response into InteractiveLesson structure
- [ ] Test: Lessons are engaging, exercises work, content appropriate

**Step 3.13: Integrate with AIOnboardingFlowView**
- [ ] Replace `AIClassroomView` with `LivingMentorView`
- [ ] Pass blueprint data
- [ ] Test: Full flow works end-to-end

**Step 3.14: Error Checking & Polish**
- [ ] Test all avatar animations
- [ ] Verify speech quality and timing
- [ ] Check emotional detection accuracy
- [ ] Test all exercise types thoroughly
- [ ] Performance test with complex lessons
- [ ] Fix any issues

---

### **Phase 4: Gamification & Avatar Customization (Weeks 11-12)**
**Goal:** Add depth to engagement with XP system, unlockables, customization, and social features.

#### **4.1 XP & Progression System**

**XP Sources:**
- Lesson completion: 100 XP
- Quiz perfect score: 50 XP
- Daily streak maintained: 25 XP
- Optional challenge: 75 XP
- Course completion: 500 XP
- Helping others (future): 30 XP

**Levels:**
```
Level 1: 0-499 XP (Beginner)
Level 2: 500-999 XP (Learner)
Level 3: 1000-1999 XP (Student)
Level 4: 2000-4999 XP (Scholar)
Level 5: 5000-9999 XP (Expert)
Level 6: 10000+ XP (Master)
```

**Level Up Benefits:**
- Avatar customization items
- Environment unlocks
- New avatar gestures
- Special badges
- Priority AI suggestions

#### **4.2 Avatar Customization Shop**

**Shop Interface:**
```swift
struct AvatarCustomizationShop: View {
    @StateObject var viewModel: ShopViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // User's XP balance
                XPBalanceCard(currentXP: viewModel.userXP)
                
                // Categories
                ForEach(ShopCategory.allCases) { category in
                    CategorySection(
                        category: category,
                        items: viewModel.items(for: category),
                        onPurchase: { item in
                            viewModel.purchase(item)
                        }
                    )
                }
            }
        }
    }
}
```

**Shop Categories:**
1. **Outfits** (100-500 XP each)
   - Casual (free)
   - Scientist
   - Artist
   - Astronaut
   - Athlete
   - Business

2. **Hairstyles** (75-200 XP each)
   - Short (free)
   - Long
   - Curly
   - Pixie
   - Mohawk

3. **Accessories** (50-150 XP each)
   - Glasses
   - Hat
   - Badge
   - Scarf
   - Watch

4. **Environments** (500-5000 XP each)
   - Library (free)
   - Lab (500)
   - Space (1000)
   - Beach (2000)
   - Forest (5000)

#### **4.3 Achievement System**

**Achievement Categories:**

**Learning Achievements:**
- 🎓 First Lesson: Complete your first lesson
- 📚 Bookworm: Complete 10 lessons
- 🧠 Knowledge Master: Complete a full course
- ⚡️ Speed Learner: Complete lesson in under 10 minutes
- 🎯 Perfectionist: Get 100% on 5 quizzes

**Streak Achievements:**
- 🔥 Getting Warm: 3-day streak
- 🔥🔥 On Fire: 7-day streak
- 🔥🔥🔥 Unstoppable: 30-day streak
- 🔥🔥🔥🔥 Legend: 100-day streak

**Exploration Achievements:**
- 🌟 Curious Mind: Try 3 different topics
- 🎨 Style Master: Customize avatar fully
- 🌍 World Explorer: Unlock all environments

**Mastery Achievements:**
- 💎 Quick Learner: 10 perfect quizzes in a row
- 🏆 Course Champion: Complete 5 full courses
- 👑 Lyo Master: Reach Level 6

#### **4.4 Streak System**

**Streak Tracking:**
```swift
class StreakTracker: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastActivityDate: Date?
    
    func recordActivity() {
        let today = Date().startOfDay
        
        guard let lastDate = lastActivityDate else {
            // First activity
            currentStreak = 1
            lastActivityDate = today
            return
        }
        
        let daysSinceLastActivity = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
        
        if daysSinceLastActivity == 0 {
            // Already recorded today
            return
        } else if daysSinceLastActivity == 1 {
            // Consecutive day
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            // Streak broken
            currentStreak = 1
        }
        
        lastActivityDate = today
    }
}
```

**Streak UI:**
- Flame icon that grows with streak
- Color changes (orange → red → blue for 30+)
- Streak freeze items (1 per week, costs 200 XP)
- Streak leaderboard (future)

#### **4.5 Implementation Steps**

**Step 4.1: Create XP System**
- [ ] File: `XPSystem.swift`
- [ ] Content: XP sources, level calculation, XP awarding logic
- [ ] Test: XP awards correctly, levels up at thresholds

**Step 4.2: Create Achievement System**
- [ ] File: `AchievementSystem.swift`
- [ ] Content: All achievements, unlock conditions, tracking
- [ ] Test: Achievements unlock correctly, no duplicates

**Step 4.3: Create Streak Tracker**
- [ ] File: `StreakTracker.swift`
- [ ] Content: Daily tracking, streak calculation, freeze system
- [ ] Test: Streaks count correctly, freeze works, persists

**Step 4.4: Create Avatar Customization Shop**
- [ ] File: `AvatarCustomizationShop.swift`
- [ ] Content: Shop UI, items, purchase logic, preview
- [ ] Test: Items display, purchase works, XP deducts

**Step 4.5: Integrate Customization with Avatar**
- [ ] Update `AnimatedAvatarView` to use customization
- [ ] Test: Avatar reflects purchases, changes smooth

**Step 4.6: Create Progress Dashboard**
- [ ] File: `ProgressDashboard.swift`
- [ ] Content: XP, level, streaks, achievements, stats
- [ ] Test: All data displays accurately, updates in real-time

**Step 4.7: Add Celebration Animations**
- [ ] Level up animation
- [ ] Achievement unlock animation
- [ ] Streak milestone animation
- [ ] Test: Animations trigger correctly, feel rewarding

**Step 4.8: Error Checking & Polish**
- [ ] Test XP persistence across sessions
- [ ] Verify achievement unlock logic
- [ ] Check streak calculation edge cases
- [ ] Test shop purchases and unlocks
- [ ] Fix any issues

---

## 🧪 Continuous Error Checking Protocol

**After Every Component:**
1. **Build Test** - Run `xcodebuild` and check for errors
2. **Syntax Check** - Verify no compiler warnings
3. **Runtime Test** - Run in simulator, test interactions
4. **Memory Check** - Monitor memory usage, check for leaks
5. **Performance Check** - Ensure 60fps, smooth animations

**Before Moving to Next Phase:**
1. **Integration Test** - Test all components together
2. **Flow Test** - Complete user journey works end-to-end
3. **Edge Case Test** - Test error scenarios, empty states
4. **Device Test** - Test on different screen sizes
5. **Accessibility Test** - VoiceOver, Dynamic Type

**Issue Resolution:**
1. Identify error/warning
2. Document root cause
3. Implement fix
4. Verify fix works
5. Test related functionality
6. Continue implementation

---

## 📊 Success Metrics

**Phase 1 Success:**
- ✅ Diagnostic completes in under 2 minutes
- ✅ Blueprint updates in real-time (<100ms delay)
- ✅ Avatar animations at 60fps
- ✅ AI intent extraction >90% accurate

**Phase 2 Success:**
- ✅ Users can create 5+ node blueprints
- ✅ Drag interactions feel smooth (<16ms latency)
- ✅ AI suggestions relevant (user acceptance >60%)
- ✅ Layout algorithm produces readable maps

**Phase 3 Success:**
- ✅ Avatar feels alive (user feedback)
- ✅ Speech is clear and natural
- ✅ Emotional detection accuracy >80%
- ✅ Users complete lessons (>70% completion rate)

**Phase 4 Success:**
- ✅ Users customize avatars (>50% engagement)
- ✅ Streaks maintained (avg >7 days)
- ✅ Achievements unlocked (avg 5 per user)
- ✅ XP system motivates (retention +30%)

---

## 🚀 Launch Checklist

Before considering "complete":
- [ ] All 4 phases implemented
- [ ] No critical bugs
- [ ] Performance acceptable (60fps, <100MB memory)
- [ ] User testing completed (5+ users)
- [ ] Accessibility verified
- [ ] Documentation updated
- [ ] Backend integration complete (if needed)
- [ ] Analytics tracking added
- [ ] Error logging configured
- [ ] Privacy policy updated (if needed)

---

## 📝 Notes

**Technology Stack:**
- SwiftUI for all UI
- Combine for reactive state
- AVFoundation for speech
- Core Animation for advanced effects
- Gemini AI for content generation
- CloudKit or Firebase for persistence (TBD)

**Team Coordination:**
- This document serves as single source of truth
- Update after each phase completion
- Flag blockers immediately
- Celebrate wins!

**Estimated Timeline:**
- Phase 1: 3 weeks
- Phase 2: 3 weeks
- Phase 3: 4 weeks
- Phase 4: 2 weeks
- **Total: 12 weeks**

**Current Status:** Ready to begin Phase 1

---

*This document will be updated as we progress through implementation.*
