# AI Avatar Screen - Layout Structure

## Visual Hierarchy

```
┌─────────────────────────────────────────────────┐
│  Status Bar                                     │
│  [Lyo AI]                        [● READY]      │
├─────────────────────────────────────────────────┤
│                                                 │
│              ╭───────────╮                      │
│              │  ◉ Glow   │  ← Outer blur ring  │
│              │ ╭───────╮ │                      │
│              │ │ ■─■─■ │ │  ← Gradient border  │
│              │ │ ╰───╯ │ │  ← Dark inner       │
│              │ │   ✨  │ │  ← Sparkles icon    │
│              │ ╰───●───╯ │  ← Active indicator │
│              ╰───────────╯                      │
│                                                 │
│              【 Lyo 】  ← Gradient text         │
│              ● AI READY  ← Status badge        │
│                                                 │
├─────────────────────────────────────────────────┤
│  Messages Area (Scrollable)                    │
│                                                 │
│  ●  ┌─────────────────────┐                    │
│  ✨ │ AI Message          │  ← Glass bubble    │
│     │ with glassmorphism  │                    │
│     └─────────────────────┘                    │
│     [Practice] [More]  ← Action buttons        │
│                                                 │
│              ┌────────────────────┐             │
│              │ User message with  │ ← Gradient │
│              │ blue-purple grad   │             │
│              └────────────────────┘             │
│                                                 │
│  ●  ┌─────┐                                    │
│  ✨ │ ● ● ●│  ← Typing indicator               │
│     └─────┘                                    │
│                                                 │
├─────────────────────────────────────────────────┤
│  Quick Actions                                  │
│  [Help]  [Create]  [Explore]  ← Pills          │
│                                                 │
│  Input Area                                     │
│  ╭─╮  ╭──────────────────────────╮             │
│  │●│  │ Ask Lyo anything...    ◉ │ ← Capsule   │
│  ╰─╯  ╰──────────────────────────╯             │
│  ↑Voice              ↑Send button              │
└─────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. Background Layer
```
┌─────────────────────────────────────────────────┐
│ Deep Slate-Black (0.02, 0.05, 0.13)            │
│                                                 │
│        ◉ Blue orb                               │
│   (top-right, pulsing)                         │
│                                                 │
│                                                 │
│                              ◉ Purple orb       │
│                         (bottom-left, pulsing)  │
│                                                 │
│  [Subtle neural network dots throughout]       │
└─────────────────────────────────────────────────┘
```

### 2. Avatar Orb Layers
```
     Layer 5: Active Indicator (16x16)
              Green with pulse
                    ●

     Layer 4: Sparkles Icon (32pt)
              ✨

     Layer 3: Dark Circle (80x80)
              #040D21

     Layer 2: Gradient Border (88x88)
              Blue → Purple → Pink

     Layer 1: Glow Ring (160x160, blurred 20pt)
              Blue-Purple gradient with opacity
```

### 3. Message Bubble Structure

#### AI Message:
```
┌────┬──────────────────────────────────────┐
│ ●  │  Glass Bubble                        │
│ ✨ │  • Fill: White 8%                    │
│    │  • Border: White 15%, 1pt            │
│    │  • Corner: 20pt continuous           │
│    │  • Padding: 16h × 12v                │
│    │  • Font: 15pt system                 │
│    └──────────────────────────────────────┘
│       [Button] [Button]  ← Action buttons
└──────────────────────────────────────────────┘
```

#### User Message:
```
┌──────────────────────────────────────┬────┐
│  Gradient Bubble                     │    │
│  • Fill: Blue 90% → Purple 80%       │    │
│  • Corner: 20pt continuous           │    │
│  • Padding: 16h × 12v                │    │
│  • Font: 15pt system                 │    │
│  • Align: Right                      │    │
└──────────────────────────────────────┴────┘
```

### 4. Input Area Components

#### Voice Button:
```
 Default State:              Recording State:
   ╭─────╮                    ╭─────╮
   │  ●  │ White 15%          │  ●  │ Red-Pink gradient
   ╰─────╯ Glass              ╰─────╯ with pulse ring
   48×48                       48×48 (scale 1.05)
```

#### Text Input:
```
╭──────────────────────────────────────────╮
│ ○ Ask Lyo anything...              ┌─┐  │
│                                     │↑│  │ ← Send (when typing)
│                                     └─┘  │
╰──────────────────────────────────────────╯
Fill: White 12%  •  Border: White 20%  •  Capsule
```

#### Quick Action Pills:
```
╭────────╮  ╭────────╮  ╭────────╮
│  Help  │  │ Create │  │Explore │
╰────────╯  ╰────────╯  ╰────────╯
Fill: White 8%  •  Border: White 15%
```

## Color Palette

```
Primary Colors:
  Blue:    #007AFF (iOS Blue)
  Purple:  #8050CC (Mid Purple)
  Pink:    #E64D99 (Pink)
  Green:   #00FF00 (Active indicator)

