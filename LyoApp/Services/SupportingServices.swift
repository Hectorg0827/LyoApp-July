import Foundation
import SwiftUI
import AVFoundation
import Speech

// MARK: - Speech Recognizer
class SpeechRecognizer: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var hasPermission = false
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkPermissions()
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.hasPermission = true
                case .denied, .restricted, .notDetermined:
                    self?.hasPermission = false
                @unknown default:
                    self?.hasPermission = false
                }
            }
        }
    }
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        guard hasPermission else {
            completion(.failure(SpeechRecognitionError.permissionDenied))
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(.failure(SpeechRecognitionError.unavailable))
            return
        }
        
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            completion(.failure(SpeechRecognitionError.requestCreationFailed))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            completion(.failure(error))
            return
        }
        
        isRecording = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                if isFinal {
                    DispatchQueue.main.async {
                        completion(.success(transcript))
                        self?.stopRecording()
                    }
                }
            }
            
            if error != nil || isFinal {
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    }
                    self?.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        isRecording = false
        
        // Reset audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case unavailable
    case requestCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .unavailable:
            return "Speech recognition unavailable"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        }
    }
}

// MARK: - Haptic Feedback Engine
class HapticFeedbackEngine: ObservableObject {
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    init() {
        // Prepare generators for optimal performance
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func lightImpact() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare() // Prepare for next use
    }
    
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
    }
    
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
        heavyImpactGenerator.prepare()
    }
    
    func successFeedback() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func warningFeedback() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    func errorFeedback() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}

// MARK: - Course Storage Manager
class CourseStorageManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let coursesKey = "saved_courses"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        // Configure date encoding/decoding strategy
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func saveCourse(_ course: ProgressiveCourse) async {
        do {
            var courses = await loadAllCourses()
            
            // Update existing course or add new one
            if let index = courses.firstIndex(where: { $0.id == course.id }) {
                courses[index] = course
            } else {
                courses.append(course)
            }
            
            let data = try encoder.encode(courses)
            userDefaults.set(data, forKey: coursesKey)
            
            print("✅ Course saved: \(course.title)")
        } catch {
            print("❌ Failed to save course: \(error)")
        }
    }
    
    func loadAllCourses() async -> [ProgressiveCourse] {
        guard let data = userDefaults.data(forKey: coursesKey) else {
            return []
        }
        
        do {
            let courses = try decoder.decode([ProgressiveCourse].self, from: data)
            return courses
        } catch {
            print("❌ Failed to load courses: \(error)")
            return []
        }
    }
    
    func deleteCourse(_ courseId: UUID) async {
        do {
            var courses = await loadAllCourses()
            courses.removeAll { $0.id == courseId }
            
            let data = try encoder.encode(courses)
            userDefaults.set(data, forKey: coursesKey)
            
            print("✅ Course deleted: \(courseId)")
        } catch {
            print("❌ Failed to delete course: \(error)")
        }
    }
    
    func loadCourse(by id: UUID) async -> ProgressiveCourse? {
        let courses = await loadAllCourses()
        return courses.first { $0.id == id }
    }
    
    func clearAllCourses() async {
        userDefaults.removeObject(forKey: coursesKey)
        print("✅ All courses cleared from storage")
    }
}

// MARK: - AI Avatar API Client
class AIAvatarAPIClient: ObservableObject {
    static let shared = AIAvatarAPIClient()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func generateWithSuperiorBackend(_ input: String) async throws -> String {
        // Use real backend AI generation - NO MOCK RESPONSES
        print("🤖 [AI Avatar] Calling real backend with prompt: \(input.prefix(50))...")
        let response = try await apiClient.generateAIContent(prompt: input, maxTokens: 500)
        print("✅ [AI Avatar] Received response: \(response.generatedText.prefix(100))...")
        return response.generatedText
    }
    
    /// Legacy Gemini method - redirects to real backend
    func generateWithGemini(_ prompt: String) async throws -> String {
        return try await generateWithSuperiorBackend(prompt)
    }
    
    func generateCourseContent(for topic: String, difficulty: CourseDifficulty) async throws -> [CourseStep] {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Generate mock course content
        let stepTemplates = [
            ("Introduction to \(topic)", "Get familiar with the basic concepts and terminology"),
            ("Core Principles", "Understand the fundamental principles that govern \(topic)"),
            ("Practical Applications", "See how \(topic) is used in real-world scenarios"),
            ("Hands-On Practice", "Apply your knowledge through interactive exercises"),
            ("Advanced Concepts", "Explore more sophisticated aspects of \(topic)"),
            ("Mastery Assessment", "Test your understanding and identify areas for improvement")
        ]
        
        return stepTemplates.enumerated().map { index, template in
            let (title, description) = template
            return CourseStep(
                id: UUID(),
                stepNumber: index + 1,
                title: title,
                description: description,
                content: "This step will be dynamically generated based on your interactions and learning style. The content adapts to your pace and provides personalized explanations, examples, and exercises.",
                estimatedDuration: difficulty == .beginner ? 30 : difficulty == .expert ? 60 : 45,
                isUnlocked: index == 0,
                progress: 0.0,
                isCompleted: false,
                interactions: []
            )
        }
    }
}

// MARK: - AIAvatarService (Compatibility)
class AIAvatarService: ObservableObject {
    static let shared = AIAvatarService()
    
    @Published var isActive: Bool = false
    @Published var currentResponse: String = ""
    @Published var isProcessing: Bool = false
    
    private init() {}
    
    func processMessage(_ message: String) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let response = try await AIAvatarAPIClient.shared.generateWithSuperiorBackend(message)
            await MainActor.run {
                currentResponse = response
            }
            return response
        } catch {
            let fallbackResponse = "I'm having trouble connecting right now, but I'm still here to help! Could you try rephrasing your question?"
            await MainActor.run {
                currentResponse = fallbackResponse
            }
            return fallbackResponse
        }
    }
    
    func activate() {
        isActive = true
    }
    
    func deactivate() {
        isActive = false
        currentResponse = ""
    }
}