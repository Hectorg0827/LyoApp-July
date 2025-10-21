# Video Creation Visual Reference

## 📱 Screen Layouts & UI Specifications

---

## 1. TikTok Feed with Create Button

```
┌─────────────────────────────────────┐
│                                     │ ← Video content
│                                     │   (full-screen)
│         VIDEO PLAYING               │
│         (Full Screen)               │
│                                     │
│                     ┌─┐             │
│                     │♡│ 12.5K       │
│                     └─┘             │
│                                     │
│                     ┌─┐             │
│                     │💬│ 234        │
│                     └─┘             │
│                                     │
│                     ┌─┐             │ ← Right side
│                     │🔗│ 89         │   engagement
│                     └─┘             │   buttons
│                                     │
│                     ┌─┐             │
│                     │⭐│ Save       │
│                     └─┘             │
│                                     │
│                     ┌───┐           │
│                     │ 👤 │          │ ← Creator
│                     └───┘           │   profile pic
│                                     │
│  @username · 2h ago                 │ ← Video info
│  Video title here...           ╭────╮
│  #hashtag #video              │ +  │ ← CREATE BUTTON
│                               ╰────╯  (floating)
│                                  ↑
│  ┌───┐  ┌───┐  ┌───┐  ┌───┐  ┌───┐
│  │🏠 │  │🔍 │  │   │  │💬 │  │👤 │
│  │Home│  │Disc│  │ + │  │Msg│  │Me │
└──┴───┴──┴───┴──┴───┴──┴───┴──┴───┴─┘
      Bottom Navigation Bar
```

**Create Button Specs:**
- Position: Bottom-right, above tab bar
- Offset: 20pt from right, 100pt from bottom
- Size: 60x60 pt
- Style: Gradient circle (pink → purple)
- Icon: + (plus, 28pt, semibold, white)
- Shadow: Pink 40% opacity, radius 10, y-offset 4pt

**CSS-like Styling:**
```swift
Button {
    width: 60pt
    height: 60pt
    background: linear-gradient(135deg, #FF1493 0%, #9B59B6 100%)
    border-radius: 30pt
    shadow: 0 4px 10px rgba(255, 20, 147, 0.4)
    
    icon {
        size: 28pt
        weight: semibold
        color: white
    }
}
```

---

## 2. Camera Recording View

```
┌─────────────────────────────────────┐
│ X                            ⚡      │ ← Top controls
│                                     │   (close, flash)
│                                     │
│                                     │
│                                     │
│         CAMERA PREVIEW              │
│         (Live Feed)                 │
│                                     │
│                                     │
│                                     │
│         ┌──────────────┐            │ ← Recording
│         │ 🔴 0:23      │            │   indicator
│         └──────────────┘            │   (when recording)
│         ────────────────            │ ← Progress bar
│         ████████░░░░░░░░            │   (fills 0-60s)
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│    🔄                ⏺                │ ← Bottom controls
│   Flip            Record         │   (flip, record)
│                                     │
└─────────────────────────────────────┘
```

### Top Bar Layout

```
┌─────────────────────────────────────┐
│                                     │
│  ┌───┐                       ┌───┐ │
│  │ X │                       │ ⚡ │ │ ← 44x44pt buttons
│  └───┘                       └───┘ │
│    ↑                           ↑   │
│  Close                      Flash  │
│  (always)              (back cam)  │
│                                     │
└─────────────────────────────────────┘
   20pt                          20pt
   padding                     padding
```

### Recording Indicator (Conditional - Only When Recording)

```
┌──────────────────┐
│ 🔴 0:23          │ ← Red dot (12pt) + timer (18pt monospaced)
└──────────────────┘
 ↑                 ↑
Black background   Padding:
60% opacity        16pt horizontal
Corner radius      8pt vertical
20pt
```

### Progress Bar (Below Indicator)

```
Full width minus 40pt padding each side

Background: White 30% opacity
─────────────────────────────────────────

Fill: Red (0-100% of 60 seconds)
███████████████████░░░░░░░░░░░░░░░░░░░░░

Height: 4pt
```

