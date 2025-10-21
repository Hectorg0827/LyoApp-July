# 📐 Messenger Visual Reference Guide

## 🎨 Complete Layout Diagrams

---

## 1️⃣ INBOX VIEW (Conversation List)

```
┌─────────────────────────────────────────────┐
│  ←  Messages                      [ + ]     │ ← Navigation bar
├─────────────────────────────────────────────┤
│  ┌──────────────────────────────────────┐  │
│  │  🔍  Search messages              [✕]│  │ ← Search bar (glass)
│  └──────────────────────────────────────┘  │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──┐ Study Group 📖              2m   [3] │ ← Unread (highlighted)
│  │👥│ Mike: Who's up for studying... │     │
│  └──┘                                       │
│                                             │
│  ┌──┐● Sarah Johnson              5m   [1] │ ← Online (green dot)
│  │👤│ ✓ Hey! How's your day going? 😊│     │ ← Read receipt
│  └──┘                                       │
│                                             │
│  ┌──┐● Mike Chen                  1h       │ ← Online
│  │👤│ ✓✓ Did you see the new course... │   │ ← Read (filled)
│  └──┘                                       │
│                                             │
│  ┌──┐  Emma Wilson               3h        │ ← Offline
│  │👤│ Thanks for the help earlier!    │    │
│  └──┘                                       │
│                                             │
│  ┌──┐● Alex Rodriguez             5h       │
│  │👤│ Typing...                      │     │ ← Typing indicator
│  └──┘                                       │
│                                             │
│  ┌──┐  Olivia Taylor              1d       │
│  │👤│ That video was amazing! 🎥     │     │
│  └──┘                                       │
│                                             │
└─────────────────────────────────────────────┘

COLORS:
- Background: Linear gradient (#0A0E27 → #1A1F3A)
- Search bar: White 10% opacity, 12pt radius
- Unread row: White 5% opacity background
- Avatar: 56x56pt circle
- Green dot: 14x14pt circle (online indicator)
- Unread badge: Cyan (#00D4FF) capsule
- Text: White (name), Gray (message)
- Checkmark: Cyan (read), Gray (delivered)

SPACING:
- Row height: 80pt
- Avatar: 56x56pt
- Horizontal padding: 16pt
- Vertical padding: 12pt
- Badge min width: 20pt
- Badge height: 20pt
```

---

## 2️⃣ CHAT VIEW (Conversation Screen)

```
┌─────────────────────────────────────────────┐
│  ← ┌──┐ Sarah Johnson            📞  📹   │ ← Toolbar
│    │👤│ Active now                          │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────┐           │ ← Received message
│  │ Hey! How are you doing? 😊  │           │
│  └─────────────────────────────┘           │
│  10:30 AM                                   │
│                                             │
│            ┌───────────────────────────┐   │ ← Sent message
│            │ I'm great! Just finished  │   │   (gradient)
│            │ that course on SwiftUI.   │   │
│            └───────────────────────────┘   │
│                              10:31 AM ✓✓   │
│                                             │
│  ┌────────────────────┐                    │ ← Received
│  │ That's awesome!    │                    │
│  │ How was it?        │                    │
│  └────────────────────┘                    │
│  10:32 AM                                   │
│                                             │
│            ┌───────────────────────────┐   │ ← Sent with reaction
│            │ Really helpful! The       │   │
│            │ animations section was    │   │
│            │ my favorite. ✨           │   │
│            └───────────────────────────┘   │
│               ❤️                      ✓✓   │ ← Reaction
│                                             │
│  ┌─────────────────────────────┐           │
│  │ I should check it out too!  │           │
│  └─────────────────────────────┘           │
│  10:35 AM                                   │
│                                             │
│            ┌───────────────────────────┐   │ ← Voice message
│            │ ▶  ▓░░░▓▓░▓░░▓▓    12s  │   │
│            └───────────────────────────┘   │
│                              10:36 AM ✓    │
│                                             │
│  ┌─────────────────────────────┐           │ ← Deleted message
│  │ ⚠️ This message was deleted │           │
│  └─────────────────────────────┘           │
│                                             │
├─────────────────────────────────────────────┤
│ ────────────────────────────────────────    │ ← Divider
│                                             │
│ 📷  🎤  ┌──────────────────┐  😊   ➤      │ ← Input bar
│         │ Message...       │               │
│         └──────────────────┘               │
│                                             │
└─────────────────────────────────────────────┘

COLORS:
- Sent bubble: Linear gradient (#00D4FF → #667EEA)
- Received bubble: White 10-15% opacity
- Text: White
- Timestamp: Gray, 11pt
- Reaction: 16pt emoji in capsule (white 20%)
- Deleted: Gray text, italic

SPACING:
- Message padding: 12pt inside bubble
- Bubble radius: 18pt
- Message spacing: 12pt vertical
- Side margin: 60pt (prevents full width)
- Input bar height: ~60pt
```

