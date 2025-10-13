# 🎯 AI Avatar - Quick Reference Card

**One-page reference for developers implementing the avatar system**

---

## 📁 File Locations

```
LyoApp/
├── Models/
│   └── AvatarModels.swift          ← Data structures
├── Managers/
│   └── AvatarStore.swift           ← State management
├── Services/
│   └── SentimentAwareAvatarManager.swift  ← AI behavior
├── Views/
│   ├── QuickAvatarSetupView.swift  ← Onboarding
│   ├── QuickAvatarPickerView.swift ← Quick picker
│   └── Components/
│       ├── FloatingAvatarButton.swift     ← CREATE THIS
│       ├── AvatarCompanionWidget.swift    ← CREATE THIS
│       └── AvatarChatView.swift           ← CREATE THIS
└── Unity/
    ├── AvatarManager.cs            ← Unity controller
    ├── AvatarBlendshapeController.cs
    └── AvatarLipSyncController.cs
```

---

## 🔑 Key Classes

### Avatar Model
```swift
struct Avatar: Codable, Identifiable {
    var id: UUID
    var name: String
    var appearance: AvatarAppearance
    var profile: PersonalityProfile
    var voiceIdentifier: String?
}
```

### AvatarStore (ObservableObject)
```swift
@MainActor
final class AvatarStore: ObservableObject {
    @Published var avatar: Avatar?
    @Published var state: CompanionState
    @Published var memory: AvatarMemory

    func speak(_ text: String)
    func recordUserAction(_ action: UserAction)
    func startSession(on topic: String)
}
```

### Usage in Views
```swift
@EnvironmentObject var avatarStore: AvatarStore

// Check if setup needed
if avatarStore.needsOnboarding {
    QuickAvatarSetupView { avatar in }
}

// Get current avatar
if let avatar = avatarStore.avatar {
    Text(avatar.name)
}

// Record action
avatarStore.recordUserAction(.answeredCorrect)
```

---

## 🎨 Personality Types

```swift
enum Personality {
    case friendlyCurious   // Lyo  - Warm & curious
    case energeticCoach    // Max  - High-energy & motivating
    case calmReflective    // Luna - Calm & mindful
    case wisePatient       // Sage - Patient & Socratic
}
```

**Each has:**
- `systemPrompt` → For AI integration
- `tagline` → UI description
- `sampleGreeting` → First message

---

## 🎭 Mood System

```swift
enum CompanionMood {
    case neutral, excited, encouraging
    case thoughtful, celebrating, tired, curious
}

// Each mood has:
mood.color  // Color for UI
mood.emoji  // Visual indicator
```

**Update mood:**
```swift
avatarStore.recordUserAction(.answeredCorrect)
// → mood becomes .celebrating
```

---

## 🗣️ Voice System

**Basic (Current):**
```swift
avatarStore.speak("Hello! Let's learn together.")
// Uses AVSpeechSynthesizer
// Modulates based on personality & mood
```

**Advanced (Future):**
```swift
let service = RealtimeVoiceService()
await service.initializeVoice(for: avatar)
await service.speak("Hello!")
// Uses OpenAI Realtime API
```

---

## 💾 Persistence

**Automatic:**
```swift
// AvatarStore automatically saves to:
// - Documents/avatar.json
// - Documents/avatar_state.json
// - Documents/avatar_memory.json
```

**Manual:**
```swift
// Save to cloud (future)
let syncService = AvatarSyncService.shared
try await syncService.syncAvatarToCloud(avatar: avatar)

// Load from cloud
let avatar = try await syncService.fetchAvatarFromCloud()
```

---

## 🧠 Memory System

```swift
// Record topic
avatarStore.memory.recordTopic("Calculus")

// Record struggle
avatarStore.memory.recordStruggle(with: "derivatives")

// Record achievement
avatarStore.memory.recordAchievement("Completed lesson")

// Get insights
let challengingTopic = avatarStore.memory.mostChallengingTopic
// → "derivatives" (mentioned 3 times)
```

---

## 🎯 User Actions

```swift
enum UserAction {
    case answeredCorrect
    case answeredIncorrect
    case struggled
    case askedQuestion
    case completedLesson
    case startedSession
}

// Record action
avatarStore.recordUserAction(.completedLesson)
// → Updates mood, memory, and triggers voice response
```

---

## 🔧 Common Code Snippets

### Add Avatar to View
```swift
struct MyView: View {
    @EnvironmentObject var avatarStore: AvatarStore

    var body: some View {
        VStack {
            if let avatar = avatarStore.avatar {
                Text("Hi, I'm \(avatar.name)!")
            }
        }
    }
}
```

### Show Avatar Setup
```swift
if avatarStore.needsOnboarding {
    QuickAvatarSetupView { completedAvatar in
        print("Setup complete: \(completedAvatar.name)")
    }
    .environmentObject(avatarStore)
}
```

