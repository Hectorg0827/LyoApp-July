# Stories System - Visual Guide 🎨

## Component Hierarchy

```
┌─────────────────────────────────────────┐
│         StoriesDrawerView               │
│  ┌───────────────────────────────────┐  │
│  │      Drawer Handle (tap)          │  │
│  └───────────────────────────────────┘  │
│                                          │
│  ┌───────────────────────────────────┐  │
│  │     COLLAPSED STATE (Default)     │  │
│  │  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │  │
│  │  │ T │ │ D │ │ C │ │ D │ │ C │   │  │
│  │  │ G │ │ W │ │ N │ │ S │ │ M │   │  │
│  │  └───┘ └───┘ └───┘ └───┘ └───┘   │  │
│  │  Story Orbs (horizontal scroll)   │  │
│  └───────────────────────────────────┘  │
│                                          │
│         OR (when expanded)               │
│                                          │
│  ┌───────────────────────────────────┐  │
│  │     EXPANDED STATE                │  │
│  │                                   │  │
│  │  Quick Actions                    │  │
│  │  ⚪ ⚪ ⚪ ⚪                        │  │
│  │  🔍 🔔 💬 ➕                      │  │
│  │                                   │  │
│  │  ───────────────────────────────  │  │
│  │                                   │  │
│  │  Stories                          │  │
│  │  ┌───┐ ┌───┐ ┌───┐ ┌───┐        │  │
│  │  │ T │ │ D │ │ C │ │ D │        │  │
│  │  │ G │ │ W │ │ N │ │ S │        │  │
│  │  └───┘ └───┘ └───┘ └───┘        │  │
│  │  user  user  user  user          │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## Story Orb States

### Unviewed Story
```
     ┌─────────────────────┐
     │  Gradient Ring      │  ← Pink/Plum gradient
     │   ┌───────────┐     │     (3pt width)
     │   │           │     │
     │   │     T     │     │  ← User initial
     │   │           │     │     (white on color)
     │   └───────────┘     │
     └─────────────────────┘
     
     Colors:
     #FF1493 (Deep Pink)
     #FF69B4 (Hot Pink)
     #FFB6C1 (Light Pink)
     #DDA0DD (Plum)
```

### Viewed Story
```
     ┌─────────────────────┐
     │   Gray Ring         │  ← Gray 30% opacity
     │   ┌───────────┐     │     (3pt width)
     │   │           │     │
     │   │     T     │     │  ← User initial
     │   │           │     │     (white on color)
     │   └───────────┘     │
     └─────────────────────┘
```

---

## Story Viewer Layout

```
┌─────────────────────────────────────┐
│ ▬▬▬ ▬▬▬ ▬▬▬ ▬▬▬ ▬▬▬              │ ← Progress bars
│                                     │   (one per segment)
│  ⚪ Username        ✕              │ ← Header
│     2h ago                          │
│                                     │
│                                     │
│                                     │
│         CONTENT AREA                │ ← Photo/Video/Text
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│  ←          │          →           │ ← Tap zones
│   Previous  │     Next              │   (left/right)
└─────────────────────────────────────┘
   Swipe down ↓ to dismiss
```

---

## Auto-Hide Timer Flow

```
User Opens Drawer
       │
       ▼
  ┌─────────┐
  │ Expanded│
  │ State   │
  └────┬────┘
       │
       ▼
  lastInteractionTime = Now
       │
       ▼
  Start 40s Timer ⏱️
       │
       ├─────► User Taps Orb ─────► Reset Timer ⏱️ (back to 0s)
       │
       ├─────► User Taps Handle ──► Reset Timer ⏱️
       │
       ├─────► User Views Story ──► Reset Timer ⏱️
       │
       ▼
    40s Passes
       │
       ▼
  ┌─────────┐
  │Collapsed│ ← Auto-hide triggered
  │ State   │
  └─────────┘
