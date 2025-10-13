# 🤖 AI Avatar Creator - Technical Implementation Specification

**Version:** 1.0
**Date:** October 9, 2025
**Status:** Ready for Implementation

---

## 📋 Executive Summary

This document provides the complete technical specification for implementing the AI Avatar Creator system in LyoApp. The system allows users to create, personalize, and interact with a persistent 3D AI companion that serves as their learning interface throughout the platform.

### Current Status
- ✅ **Foundation Complete**: Avatar models, state management, and basic UI implemented in SwiftUI
- ✅ **Sentiment System**: Real-time mood detection and intervention system ready
- 🔄 **Phase 1 (Current)**: Enhance existing SwiftUI implementation
- 🔜 **Phase 2**: Unity 3D avatar integration
- 🔜 **Phase 3**: Cross-platform expansion

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │ QuickAvatarSetup│  │ AvatarPicker   │  │ AvatarWidget  │ │
│  │     View        │  │     View       │  │   (FloatingUI)│ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    State Management Layer                    │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │  AvatarStore   │  │  AvatarBrain   │  │  Sentiment    │ │
│  │  (Persistence) │  │  (Behavior)    │  │  Manager      │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Integration Layer                         │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │  Unity Bridge  │  │  Voice Engine  │  │  AI Service   │ │
│  │  (3D Render)   │  │  (TTS/STT)     │  │  (GPT-4o)     │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Data & Backend Layer                      │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │  Firebase      │  │  Asset CDN     │  │  Analytics    │ │
│  │  (Cloud Sync)  │  │  (Addressables)│  │  (Telemetry)  │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Models

### Current Implementation (Swift)

Located in [AvatarModels.swift](LyoApp/Models/AvatarModels.swift)

```swift
// Main Avatar Model
struct Avatar: Codable, Identifiable {
    var id: UUID
    var name: String
    var appearance: AvatarAppearance
    var profile: PersonalityProfile
    var voiceIdentifier: String?
    var calibrationAnswers: CalibrationAnswers
    var createdAt: Date
}

// Visual Configuration
struct AvatarAppearance: Codable {
    var style: AvatarStyle  // friendlyBot, wiseMentor, energeticCoach
    var skinTone: Int
    var faceShape: Int
    var eyeShape: Int
    var eyeColor: Int
    var hairStyle: Int
    var hairColor: Int
    var accessories: [Int]
    var outfit: Int
}

// Behavioral Configuration
struct PersonalityProfile: Codable {
    var basePersonality: Personality
    var hintFrequency: Float       // 0.0-1.0
    var celebrationIntensity: Float // 0.0-1.0
    var pacePreference: Float      // 0.0-1.0
    var scaffoldingStyle: ScaffoldingStyle
}

// Runtime State
struct CompanionState: Codable {
    var mood: CompanionMood
    var energy: Float
    var lastInteraction: Date
    var currentActivity: String?
    var isSpeaking: Bool
}

// Persistent Memory
struct AvatarMemory: Codable {
    var lastSeenDate: Date
    var topicsDiscussed: [String]
    var strugglesNoted: [String: Int]
    var achievements: [String]
    var conversationCount: Int
    var totalStudyMinutes: Int
}
```

### JSON Payload for Backend Sync

```json
{
  "userId": "user_abc123",
  "avatar": {
    "id": "avatar_xyz789",
    "name": "Lyo",
    "version": "1.0",
    "appearance": {
      "style": "friendlyBot",
      "skinTone": 4,
      "faceShape": 2,
      "eyeShape": 1,
      "eyeColor": 3,
      "hairStyle": 4,
      "hairColor": 3,
      "accessories": [1, 5],
      "outfit": 2
    },
    "personality": {
      "baseType": "friendlyCurious",
      "hintFrequency": 0.7,
      "celebrationIntensity": 0.8,
      "pacePreference": 0.5,
      "scaffoldingStyle": "examplesFirst"
    },
    "voice": {
      "identifier": "com.apple.ttsbundle.Samantha-compact",
      "language": "en-US",
      "pitch": 1.0,
      "rate": 0.52
    },
    "stats": {
      "level": 5,
      "xp": 2450,
      "totalSessions": 23,
      "totalMinutes": 487,
      "lessonsCompleted": 12,
      "createdAt": "2025-10-01T10:30:00Z"
    }
  }
}
```

---

## 🎨 User Experience Flow

### 1. First-Time Onboarding

**Entry Point:** After user signs up or first launches app

```swift
// In LyoApp.swift or main ContentView
@StateObject private var avatarStore = AvatarStore()

var body: some View {
    if avatarStore.needsOnboarding {
        QuickAvatarSetupView { completedAvatar in
            // Avatar created, proceed to main app
            showMainApp = true
        }
        .environmentObject(avatarStore)
    } else {
        MainAppView()
            .environmentObject(avatarStore)
    }
}
```

