//
//  AvatarStore.swift
//  LyoApp
//
//  Avatar persistence and state management
//  Created: October 6, 2025
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Avatar Store (Persistence + Global State)

@MainActor
final class AvatarStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published var avatar: Avatar? {
        didSet { save() }
    }
    
    @Published var state: CompanionState = CompanionState() {
        didSet { saveState() }
    }
    
    @Published var memory: AvatarMemory = AvatarMemory() {
        didSet { saveMemory() }
    }
    
    // MARK: - Persistence Keys
    
    @AppStorage("hasCompletedAvatarSetup") var hasCompletedSetup: Bool = false
    
    private let avatarURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar.json")
    }()
    
    private let stateURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar_state.json")
    }()
    
    private let memoryURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar_memory.json")
    }()
    
    // MARK: - Initialization
    
    init() {
        load()
    }
    
    // MARK: - Computed Properties
    
    var needsOnboarding: Bool {
        !hasCompletedSetup || avatar == nil
    }
    
    var currentGreeting: String {
        guard let avatar else { return "Hello! Let's get started." }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        if hour < 12 {
            timeGreeting = "Good morning"
        } else if hour < 18 {
            timeGreeting = "Good afternoon"
        } else {
            timeGreeting = "Good evening"
        }
        
        // Personalized based on memory
        if let lastTopic = memory.topicsDiscussed.last {
            return "\(timeGreeting), \(avatar.name)! Ready to continue with \(lastTopic)?"
        }
        
        if memory.conversationCount == 0 {
            return "\(timeGreeting)! I'm \(avatar.name), your learning companion. What would you like to learn today?"
        }
        
        return "\(timeGreeting), \(avatar.name)! What would you like to explore today?"
    }
    
    var currentMood: CompanionMood {
        // Dynamic mood based on context
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Late night → tired
        if hour >= 22 || hour <= 5 {
            return .tired
        }
        
        // Check recent achievements
        if !memory.achievements.isEmpty {
            let recentAchievements = memory.achievements.suffix(5)
            if recentAchievements.contains(where: { $0.contains("completed") }) {
                return .celebrating
            }
        }
        
        // Check for struggles
        if let mostChallenging = memory.mostChallengingTopic, memory.strugglesNoted[mostChallenging, default: 0] > 3 {
            return .encouraging
        }
        
        // Default mood based on personality
        guard let avatar else { return .neutral }
        switch avatar.personality {
        case .energeticCoach:
            return .excited
        case .friendlyCurious:
            return .curious
        case .calmReflective:
            return .neutral
        case .wisePatient:
            return .thoughtful
        }
    }
    
    // MARK: - Load
    
    func load() {
        // Load avatar
        if let data = try? Data(contentsOf: avatarURL),
           let loadedAvatar = try? JSONDecoder().decode(Avatar.self, from: data) {
            self.avatar = loadedAvatar
            self.hasCompletedSetup = true
        }
        
        // Load state
        if let data = try? Data(contentsOf: stateURL),
           let loadedState = try? JSONDecoder().decode(CompanionState.self, from: data) {
            self.state = loadedState
        }
        
        // Load memory
        if let data = try? Data(contentsOf: memoryURL),
           let loadedMemory = try? JSONDecoder().decode(AvatarMemory.self, from: data) {
            self.memory = loadedMemory
        }
    }
    
    // MARK: - Save
    
    private func save() {
        guard let avatar else { return }
        if let data = try? JSONEncoder().encode(avatar) {
            try? data.write(to: avatarURL, options: .atomic)
            hasCompletedSetup = true
        }
    }
    
    private func saveState() {
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: stateURL, options: .atomic)
        }
    }
    
    private func saveMemory() {
        if let data = try? JSONEncoder().encode(memory) {
            try? data.write(to: memoryURL, options: .atomic)
        }
    }
    
    // MARK: - Actions
    
    func completeSetup(with avatar: Avatar) {
        print("🔧 [AvatarStore] Completing setup for avatar: \(avatar.name)")
        self.avatar = avatar
        self.hasCompletedSetup = true
        self.state.recordInteraction()
        print("🔧 [AvatarStore] hasCompletedSetup is now: \(self.hasCompletedSetup)")
        print("🔧 [AvatarStore] avatar is now: \(String(describing: self.avatar?.name))")
        // Manually trigger objectWillChange since @AppStorage doesn't do it automatically
        objectWillChange.send()
        print("🔧 [AvatarStore] Sent objectWillChange notification")
    }
    
    func save3DAvatar(_ avatar3D: Avatar3DModel) {
        print("🔧 [AvatarStore] Saving 3D Avatar: \(avatar3D.name)")
        
        let storageManager = Avatar3DStorageManager()
        
        // Save the 3D avatar using its persistence layer
        do {
            try storageManager.save(avatar: avatar3D)
        } catch {
            print("❌ [AvatarStore] Failed to save 3D avatar: \(error)")
            return
        }
        
        // Convert to 2D avatar for compatibility
        let converted2DAvatar = convert3DTo2D(avatar3D)
        self.avatar = converted2DAvatar
        self.hasCompletedSetup = true
        self.state.recordInteraction()
        
        print("🔧 [AvatarStore] 3D Avatar saved and converted to 2D")
        objectWillChange.send()
    }
    
    /// Convert Avatar3DModel to Avatar (2D) for backward compatibility
    private func convert3DTo2D(_ avatar3D: Avatar3DModel) -> Avatar {
        // Map species/appearance to personality
        let personality: Personality
        
        switch avatar3D.species {
        case .human:
            // Use gender and appearance to determine personality
            switch avatar3D.gender {
            case .male:
                personality = avatar3D.hair.color == .white ? .wisePatient : .friendlyCurious
            case .female:
                personality = .calmReflective
            case .neutral:
                personality = .friendlyCurious
            }
            
        case .animal:
            personality = .energeticCoach
            
        case .robot:
            personality = .friendlyCurious
        }
        
        // Map personality to style
        let style: AvatarStyle
        switch personality {
        case .friendlyCurious:
            style = .friendlyBot
        case .energeticCoach:
            style = .energeticCoach
        case .calmReflective:
            style = .friendlyBot
        case .wisePatient:
            style = .wiseMentor
        }
        
        var avatar = Avatar()
        avatar.name = avatar3D.name
        avatar.appearance.style = style
        avatar.profile.basePersonality = personality
        avatar.voiceIdentifier = avatar3D.voiceId
        return avatar
    }
    
    /// Load a 3D avatar if available, otherwise return nil
    func load3DAvatar() -> Avatar3DModel? {
        let storageManager = Avatar3DStorageManager()
        return storageManager.load()
    }
    
    /// Check if user has a 3D avatar
    func has3DAvatar() -> Bool {
        let storageManager = Avatar3DStorageManager()
        return storageManager.has3DAvatar()
    }
    
    func recordUserAction(_ action: UserAction) {
        state.updateMood(for: action)
        state.recordInteraction()
        
        // Update memory based on action
        switch action {
        case .completedLesson:
            memory.recordAchievement("Completed a lesson")
        case .struggled:
            if let currentActivity = state.currentActivity {
                memory.recordStruggle(with: currentActivity)
            }
        default:
            break
        }
    }
    
    func startSession(on topic: String) {
        state.currentActivity = topic
        state.updateMood(for: .startedSession)
        memory.recordTopic(topic)
        memory.recordConversation(durationMinutes: 0)  // Will update on end
    }
    
    func endSession(durationMinutes: Int) {
        memory.recordConversation(durationMinutes: durationMinutes)
        state.currentActivity = nil
    }
    
    func resetForEdit() -> Avatar {
        avatar ?? Avatar()
    }
    
    // MARK: - Voice
    
    func speak(_ text: String) {
        guard let avatar else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Use custom voice if set
        if let voiceID = avatar.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
            utterance.voice = voice
        } else {
            // Default to natural English voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Modulate based on mood and personality
        utterance.rate = baseRate(for: avatar.personality, mood: state.mood)
        utterance.pitchMultiplier = basePitch(for: state.mood)
        utterance.volume = 0.8
        
        state.isSpeaking = true
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        
        // Reset speaking state after delay
        Task {
            try? await Task.sleep(nanoseconds: UInt64(text.count) * 50_000_000)  // ~50ms per character
            state.isSpeaking = false
        }
    }
    
    private func baseRate(for personality: Personality, mood: CompanionMood) -> Float {
        var rate: Float = 0.5  // Default speaking rate
        
        // Adjust for personality
        switch personality {
        case .energeticCoach:
            rate = 0.55  // Slightly faster
        case .calmReflective:
            rate = 0.45  // Slower, more deliberate
        case .friendlyCurious:
            rate = 0.52  // Moderate
        case .wisePatient:
            rate = 0.48  // Thoughtful pace
        }
        
        // Adjust for mood
        switch mood {
        case .excited, .celebrating:
            rate += 0.05
        case .tired, .thoughtful:
            rate -= 0.05
        default:
            break
        }
        
        return min(max(rate, 0.3), 0.7)  // Clamp between reasonable bounds
    }
    
    private func basePitch(for mood: CompanionMood) -> Float {
        switch mood {
        case .excited, .celebrating:
            return 1.1
        case .tired:
            return 0.9
        case .encouraging:
            return 1.05
        default:
            return 1.0
        }
    }
}