```

---

## Integration Points

### Home Feed View
```
┌────────────────────────────────────┐
│  Top Status Bar (Production)      │
├────────────────────────────────────┤
│  Stories Drawer                    │ ← Added here
│  ┌───┐ ┌───┐ ┌───┐               │
│  │ T │ │ D │ │ C │               │
│  └───┘ └───┘ └───┘               │
├────────────────────────────────────┤
│                                    │
│        Feed Content                │
│                                    │
│    (Videos, Courses, etc.)         │
│                                    │
└────────────────────────────────────┘
```

### Discover Feed View (TikTok-style)
```
┌────────────────────────────────────┐
│  Stories Drawer                    │ ← Added at top
│  ┌───┐ ┌───┐ ┌───┐               │
│  │ T │ │ D │ │ C │               │
│  └───┘ └───┘ └───┘               │
├────────────────────────────────────┤
│                                    │
│                                    │
│      Video Content                 │
│      (Full Screen)                 │
│                                    │
│                                    │
│                                    │
│                                    │
│              ⚪                    │ ← + button
└────────────────────────────────────┘
   Swipe ↑↓ for videos
```

---

## Segment Types

### Photo Segment
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│         Background Color        │
│                                 │
│         (Photo Image)           │
│                                 │
│                                 │
└─────────────────────────────────┘
Duration: 5 seconds (default)
```

### Video Segment
```
┌─────────────────────────────────┐
│                                 │
│           ▶️ Video              │
│        (AVPlayer)               │
│                                 │
│         With Controls           │
│                                 │
│                                 │
└─────────────────────────────────┘
Duration: 15 seconds (or video length)
```

### Text Segment
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│        "My Story Text"          │
│         📚 🚀 💡               │
│                                 │
│    (Bold 32pt, centered)        │
│                                 │
└─────────────────────────────────┘
Duration: 5 seconds (default)
Background: Custom hex color
```

---

## Progress Bar Animation

```
Segment 1:  ████████████ 100%  (completed)
Segment 2:  ██████------ 60%   (current)
Segment 3:  ------------ 0%    (not started)
Segment 4:  ------------ 0%    (not started)
Segment 5:  ------------ 0%    (not started)

Timer: 0.1s intervals
Progress: += 0.1 / segment.duration
Auto-advance when progress >= 1.0
```

---

## Quick Actions Icons

```
┌─────────────────────────────────────┐
│        Quick Actions                │
├─────────────────────────────────────┤
│                                     │
│   ⚪        ⚪        ⚪        ⚪   │
│   🔍        🔔        💬        ➕   │
│  Search   Alerts  Messages  Create  │
│                                     │
└─────────────────────────────────────┘

Each icon:
- 50pt circle
- System background color
- 20pt SF Symbol
- Caption label below
```

---

## Color Palette

### Story Orbs (Unviewed)
- **Deep Pink:** `#FF1493`
- **Hot Pink:** `#FF69B4`
- **Light Pink:** `#FFB6C1`
- **Plum:** `#DDA0DD`

### Story Orbs (Viewed)
- **Gray:** `Color.gray.opacity(0.3)`

### Story Backgrounds (Examples)
- **Red:** `#FF6B6B`
- **Teal:** `#4ECDC4`
- **Blue:** `#45B7D1`
- **Coral:** `#FFA07A`
- **Mint:** `#98D8C8`
- **Purple:** `#6C5CE7`
- **Lavender:** `#A29BFE`
- **Pink:** `#FD79A8`
- **Yellow:** `#FDCB6E`
- **Green:** `#00B894`

### UI Elements
- **Drawer Background:** System background
- **Drawer Shadow:** Black 10% opacity
- **Handle:** Gray 30% opacity
- **Text (Light):** White
- **Text (Dark):** Primary label

---

## Dimensions Reference

### Drawer
- **Handle:** 40pt × 5pt
- **Corner Radius:** 16pt (collapsed), 24pt (expanded)
- **Horizontal Padding:** 16pt
- **Shadow Radius:** 10pt
- **Shadow Offset:** (0, 5)

### Story Orbs
- **Collapsed:** 64pt diameter
- **Expanded:** 70pt diameter
- **Viewer Header:** 36pt diameter
- **Ring Width:** 3pt
- **Inner Offset:** 8pt

### Collapsed State
- **Height:** 88pt
- **Orb Spacing:** 16pt
- **Horizontal Padding:** 20pt
- **Vertical Padding:** 12pt
- **Max Visible Orbs:** 8

### Expanded State
- **Section Spacing:** 20pt
- **Icon Spacing:** 24pt
- **Icon Circle:** 50pt diameter
- **Icon Size:** 20pt
- **Username Width:** 70pt

### Story Viewer
- **Progress Bar Height:** 3pt
- **Progress Bar Spacing:** 4pt
- **Header Spacing:** 12pt
- **Header Top Padding:** 50pt
- **Close Button:** 32pt × 32pt
- **Content Padding:** 40pt