**Steps:**
1. **Welcome Screen**
   - Animated greeting
   - "Let's create your learning companion"
   - Tap to begin

2. **Style Selection** (Step 1/4)
   - Preview: Live rotating 3D preview (emoji currently, Unity later)
   - Options: 3 personality types with descriptions
   - Action: Tap card to select, auto-updates preview

3. **Name Input** (Step 2/4)
   - Text field with smart suggestions
   - Real-time preview updates
   - Validation: Non-empty, 2-20 characters

4. **Voice Selection** (Step 3/4)
   - 4-6 high-quality voice options
   - Tap to preview (speaks personality greeting)
   - Visual waveform while speaking

5. **Confirmation** (Step 4/4)
   - Full preview with celebration animation
   - Summary cards (personality, style, voice)
   - CTA: "Start Learning with [Name]"

**Implementation Files:**
- [QuickAvatarSetupView.swift](LyoApp/QuickAvatarSetupView.swift) - Complete 4-step flow
- [QuickAvatarPickerView.swift](LyoApp/QuickAvatarPickerView.swift) - Quick selection alternative
- [AvatarStore.swift](LyoApp/Managers/AvatarStore.swift) - State management

---

### 2. Avatar Integration Points

#### A. Home Dashboard
```swift
struct HomeFeedView: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @State private var showAvatarChat = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main content
            ScrollView {
                // ...
            }

            // Floating Avatar Button
            FloatingAvatarButton(
                avatar: avatarStore.avatar!,
                mood: avatarStore.currentMood
            ) {
                showAvatarChat = true
            }
            .padding(24)
        }
        .sheet(isPresented: $showAvatarChat) {
            AvatarChatView()
                .environmentObject(avatarStore)
        }
    }
}
```

#### B. AI Classroom View
```swift
struct AIClassroomView: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @StateObject private var sentimentManager = SentimentAwareAvatarManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Top: Avatar companion widget
            AvatarCompanionWidget(
                avatar: avatarStore.avatar!,
                emotion: sentimentManager.currentEmotion,
                message: sentimentManager.empathyMessage
            )
            .frame(height: 80)

            // Middle: Lesson content
            LessonContentView()

            // Bottom: Chat interface
            ChatInputView()
        }
    }
}
```

#### C. Lesson Player (Horizontal Mode)
```swift
struct LessonPlayerView: View {
    @EnvironmentObject var avatarStore: AvatarStore

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-screen video/content
            VideoPlayerView()
                .ignoresSafeArea()

            // Mini avatar overlay (bottom-left)
            MiniAvatarOverlay(
                avatar: avatarStore.avatar!,
                state: avatarStore.state,
                size: .small
            )
            .padding(16)
        }
    }
}
```

#### D. Quiz/Assessment Mode
```swift
struct QuizView: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @State private var lastAnswer: AnswerResult?

    var body: some View {
        VStack {
            // Question
            QuestionCard(question: currentQuestion)

            // Avatar reaction
            if let result = lastAnswer {
                AvatarReactionView(
                    avatar: avatarStore.avatar!,
                    reaction: result == .correct ? .celebrating : .encouraging
                )
                .transition(.scale)
            }

            // Answer options
            AnswerButtonsView { answer in
                handleAnswer(answer)
            }
        }
    }

    func handleAnswer(_ answer: Answer) {
        let result = answer.isCorrect ? AnswerResult.correct : .incorrect

        // Update avatar state
        if answer.isCorrect {
            avatarStore.recordUserAction(.answeredCorrect)
        } else {
            avatarStore.recordUserAction(.answeredIncorrect)
        }

        lastAnswer = result
    }
}
```

---

## 🎭 Avatar Behavior Engine

### System Prompt Generation