// MARK: - Avatar Brain (Behavior Controller)

@MainActor
final class AvatarBrain: ObservableObject {
    
    private let store: AvatarStore
    
    init(store: AvatarStore) {
        self.store = store
    }
    
    var avatar: Avatar? {
        store.avatar
    }
    
    var state: CompanionState {
        store.state
    }
    
    var memory: AvatarMemory {
        store.memory
    }
    
    // MARK: - LLM System Prompt Builder
    
    func buildSystemPrompt(for context: String = "") -> String {
        guard let avatar = store.avatar else {
            return "You are a helpful learning assistant."
        }
        
        var prompt = avatar.personality.systemPrompt
        
        // Add calibration context
        prompt += "\n\nLearning Style: \(avatar.calibrationAnswers.learningStyle.description)"
        prompt += "\nPace Preference: \(avatar.calibrationAnswers.pace)"
        prompt += "\nMotivation Style: \(avatar.calibrationAnswers.motivation)"
        
        // Add memory context if available
        if !memory.topicsDiscussed.isEmpty {
            prompt += "\n\nRecent Topics: \(memory.topicsDiscussed.suffix(3).joined(separator: ", "))"
        }
        
        if let strugglingWith = memory.mostChallengingTopic {
            prompt += "\nStudent struggles with: \(strugglingWith) (be extra patient and scaffold carefully)"
        }
        
        if !memory.achievements.isEmpty {
            prompt += "\nRecent achievements: \(memory.achievements.suffix(2).joined(separator: "; "))"
        }
        
        // Add behavioral directives
        let hintLevel = avatar.profile.hintFrequency
        if hintLevel > 0.7 {
            prompt += "\n\nProvide frequent hints and guidance."
        } else if hintLevel < 0.3 {
            prompt += "\n\nLet the student figure things out independently; only hint when stuck."
        }
        
        let celebrationLevel = avatar.profile.celebrationIntensity
        if celebrationLevel > 0.7 {
            prompt += "\nCelebrate wins enthusiastically with emojis and encouragement!"
        } else if celebrationLevel < 0.4 {
            prompt += "\nAcknowledge progress quietly and professionally."
        }
        
        // Add specific context
        if !context.isEmpty {
            prompt += "\n\nCurrent Context: \(context)"
        }
        
        return prompt
    }
    