Background:
  Base:    RGB(5, 13, 33)  - Deep slate-black

Glass Effects:
  Light:   White @ 8%  opacity
  Medium:  White @ 12% opacity
  Border:  White @ 15% opacity
  Strong:  White @ 20% opacity

Text:
  Primary:   White @ 100%
  Secondary: White @ 90%
  Tertiary:  White @ 60%
  Hint:      White @ 40%
```

## Spacing Scale

```
Micro:   4pt   (icon spacing)
Small:   8pt   (tight elements)
Medium:  12pt  (standard spacing)
Large:   16pt  (section spacing)
XLarge:  20pt  (major sections)
XXLarge: 40pt  (minimum spacers)
```

## Font Scale

```
Title:      32pt Bold       (Lyo title)
Subtitle:   15pt Regular    (Message text)
Caption:    13pt Medium     (Quick actions)
Small:      12pt Medium     (Action buttons)
Micro:      11pt Semibold   (Status badge)
Tiny:       10pt Semibold   (Status indicators)
```

## Corner Radius Scale

```
Buttons:    Capsule (height/2)
Messages:   20pt continuous
Cards:      16pt continuous
Pills:      Capsule
Avatar:     Circle (infinite)
```

## Animation Timings

```
Quick:       0.2s  (button press)
Natural:     0.4s  (voice button)
Smooth:      0.6s  (typing dots)
Gentle:      2.0s  (avatar pulse)
Background:  3.5s  (orb pulse)
Slow:        4.0s  (background gradient)
```

## Layer Stack (Bottom to Top)

```
10. Send Button (conditional)
 9. Quick Action Pills
 8. Input Area (voice + text)
 7. Action Buttons
 6. Message Bubbles
 5. Typing Indicator
 4. Scroll Area
 3. Avatar + Title
 2. Status Bar
 1. Animated Background Orbs
 0. Deep Slate-Black Base
```

## Interactive States

### Avatar Orb:
- **Default**: Gentle pulse (scale: 1.0 ↔ 1.15)
- **Tap**: Quick scale (1.0 → 1.2 → 1.0)
- **Thinking**: Green indicator pulses

### Voice Button:
- **Default**: Glass effect, white circle
- **Tap**: Scale 1.05
- **Recording**: Red gradient, pulse ring
- **Release**: Scale back to 1.0

### Send Button:
- **Hidden**: When text is empty
- **Appear**: Scale + opacity transition
- **Press**: Scale to 0.95

### Message Bubbles:
- **Appear**: Slide from bottom
- **Scroll**: Auto-scroll to latest

### Action Buttons:
- **Press**: Scale to 0.95
- **Duration**: 0.2s ease-in-out

## Glassmorphism Formula

```swift
Background Layer:
  .fill(Color.white.opacity(0.08))

Border Layer:
  .stroke(Color.white.opacity(0.15), lineWidth: 1)

Combined:
  .background(
    Shape()
      .fill(Color.white.opacity(0.08))
      .background(
        Shape()
          .stroke(Color.white.opacity(0.15), lineWidth: 1)
      )
  )
```

## Gradient Formula

```swift
Standard Gradient:
  LinearGradient(
    colors: [Color.blue, Color.purple],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

Extended Gradient (3 colors):
  LinearGradient(
    colors: [
      Color.blue,
      Color(red: 0.5, green: 0.3, blue: 0.8),  // Purple
      Color(red: 0.9, green: 0.3, blue: 0.6)   // Pink
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
```

## Accessibility Considerations

- **Contrast Ratio**: White on dark background = 15:1 (AAA)
- **Touch Targets**: All buttons ≥ 44pt minimum
- **Text Size**: Minimum 12pt for readability
- **Color Independence**: Status shown with shapes + text
- **Animation**: Can be disabled via iOS settings

## Performance Optimizations

- **Blur Radius**: Limited to 20-60pt
- **Animations**: Use `.animation()` sparingly
- **Opacity Layers**: Maximum 3 layers per element
- **Gradients**: Pre-defined, not computed
- **Particles**: Removed heavy particle system

---

This layout creates a **professional, modern, futuristic** interface that's both visually stunning and highly functional! 🚀✨
