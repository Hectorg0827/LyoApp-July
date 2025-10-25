import Foundation
import SwiftUI
import Combine

/// Manages AI Avatar behavior with real-time sentiment analysis from backend
@MainActor
class SentimentAwareAvatarManager: ObservableObject {
    static let shared = SentimentAwareAvatarManager()
    
    // MARK: - Published State
    @Published var currentEmotion: AvatarEmotion = .neutral
    @Published var confidenceLevel: Float = 0
    @Published var detectedMood: StudentMood = .engaged
    @Published var suggestedInterventions: [Intervention] = []
    @Published var empathyMessage: String = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var sentimentHistory: [SentimentReading] = []
    private let maxHistorySize = 20
    
    // MARK: - Initialization
    private init() {
        setupSentimentMonitoring()
    }
    
    // MARK: - Sentiment Monitoring
    private func setupSentimentMonitoring() {
        // Listen to real-time sentiment updates from LiveLearningOrchestrator
        NotificationCenter.default.publisher(for: NSNotification.Name("sentimentUpdated"))
            .compactMap { $0.object as? [String: Any] }
            .sink { [weak self] sentimentData in
                self?.handleSentimentUpdate(sentimentData)
            }
            .store(in: &cancellables)
        
        // Listen for struggle detection
        NotificationCenter.default.publisher(for: NSNotification.Name("userStrugglingWithConcept"))
            .compactMap { $0.object as? String }
            .sink { [weak self] concept in
                self?.handleStruggleDetected(concept)
            }
            .store(in: &cancellables)
        
        // Listen for mastery achievement
        NotificationCenter.default.publisher(for: NSNotification.Name("userMasteredConcept"))
            .compactMap { $0.object as? String }
            .sink { [weak self] concept in
                self?.handleMasteryAchieved(concept)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sentiment Analysis
    private func handleSentimentUpdate(_ data: [String: Any]) {
        guard let emotionStr = data["emotion"] as? String,
              let confidence = data["confidence"] as? Float,
              let moodStr = data["mood"] as? String else {
            return
        }
        
        // Update current emotion
        if let emotion = AvatarEmotion(rawValue: emotionStr) {
            currentEmotion = emotion
        }
        
        confidenceLevel = confidence
        
        // Update detected mood
        if let mood = StudentMood(rawValue: moodStr) {
            detectedMood = mood
            generateEmpathyResponse(for: mood)
        }
        
        // Record sentiment reading
        let reading = SentimentReading(
            emotion: currentEmotion,
            mood: detectedMood,
            confidence: confidence,
            timestamp: Date()
        )
        addToHistory(reading)
        
        // Analyze patterns and suggest interventions
        analyzePatterns()
    }
    
    private func handleStruggleDetected(_ concept: String) {
        print("😟 [SentimentAvatar] User struggling with: \(concept)")
        
        // Shift to concerned emotion
        currentEmotion = .concerned
        detectedMood = .frustrated
        
        // Generate empathy message
        empathyMessage = "I notice you're finding \(concept) challenging. Let's break it down together! 💪"
        
        // Suggest interventions
        suggestedInterventions = [
            Intervention(
                type: .scaffolding,
                title: "Break It Down",
                description: "Let's tackle \(concept) in smaller steps",
                action: .offerSimplification
            ),
            Intervention(
                type: .encouragement,
                title: "You've Got This!",
                description: "Remember, struggling means you're learning",
                action: .showMotivation
            ),
            Intervention(
                type: .alternative,
                title: "Try a Different Approach",
                description: "Let's explore \(concept) from another angle",
                action: .suggestAlternative
            )
        ]
    }
    
    private func handleMasteryAchieved(_ concept: String) {
        print("🎉 [SentimentAvatar] User mastered: \(concept)")
        
        // Celebrate!
        currentEmotion = .excited
        detectedMood = .confident
        
        empathyMessage = "Amazing work! You've mastered \(concept)! 🌟"
        
        // Suggest next challenges
        suggestedInterventions = [
            Intervention(
                type: .progression,
                title: "Ready for More?",
                description: "You're on a roll! Let's level up",
                action: .suggestProgression
            ),
            Intervention(
                type: .celebration,
                title: "Celebrate Your Win",
                description: "Take a moment to appreciate your progress",
                action: .showCelebration
            )
        ]
    }
    
    // MARK: - Empathy Response Generation
    private func generateEmpathyResponse(for mood: StudentMood) {
        switch mood {
        case .engaged:
            empathyMessage = "You're doing great! I can see you're really focused. 📚"
            currentEmotion = .happy
            
        case .confused:
            empathyMessage = "I can see this might be unclear. Let me help clarify! 💡"
            currentEmotion = .thinking
            
        case .frustrated:
            empathyMessage = "I know this is tough, but you're making progress. Let's take it step by step. 🤝"
            currentEmotion = .concerned
            
        case .bored:
            empathyMessage = "Let's make this more interesting! How about we try something different? ✨"
            currentEmotion = .encouraging
            
        case .confident:
            empathyMessage = "I love your confidence! You're crushing it! 🚀"
            currentEmotion = .excited
            
        case .anxious:
            empathyMessage = "Take a deep breath. We'll go at your pace, no pressure. 🌿"
            currentEmotion = .calm
        }
    }
    
    // MARK: - Pattern Analysis
    private func analyzePatterns() {
        guard sentimentHistory.count >= 5 else { return }
        
        let recentReadings = Array(sentimentHistory.suffix(5))
        
        // Check for consistent frustration
        let frustratedCount = recentReadings.filter { $0.mood == .frustrated }.count
        if frustratedCount >= 3 {
            suggestIntervention(.scaffolding, message: "I notice you've been struggling. Let's try a different approach!")
        }
        
        // Check for sustained engagement
        let engagedCount = recentReadings.filter { $0.mood == .engaged }.count
        if engagedCount >= 4 {
            suggestIntervention(.progression, message: "You're in the zone! Ready to tackle something more advanced?")
        }
        
        // Check for boredom pattern
        let boredCount = recentReadings.filter { $0.mood == .bored }.count
        if boredCount >= 2 {
            suggestIntervention(.gamification, message: "Let's make this more fun! How about a quick challenge?")
        }
    }
    
    private func suggestIntervention(_ type: InterventionType, message: String) {
        let intervention = Intervention(
            type: type,
            title: message,
            description: generateInterventionDetails(for: type),
            action: getActionFor(type)
        )
        
        if !suggestedInterventions.contains(where: { $0.type == type }) {
            suggestedInterventions.append(intervention)
        }
    }
    
    private func generateInterventionDetails(for type: InterventionType) -> String {
        switch type {
        case .scaffolding:
            return "Break down complex concepts into manageable pieces"
        case .encouragement:
            return "Boost confidence with positive reinforcement"
        case .alternative:
            return "Present the material in a different format"
        case .progression:
            return "Move to more challenging material"
        case .celebration:
            return "Acknowledge achievements and progress"
        case .gamification:
            return "Add interactive elements and challenges"
        case .break:
            return "Suggest a brief pause to recharge"
        }
    }
    
    private func getActionFor(_ type: InterventionType) -> InterventionAction {
        switch type {
        case .scaffolding: return .offerSimplification
        case .encouragement: return .showMotivation
        case .alternative: return .suggestAlternative
        case .progression: return .suggestProgression
        case .celebration: return .showCelebration
        case .gamification: return .offerMinigame
        case .break: return .suggestBreak
        }
    }
    
    // MARK: - History Management
    private func addToHistory(_ reading: SentimentReading) {
        sentimentHistory.append(reading)
        
        // Keep only recent readings
        if sentimentHistory.count > maxHistorySize {
            sentimentHistory.removeFirst()
        }
    }
    
    // MARK: - Public API
    func resetState() {
        currentEmotion = .neutral
        confidenceLevel = 0
        detectedMood = .engaged
        suggestedInterventions = []
        empathyMessage = ""
        sentimentHistory = []
    }
    
    func dismissIntervention(_ intervention: Intervention) {
        suggestedInterventions.removeAll { $0.id == intervention.id }
    }
    
    func acceptIntervention(_ intervention: Intervention) {
        print("✅ [SentimentAvatar] Accepted intervention: \(intervention.title)")
        dismissIntervention(intervention)
        // Notify system to apply intervention
        NotificationCenter.default.post(
            name: NSNotification.Name("interventionAccepted"),
            object: intervention
        )
    }
}

// MARK: - Supporting Types

enum AvatarEmotion: String, Codable {
    case neutral
    case happy
    case excited
    case thinking
    case concerned
    case encouraging
    case calm
    case celebrating
    
    var animationName: String {
        switch self {
        case .neutral: return "idle"
        case .happy: return "smile"
        case .excited: return "jump"
        case .thinking: return "ponder"
        case .concerned: return "concerned"
        case .encouraging: return "cheer"
        case .calm: return "breathe"
        case .celebrating: return "celebrate"
        }
    }
}

enum StudentMood: String, Codable {
    case engaged
    case confused
    case frustrated
    case bored
    case confident
    case anxious
}

struct SentimentReading {
    let emotion: AvatarEmotion
    let mood: StudentMood
    let confidence: Float
    let timestamp: Date
}

struct Intervention: Identifiable {
    let id = UUID()
    let type: InterventionType
    let title: String
    let description: String
    let action: InterventionAction
}

enum InterventionType: String {
    case scaffolding
    case encouragement
    case alternative
    case progression
    case celebration
    case gamification
    case `break`
}

enum InterventionAction {
    case offerSimplification
    case showMotivation
    case suggestAlternative
    case suggestProgression
    case showCelebration
    case offerMinigame
    case suggestBreak
}