### Bottom Controls

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│   ┌────┐         ┌────┐         ┌──│ ← 3 buttons
│   │ 🔄 │         │ ⏺  │         │  │   (symmetrical)
│   └────┘         └────┘         └──│
│   Flip           Record      Empty │
│                                     │
└─────────────────────────────────────┘
    60pt           80pt          60pt
    spacing        diameter      spacing
```

### Record Button States

**Not Recording:**
```
    ┌────────────────┐
    │                │ ← White ring
    │   ┌────────┐   │   (6pt stroke, 80pt diameter)
    │   │        │   │
    │   │   🔴   │   │ ← Red circle
    │   │        │   │   (filled, 68pt diameter)
    │   └────────┘   │
    │                │
    └────────────────┘
```

**Recording:**
```
    ┌────────────────┐
    │                │ ← White ring
    │      ┌──┐      │   (6pt stroke, 80pt diameter)
    │      │▪️▪️│      │ ← Red rounded square
    │      └──┘      │   (32x32pt, 8pt corner radius)
    │                │
    └────────────────┘
```

---

## 3. Video Preview View

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│                                     │
│         VIDEO PLAYBACK              │
│         (Full Screen)               │
│         (Looping)                   │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│  ┌──────────────┐ ┌──────────────┐ │ ← Action buttons
│  │ 🔄  Retake   │ │   Next   →   │ │
│  └──────────────┘ └──────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Action Buttons Layout

```
┌─────────────────────────────────────┐
│                                     │
│  Retake Button         Next Button  │
│  ┌────────────┐       ┌────────────┐│
│  │ 🔄 Retake  │       │  Next  →   ││
│  └────────────┘       └────────────┘│
│   ↑                    ↑            │
│   White 20% bg         White bg     │
│   50% width            50% width    │
│   Height: 50pt         Height: 50pt │
│   Corner: 25pt         Corner: 25pt │
│   Text: White          Text: Black  │
│                                     │
│   20pt padding                  20pt│
│                                     │
└─────────────────────────────────────┘
         40pt from bottom
```

---

## 4. Post Creation View

```
┌─────────────────────────────────────┐
│ Cancel              New Post   Post │ ← Navigation bar
├─────────────────────────────────────┤
│                                     │
│  ┌──────┐                           │
│  │      │  Duration: 0:23           │ ← Video info
│  │ 📹   │  Sound: Original Sound    │   (left side)
│  │      │                           │
│  └──────┘                           │
│  100x177pt                          │
│                                     │
│  ────────────────────────────────── │
│                                     │
│  Title                              │ ← Title field
│  ┌─────────────────────────────────┐│   (required)
│  │ Add a catchy title...          ││
│  └─────────────────────────────────┘│
│                                     │
│  Description                        │ ← Description
│  ┌─────────────────────────────────┐│   (optional)
│  │                                 ││
│  │ (multiline)                     ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  Hashtags                           │ ← Hashtags
│  ┌──────────────────────────┐  [+] │   (input + add)
│  │ Add hashtag...           │      │
│  └──────────────────────────┘      │
│                                     │
│  ╭──────╮ ╭──────╮ ╭──────╮        │ ← Hashtag chips
│  │#test │ │#video│ │#lyo  │        │   (blue, removable)
│  ╰──────╯ ╰──────╯ ╰──────╯        │
│                                     │
└─────────────────────────────────────┘
```

### Video Info Section

```
┌─────────────────────────────────────┐
│                                     │
│  ┌──────────┐  Video Details        │
│  │          │                       │
│  │   📹     │  Duration: 0:23       │ ← 14pt, gray
│  │          │  Sound: Original Sound│ ← 14pt, gray
│  │  Video   │                       │
│  │ Thumbnail│                       │
│  └──────────┘                       │
│   100x177pt                         │
│   (9:16 ratio)                      │
│   12pt corner                       │
│   radius                            │
│                                     │
└─────────────────────────────────────┘
   16pt padding all around
```

### Input Fields

```
Label Style:
  font: 14pt, semibold
  color: secondary (gray)
  spacing: 8pt below

Field Style:
  background: systemSecondaryGroupedBackground
  padding: 12-16pt
  corner radius: 12pt
  
Title Field:
  height: 44pt (single line)
  
