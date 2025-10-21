# TikTok Video Feed - Visual Reference

## 📱 Main Feed Interface

```
┌─────────────────────────────────────┐
│         Following  [For You]        │  ← Top toggle
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
│        FULL SCREEN VIDEO            │
│        (9:16 aspect ratio)          │
│                                     │
│                                     │
│  ┌─────────────────────┐            │
│  │ @username ✓         │   [❤️ 12K]│  ← Action
│  │ Video Title Here    │   [💬 234]│     Buttons
│  │ Description text... │   [🔖 1.2K]│
│  │ #swift #ios #code   │   [📤 89] │
│  │ 🎵 Original Sound   │            │
│  │ 👁 1.2M views       │   [👤]    │  ← Profile
│  └─────────────────────┘            │     Disc
│                                     │
└─────────────────────────────────────┘
```

---

## 🎬 Video Player States

### Playing State
```
┌─────────────────────────────────────┐
│                                     │
│          [VIDEO PLAYING]            │
│                                     │
│  ▶️ Auto-playing                    │
│  🔊 Sound on                        │
│  🔄 Looping enabled                 │
└─────────────────────────────────────┘
```

### Paused State
```
┌─────────────────────────────────────┐
│                                     │
│          [VIDEO PAUSED]             │
│                                     │
│            ⏸️                       │
│       (Large pause icon)            │
│                                     │
└─────────────────────────────────────┘
```

---

## 👆 Gesture Controls

### Vertical Swipe (Primary Navigation)
```
         ⬆️ Swipe Up
      ┌─────────┐
      │ Video 3 │  ← Next
      ├─────────┤
      │ Video 2 │  ← Current (visible)
      ├─────────┤
      │ Video 1 │  ← Previous
      └─────────┘
         ⬇️ Swipe Down

Threshold: 100pt vertical movement
Animation: Spring (response: 0.3, damping: 0.8)
```

### Tap Interactions
```
┌─────────────────────────────────────┐
│ [Tap anywhere]  →  Pause/Play       │
│                                     │
│ [Tap profile pic]  →  Open profile  │
│ [Tap @username]  →  Open profile    │
│ [Tap description]  →  Expand text   │
│ [Tap action button]  →  Execute     │
└─────────────────────────────────────┘
```

---

## 💬 Comments Sheet

```
┌─────────────────────────────────────┐
│         ━━━  (Drag handle)          │
│                                     │
│  📝 234 Comments              ✖️    │
│  ─────────────────────────────────  │
│                                     │
│  👤 @user123        Just now        │
│     This is amazing! 🔥             │
│     ❤️ 12  Reply                    │
│                                     │
│  👤 @learner_pro    2m ago          │
│     Thanks for sharing!             │
│     ❤️ 5  Reply                     │
│                                     │
│  [More comments...]                 │
│                                     │
│  ─────────────────────────────────  │
│  👤 [Add comment...]         📤     │
└─────────────────────────────────────┘

Height: 70% of screen
Animation: Slide from bottom
Dismiss: Swipe down or tap X
```

---

## 📤 Share Sheet

```
┌─────────────────────────────────────┐
│         ━━━  (Drag handle)          │
│                                     │
│  Share                        ✖️    │
│  ─────────────────────────────────  │
│                                     │
│     💬         🔗                   │
│   Message   Copy Link               │
│                                     │
│     📤         💾                   │
│    More      Save                   │
│                                     │
└─────────────────────────────────────┘

Height: 300pt
Layout: 4-column grid
Icons: Circular 60pt backgrounds
Colors: Blue, Green, Orange, Purple
```

---

## 👤 User Profile Sheet