---

## Animation Timing

### Spring Animations
```swift
.spring(response: 0.4, dampingFraction: 0.8)
```
- **Response:** 0.4 seconds
- **Damping:** 0.8 (slightly bouncy)
- **Used for:** Drawer expand/collapse

### Auto-Hide Timer
- **Check Interval:** 1.0 second
- **Hide Delay:** 40.0 seconds
- **Type:** Repeating Timer

### Progress Timer
- **Update Interval:** 0.1 second
- **Increment:** `0.1 / segment.duration`
- **Type:** Repeating Timer

### Transitions
- **Drawer:** `.move(edge: .top).combined(with: .opacity)`
- **Story Viewer:** `.fullScreenCover` (system default)

---

## Gesture Zones

### Story Viewer Tap Zones
```
┌─────────────────────────────┐
│                             │
│                             │
│   Previous    │    Next     │
│   Segment     │   Segment   │
│   (Left 50%)  │  (Right 50%)│
│                             │
│                             │
└─────────────────────────────┘
```

### Drawer Handle
- **Tap:** Toggle expand/collapse
- **Area:** Full width of handle (40pt × 5pt + padding)

### Story Orb
- **Tap:** Open story viewer
- **Area:** Full circle (64pt or 70pt diameter)

### Swipe Gestures
- **Story Viewer:** Swipe down (threshold: 100pt) → Dismiss
- **Drawer:** No swipe gestures (tap only)

---

## State Management

### StoriesDrawerView States
```swift
@StateObject private var storyManager = StorySystemManager()
@Binding var isExpanded: Bool
@State private var selectedStory: StoryContent?
@State private var showingStoryViewer = false
```

### StorySystemManager States
```swift
@Published var stories: [StoryContent]
@Published var isLoading = false
@Published var lastInteractionTime: Date?
private var hideTimer: Timer?
private let autoHideDelay: TimeInterval = 40.0
```

### StoryViewerView States
```swift
@State private var currentSegmentIndex = 0
@State private var progress: Double = 0
@State private var timer: Timer?
@State private var isPaused = false
```

---

## Component Props

### StoriesDrawerView
```swift
StoriesDrawerView(
    isExpanded: Binding<Bool>  // Two-way binding
)
```

### StoryOrbView
```swift
StoryOrbView(
    story: StoryContent,       // Story data
    size: CGFloat              // 64, 70, or 36
)
```

### StoryViewerView
```swift
StoryViewerView(
    story: StoryContent,       // Current story
    allStories: [StoryContent],// All stories (for navigation)
    isPresented: Binding<Bool> // Dismissal binding
)
```

### HeaderIconButton
```swift
HeaderIconButton(
    icon: HeaderIcon,          // Icon data
    action: () -> Void         // Tap callback
)
```

---

## Testing Visual Checklist

### ✅ Story Orbs
- [ ] Unviewed: Pink/plum gradient ring (4 colors)
- [ ] Viewed: Gray ring (30% opacity)
- [ ] Profile initial: White on colored circle
- [ ] Ring width: 3pt
- [ ] Size matches state (64pt/70pt/36pt)

### ✅ Drawer States
- [ ] Collapsed: Shows 8 orbs, 88pt height
- [ ] Expanded: Shows quick actions + all stories
- [ ] Handle: Visible and centered (40×5pt)
- [ ] Corner radius changes (16pt → 24pt)
- [ ] Shadow visible (black 10%, radius 10)

### ✅ Animations
- [ ] Expand/collapse: Smooth spring animation (0.4s)
- [ ] Auto-hide: Collapses after 40s inactivity
- [ ] Progress bars: Smooth fill animation
- [ ] Segment transitions: Instant on completion

### ✅ Story Viewer
- [ ] Progress bars: One per segment, fills left to right
- [ ] Header: Shows user, timestamp, close button
- [ ] Content: Photo/video/text displays correctly
- [ ] Tap zones: Left (previous), right (next) work
- [ ] Swipe down: Dismisses viewer
- [ ] Auto-advance: Moves to next segment

### ✅ Integration
- [ ] Home feed: Drawer below status bar
- [ ] Discover feed: Drawer above videos
- [ ] No content overlap or clipping
- [ ] Safe area respected
- [ ] Status bar visible

---

**Visual Guide Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Complete ✅

---

*This visual guide complements the technical documentation and provides a clear reference for design implementation and testing.*