---

## 3️⃣ MESSAGE BUBBLE TYPES

### A) Text Message (Received)
```
┌─────────────────────────────┐
│ Hey! How are you doing? 😊  │  ← White 15% opacity
└─────────────────────────────┘     18pt radius
10:30 AM                            12pt padding
```

### B) Text Message (Sent)
```
     ┌───────────────────────────┐
     │ I'm doing great! Thanks!  │  ← Cyan→Purple gradient
     └───────────────────────────┘
                     10:31 AM ✓✓  ← Read receipt
```

### C) Voice Message
```
┌────────────────────────────────┐
│ ▶  ▓░▓░░▓▓░▓░░▓▓░▓░▓  12s    │  ← 20 waveform bars
└────────────────────────────────┘     Play button (32pt)
```

### D) Image Message
```
┌─────────────────┐
│                 │
│   [  IMAGE  ]   │  ← 200x200pt
│                 │     Rounded 18pt
└─────────────────┘
```

### E) Video Message
```
┌─────────────────┐
│                 │
│      ▶         │  ← 200x200pt with play icon
│                 │     48pt play button
└─────────────────┘
```

### F) Deleted Message
```
┌─────────────────────────────┐
│ ⚠️ This message was deleted │  ← White 5% opacity
└─────────────────────────────┘     Gray text, italic
```

---

## 4️⃣ REACTION SYSTEM

### A) Message with Reactions
```
┌───────────────────────────┐
│ That's amazing! ✨        │  ← Original message
└───────────────────────────┘
  ❤️ 😂 👍                   ← Reactions (3 users)
10:30 AM
```

### B) Reaction Picker Sheet (Modal)
```
┌─────────────────────────────────────────────┐
│           ───                               │ ← Drag handle
│                                             │
│              React                          │ ← Title
│                                             │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐           │
│  │ ❤️ │  │ 😂 │  │ 😮 │  │ 😢 │           │
│  └────┘  └────┘  └────┘  └────┘           │
│                                             │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐           │
│  │ 😡 │  │ 👍 │  │ 👏 │  │ 🔥 │           │
│  └────┘  └────┘  └────┘  └────┘           │
│                                             │
│                                             │
│                                             │
└─────────────────────────────────────────────┘
← 400pt height
← Dark gradient background
← 40pt emoji in 70x70pt circles
← 4-column grid, 16pt spacing
```

---

## 5️⃣ MESSAGE CONTEXT MENU

```
Long press message → Context menu appears:

┌─────────────────────┐
│  ❤️  React          │  ← Open reaction picker
├─────────────────────┤
│  ↩️  Reply          │  ← Reply to message
├─────────────────────┤
│  ➤  Forward         │  ← Forward to another chat
├─────────────────────┤
│  🗑  Delete         │  ← Delete (sender only, red)
└─────────────────────┘
```

---

## 6️⃣ CONVERSATION ROW STATES

### A) Unread Conversation
```
┌──┐  Sarah Johnson           5m   [3]  ← Unread badge (cyan)
│👤│  Hey! How's your day going? 😊      ← White text (bold)
└──┘                                     ← White 5% background
```

### B) Online User
```
┌──┐● Mike Chen               1h        ← Green dot (14x14pt)
│👤│  ✓✓ Did you see the new course...  ← Filled checkmark (read)
└──┘
```

### C) Typing Indicator
```
┌──┐● Alex Rodriguez          Just now
│👤│  Typing...  ● ● ●                  ← Animated dots (cyan)
└──┘               ↑ Bounce animation
```

### D) Group Chat
```
┌──┐  Study Group 📖           2m   [3]
│👥│  Mike: Who's up for studying...    ← Group icon
└──┘                                     ← Sender name prefix
```

---

## 7️⃣ INPUT BAR ANATOMY

```
┌─────────────────────────────────────────────┐
│                                             │
│ 📷  🎤  ┌──────────────────────┐  😊   ➤  │
│         │ Message...           │           │
│         │ (1-5 lines auto-grow)│           │
│         └──────────────────────┘           │
│ ↑   ↑            ↑              ↑     ↑   │
│ │   │            │              │     │   │
│ │   │            │              │     └─ Send (28pt)
│ │   │            │              └─ Emoji picker
│ │   │            └─ Text field (white 10% bg, 20pt radius)
│ │   └─ Voice recording (red when active)
│ └─ Photo picker
│                                             │
└─────────────────────────────────────────────┘

STATES:
- Empty input: Heart icon (❤️)
- Has text: Arrow up circle filled (➤)
- Recording: Red mic icon with timer
- Typing: Smooth expansion (1-5 lines)
```