Description Field:
  height: 100pt (multiline)
  scrollable
```

### Hashtag Input Row

```
┌─────────────────────────────────────┐
│                                     │
│  ┌───────────────────────────┐ ┌─┐ │
│  │ Add hashtag...            │ │+││ ← Add button
│  └───────────────────────────┘ └─┘ │   (24pt, blue)
│                                     │
│  Height: 44pt                       │
│  Padding: 12pt                      │
│  Background: systemSecondary...     │
│  Corner radius: 12pt                │
│                                     │
└─────────────────────────────────────┘
```

### Hashtag Chips (Flow Layout)

```
┌─────────────────────────────────────┐
│                                     │
│  ╭──────────╮ ╭──────────╮         │ ← Row 1
│  │ #test  X │ │ #video X │         │
│  ╰──────────╯ ╰──────────╯         │
│                                     │
│  ╭──────────╮ ╭──────────╮         │ ← Row 2
│  │ #lyoapp X│ │ #swift X │         │   (auto-wrap)
│  ╰──────────╯ ╰──────────╯         │
│                                     │
└─────────────────────────────────────┘

Chip Style:
  background: blue 10% opacity
  padding: 12pt horizontal, 6pt vertical
  corner radius: 16pt
  text: 14pt, blue
  X button: 14pt, gray, xmark.circle.fill
  spacing: 8pt between chips
```

---

## 5. Loading State (Post Creation)

```
┌─────────────────────────────────────┐
│                                     │
│           (Dimmed content)          │
│                                     │
│                                     │
│       ┌───────────────────┐         │
│       │                   │         │
│       │       ⏳          │         │ ← Progress
│       │                   │         │   spinner
│       │  Posting your     │         │   (1.5x scale)
│       │  video...         │         │
│       │                   │         │
│       └───────────────────┘         │
│                                     │
│       Background: white (or dark)   │
│       Padding: 32pt all sides       │
│       Corner radius: 16pt           │
│       Shadow: default               │
│                                     │
└─────────────────────────────────────┘
         Black overlay 40% opacity
```

---

## 6. Permission Request Dialog (System)

```
┌─────────────────────────────────────┐
│                                     │
│       "LyoApp" Would Like to        │
│         Access the Camera           │
│                                     │
│  LyoApp needs camera access to      │
│  record videos for your posts.      │
│                                     │
│  ┌─────────────────────────────────┐│
│  │        Don't Allow             ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │           OK                   ││ ← Primary action
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘

Same for:
- Microphone ("to record audio...")
- Photo Library ("to save videos...")
```

---

## 7. Error Alert

```
┌─────────────────────────────────────┐
│                                     │
│              Error                  │
│                                     │
│  Camera permission denied.          │
│  Please enable in Settings.         │
│                                     │
│  ┌─────────────────────────────────┐│
│  │           OK                   ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

---

## 📏 Spacing & Measurements

### Screen Padding
```
Top Safe Area: 60pt (status bar + nav bar)
Bottom Safe Area: 34pt (iPhone X+ home indicator)
Standard Padding: 20pt (horizontal edges)
Content Padding: 16pt (inside cards/sections)
```

### Button Sizes
```
Small Button:     44x44 pt (touch target minimum)
Medium Button:    60x60 pt (create FAB)
Large Button:     80x80 pt (record button)
Action Button:    full width x 50pt height
```

### Text Sizes
```
Navigation Title:  17pt (system default)
Section Label:     14pt semibold (gray)
Field Text:        16pt regular
Button Text:       16pt semibold
Timer Text:        18pt monospaced
Hashtag Text:      14pt regular
```

### Corner Radius
```
Small Elements:    8pt  (input fields)
Medium Elements:   12pt (cards, thumbnails)
Large Elements:    16pt (modals, overlays)
Pills/Chips:       16pt (half of height)
Buttons:           25pt (half of height for 50pt button)
Circle Buttons:    50% of diameter
```

### Spacing Scale
```
4pt:  Tight (icon + text)
8pt:  Close (chip spacing, label to field)
12pt: Standard (field padding)
16pt: Comfortable (card padding, between sections)
20pt: Loose (screen edges)
32pt: Very Loose (modal padding)
40pt: Extra Loose (progress bar from bottom)
```

