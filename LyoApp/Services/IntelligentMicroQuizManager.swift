import Foundation
import SwiftUI
import Combine

/// Intelligent Micro-Quiz System with automated gap detection
@MainActor
class IntelligentMicroQuizManager: ObservableObject {
    static let shared = IntelligentMicroQuizManager()
    
    // MARK: - Published State
    @Published var currentQuiz: IntelligentMicroQuiz?
    @Published var detectedGaps: [KnowledgeGap] = []
    @Published var quizHistory: [QuizAttempt] = []
    @Published var masteryMap: [String: MasteryLevel] = [:] // concept -> mastery
    @Published var isGeneratingQuiz: Bool = false
    @Published var recommendedFocus: [String] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let apiService = ClassroomAPIService.shared
    private var conceptPerformance: [String: ConceptPerformance] = [:]
    
    // MARK: - Initialization
    private init() {
        setupQuizMonitoring()
    }
    
    // MARK: - Quiz Monitoring
    private func setupQuizMonitoring() {
        // Listen to gap detection from backend
        NotificationCenter.default.publisher(for: NSNotification.Name("knowledgeGapDetected"))
            .compactMap { $0.object as? [String: Any] }
            .sink { [weak self] gapData in
                self?.handleGapDetection(gapData)
            }
            .store(in: &cancellables)
        
        // Listen to quiz completion notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("quizCompleted"))
            .compactMap { $0.object as? QuizAttempt }
            .sink { [weak self] attempt in
                self?.handleQuizCompleted(attempt)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Gap Detection
    private func handleGapDetection(_ data: [String: Any]) {
        guard let concept = data["concept"] as? String,
              let severityStr = data["severity"] as? String,
              let confidence = data["confidence"] as? Float else {
            return
        }
        
        let severity = GapSeverity(rawValue: severityStr) ?? .medium
        
        let gap = KnowledgeGap(
            concept: concept,
            severity: severity,
            confidence: confidence,
            detectedAt: Date(),
            relatedConcepts: data["related_concepts"] as? [String] ?? []
        )
        
        // Add to detected gaps if not already present
        if !detectedGaps.contains(where: { $0.concept == concept }) {
            detectedGaps.append(gap)
            print("🔍 [MicroQuiz] Gap detected: \(concept) (severity: \(severity))")
            
            // Auto-generate targeted quiz for critical gaps
            if severity == .critical {
                Task {
                    await generateTargetedQuiz(for: concept)
                }
            }
        }
    }
    
    // MARK: - Quiz Generation
    func generateTargetedQuiz(for concept: String) async {
        isGeneratingQuiz = true
        defer { isGeneratingQuiz = false }
        
        do {
            print("🎯 [MicroQuiz] Generating quiz for: \(concept)")
            
            // Request quiz from backend
            let microQuiz = try await apiService.generateQuiz(
                lessonId: UUID(), // Placeholder - should be passed in
                difficulty: getDifficultyFor(concept),
                questionCount: 3
            )
            
            // Convert QuizQuestion to IntelligentQuizQuestion
            let intelligentQuestions = microQuiz.questions.map { q in
                IntelligentQuizQuestion(
                    id: q.id.uuidString,
                    question: q.question,
                    options: q.answers,
                    correctAnswer: q.answers[q.correctAnswerIndex],
                    explanation: q.explanation,
                    concept: concept
                )
            }
            
            currentQuiz = IntelligentMicroQuiz(
                id: UUID().uuidString,
                targetConcept: concept,
                questions: intelligentQuestions,
                createdAt: Date(),
                source: .gapDetection
            )
            
            print("✅ [MicroQuiz] Generated \(intelligentQuestions.count) questions")
            
        } catch {
            print("❌ [MicroQuiz] Failed to generate quiz: \(error)")
        }
    }
    
    func generateAdaptiveQuiz(for lesson: Lesson) async {
        isGeneratingQuiz = true
        defer { isGeneratingQuiz = false }
        
        do {
            // Identify weak concepts from history
            let weakConcepts = identifyWeakConcepts(in: lesson)
            recommendedFocus = weakConcepts
            let focusConcept = weakConcepts.first ?? lesson.title
            
            let microQuiz = try await apiService.generateQuiz(
                lessonId: lesson.id,
                difficulty: .medium,
                questionCount: 5
            )
            
            // Convert QuizQuestion to IntelligentQuizQuestion
            let intelligentQuestions = microQuiz.questions.map { q in
                IntelligentQuizQuestion(
                    id: q.id.uuidString,
                    question: q.question,
                    options: q.answers,
                    correctAnswer: q.answers[q.correctAnswerIndex],
                    explanation: q.explanation,
                    concept: focusConcept
                )
            }
            
            currentQuiz = IntelligentMicroQuiz(
                id: UUID().uuidString,
                targetConcept: focusConcept,
                questions: intelligentQuestions,
                createdAt: Date(),
                source: .lessonReview
            )
            
            if !weakConcepts.isEmpty {
                print("🎯 [MicroQuiz] Focusing on weak concepts: \(weakConcepts.joined(separator: ", "))")
            }
            
        } catch {
            print("❌ [MicroQuiz] Failed to generate adaptive quiz: \(error)")
        }
    }
    
    // MARK: - Quiz Submission
    func submitQuiz(_ quiz: IntelligentMicroQuiz, answers: [String: String]) async -> QuizResult {
        let attempt = QuizAttempt(
            quizId: quiz.id,
            concept: quiz.targetConcept,
            answers: answers,
            submittedAt: Date()
        )
        
        do {
            // Send to backend for evaluation
            let result = try await apiService.evaluateQuiz(
                quizId: quiz.id,
                answers: answers
            )
            
            // Update local state
            handleQuizCompleted(attempt)
            updateMasteryMap(result)
            updateConceptPerformance(result)
            
            // Notify sentiment system of performance
            notifySentimentSystem(result)
            
            return result
            
        } catch {
            print("❌ [MicroQuiz] Failed to evaluate quiz: \(error)")
            return QuizResult(
                score: 0,
                correctCount: 0,
                totalCount: quiz.questions.count,
                feedback: [],
                detectedGaps: []
            )
        }
    }
    
    // MARK: - Performance Tracking
    private func handleQuizCompleted(_ attempt: QuizAttempt) {
        quizHistory.append(attempt)
        
        // Keep only recent attempts
        if quizHistory.count > 50 {
            quizHistory.removeFirst()
        }
        
        print("📝 [MicroQuiz] Quiz completed. Total attempts: \(quizHistory.count)")
    }
    
    private func updateMasteryMap(_ result: QuizResult) {
        for feedback in result.feedback {
            let concept = feedback.concept
            let wasCorrect = feedback.wasCorrect
            
            // Get current mastery
            var mastery = masteryMap[concept] ?? .novice
            
            // Update based on performance
            if wasCorrect {
                mastery = mastery.levelUp()
            } else {
                mastery = mastery.levelDown()
            }
            
            masteryMap[concept] = mastery
            print("📊 [MicroQuiz] \(concept): \(mastery)")
        }
        
        // Update recommended focus areas
        updateRecommendedFocus()
    }
    
    private func updateConceptPerformance(_ result: QuizResult) {
        for feedback in result.feedback {
            let concept = feedback.concept
            var performance = conceptPerformance[concept] ?? ConceptPerformance(concept: concept)
            
            performance.attempts += 1
            if feedback.wasCorrect {
                performance.correct += 1
            }
            performance.lastAttempt = Date()
            
            conceptPerformance[concept] = performance
        }
    }
    
    private func updateRecommendedFocus() {
        // Find concepts with low mastery
        let weakConcepts = masteryMap
            .filter { $0.value.rawValue < MasteryLevel.proficient.rawValue }
            .sorted { $0.value.rawValue < $1.value.rawValue }
            .prefix(3)
            .map { $0.key }
        
        recommendedFocus = Array(weakConcepts)
    }
    
    // MARK: - Analytics
    private func identifyWeakConcepts(in lesson: Lesson) -> [String] {
        // Analyze quiz history for this lesson's concepts
        let lessonConcepts = extractConcepts(from: lesson)
        
        return lessonConcepts.filter { concept in
            guard let mastery = masteryMap[concept] else { return true }
            return mastery.rawValue < MasteryLevel.proficient.rawValue
        }
    }
    
    private func extractConcepts(from lesson: Lesson) -> [String] {
        // Extract key concepts from lesson (simplified)
        // In production, this would use NLP from backend
        return [lesson.title]
    }
    
    private func getDifficultyFor(_ concept: String) -> QuizQuestion.QuestionDifficulty {
        guard let mastery = masteryMap[concept] else {
            return .easy
        }
        
        switch mastery {
        case .novice: return .easy
        case .beginner: return .easy
        case .intermediate: return .medium
        case .proficient: return .medium
        case .advanced: return .hard
        case .expert: return .hard
        }
    }
    
    private func notifySentimentSystem(_ result: QuizResult) {
        let performance = Double(result.correctCount) / Double(result.totalCount)
        
        if performance < 0.5 {
            // Poor performance - notify sentiment system
            NotificationCenter.default.post(
                name: NSNotification.Name("quizPerformancePoor"),
                object: result
            )
        } else if performance >= 0.9 {
            // Excellent performance
            NotificationCenter.default.post(
                name: NSNotification.Name("quizPerformanceExcellent"),
                object: result
            )
        }
    }
    
    // MARK: - Public API
    func dismissQuiz() {
        currentQuiz = nil
    }
    
    func retryQuiz() async {
        guard let quiz = currentQuiz else { return }
        await generateTargetedQuiz(for: quiz.targetConcept)
    }
    
    func getGapsForConcept(_ concept: String) -> [KnowledgeGap] {
        return detectedGaps.filter { $0.concept == concept }
    }
    
    func getMastery(for concept: String) -> MasteryLevel {
        return masteryMap[concept] ?? .novice
    }
    
    func getPerformanceSummary() -> PerformanceSummary {
        let totalAttempts = quizHistory.count
        
        // Calculate average from concept performance
        let totalCorrect = conceptPerformance.values.reduce(0) { $0 + $1.correct }
        let totalQuestions = conceptPerformance.values.reduce(0) { $0 + $1.attempts }
        let averageScore = totalQuestions > 0 ? Double(totalCorrect) / Double(totalQuestions) : 0.0
        
        return PerformanceSummary(
            totalAttempts: totalAttempts,
            averageScore: averageScore,
            masteryDistribution: calculateMasteryDistribution(),
            weakestConcepts: Array(recommendedFocus.prefix(3)),
            strongestConcepts: getStrongestConcepts()
        )
    }
    
    private func calculateMasteryDistribution() -> [MasteryLevel: Int] {
        var distribution: [MasteryLevel: Int] = [:]
        
        for mastery in masteryMap.values {
            distribution[mastery, default: 0] += 1
        }
        
        return distribution
    }
    
    private func getStrongestConcepts() -> [String] {
        return masteryMap
            .filter { $0.value == .expert || $0.value == .advanced }
            .sorted { $0.value.rawValue > $1.value.rawValue }
            .prefix(3)
            .map { $0.key }
    }
}

// MARK: - Supporting Types

struct IntelligentMicroQuiz: Identifiable {
    let id: String
    let targetConcept: String
    let questions: [IntelligentQuizQuestion]
    let createdAt: Date
    let source: QuizSource
}

struct IntelligentQuizQuestion: Identifiable, Codable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let concept: String
}

enum QuizSource {
    case gapDetection
    case lessonReview
    case proactiveCheck
    case userRequested
}

struct QuizAttempt {
    let quizId: String
    let concept: String
    let answers: [String: String]
    let submittedAt: Date
}

struct QuizResult {
    let score: Double
    let correctCount: Int
    let totalCount: Int
    let feedback: [QuestionFeedback]
    let detectedGaps: [KnowledgeGap]
}

struct QuestionFeedback {
    let questionId: String
    let concept: String
    let wasCorrect: Bool
    let explanation: String
    let userAnswer: String
    let correctAnswer: String
}

struct KnowledgeGap: Identifiable {
    let id = UUID()
    let concept: String
    let severity: GapSeverity
    let confidence: Float
    let detectedAt: Date
    let relatedConcepts: [String]
}

enum GapSeverity: String, Codable {
    case low
    case medium
    case high
    case critical
}

enum MasteryLevel: Int, Codable {
    case novice = 0
    case beginner = 1
    case intermediate = 2
    case proficient = 3
    case advanced = 4
    case expert = 5
    