Located in [AvatarStore.swift:310](LyoApp/Managers/AvatarStore.swift#L310)

```swift
class AvatarBrain: ObservableObject {
    func buildSystemPrompt(for context: String = "") -> String {
        guard let avatar = store.avatar else {
            return "You are a helpful learning assistant."
        }

        var prompt = avatar.personality.systemPrompt

        // Add learning style preferences
        prompt += "\n\nLearning Style: \(avatar.calibrationAnswers.learningStyle.description)"
        prompt += "\nPace: \(avatar.calibrationAnswers.pace)"

        // Add memory context
        if !memory.topicsDiscussed.isEmpty {
            let recentTopics = memory.topicsDiscussed.suffix(3).joined(separator: ", ")
            prompt += "\n\nRecent Topics: \(recentTopics)"
        }

        // Add struggle context
        if let strugglingTopic = memory.mostChallengingTopic {
            prompt += "\n\nNote: Student struggles with \(strugglingTopic). Be extra patient and scaffold carefully."
        }

        // Add behavioral tuning
        if avatar.profile.hintFrequency > 0.7 {
            prompt += "\n\nProvide frequent hints and guidance."
        } else if avatar.profile.hintFrequency < 0.3 {
            prompt += "\n\nLet student figure things out independently; only hint when stuck."
        }

        return prompt
    }
}
```

### Usage with OpenAI Realtime API

```swift
class AIChatService: ObservableObject {
    @Published var avatarBrain: AvatarBrain

    func startConversation(about topic: String) async throws {
        let systemPrompt = avatarBrain.buildSystemPrompt(for: "Learning topic: \(topic)")

        let session = try await OpenAIRealtime.createSession(
            model: "gpt-4o-realtime-preview",
            systemPrompt: systemPrompt,
            voice: avatarBrain.avatar?.voiceIdentifier ?? "alloy"
        )

        // Stream conversation
        for try await event in session.events {
            switch event {
            case .audioChunk(let data):
                playAudio(data)
            case .transcript(let text):
                updateTranscript(text)
            case .functionCall(let name, let args):
                handleFunction(name, args)
            }
        }
    }
}
```

---

## 🗣️ Voice & Speech System

### Current Implementation (AVSpeechSynthesizer)

Located in [AvatarStore.swift:212](LyoApp/Managers/AvatarStore.swift#L212)

```swift
extension AvatarStore {
    func speak(_ text: String) {
        guard let avatar else { return }

        let utterance = AVSpeechUtterance(string: text)

        // Apply custom voice
        if let voiceID = avatar.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
            utterance.voice = voice
        }

        // Modulate based on personality and mood
        utterance.rate = baseRate(for: avatar.personality, mood: state.mood)
        utterance.pitchMultiplier = basePitch(for: state.mood)
        utterance.volume = 0.8

        state.isSpeaking = true

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)

        // Reset state after speaking
        Task {
            try? await Task.sleep(nanoseconds: UInt64(text.count) * 50_000_000)
            state.isSpeaking = false
        }
    }
}
```

### Upgrade Path: OpenAI Realtime API

```swift
class RealtimeVoiceService: ObservableObject {
    private var session: OpenAIRealtimeSession?

    func initializeVoice(for avatar: Avatar) async throws {
        // Map avatar personality to OpenAI voice
        let voiceID = mapAvatarToOpenAIVoice(avatar)

        session = try await OpenAIRealtime.connect(
            apiKey: AppConfig.openAIKey,
            voice: voiceID,
            instructions: AvatarBrain.buildSystemPrompt()
        )
    }

    func speak(_ text: String) async throws {
        guard let session else { return }
        try await session.sendText(text)
    }

    func startListening() async throws {
        guard let session else { return }

        // Stream microphone input
        for try await audioBuffer in AudioEngine.shared.captureStream() {
            try await session.sendAudio(audioBuffer)
        }
    }

    private func mapAvatarToOpenAIVoice(_ avatar: Avatar) -> String {
        switch avatar.personality {
        case .friendlyCurious: return "alloy"      // Warm, neutral
        case .energeticCoach: return "fable"       // Energetic, upbeat
        case .calmReflective: return "nova"        // Calm, soothing
        case .wisePatient: return "onyx"           // Deep, authoritative
        }
    }
}
```

---

## 🎮 Unity 3D Avatar Integration

### Phase 2 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   SwiftUI Host App                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │        UnityViewControllerRepresentable          │  │
│  │                                                   │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │        Unity View (UIViewRepresentable)    │ │  │
│  │  │                                             │ │  │
│  │  │  ┌──────────────────────────────────────┐  │ │  │
│  │  │  │   Unity Render (3D Avatar Scene)     │  │ │  │
│  │  │  │                                       │  │ │  │
│  │  │  │   - Character Controller             │  │ │  │
│  │  │  │   - Animation Controller             │  │ │  │
│  │  │  │   - Blendshape Controller            │  │ │  │
│  │  │  │   - Particle Effects (mood glow)     │  │ │  │
│  │  │  └──────────────────────────────────────┘  │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ↕ Unity-Swift Bridge
┌─────────────────────────────────────────────────────────┐
│                  Unity C# Controllers                    │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  AvatarManager  │  │  MessageHandler │              │
│  │  (Receives JSON)│→ │  (Swift Events) │              │
│  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

### Swift → Unity Bridge

**1. Unity View Wrapper**

Create file: `LyoApp/Unity/UnityAvatarView.swift`

```swift
import SwiftUI
import UnityFramework

struct UnityAvatarView: UIViewRepresentable {
    let avatar: Avatar
    let mood: CompanionMood
    let isSpeaking: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UnityBridge.shared.getUnityView()

        // Initialize with avatar config
        UnityBridge.shared.sendMessage(
            objectName: "AvatarManager",
            methodName: "LoadAvatar",
            message: avatar.toUnityJSON()
        )

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update mood
        UnityBridge.shared.sendMessage(
            objectName: "AvatarManager",
            methodName: "SetMood",
            message: mood.rawValue
        )

        // Update speaking state
        UnityBridge.shared.sendMessage(
            objectName: "AvatarManager",
            methodName: "SetSpeaking",
            message: isSpeaking ? "true" : "false"
        )
    }
}

// Unity Bridge Singleton
class UnityBridge {
    static let shared = UnityBridge()
    private var unityFramework: UnityFramework?

    func initialize() {
        let bundlePath = Bundle.main.path(forResource: "UnityFramework", ofType: "framework")!
        let bundle = Bundle(path: bundlePath)!

        if let framework = bundle.principalClass?.getInstance() {
            unityFramework = framework
            framework.setDataBundleId("com.unity3d.framework")
            framework.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: nil)
        }
    }

    func sendMessage(objectName: String, methodName: String, message: String) {
        unityFramework?.sendMessageToGO(
            withName: objectName,
            functionName: methodName,
            message: message
        )
    }

    func getUnityView() -> UIView {
        return unityFramework?.appController()?.rootView ?? UIView()
    }
}

// Avatar → Unity JSON
extension Avatar {
    func toUnityJSON() -> String {
        let config: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "style": appearance.style.rawValue,
            "skinTone": appearance.skinTone,
            "hairStyle": appearance.hairStyle,
            "hairColor": appearance.hairColor,
            "outfit": appearance.outfit,
            "accessories": appearance.accessories
        ]

        let data = try! JSONSerialization.data(withJSONObject: config)
        return String(data: data, encoding: .utf8)!
    }
}
```

**2. Unity C# Controllers**

Create file: `Unity/Assets/Scripts/AvatarManager.cs`

```csharp
using UnityEngine;
using System;
using System.Collections.Generic;

public class AvatarManager : MonoBehaviour
{
    [Header("Avatar Components")]
    public SkinnedMeshRenderer bodyMesh;
    public SkinnedMeshRenderer hairMesh;
    public SkinnedMeshRenderer outfitMesh;

    [Header("Controllers")]
    public Animator animator;
    public AvatarBlendshapeController blendshapes;
    public ParticleSystem moodGlow;

    private AvatarConfig currentConfig;
    private string currentMood = "neutral";
    private bool isSpeaking = false;

    // Called from Swift
    public void LoadAvatar(string jsonConfig)
    {
        Debug.Log($"[Unity] Loading avatar: {jsonConfig}");

        currentConfig = JsonUtility.FromJson<AvatarConfig>(jsonConfig);
        ApplyAvatarConfiguration();
    }

    public void SetMood(string mood)
    {
        Debug.Log($"[Unity] Setting mood: {mood}");
        currentMood = mood;

        // Trigger mood animation
        animator.SetTrigger($"Mood_{mood}");

        // Update particle glow color
        UpdateMoodGlow(mood);

        // Adjust blendshapes
        blendshapes.SetMood(mood);
    }

    public void SetSpeaking(string speaking)
    {
        isSpeaking = speaking == "true";
        animator.SetBool("IsSpeaking", isSpeaking);

        if (isSpeaking)
        {
            StartLipSync();
        }
        else
        {
            StopLipSync();
        }
    }

    private void ApplyAvatarConfiguration()
    {
        // Load addressable assets based on config
        LoadBodyMesh(currentConfig.style);
        LoadHairStyle(currentConfig.hairStyle, currentConfig.hairColor);
        LoadOutfit(currentConfig.outfit);
        LoadAccessories(currentConfig.accessories);

        // Apply skin tone material
        ApplySkinTone(currentConfig.skinTone);
    }

    private void UpdateMoodGlow(string mood)
    {
        Color glowColor = mood switch
        {
            "excited" => Color.yellow,
            "celebrating" => new Color(1f, 0f, 1f), // Purple
            "encouraging" => Color.green,
            "thoughtful" => Color.blue,
            "tired" => Color.gray,
            _ => Color.white
        };

        var main = moodGlow.main;
        main.startColor = glowColor;
    }

    private void StartLipSync()
    {
        // Integrate with OVR LipSync or Salsa LipSync
        blendshapes.EnableLipSync();
    }

    private void StopLipSync()
    {
        blendshapes.DisableLipSync();
    }
}

[Serializable]
public class AvatarConfig
{
    public string id;
    public string name;
    public string style;
    public int skinTone;
    public int hairStyle;
    public int hairColor;
    public int outfit;
    public List<int> accessories;
}
```

**3. Blendshape Controller for Expressions**

Create file: `Unity/Assets/Scripts/AvatarBlendshapeController.cs`

```csharp
using UnityEngine;
using System.Collections;

public class AvatarBlendshapeController : MonoBehaviour
{
    public SkinnedMeshRenderer faceMesh;

    // Blendshape indices (mapped to VRM standard)
    private const int BLINK_LEFT = 0;
    private const int BLINK_RIGHT = 1;
    private const int SMILE = 2;
    private const int MOUTH_OPEN = 3;
    private const int EYEBROW_UP_LEFT = 4;
    private const int EYEBROW_UP_RIGHT = 5;
    private const int EYEBROW_DOWN = 6;

    private bool lipSyncEnabled = false;

    public void SetMood(string mood)
    {
        StopAllCoroutines();

        switch (mood)
        {
            case "happy":
                StartCoroutine(AnimateBlendshape(SMILE, 80f, 0.3f));
                break;
            case "excited":
                StartCoroutine(AnimateBlendshape(SMILE, 100f, 0.2f));
                StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 70f, 0.2f));
                StartCoroutine(AnimateBlendshape(EYEBROW_UP_RIGHT, 70f, 0.2f));
                break;
            case "concerned":
                StartCoroutine(AnimateBlendshape(EYEBROW_DOWN, 60f, 0.3f));
                StartCoroutine(AnimateBlendshape(SMILE, 20f, 0.3f));
                break;
            case "thinking":
                StartCoroutine(AnimateBlendshape(EYEBROW_UP_LEFT, 40f, 0.4f));
                break;
            default:
                ResetToNeutral();
                break;
        }

        // Automatic blinking
        StartCoroutine(AutoBlink());
    }

    public void EnableLipSync()
    {
        lipSyncEnabled = true;
        StartCoroutine(LipSyncRoutine());
    }

    public void DisableLipSync()
    {
        lipSyncEnabled = false;
    }

    private IEnumerator AnimateBlendshape(int index, float target, float duration)
    {
        float start = faceMesh.GetBlendShapeWeight(index);
        float elapsed = 0f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float value = Mathf.Lerp(start, target, elapsed / duration);
            faceMesh.SetBlendShapeWeight(index, value);
            yield return null;
        }

        faceMesh.SetBlendShapeWeight(index, target);
    }

    private IEnumerator AutoBlink()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(2f, 5f));

            // Quick blink
            yield return AnimateBlendshape(BLINK_LEFT, 100f, 0.05f);
            yield return AnimateBlendshape(BLINK_RIGHT, 100f, 0.05f);
            yield return new WaitForSeconds(0.1f);
            yield return AnimateBlendshape(BLINK_LEFT, 0f, 0.05f);
            yield return AnimateBlendshape(BLINK_RIGHT, 0f, 0.05f);
        }
    }

    private IEnumerator LipSyncRoutine()
    {
        // Simple procedural lip sync (upgrade to OVR LipSync for real audio-driven)
        while (lipSyncEnabled)
        {
            float randomOpen = Random.Range(30f, 70f);
            yield return AnimateBlendshape(MOUTH_OPEN, randomOpen, 0.1f);
            yield return new WaitForSeconds(0.05f);
            yield return AnimateBlendshape(MOUTH_OPEN, 0f, 0.1f);
            yield return new WaitForSeconds(0.1f);
        }

        faceMesh.SetBlendShapeWeight(MOUTH_OPEN, 0f);
    }

    private void ResetToNeutral()
    {
        for (int i = 0; i < faceMesh.sharedMesh.blendShapeCount; i++)
        {
            StartCoroutine(AnimateBlendshape(i, 0f, 0.3f));
        }
    }
}
```

---

## 🎁 Avatar Upgrades & Progression System

### XP and Level System

```swift
extension Avatar {
    var currentLevel: Int {
        return calculateLevel(from: xp)
    }

    var xpForNextLevel: Int {
        let nextLevel = currentLevel + 1
        return xpRequired(for: nextLevel)
    }

    var progressToNextLevel: Float {
        let currentLevelXP = xpRequired(for: currentLevel)
        let nextLevelXP = xpRequired(for: currentLevel + 1)
        let xpInCurrentLevel = xp - currentLevelXP
        let xpNeeded = nextLevelXP - currentLevelXP
        return Float(xpInCurrentLevel) / Float(xpNeeded)
    }

    private func calculateLevel(from xp: Int) -> Int {
        var level = 1
        while xpRequired(for: level + 1) <= xp {
            level += 1
        }
        return level
    }

    private func xpRequired(for level: Int) -> Int {
        // Exponential curve: 100 * level^1.5
        return Int(100.0 * pow(Double(level), 1.5))
    }

    mutating func awardXP(_ amount: Int, for action: LearningAction) {
        xp += amount

        // Check for level up
        if calculateLevel(from: xp) > currentLevel {
            handleLevelUp()
        }
    }

    mutating func handleLevelUp() {
        // Unlock rewards
        let newLevel = currentLevel
        let rewards = AvatarRewards.unlockables(at: newLevel)

        // Notify user
        NotificationCenter.default.post(
            name: .avatarLeveledUp,
            object: AvatarLevelUpEvent(
                level: newLevel,
                rewards: rewards
            )
        )
    }
}

struct AvatarRewards {
    static func unlockables(at level: Int) -> [Unlockable] {
        switch level {
        case 2: return [.outfit("Casual Hoodie"), .accessory("Cool Glasses")]
        case 3: return [.hairStyle("Spiky"), .animation("Victory Dance")]
        case 5: return [.outfit("Scholar Robe"), .particle("Golden Aura")]
        case 10: return [.outfit("Cyber Suit"), .voice("Premium Voice Pack")]
        case 15: return [.outfit("Space Explorer"), .animation("Rocket Ride")]
        case 20: return [.unlimitedCustomization]
        default: return []
        }
    }
}

enum Unlockable {
    case outfit(String)
    case hairStyle(String)
    case accessory(String)
    case animation(String)
    case particle(String)
    case voice(String)
    case unlimitedCustomization
}
```

### Reward UI

```swift
struct AvatarLevelUpView: View {
    let event: AvatarLevelUpEvent
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Celebration animation
                LottieView(name: "confetti")
                    .frame(width: 200, height: 200)

                VStack(spacing: 12) {
                    Text("Level Up!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Level \(event.level)")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.yellow)
                }

                // Unlocked rewards
                VStack(spacing: 16) {
                    Text("New Rewards Unlocked!")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(event.rewards, id: \.self) { reward in
                                RewardCard(reward: reward)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                )

                Button("Awesome!") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(40)
        }
    }
}
```

---

## 🌐 Cross-Platform Sync

### Firebase Backend Structure

```
/users/{userId}/
  /avatar/
    id: "avatar_xyz"
    name: "Lyo"
    appearance: { ... }
    personality: { ... }
    stats: { ... }
    updatedAt: timestamp

  /avatar_state/
    mood: "curious"
    energy: 0.85
    lastInteraction: timestamp
    currentActivity: "Calculus Lesson"

  /avatar_memory/
    topicsDiscussed: ["calculus", "physics"]
    strugglesNoted: { "derivatives": 3 }
    achievements: [...]
    conversationCount: 23
    totalStudyMinutes: 487

  /avatar_inventory/
    outfits: [1, 2, 5, 12]
    accessories: [3, 7, 11]
    animations: [1, 4, 9]
    particles: [2]
```

### Sync Service

Create file: `LyoApp/Services/AvatarSyncService.swift`

```swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AvatarSyncService: ObservableObject {
    static let shared = AvatarSyncService()

    private let db = Firestore.firestore()
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    // MARK: - Upload Avatar to Cloud
    func syncAvatarToCloud(avatar: Avatar) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SyncError.notAuthenticated
        }

        isSyncing = true
        defer { isSyncing = false }

        let avatarData = try JSONEncoder().encode(avatar)
        let avatarDict = try JSONSerialization.jsonObject(with: avatarData) as! [String: Any]

        try await db.collection("users")
            .document(userId)
            .collection("avatar")
            .document("current")
            .setData(avatarDict, merge: true)

        lastSyncDate = Date()
    }

    // MARK: - Download Avatar from Cloud
    func fetchAvatarFromCloud() async throws -> Avatar? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw SyncError.notAuthenticated
        }

        isSyncing = true
        defer { isSyncing = false }

        let doc = try await db.collection("users")
            .document(userId)
            .collection("avatar")
            .document("current")
            .getDocument()

        guard let data = doc.data() else {
            return nil
        }

        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let avatar = try JSONDecoder().decode(Avatar.self, from: jsonData)

        lastSyncDate = Date()
        return avatar
    }

    // MARK: - Real-time Listener
    func startRealtimeSync(avatarStore: AvatarStore) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(userId)
            .collection("avatar")
            .document("current")
            .addSnapshotListener { [weak avatarStore] snapshot, error in
                guard let data = snapshot?.data(),
                      let jsonData = try? JSONSerialization.data(withJSONObject: data),
                      let avatar = try? JSONDecoder().decode(Avatar.self, from: jsonData) else {
                    return
                }

                // Update local store
                Task { @MainActor in
                    avatarStore?.avatar = avatar
                }
            }
    }
}

enum SyncError: Error {
    case notAuthenticated
    case encodingFailed
    case uploadFailed
}
```

---

## 📱 UI Components Library

### Floating Avatar Button

Create file: `LyoApp/Views/Components/FloatingAvatarButton.swift`

```swift
import SwiftUI

struct FloatingAvatarButton: View {
    let avatar: Avatar
    let mood: CompanionMood
    let action: () -> Void

    @State private var isPulsing = false
    @State private var showNotificationBadge = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Main avatar circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: avatar.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text(avatar.displayEmoji)
                            .font(.system(size: 32))
                    )
                    .overlay(
                        Circle()
                            .stroke(mood.color, lineWidth: 3)
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .opacity(isPulsing ? 0.0 : 1.0)
                    )
                    .shadow(color: avatar.gradientColors[0].opacity(0.5), radius: 20, x: 0, y: 10)

                // Notification badge
                if showNotificationBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 5, y: -5)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}
```

### Avatar Companion Widget

Create file: `LyoApp/Views/Components/AvatarCompanionWidget.swift`

```swift
import SwiftUI

struct AvatarCompanionWidget: View {
    let avatar: Avatar
    let emotion: AvatarEmotion
    let message: String

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar preview
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: avatar.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text(avatar.displayEmoji)
                    .font(.system(size: 28))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
            }

            // Message bubble
            VStack(alignment: .leading, spacing: 4) {
                Text(avatar.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()

            // Mood indicator
            Text(emotion.emoji)
                .font(.title3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

extension AvatarEmotion {
    var emoji: String {
        switch self {
        case .neutral: return "😊"
        case .happy: return "😄"
        case .excited: return "🤩"
        case .thinking: return "🤔"
        case .concerned: return "😟"
        case .encouraging: return "💪"
        case .calm: return "😌"
        case .celebrating: return "🎉"
        }
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests

Create file: `Tests/LyoAppTests/Avatar/AvatarModelTests.swift`

```swift
import XCTest
@testable import LyoApp

final class AvatarModelTests: XCTestCase {

    func testAvatarCreation() {
        let avatar = Avatar()
        XCTAssertNotNil(avatar.id)
        XCTAssertEqual(avatar.name, "Lyo")
        XCTAssertEqual(avatar.personality, .friendlyCurious)
    }

    func testXPProgression() {
        var avatar = Avatar()
        avatar.xp = 0
        XCTAssertEqual(avatar.currentLevel, 1)

        avatar.xp = 150  // Should be level 2
        XCTAssertEqual(avatar.currentLevel, 2)
    }

    func testPersonalitySystemPrompt() {
        let avatar = Avatar(
            profile: PersonalityProfile(basePersonality: .energeticCoach)
        )

        let prompt = avatar.personality.systemPrompt
        XCTAssertTrue(prompt.contains("Max"))
        XCTAssertTrue(prompt.contains("motivational"))
    }

    func testAvatarMemoryTracking() {
        var memory = AvatarMemory()
        memory.recordTopic("Calculus")
        memory.recordTopic("Physics")

        XCTAssertEqual(memory.topicsDiscussed.count, 2)
        XCTAssertTrue(memory.topicsDiscussed.contains("Calculus"))
    }
}
```

### Integration Tests

Create file: `Tests/LyoAppTests/Avatar/AvatarStoreIntegrationTests.swift`

```swift
import XCTest
@testable import LyoApp

@MainActor
final class AvatarStoreIntegrationTests: XCTestCase {

    var store: AvatarStore!

    override func setUp() async throws {
        store = AvatarStore()
    }

    func testAvatarPersistence() async throws {
        // Create and save avatar
        let avatar = Avatar(name: "TestBot")
        store.completeSetup(with: avatar)

        // Simulate app restart
        let newStore = AvatarStore()

        XCTAssertNotNil(newStore.avatar)
        XCTAssertEqual(newStore.avatar?.name, "TestBot")
    }

    func testMoodUpdates() {
        store.avatar = Avatar()
        store.recordUserAction(.answeredCorrect)

        XCTAssertEqual(store.state.mood, .celebrating)
    }

    func testGreetingGeneration() {
        store.avatar = Avatar(name: "Lyo")
        let greeting = store.currentGreeting

        XCTAssertTrue(greeting.contains("Lyo"))
    }
}
```

---

## 📦 Implementation Checklist

### Phase 1: SwiftUI Enhancement (Current - Week 1-2)

- [x] Avatar models created ([AvatarModels.swift](LyoApp/Models/AvatarModels.swift))
- [x] State management implemented ([AvatarStore.swift](LyoApp/Managers/AvatarStore.swift))
- [x] Basic UI components created
- [ ] **Enhance FloatingAvatarButton component**
- [ ] **Add AvatarCompanionWidget to classroom views**
- [ ] **Implement MiniAvatarOverlay for lesson player**
- [ ] **Create AvatarProgressBar for XP display**
- [ ] **Add avatar reaction animations to quiz views**
- [ ] **Test voice modulation across all personalities**

### Phase 2: Unity 3D Integration (Week 3-6)

- [ ] Set up Unity project with URP
- [ ] Create Unity-Swift bridge
- [ ] Implement UnityAvatarView wrapper
- [ ] Build 3D avatar base models (VRM format)
- [ ] Implement animation controller
- [ ] Add blendshape facial expressions
- [ ] Integrate OVR LipSync
- [ ] Create particle effects for moods
- [ ] Build addressables system for customization items
- [ ] Test performance on target iOS devices

### Phase 3: Backend & Sync (Week 7-8)

- [ ] Set up Firebase Firestore schema
- [ ] Implement AvatarSyncService
- [ ] Add real-time listeners
- [ ] Create cloud backup/restore flow
- [ ] Build inventory system
- [ ] Implement reward unlocks
- [ ] Add analytics tracking
- [ ] Test cross-device synchronization

### Phase 4: Voice & AI Enhancement (Week 9-10)

- [ ] Integrate OpenAI Realtime API
- [ ] Map avatar personalities to voices
- [ ] Implement audio streaming
- [ ] Add speech-to-text for user input
- [ ] Create conversation flow manager
- [ ] Test latency and responsiveness
- [ ] Add fallback to AVSpeechSynthesizer

### Phase 5: Polish & Testing (Week 11-12)

- [ ] Write comprehensive unit tests
- [ ] Conduct user testing sessions
- [ ] Optimize performance
- [ ] Add accessibility features
- [ ] Create onboarding tutorial
- [ ] Polish animations and transitions
- [ ] Final QA pass

---

## 🚀 Quick Start Guide

### For Engineers Starting Today

1. **Review Current Implementation**
   ```bash
   # Key files to understand first
   LyoApp/Models/AvatarModels.swift
   LyoApp/Managers/AvatarStore.swift
   LyoApp/QuickAvatarSetupView.swift
   ```

2. **Test Current Flow**
   ```bash
   # Build and run
   cd "LyoApp July"
   xcodebuild -scheme LyoApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
   ```

3. **Add Avatar to Existing Views**
   ```swift
   // In any view that needs avatar integration
   @EnvironmentObject var avatarStore: AvatarStore

   // Use avatar
   if let avatar = avatarStore.avatar {
       FloatingAvatarButton(avatar: avatar, mood: avatarStore.currentMood) {
           // Handle tap
       }
   }
   ```

4. **Extend with New Features**
   - Add new personality types in `AvatarModels.swift`
   - Create custom UI components in `Views/Components/`
   - Implement new behaviors in `AvatarBrain`

---

## 📚 Additional Resources

### Unity Setup Guides
- [Unity for iOS Official Guide](https://docs.unity3d.com/Manual/UnityasaLibrary-iOS.html)
- [VRM Avatar Format](https://vrm.dev/en/)
- [Addressables Documentation](https://docs.unity3d.com/Manual/com.unity.addressables.html)

### Voice Integration
- [OpenAI Realtime API Docs](https://platform.openai.com/docs/guides/realtime)
- [AVSpeechSynthesizer Reference](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer)
- [OVR LipSync](https://developer.oculus.com/downloads/package/oculus-lipsync-unity/)

### 3D Character Resources
- [Ready Player Me](https://readyplayer.me/) - Avatar creation SDK
- [VRoid Studio](https://vroid.com/en/studio) - Character creator
- [Mixamo](https://www.mixamo.com/) - Animation library

---

## 🎯 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Avatar Creation Completion** | >90% | % of users who complete setup |
| **Daily Avatar Interactions** | >5 per user | Avg. taps/conversations per day |
| **Voice Usage** | >60% | % of users who enable voice |
| **Customization Engagement** | >40% | % who change avatar after creation |
| **XP Progression** | 80% reach level 5 | Within first month |
| **Cross-Device Sync** | <2s sync time | Firebase latency |

---

## 🔮 Future Roadmap

### Phase 6: Social Features (Q1 2026)
- Avatar-to-avatar interactions
- Group study sessions with avatars
- Avatar showcase gallery
- Custom avatar sharing

### Phase 7: AR Integration (Q2 2026)
- ARKit avatar projection
- Real-world avatar companion
- Spatial computing support

### Phase 8: Advanced AI (Q3 2026)
- Emotion recognition from camera
- Adaptive personality learning
- Multi-modal interaction (voice + gesture)

---

## 📞 Support & Contact

For implementation questions:
- Technical Lead: [Your Engineering Team]
- AI/ML Questions: [AI Specialist]
- Unity Integration: [Unity Developer]

**Let's build the future of AI-powered learning! 🚀**