---

## 🎨 Color Palette

### Create Button Gradient
```swift
Color.pink       // #FF1493 (DeepPink)
Color.purple     // #9B59B6 (Amethyst)

LinearGradient(
    colors: [Color.pink, Color.purple],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Recording UI
```swift
Color.red        // Recording dot, progress bar
Color.white      // Buttons, text, timer text
Color.black      // Backgrounds (opacity 60% for timer bg)
```

### Form UI
```swift
Color.primary                         // Main text (adaptive)
Color.secondary                       // Labels (gray)
Color(UIColor.systemGroupedBackground) // Screen background
Color(UIColor.secondarySystemGroupedBackground) // Field background
Color.blue                            // Hashtags (text and bg tint)
Color.blue.opacity(0.1)               // Hashtag chip background
```

### Shadows
```swift
// Create button shadow
Color.pink.opacity(0.4), radius: 10, x: 0, y: 4

// Card shadows (system default)
Color.black.opacity(0.1), radius: 8, x: 0, y: 2
```

---

## 🎬 Animation Sequences

### 1. Floating Action Button Tap

```
User taps + button
    ↓
Scale down to 0.95 (0.1s, easeIn)
    ↓
Scale back to 1.0 (0.15s, easeOut)
    ↓
Full-screen modal slides up (0.3s, spring)
```

### 2. Start Recording

```
User taps record button
    ↓
Haptic feedback (medium impact)
    ↓
Red circle → Red rounded square (0.2s)
    ↓
Recording indicator fades in (0.2s)
    ↓
Timer starts counting
    ↓
Progress bar animates from 0% (linear, 60s duration)
```

### 3. Stop Recording

```
User taps record button
    ↓
Haptic feedback (success notification)
    ↓
Red rounded square → Red circle (0.2s)
    ↓
Recording indicator fades out (0.2s)
    ↓
Timer stops
    ↓
Wait 0.3s for file write
    ↓
Transition to preview (0.3s slide)
```

### 4. Flip Camera

```
User taps flip button
    ↓
Haptic feedback (light impact)
    ↓
Camera preview flips horizontally (0.3s)
    ↓
Reconfigure AVCaptureSession
    ↓
New camera preview appears
```

### 5. Add Hashtag

```
User types hashtag + taps +
    ↓
Input field clears
    ↓
New chip scales up from 0.8 (0.2s, spring)
    ↓
Flow layout recalculates
    ↓
Chips reposition with animation (0.3s)
```

### 6. Post Video

```
User taps "Post"
    ↓
Dimmed overlay fades in (0.2s)
    ↓
Loading modal scales up from 0.8 (0.3s, spring)
    ↓
Progress spinner animates (continuous)
    ↓
Wait 1.5s (processing simulation)
    ↓
Modal scales down to 0.8 (0.2s)
    ↓
Overlay fades out (0.2s)
    ↓
Full-screen modal dismisses (0.3s, slide down)
    ↓
Video appears at top of feed
```

---

## 📱 Touch Targets

All interactive elements meet Apple's minimum touch target guidelines:

```
Minimum Touch Target: 44x44 pt

✅ Close button (camera):       44x44 pt
✅ Flash toggle:                 44x44 pt
✅ Flip camera button:           60x60 pt
✅ Record button:                80x80 pt (oversized for importance)
✅ Create FAB:                   60x60 pt
✅ Retake/Next buttons:          full width x 50pt
✅ Hashtag add button:           44x44 pt
✅ Hashtag remove (X):           ~44x44 pt (chip includes padding)
```

---

## 🔤 Typography

### Font Weights
```
Regular:    Body text, input fields
Semibold:   Labels, button text
Bold:       (Not used in this feature)
Monospaced: Timer display (for consistent width)
```

### Font Sizes
```
14pt:  Small labels, hashtags
16pt:  Body text, input fields, buttons
17pt:  Navigation title (system)
18pt:  Timer text
28pt:  + icon in FAB
```

---

## ♿ Accessibility

### Dynamic Type Support
All text sizes scale with user's preferred text size:
```swift
.font(.system(size: 16)) → .font(.body)
.font(.system(size: 14)) → .font(.caption)
```

### VoiceOver Labels
```swift
// Create button
.accessibilityLabel("Create Video")
.accessibilityHint("Opens camera to record a new video")