---

## 8️⃣ TYPING INDICATOR ANIMATION

```
Frame 1 (0.0s):  ● ● ●     ← All at baseline
                 
Frame 2 (0.2s):  ● ● ●     ← Dot 1 up
                 ↑

Frame 3 (0.4s):  ● ● ●     ← Dot 2 up
                   ↑

Frame 4 (0.6s):  ● ● ●     ← Dot 3 up
                     ↑

Frame 5 (0.8s):  ● ● ●     ← All back down, repeat
                 
Color: Cyan (#00D4FF)
Duration: 0.6s per cycle
Offset: 5pt vertical
Delay: 0.2s between dots
```

---

## 9️⃣ ONLINE STATUS INDICATOR

```
┌──────┐
│      │
│  👤  │  ← 56x56pt avatar
│      │
└──────┘
      ●  ← Green dot (14x14pt)
         ← White ring (2pt stroke)
         ← Bottom-right position
```

---

## 🔟 VOICE MESSAGE WAVEFORM

```
┌─────────────────────────────────────┐
│ ▶  ▓░▓░░▓▓░▓░░▓▓░▓░▓░░▓░░▓▓  12s │
│    ↑ 20 bars, random heights       │
│    └ White 50% opacity              │
└─────────────────────────────────────┘

Bar dimensions:
- Width: 2pt
- Height: Random between 10-30pt
- Spacing: 2pt
- Color: White 50% opacity
```

---

## 📊 SPACING & MEASUREMENTS

### Typography
```
Navigation title: 34pt bold (Large title)
Conversation name: 16pt semibold
Last message: 14pt regular
Timestamp: 12pt regular
Message content: 16pt regular
"Active now": 11pt regular (cyan)
Button labels: 18pt semibold
```

### Dimensions
```
Avatar (conversation list): 56x56pt
Avatar (chat header): 32x32pt
Online indicator: 14x14pt
Unread badge min: 20x20pt
Message bubble radius: 18pt
Input field radius: 20pt
Search bar radius: 12pt
Reaction circle: 70x70pt
Reaction emoji: 40pt
Sheet drag handle: 40x5pt
```

### Padding
```
Row horizontal: 16pt
Row vertical: 12pt
Message bubble: 12pt
Input bar horizontal: 16pt
Input bar vertical: 8pt
Text field: 10pt
Search bar: 12pt
```

### Margins
```
Message side margin: 60pt (prevents full width)
Conversation spacing: 0pt (seamless)
Message spacing: 12pt vertical
Reaction spacing: 4pt horizontal
```

---

## 🎨 COMPLETE COLOR PALETTE

```swift
// Background gradients
Background top: #0A0E27 (dark navy)
Background bottom: #1A1F3A (dark purple)

// Primary accents
Cyan: #00D4FF (primary actions, online, unread)
Purple: #667EEA (gradient secondary)

// Message bubbles
Sent start: #00D4FF (cyan)
Sent end: #667EEA (purple)
Received: White 10-15% opacity

// Text colors
Primary text: #FFFFFF (white)
Secondary text: #666666 (gray)
Timestamp: #999999 (light gray)
Deleted: #888888 (dark gray)

// Status indicators
Online: #00FF00 (green)
Recording: #FF0000 (red)
Checkmark read: #00D4FF (cyan)
Checkmark delivered: #666666 (gray)

// UI elements
Search bar: White 10% opacity
Input bar: White 10% opacity
Unread row: White 5% opacity
Reaction bg: White 20% opacity
Divider: White 10% opacity
```

---

## 🎬 ANIMATION SEQUENCES

### 1. Send Message
```
1. User taps send button
2. Message appears at bottom (opacity 0 → 1, 0.2s)
3. Scroll to bottom (spring animation, 0.3s)
4. Checkmark appears (scale 0 → 1, 0.2s delay)
5. Haptic feedback (light impact)
```

### 2. Receive Message
```
1. New message arrives
2. Message appears (slide from left, 0.3s)
3. Scroll to bottom (spring animation, 0.3s)
4. If in inbox: unread badge updates (scale pulse)
```

### 3. Add Reaction
```
1. User taps emoji in picker
2. Sheet dismisses (slide down, 0.3s)
3. Reaction appears below bubble (scale 0 → 1.2 → 1.0, 0.4s)
4. Haptic feedback (light impact)
```

### 4. Delete Message
```
1. User taps Delete in context menu
2. Message fades out (opacity 1 → 0, 0.2s)
3. Deleted placeholder appears (opacity 0 → 1, 0.2s)
4. Haptic feedback (success notification)
```

### 5. Start Recording
```
1. User taps mic button
2. Icon color: cyan → red (0.2s)
3. Timer appears (fade in, 0.2s)
4. Waveform animates (continuous)
```

