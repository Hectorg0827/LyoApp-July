import SwiftUI
import AVFoundation

// MARK: - Environment Themes
enum EnvironmentTheme: String, CaseIterable {
    case cosmic = "cosmic"
    case ocean = "ocean"
    case forest = "forest"
    case aurora = "aurora"
    case sunset = "sunset"
    
    var backgroundColors: [Color] {
        switch self {
        case .cosmic:
            return [.purple.opacity(0.8), .blue.opacity(0.6), .black.opacity(0.9)]
        case .ocean:
            return [.cyan.opacity(0.7), .blue.opacity(0.8), .teal.opacity(0.6)]
        case .forest:
            return [.green.opacity(0.6), .mint.opacity(0.5), .teal.opacity(0.7)]
        case .aurora:
            return [.green.opacity(0.6), .cyan.opacity(0.7), .purple.opacity(0.5)]
        case .sunset:
            return [.orange.opacity(0.7), .pink.opacity(0.6), .purple.opacity(0.5)]
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .cosmic: return .cyan
        case .ocean: return .blue
        case .forest: return .green
        case .aurora: return .mint
        case .sunset: return .orange
        }
    }
    
    var shapeCount: Int {
        switch self {
        case .cosmic: return 8
        case .ocean: return 6
        case .forest: return 5
        case .aurora: return 7
        case .sunset: return 6
        }
    }
}

// MARK: - Avatar Personalities
enum AvatarPersonality: String, CaseIterable {
    case mentor = "mentor"
    case friend = "friend"
    case sage = "sage"
    case explorer = "explorer"
    case innovator = "innovator"
    
    var iconName: String {
        switch self {
        case .mentor: return "graduationcap.fill"
        case .friend: return "heart.fill"
        case .sage: return "brain.head.profile"
        case .explorer: return "safari.fill"
        case .innovator: return "lightbulb.fill"
        }
    }
    
    var glowColors: [Color] {
        switch self {
        case .mentor: return [.blue.opacity(0.8), .cyan.opacity(0.6)]
        case .friend: return [.pink.opacity(0.7), .purple.opacity(0.5)]
        case .sage: return [.purple.opacity(0.8), .indigo.opacity(0.6)]
        case .explorer: return [.green.opacity(0.7), .teal.opacity(0.5)]
        case .innovator: return [.yellow.opacity(0.8), .orange.opacity(0.6)]
        }
    }
    
    var coreColors: [Color] {
        switch self {
        case .mentor: return [.blue, .cyan]
        case .friend: return [.pink, .purple]
        case .sage: return [.purple, .indigo]
        case .explorer: return [.green, .teal]
        case .innovator: return [.yellow, .orange]
        }
    }
}

// MARK: - Conversation Modes
enum ConversationMode: String, CaseIterable {
    case friendly = "friendly"
    case professional = "professional"
    case casual = "casual"
    case focused = "focused"
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .focused: return "Focused"
        }
    }
}

// MARK: - Learning Context
struct LearningContext {
    let topic: String
    let difficulty: LearningDifficulty
    let objectives: [String]
    let duration: Int // in minutes
    let createdAt: Date
    
    enum LearningDifficulty: String, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
    }
}

// MARK: - Course Difficulty
enum CourseDifficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

// MARK: - Speech Recognizer
class SpeechRecognizer: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(SpeechError.recognizerUnavailable))
            return
        }
        
        isRecording = true
        transcript = ""
        
        // Simulate speech recognition for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.stopRecording()
            completion(.success("Hello, I'd like to learn about SwiftUI"))
        }
    }
    
    func stopRecording() {
        isRecording = false
        audioEngine?.stop()
        recognitionRequest?.endAudio()
    }
    
    enum SpeechError: Error {
        case recognizerUnavailable
        case audioEngineError
        case recognitionError
    }
}

// MARK: - Haptic Feedback Engine
class HapticFeedbackEngine {
    func lightImpact() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func mediumImpact() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    func heavyImpact() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    func successFeedback() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    func errorFeedback() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    func warningFeedback() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
    }
}

// MARK: - Course Storage Manager
class CourseStorageManager {
    private let userDefaults = UserDefaults.standard
    private let coursesKey = "saved_courses"
    
    func saveCourse(_ course: ProgressiveCourse) async {
        var savedCourses = await loadAllCourses()
        
        if let index = savedCourses.firstIndex(where: { $0.id == course.id }) {
            savedCourses[index] = course
        } else {
            savedCourses.append(course)
        }
        
        if let encoded = try? JSONEncoder().encode(savedCourses) {
            userDefaults.set(encoded, forKey: coursesKey)
        }
    }
    
    func loadAllCourses() async -> [ProgressiveCourse] {
        guard let data = userDefaults.data(forKey: coursesKey),
              let courses = try? JSONDecoder().decode([ProgressiveCourse].self, from: data) else {
            return []
        }
        return courses
    }
    
    func deleteCourse(_ courseId: UUID) async {
        var savedCourses = await loadAllCourses()
        savedCourses.removeAll { $0.id == courseId }
        
        if let encoded = try? JSONEncoder().encode(savedCourses) {
            userDefaults.set(encoded, forKey: coursesKey)
        }
    }
}

// MARK: - AI Avatar API Client
class AIAvatarAPIClient {
    static let shared = AIAvatarAPIClient()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func generateWithSuperiorBackend(_ prompt: String) async throws -> String {
        // Try to use the superior backend for AI generation
        do {
            let response: AIGenerationResponse = try await apiClient.post("/ai/generate", body: [
                "prompt": prompt,
                "model": "superior",
                "max_tokens": 500
            ])
            return response.text
        } catch {
            // Fallback to mock response
            throw AIError.backendUnavailable
        }
    }
    
    enum AIError: Error {
        case backendUnavailable
        case invalidResponse
    }
}

struct AIGenerationResponse: Codable {
    let text: String
    let model: String
    let tokens_used: Int
}

// MARK: - AI Avatar Service
class AIAvatarService: ObservableObject {
    static let shared = AIAvatarService()
    
    @Published var isActive = false
    @Published var currentSession: String?
    
    private init() {}
    
    func startSession() async {
        isActive = true
        currentSession = UUID().uuidString
    }
    
    func endSession() async {
        isActive = false
        currentSession = nil
    }
}

#if DEBUG
import Speech

// Add SFSpeechRecognizer import for speech recognition functionality
extension SpeechRecognizer {
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                // Handle authorization status
            }
        }
    }
}
#endif