```
┌─────────────────────────────────────┐
│                              ✖️     │
│                                     │
│           👤                        │
│      (Large gradient                │
│       profile avatar                │
│         100pt)                      │
│                                     │
│       @username ✓                   │
│   Teaching you code daily 💻        │
│                                     │
│   89          125K        234       │
│  Following   Followers   Videos     │
│                                     │
│  [Follow ✨]          [✉️]          │
│  (Gradient button)  (Message)       │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Saved Videos                       │
│                                     │
│  ┌───┬───┬───┐                     │
│  │ 1 │ 2 │ 3 │  ← 3-column grid    │
│  ├───┼───┼───┤                     │
│  │ 4 │ 5 │ 6 │  ← Video thumbnails │
│  ├───┼───┼───┤     with play icon  │
│  │ 7 │ 8 │ 9 │     and view count  │
│  └───┴───┴───┘                     │
│                                     │
└─────────────────────────────────────┘

Animation: Slide from right
Width: Full screen
Dismiss: Swipe right or tap X
```

---

## 🎨 Action Button Layout

### Vertical Stack (Right Side)

```
                   Screen Edge
                        │
        ┌───────────────┤
        │               │
        │    ❤️  12K    │  ← Like (32pt icon)
        │               │     Red when active
        │               │
        │    💬  234    │  ← Comments
        │               │     White icon
        │               │
        │    🔖  1.2K   │  ← Save
        │               │     Yellow when active
        │               │
        │    📤  89     │  ← Share
        │               │     White icon
        │               │
        │      👤       │  ← Profile
        │   (48pt disc, │     Rotating animation
        │    rotating)  │     when current video
        │               │
        └───────────────┘

Spacing: 24pt between buttons
Padding: 12pt from right edge
Bottom: 100pt from bottom (above nav bar)
```

---

## 🎭 Animation Sequences

### Like Animation
```
Frame 1 (0.0s):   ❤️ (scale: 1.0, white)
Frame 2 (0.1s):   ❤️ (scale: 1.3, red fill)
Frame 3 (0.2s):   ❤️ (scale: 1.0, red fill)

Duration: 0.3s
Easing: Spring (response: 0.3, damping: 0.6)
```

### Profile Disc Rotation
```
 0° ──────► 360° ──────► (repeat forever)
 │                        │
 └────────────────────────┘
           3 seconds

Condition: Only when isCurrentVideo == true
Animation: .linear(duration: 3).repeatForever()
```

### Video Transition
```
Video Index 0  (y: -screenHeight)
     ▼
Video Index 1  (y: 0)           ← Current, visible
     ▼
Video Index 2  (y: +screenHeight)

Swipe Up Gesture:
  Frame 1: Drag offset tracks finger
  Frame 2: Release at -100pt threshold
  Frame 3: Spring animation to next index
  Duration: ~0.3s with spring damping
```

### Sheet Presentation
```
Frame 1 (hidden):  y = screenHeight
Frame 2 (start):   y = screenHeight
Frame 3 (visible): y = 0

Transition: .move(edge: .bottom)
Animation: .spring(response: 0.3, dampingFraction: 0.8)
```

---

## 🎯 Hit Targets & Spacing

### Action Buttons
```
Button Size: 32pt × 32pt (icon)
Touch Target: ~60pt × 60pt (with padding)
Text Size: 13pt (semibold)
Vertical Spacing: 24pt between centers
```

### Profile Avatar (in feed)
```
Small Avatar: 48pt circle
Touch Target: 48pt (full circle tappable)
Border: None (gradient fill)
Initial Letter: 20pt bold
```

### Profile Avatar (in profile sheet)
```
Large Avatar: 100pt circle
Border: 4pt white stroke
Initial Letter: 40pt bold
Shadow: Radius 10pt
```

---

## 📊 Content Layout Dimensions

### Video Info Section
```
┌─────────────────────────────────────┐
│ Profile + Username                  │
│ 48pt avatar + 12pt spacing          │
│                                     │
│ Title (18pt semibold)               │
│ 2 lines max, then truncate          │
│                                     │
│ Description (15pt regular)          │
│ 2 lines collapsed, expand on tap    │
│                                     │
│ Hashtags (14pt semibold)            │
│ Horizontal scroll, 8pt spacing      │
│ Capsule: 12pt H padding, 6pt V      │
│                                     │
│ Sound (14pt regular)                │
│ 🎵 icon + text                      │
│                                     │
│ Views (13pt regular, 70% opacity)   │
│ 👁 icon + formatted number          │
└─────────────────────────────────────┘

Left Padding: 16pt
Right Margin: 80pt (for action buttons)
Bottom Padding: 100pt (above nav bar)
```