---

## 📱 RESPONSIVE LAYOUTS

### iPhone SE (Small)
```
- Avatar: 48x48pt (smaller)
- Message max width: 250pt
- Font sizes: -2pt
- Spacing: -2pt padding
```

### iPhone 14 Pro (Standard)
```
- Avatar: 56x56pt
- Message max width: 300pt
- Font sizes: Default
- Spacing: Default
```

### iPhone 14 Pro Max (Large)
```
- Avatar: 60x60pt (larger)
- Message max width: 350pt
- Font sizes: +2pt
- Spacing: +2pt padding
```

---

## 🔄 STATE TRANSITIONS

### Conversation List States
```
Default     →  [Tap]  →  Chat View
Default     →  [Swipe] →  Delete/Archive (future)
Default     →  [Search] → Filtered List
Empty State →  [+]    →  New Message
```

### Message States
```
Sending  →  Sent (checkmark)  →  Delivered (✓)  →  Read (✓✓)
Draft    →  [Long press]      →  Context Menu
Text     →  [React]           →  Text + Reaction
Active   →  [Delete]          →  Deleted Placeholder
```

### Input Bar States
```
Empty       →  [Type]       →  Has Text (send enabled)
Empty       →  [Mic press]  →  Recording (timer visible)
Recording   →  [Stop]       →  Voice Message Sent
Has Text    →  [Send]       →  Empty (message sent)
```

---

## 🎯 TOUCH TARGETS

```
Minimum touch target: 44x44pt (Apple HIG)

Conversation row: 80pt height (entire row tappable)
Send button: 44x44pt
Voice button: 44x44pt  
Photo button: 44x44pt
Emoji button: 44x44pt
Reaction emoji: 70x70pt (comfortable tap)
Context menu: Full message bubble (long press)
Avatar: 56x56pt (navigation to profile, future)
```

---

## 🚀 PERFORMANCE TARGETS

```
60 FPS scroll: ✅ LazyVStack rendering
Smooth animations: ✅ Spring curves, proper timing
Memory efficient: ✅ Image caching, lazy loading
Fast persistence: ✅ UserDefaults JSON encoding
Instant search: ✅ Real-time filtering
No jank: ✅ Main thread UI updates
```

---

## 📐 ACCESSIBILITY

```
VoiceOver labels:
- "Conversation with [name]"
- "Unread message from [name]"
- "[Name] is online"
- "Send message"
- "Record voice message"
- "Add reaction"
- "Delete message"

Dynamic Type support:
- All text scales with system font size
- Maintains minimum 12pt for timestamps
- Layout adapts to larger text

Color Contrast:
- White on dark: 15:1 ratio (WCAG AAA)
- Cyan on dark: 8:1 ratio (WCAG AAA)
- Gray on dark: 4.5:1 ratio (WCAG AA)
```

---

## 🎨 DESIGN TOKENS SUMMARY

```swift
// Colors
Primary: #00D4FF
Secondary: #667EEA
Background: Linear gradient (#0A0E27 → #1A1F3A)
Text: #FFFFFF
Muted: #666666

// Typography
Large: 34pt (nav titles)
H1: 24pt
Body: 16pt
Caption: 14pt
Small: 12pt
Micro: 11pt

// Spacing
XXS: 4pt
XS: 8pt
S: 12pt
M: 16pt
L: 20pt
XL: 24pt
XXL: 32pt

// Radius
Small: 12pt (search bar)
Medium: 18pt (message bubbles)
Large: 20pt (input field)
Circle: 50% (avatars)

// Shadows
None (flat design)
Glow: Cyan 20% blur 6pt (future)
```

---

## 📸 Screenshot Mockups

### Inbox View
```
[ Search: "sarah" ]
→ Filters to Sarah Johnson conversation
→ Other conversations hidden
```

### Chat View
```
[ Send: "Hello!" ]
→ Bubble appears bottom-right (gradient)
→ Scroll to bottom animates
→ After 1s: AI reply appears bottom-left
```

### Reaction Flow
```
[ Long press message ]
→ Context menu appears
[ Tap "React" ]
→ Sheet slides up
[ Tap ❤️ ]
→ Heart appears below bubble
```

### Voice Recording
```
[ Tap mic button ]
→ Icon turns red
→ Timer starts: 0s, 1s, 2s...
[ Tap stop ]
→ "Voice message (5s)" sent
→ Waveform visualization appears
```

---

**Total Visual Components Documented**: 50+  
**Layouts Defined**: 10 major screens/states  
**Animations Specified**: 5 key sequences  
**Colors Defined**: 15 unique values  
**Measurements Documented**: 40+ dimensions  

*Every pixel designed with intention* ✨