### Floating Button
```swift
ZStack {
    // Your content
    ScrollView { }

    // Floating avatar button
    VStack {
        Spacer()
        HStack {
            Spacer()
            FloatingAvatarButton()
                .padding(24)
        }
    }
}
```

### AI Integration
```swift
let brain = AvatarBrain(store: avatarStore)
let systemPrompt = brain.buildSystemPrompt(for: "Learning calculus")

// Use with OpenAI
let completion = try await openAI.chatCompletion(
    messages: [
        .system(systemPrompt),
        .user("Explain derivatives")
    ]
)
```

---

## 🎨 UI Components

### Avatar Preview
```swift
// Large preview
AvatarPreviewView(
    avatar: avatar,
    mood: .celebrating,
    size: 220,
    showMoodIndicator: true
)

// Small preview
Circle()
    .fill(LinearGradient(colors: avatar.gradientColors, ...))
    .frame(width: 64, height: 64)
    .overlay(Text(avatar.displayEmoji).font(.largeTitle))
```

### Mood Indicator
```swift
HStack {
    Text(avatar.name)
    Text(mood.emoji)  // 😊, 🤩, 🤔, etc.
        .foregroundColor(mood.color)
}
```

### Message Bubble
```swift
HStack {
    if message.isUser { Spacer() }

    Text(message.text)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(message.isUser ? .blue : .gray.opacity(0.2))
        )

    if !message.isUser { Spacer() }
}
```

---

## 🧪 Testing

### Test Avatar Creation
```swift
func testAvatarCreation() {
    let store = AvatarStore()
    let avatar = Avatar(name: "TestBot")
    store.completeSetup(with: avatar)

    XCTAssertNotNil(store.avatar)
    XCTAssertEqual(store.avatar?.name, "TestBot")
    XCTAssertTrue(store.hasCompletedSetup)
}
```

### Test Voice
```swift
func testVoice() {
    let store = AvatarStore()
    store.avatar = Avatar()
    store.speak("Hello, world!")
    // Should hear speech
}
```

### Test Mood Changes
```swift
func testMoodChanges() {
    let store = AvatarStore()
    store.avatar = Avatar()

    store.recordUserAction(.answeredCorrect)
    XCTAssertEqual(store.state.mood, .celebrating)

    store.recordUserAction(.answeredIncorrect)
    XCTAssertEqual(store.state.mood, .encouraging)
}
```

---

## 🐛 Common Issues

### "Avatar not found"
```swift
// ❌ Wrong
Text(avatarStore.avatar.name)

// ✅ Correct
if let avatar = avatarStore.avatar {
    Text(avatar.name)
}
```

### "EnvironmentObject error"
```swift
// Make sure to pass avatarStore
ContentView()
    .environmentObject(avatarStore)  // ← Add this
```

### "Voice not working"
```swift
// Check audio session
import AVFoundation

let session = AVAudioSession.sharedInstance()
try? session.setCategory(.playback)
try? session.setActive(true)
```

### "Avatar resets every launch"
```swift
// Check AvatarStore initialization
@StateObject private var avatarStore = AvatarStore()
// NOT @State or let

// Verify files exist
print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
```

---

## 📊 Performance

### Target Metrics
- Avatar creation: < 5 seconds
- Voice response: < 1 second
- Mood change: < 100ms
- Memory usage: < 50MB (emoji), < 200MB (Unity)
- Battery: < 5% per hour

### Optimization
```swift
// Lazy load components
if showAvatar {
    AvatarView()
        .onAppear { loadAvatarAssets() }
}

// Release Unity when not visible
.onDisappear {
    UnityBridge.shared.pause()
}
```

---

## 🔗 Quick Links

- [Quick Start](AVATAR_QUICK_START.md) - Get started today
- [Technical Spec](AI_AVATAR_CREATOR_TECHNICAL_SPEC.md) - Full details
- [Visual Guide](AVATAR_VISUAL_GUIDE.md) - UX mockups
- [Unity Setup](Unity/UNITY_SETUP_GUIDE.md) - 3D integration

---

## 💡 Pro Tips

1. **Start Simple**: Get emoji avatars working before Unity 3D
2. **Test Voice Early**: Voice is critical to user experience
3. **Use Memory**: Show you remember - users love that
4. **Celebrate Wins**: Level-up animations = engagement
5. **Monitor Performance**: Use Instruments from day 1

---

## 🚀 Quick Start Checklist

- [ ] Read [AVATAR_QUICK_START.md](AVATAR_QUICK_START.md)
- [ ] Test existing avatar setup flow
- [ ] Create `FloatingAvatarButton.swift`
- [ ] Create `AvatarCompanionWidget.swift`
- [ ] Create `AvatarChatView.swift`
- [ ] Add to [LyoApp.swift](LyoApp/LyoApp.swift)
- [ ] Add to home view
- [ ] Test end-to-end
- [ ] Ship! 🎉

---

**Keep this reference handy while coding!**

For detailed explanations, see the full documentation.