---

## 🌈 Color Palette

### Profile Gradients
```
Style 1: Purple → Pink
  Start: #8B5CF6 (Purple)
  End:   #EC4899 (Pink)

Style 2: Blue → Cyan
  Start: #3B82F6 (Blue)
  End:   #06B6D4 (Cyan)

Style 3: Purple → Pink → Orange
  Colors: [#8B5CF6, #EC4899, #F97316]
```

### UI Elements
```
Background:      #000000 (Black)
Text Primary:    #FFFFFF (White 100%)
Text Secondary:  #FFFFFF (White 80%)
Text Tertiary:   #FFFFFF (White 70%)

Like Active:     #EF4444 (Red)
Save Active:     #EAB308 (Yellow)
Verify Badge:    #3B82F6 (Blue)
```

### Overlays
```
Top Gradient:    Black 60% → Clear
Bottom Gradient: Clear → Black 40%

Blur Effect:     .systemMaterialDark
Opacity: 15% for buttons
```

---

## 📐 Layout Breakpoints

### iPhone SE (Small)
```
Screen Width: 375pt
Video Width: 375pt
Action Buttons: Right side, 12pt padding
Text: 2 lines max for title
```

### iPhone 14 Pro (Standard)
```
Screen Width: 393pt
Video Width: 393pt
Action Buttons: Right side, 12pt padding
Text: 2 lines max for title
```

### iPhone 14 Pro Max (Large)
```
Screen Width: 430pt
Video Width: 430pt
Action Buttons: Right side, 16pt padding
Text: 3 lines max for title
```

### iPad (Tablet)
```
Screen Width: 768pt+
Video Width: 540pt (centered)
Action Buttons: Overlay on video
Text: Full description visible
```

---

## 🎬 Empty States

### No Videos
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│            🎥                       │
│      (64pt icon, 60% opacity)       │
│                                     │
│     No content available            │
│     (20pt bold, white)              │
│                                     │
│  Check back later for new content   │
│  (16pt regular, 70% opacity)        │
│                                     │
└─────────────────────────────────────┘
```

### No Comments
```
┌─────────────────────────────────────┐
│                                     │
│            💬                       │
│      (48pt icon, 50% opacity)       │
│                                     │
│      No comments yet                │
│      (16pt medium, gray)            │
│                                     │
│   Be the first to comment!          │
│   (14pt regular, gray 70%)          │
│                                     │
└─────────────────────────────────────┘
```

### No Saved Videos
```
┌─────────────────────────────────────┐
│                                     │
│            🔖                       │
│      (48pt icon, 50% opacity)       │
│                                     │
│     No saved videos yet             │
│     (16pt medium, gray)             │
│                                     │
└─────────────────────────────────────┘
```

---

## ⚡ Performance Targets

### Load Times
```
Video Start:    < 1.0s
Swipe Response: < 100ms
Sheet Open:     < 200ms
Like Animation: 300ms
```

### Memory Usage
```
Single Video:  ~50MB
3 Videos:      ~150MB
Peak Usage:    < 200MB
Cache Limit:   10 videos
```

### Frame Rate
```
Target:        60 FPS
Minimum:       30 FPS
Swipe:         60 FPS maintained
Animations:    60 FPS maintained
```

---

## 🎉 Summary

A complete, pixel-perfect TikTok-style feed with:

✅ **Full-screen video** (9:16 aspect ratio)
✅ **Vertical swipe** navigation
✅ **Right-side action** buttons
✅ **Profile disc** with rotation
✅ **Comments sheet** (70% height)
✅ **Share sheet** (300pt height)
✅ **User profile** (full screen, slide from right)
✅ **Saved videos grid** (3 columns)
✅ **Smooth animations** (spring, 0.3s response)
✅ **Haptic feedback** (all interactions)
✅ **Empty states** (no videos, comments, saves)

**Status**: 🚀 **Production Ready**

All measurements, colors, and animations professionally tuned for optimal user experience!
