# Unity Course Activation - Visual Flow

## 📱 User Journey

```
┌─────────────────────────────────────────────────────────────┐
│                     LEARNING HUB                             │
├─────────────────────────────────────────────────────────────┤
│  [Search Bar: "Search courses..."]                          │
│                                                              │
│  [All] [Programming] [Data Science] [Design]                │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  [Image]     │  │  [Image]     │  │  [Image]     │     │
│  │  Maya        │  │  Mars        │  │  Chemistry   │     │
│  │  4.8⭐       │  │  4.9⭐       │  │  4.7⭐       │     │
│  │ [START] [✓]  │  │ [START] [📝] │  │ [START] [📝] │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    USER TAPS "START"
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              DYNAMIC CLASSROOM (Unity-Powered)               │
├─────────────────────────────────────────────────────────────┤
│  Tikal, Guatemala                              [X Close]    │
│  1200 CE              👤 Maya Elder                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│      🏛️ Maya Temple Background (Immersive)                 │
│                                                              │
│           Ancient Maya Civilization                          │
│                                                              │
│  📍 Location: Tikal Ceremonial Center                       │
│  ⏰ Time Period: 1200 CE                                    │
│  📖 Explore Maya culture, architecture, and history...      │
│                                                              │
│  ⏱️ 4h     ⭐ 4.8     👥 1,500 enrolled                     │
│                                                              │
│          [▶️ Start Interactive Lesson]                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Button States

### Course Card Buttons

```
┌─────────────────────────────────┐
│  NOT ENROLLED                   │
├─────────────────────────────────┤
│  [▶️ Start]  [Enroll]           │
│   (Cyan)      (Blue)            │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  ENROLLED                       │
├─────────────────────────────────┤
│  [▶️ Start]  [✓]                │
│   (Cyan)     (Green, disabled)  │
└─────────────────────────────────┘
```

---

## 🌍 Environment Examples

### 1. Maya Temple (History)
```
Background: Ancient stone pyramids, jungle canopy
Colors: Earth tones (brown, green, stone gray)
Cultural Elements: Calendar stones, hieroglyphs, jade artifacts
Avatar: Maya Elder Historian
Time Period: 1200 CE
Location: Tikal, Guatemala
```

### 2. Mars Surface (Science)
```
Background: Red rocky terrain, distant craters
Colors: Red, orange, dusty pink
Cultural Elements: Rover, habitat modules, rock samples
Avatar: Space Scientist
Time Period: 2025
Location: Mars Surface Base
```

### 3. Chemistry Lab (Science)
```
Background: Modern laboratory with equipment
Colors: White, steel blue, glass reflections
Cultural Elements: Beakers, periodic table, molecular models
Avatar: Chemistry Professor
Time Period: 2025
Location: State-of-the-art Laboratory
```

---

## 🎨 Color Scheme

### Course Cards
- **Background**: `Color(.systemGray6)` (light gray)
- **Text**: White/Gray contrast
- **Start Button**: Cyan (`Color.cyan`)
- **Enroll Button**: Blue (`Color.blue.opacity(0.8)`)
- **Enrolled Badge**: Green (`Color.green.opacity(0.2)`)

### Dynamic Classroom
- **Header**: `Color.black.opacity(0.4)`
- **Text**: White
- **Environment**: Category-specific gradients
- **Start Lesson Button**: Cyan (`Color.cyan`)

---

## 📐 Layout Specifications

### Course Card
```
┌────────────────────────┐
│  Thumbnail (120pt)     │  ← AsyncImage with placeholder
├────────────────────────┤
│  Title (2 lines max)   │  ← .subheadline, semibold
│  Description (3 lines) │  ← .caption, gray
│  [Category] ⭐ Rating  │  ← Badges and rating
│  [Start] [Enroll]      │  ← Action buttons
└────────────────────────┘
Total Width: Flexible (Grid: 2 columns)
Padding: 12pt all sides
Corner Radius: 12pt
```

### Dynamic Classroom Header
```
┌─────────────────────────────────────┐
│  Location              [X Close]    │  ← Header bar
│  Time Period    Avatar Role         │
├─────────────────────────────────────┤
│  (Scrollable Content Below)         │
└─────────────────────────────────────┘
Height: Auto (based on content)
Background: Black 40% opacity
Padding: 16pt
```

---

## 🔄 State Transitions

### Animation Flow

```
Learning Hub
    ↓ (fade in)
Course Card Tap
    ↓ (.move(edge: .trailing))
Dynamic Classroom
    ↓ (slide from right)
Immersive Experience
    ↓ (close button)
Learning Hub
    ↓ (fade out)
```

### SwiftUI Modifiers
```swift
.transition(.move(edge: .trailing))  // Classroom enters
.zIndex(1)                           // Classroom on top
.animation(.easeInOut(duration: 0.3)) // Smooth transition
```

---

## 📊 Data Mapping

### LearningResource → Course Conversion

```
LearningResource                Course
├─ id: String              →    id: UUID
├─ title: String           →    title: String
├─ description: String     →    description: String
├─ authorCreator: String?  →    instructor: String
├─ duration: Int           →    duration: Int
├─ difficulty: String      →    difficulty: Enum
├─ tags: [String]          →    tags: [String]?
├─ thumbnailUrl: String?   →    thumbnailURL: URL?
├─ progress: Double        →    progress: Double
├─ isEnrolled: Bool        →    isEnrolled: Bool
└─ createdAt: String       →    createdAt: Date
```

---

## 🎯 Interaction Patterns

### Tap Zones

```
┌────────────────────────┐
│  [Entire Card Area]    │  ← No default action
│  ┌──────────────────┐  │
│  │ Thumbnail        │  │  ← No action
│  └──────────────────┘  │
│  Title/Description     │  ← No action
│  [Start] [Enroll]      │  ← Explicit buttons
└────────────────────────┘

Start Button:
- Primary action: Launch classroom
- Visual feedback: Cyan highlight
- Async operation: Shows loading

Enroll Button:
- Secondary action: Enroll in course
- Disabled when enrolled
- Shows checkmark when complete
```

---

## 🚀 Performance Notes

### Optimization
- **Lazy Loading**: LazyVGrid for course cards
- **AsyncImage**: Automatic image caching
- **@StateObject**: Single shared manager instance
- **@MainActor**: All UI updates on main thread

### Memory Management
- Course conversion is lightweight
- No retained circular references
- Proper cleanup on dismiss

---

## ✅ Accessibility

### VoiceOver Support
```swift
.accessibilityLabel("Start \(course.title)")
.accessibilityHint("Launches immersive classroom experience")
```

### Dynamic Type
- All text scales with system font size
- Minimum touch targets: 44x44pt
- High contrast mode compatible

---

## 🎉 Ready to Use!

**Everything is wired up and ready for testing:**
1. Open Classroom tab
2. See 3 sample courses
3. Tap "Start" on any course
4. Experience immersive Unity classroom
5. Close to return to hub

**Build Status: ✅ SUCCESSFUL (0 errors)**