// Record button (not recording)
.accessibilityLabel("Start Recording")

// Record button (recording)
.accessibilityLabel("Stop Recording")
.accessibilityValue("Recording time: \(formattedDuration)")

// Flip camera
.accessibilityLabel("Flip Camera")
.accessibilityHint("Switches between front and back camera")

// Flash toggle
.accessibilityLabel("Flash")
.accessibilityValue(flashMode == .on ? "On" : "Off")

// Post button
.accessibilityLabel("Post Video")
.accessibilityHint("Posts your video to your feed")
.accessibilityAddTraits(.isButton)
```

### Color Contrast
All text meets WCAG AA standards:
- White on black: 21:1 (AAA)
- Black on white: 21:1 (AAA)
- Blue on light blue (10%): 8:1 (AA)
- White on pink gradient: 4.5:1+ (AA)

---

## 📐 Layout Grid

### Camera Recording View Grid
```
┌───────────────────────────────────────┐
│ 60pt │                          │ 60pt │ Top safe area
├──────┼──────────────────────────┼──────┤
│ 20pt │ Close              Flash │ 20pt │ Top controls
│      │  44pt                    │      │
├──────┴──────────────────────────┴──────┤
│                                        │
│                                        │ Camera preview
│             (Flexible)                 │ (full available
│                                        │  height)
│                                        │
├────────────────────────────────────────┤
│             Timer + Progress           │ Recording indicator
│                 (48pt)                 │ (conditional)
├────────────────────────────────────────┤
│                                        │
│        60pt     80pt     60pt          │ Bottom controls
│       (Flip)  (Record) (Empty)         │ (120pt total)
│                                        │
├────────────────────────────────────────┤
│ 40pt                                   │ Bottom padding
└────────────────────────────────────────┘
│ 34pt │                                 │ Bottom safe area
└──────┴─────────────────────────────────┘
```

### Post Creation View Grid
```
┌───────────────────────────────────────┐
│ Navigation Bar (44pt)                  │
├───────────────────────────────────────┤
│ 20pt padding                           │
├───────────────────────────────────────┤
│ Video info section (177pt + 20pt pad) │ Thumbnail + metadata
├───────────────────────────────────────┤
│ 20pt spacing                           │
├───────────────────────────────────────┤
│ Title label (22pt) + field (44pt)     │ Title input
├───────────────────────────────────────┤
│ 20pt spacing                           │
├───────────────────────────────────────┤
│ Description label (22pt) + field      │ Description input
│ (100pt)                                │
├───────────────────────────────────────┤
│ 20pt spacing                           │
├───────────────────────────────────────┤
│ Hashtags label (22pt) + input (44pt)  │ Hashtag input
├───────────────────────────────────────┤
│ 12pt spacing                           │
├───────────────────────────────────────┤
│ Hashtag chips (flexible height)       │ Hashtag display
├───────────────────────────────────────┤
│ 20pt padding                           │
└───────────────────────────────────────┘
```

---

## 🎯 Key Measurements Summary

| Element | Width | Height | Padding | Corner Radius |
|---------|-------|--------|---------|---------------|
| **Create FAB** | 60pt | 60pt | — | 30pt (circle) |
| **Record Button** | 80pt | 80pt | — | 40pt (circle) |
| **Close/Flash Button** | 44pt | 44pt | — | — |
| **Flip Camera** | 60pt | 60pt | — | — |
| **Recording Indicator** | auto | 32pt | 16h/8v | 20pt |
| **Progress Bar** | full-40 | 4pt | 40h | — |
| **Video Thumbnail** | 100pt | 177pt | — | 12pt |
| **Title Field** | full | 44pt | 12pt | 12pt |
| **Description Field** | full | 100pt | 8pt | 12pt |
| **Hashtag Input** | flex | 44pt | 12pt | 12pt |
| **Hashtag Chip** | auto | 32pt | 12h/6v | 16pt |
| **Retake/Next Button** | 50% | 50pt | — | 25pt |
| **Loading Modal** | auto | auto | 32pt | 16pt |

---

## 🖼️ Asset Requirements

### SF Symbols Used
```
plus                      // Create FAB icon
xmark                     // Close button
bolt.fill                 // Flash on
bolt.slash.fill           // Flash off
arrow.triangle.2.circlepath.camera  // Flip camera
play.fill                 // Video thumbnail play icon
arrow.counterclockwise    // Retake button
arrow.right               // Next button
plus.circle.fill          // Add hashtag button
xmark.circle.fill         // Remove hashtag button
```

### Video Thumbnail Generation
```swift
// Generate thumbnail from video URL
func generateThumbnail(from url: URL) async throws -> UIImage {
    let asset = AVAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTime(seconds: 1, preferredTimescale: 600)
    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
    
    return UIImage(cgImage: cgImage)
}
```

---

## 🎥 Video Preview Loop

```
AVPlayer plays video
    ↓