    // MARK: - Behavior Methods
    
    func greetUser() -> String {
        store.currentGreeting
    }
    
    func respondToAction(_ action: UserAction, context: String = "") {
        store.recordUserAction(action)
        
        // Trigger appropriate response
        switch action {
        case .answeredCorrect:
            let responses = [
                "Perfect! You've got this.",
                "Excellent work!",
                "That's exactly right!",
                "You're doing great!"
            ]
            if let avatar = avatar, avatar.profile.celebrationIntensity > 0.7 {
                store.speak(responses.randomElement() ?? "Great job!")
            }
            
        case .answeredIncorrect:
            let responses = [
                "Not quite, but you're on the right track.",
                "Let's think about this differently.",
                "That's okay—mistakes help us learn!"
            ]
            store.speak(responses.randomElement() ?? "Let's try again.")
            
        case .completedLesson:
            store.speak("Amazing! You completed this lesson. I'm proud of you!")
            
        default:
            break
        }
    }
    
    func startLearningSession(topic: String) {
        store.startSession(on: topic)
        
        let greeting = greetUser()
        store.speak(greeting)
    }
    
    func endLearningSession(durationMinutes: Int) {
        store.endSession(durationMinutes: durationMinutes)
        
        let farewell = "Great session today! See you next time."
        store.speak(farewell)
    }
}