    func levelUp() -> MasteryLevel {
        let nextRaw = min(rawValue + 1, MasteryLevel.expert.rawValue)
        return MasteryLevel(rawValue: nextRaw) ?? self
    }
    
    func levelDown() -> MasteryLevel {
        let prevRaw = max(rawValue - 1, MasteryLevel.novice.rawValue)
        return MasteryLevel(rawValue: prevRaw) ?? self
    }
}

struct ConceptPerformance {
    let concept: String
    var attempts: Int = 0
    var correct: Int = 0
    var lastAttempt: Date?
    
    var successRate: Double {
        attempts > 0 ? Double(correct) / Double(attempts) : 0.0
    }
}

struct PerformanceSummary {
    let totalAttempts: Int
    let averageScore: Double
    let masteryDistribution: [MasteryLevel: Int]
    let weakestConcepts: [String]
    let strongestConcepts: [String]
}

// MARK: - API Service Extension
extension ClassroomAPIService {
    func generateMicroQuiz(concept: String, difficulty: String, questionCount: Int) async throws -> [QuizQuestion] {
        // This would call the backend's quiz generation endpoint
        // For now, return placeholder
        print("🔄 [API] Generating micro-quiz for: \(concept)")
        return []
    }
    
    func generateAdaptiveQuiz(lessonId: String, weakConcepts: [String], questionCount: Int) async throws -> [QuizQuestion] {
        print("🔄 [API] Generating adaptive quiz for lesson: \(lessonId)")
        return []
    }
    
    func evaluateQuiz(quizId: String, answers: [String: String]) async throws -> QuizResult {
        print("🔄 [API] Evaluating quiz: \(quizId)")
        return QuizResult(score: 0, correctCount: 0, totalCount: 0, feedback: [], detectedGaps: [])
    }
}