Video reaches end (CMTime)
    ↓
NotificationCenter fires .AVPlayerItemDidPlayToEndTime
    ↓
Seek to .zero (beginning)
    ↓
Play again
    ↓
(Infinite loop)
```

**Implementation:**
```swift
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemDidPlayToEndTime,
    object: player.currentItem,
    queue: .main
) { _ in
    player.seek(to: .zero)
    player.play()
}
```

---

## 🎨 Visual Examples

### Gradient Calculation

**Create FAB Gradient:**
```
topLeading (0, 0) → Pink #FF1493
bottomTrailing (100%, 100%) → Purple #9B59B6

Angle: 135° (diagonal)
Smooth transition across circle
```

**CSS Equivalent:**
```css
background: linear-gradient(135deg, #FF1493 0%, #9B59B6 100%);
```

**SwiftUI:**
```swift
LinearGradient(
    gradient: Gradient(colors: [Color.pink, Color.purple]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## 📊 Comparison with TikTok

| Feature | TikTok | LyoApp | Notes |
|---------|--------|--------|-------|
| **Create Button** | Center of tab bar (tab slot) | Floating (bottom-right) | More prominent |
| **Max Duration** | 60s (extended tiers) | 60s | Same |
| **Camera Flip** | Top-right | Bottom-left | Different placement |
| **Record Button** | Bottom-center | Bottom-center | Same |
| **Flash** | Top-left | Top-right | Mirrored |
| **Timer** | Top-center | Center | Different placement |
| **Preview** | Full-screen | Full-screen | Same |
| **Effects** | Yes (extensive) | No (future) | Phase 3 |
| **Music** | Yes (library) | No (future) | Phase 2 |
| **Editing** | Yes (trim, filters) | No (future) | Phase 1 |

---

## ✅ Visual QA Checklist

- [ ] Create FAB is visible and prominent
- [ ] Create FAB gradient renders smoothly
- [ ] Create FAB shadow is visible
- [ ] Camera preview fills entire screen
- [ ] Camera preview is not distorted
- [ ] Recording indicator is centered
- [ ] Recording timer updates smoothly
- [ ] Progress bar fills proportionally
- [ ] Record button changes state correctly
- [ ] All buttons have 44pt minimum touch target
- [ ] Video preview loops seamlessly
- [ ] Hashtag chips wrap correctly
- [ ] Hashtag chips are removable
- [ ] Loading modal is centered
- [ ] Text is readable on all backgrounds
- [ ] Animations are smooth (60fps)
- [ ] No layout issues on different screen sizes

---

## 📱 Screen Size Adaptations

### iPhone SE (3rd gen) - 4.7"
```
- Smaller create FAB (50x50pt)
- Smaller record button (70x70pt)
- Reduced padding (16pt instead of 20pt)
```

### iPhone 15 Pro Max - 6.7"
```
- Standard create FAB (60x60pt)
- Standard record button (80x80pt)
- Standard padding (20pt)
```

### iPad (if supported)
```
- Larger create FAB (80x80pt)
- Larger record button (100x100pt)
- Increased padding (32pt)
- Wider video thumbnail (150x266pt)
```

---

**Created:** January 2025  
**Version:** 1.0.0  
**Purpose:** Visual reference for video creation feature implementation
