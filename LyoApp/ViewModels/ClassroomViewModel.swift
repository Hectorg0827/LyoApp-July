import SwiftUI
import Combine
import AVFoundation

/// ViewModel for managing AI Classroom state and logic
@MainActor
class ClassroomViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentLesson: Lesson?
    @Published var currentChunk: LessonChunk?
    @Published var currentChunkIndex: Int = 0
    @Published var lessonProgress: Double = 0.0
    @Published var isProcessing: Bool = false

    @Published var curatedCards: [ContentCard] = []
    @Published var notes: [LessonNote] = []
    @Published var currentQuiz: MicroQuiz?
    @Published var nextLesson: Lesson?

    @Published var xpEarned: Int = 0
    @Published var quizAccuracy: Double = 1.0
    @Published var timeSpent: TimeInterval = 0

    // MARK: - Computed Properties
    var totalChunks: Int {
        currentLesson?.chunks.count ?? 0
    }

    var remainingTime: TimeInterval {
        guard let lesson = currentLesson else { return 0 }
        let totalDuration = lesson.chunks.reduce(0.0) { $0 + $1.duration }
        let elapsed = lesson.chunks.prefix(currentChunkIndex).reduce(0.0) { $0 + $1.duration }
        return totalDuration - elapsed
    }

    var remainingTimeFormatted: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var timeSpentFormatted: String {
        let minutes = Int(timeSpent) / 60
        return "\(minutes)m"
    }

    // MARK: - Private Properties
    private var startTime: Date?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        setupTimerTracking()
    }

    // MARK: - Public Methods

    /// Load a lesson and prepare for playback
    func loadLesson(_ lesson: Lesson) {
        currentLesson = lesson
        currentChunkIndex = 0
        currentChunk = lesson.chunks.first
        startTime = Date()
        updateProgress()

        print("📚 [Classroom] Loaded lesson: \(lesson.title)")
    }

    /// Load curated content cards for this lesson
    func loadCuratedContent() {
        // TODO: Replace with real API call to content curation service
        curatedCards = ContentCard.mockCards

        print("📖 [Classroom] Loaded \(curatedCards.count) curated resources")
    }

    /// Move to the next chunk in the lesson
    func moveToNextChunk() {
        guard let lesson = currentLesson else { return }

        currentChunkIndex += 1

        if currentChunkIndex < lesson.chunks.count {
            currentChunk = lesson.chunks[currentChunkIndex]
            updateProgress()

            print("➡️ [Classroom] Moved to chunk \(currentChunkIndex + 1)/\(totalChunks)")
        } else {
            print("✅ [Classroom] Lesson completed!")
            finishLesson()
        }
    }

    /// Move to the previous chunk
    func moveToPreviousChunk() {
        guard currentChunkIndex > 0 else { return }

        currentChunkIndex -= 1
        currentChunk = currentLesson?.chunks[currentChunkIndex]
        updateProgress()

        print("⬅️ [Classroom] Moved back to chunk \(currentChunkIndex + 1)/\(totalChunks)")
    }

    /// Skip backward 10 seconds
    func skipBackward() {
        // TODO: Implement with AVPlayer
        print("⏪ [Classroom] Skip backward 10s")
    }

    /// Skip forward 10 seconds
    func skipForward() {
        // TODO: Implement with AVPlayer
        print("⏩ [Classroom] Skip forward 10s")
    }

    /// Save user progress to persistent storage
    func saveProgress() {
        guard currentLesson != nil else { return }

        if let elapsed = startTime {
            timeSpent += Date().timeIntervalSince(elapsed)
        }

        // TODO: Save to Core Data or UserDefaults
        print("💾 [Classroom] Progress saved - \(Int(lessonProgress * 100))% complete, \(timeSpentFormatted) spent")
    }

    /// Add a user note
    func addNote(_ content: String) {
        guard let lessonId = currentLesson?.id else { return }
        let timestamp = timeSpent // Current playback time

        let note = LessonNote(
            lessonId: lessonId,
            timestamp: timestamp,
            content: content
        )
        notes.append(note)

        print("📝 [Classroom] Note added: \(content)")
    }

    /// Generate an AI summary note for the current chunk
    func generateAISummary() async {
        guard let chunk = currentChunk else { return }

        isProcessing = true

    // TODO: Call AI service to generate summary
    try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate API call

        let summary = "Key concepts from '\(chunk.title)': Understanding the fundamentals and practical applications."

        guard let lessonId = currentLesson?.id else { return }
        let note = LessonNote(
            lessonId: lessonId,
            timestamp: timeSpent,
            content: summary
        )
        notes.append(note)

        isProcessing = false

        print("✨ [Classroom] AI summary generated")
    }

    /// Submit quiz answers and calculate score
    func submitQuizAnswers(_ answers: [UUID: Int]) -> Double {
        guard let quiz = currentQuiz else { return 0.0 }

        var correct = 0
        for question in quiz.questions {
            if let userAnswer = answers[question.id], userAnswer == question.correctAnswerIndex {
                correct += 1
            }
        }

        let accuracy = Double(correct) / Double(quiz.questions.count)
        quizAccuracy = accuracy

        print("📊 [Classroom] Quiz completed - \(Int(accuracy * 100))% accuracy")

        return accuracy
    }

    // MARK: - Private Methods

    private func updateProgress() {
        guard totalChunks > 0 else {
            lessonProgress = 0.0
            return
        }

        lessonProgress = Double(currentChunkIndex) / Double(totalChunks)

        print("📈 [Classroom] Progress updated: \(Int(lessonProgress * 100))%")
    }

    private func finishLesson() {
        lessonProgress = 1.0
        saveProgress()

        // Award completion XP
        xpEarned += 50

        print("🎉 [Classroom] Lesson finished! Total XP: \(xpEarned)")
    }

    private func setupTimerTracking() {
        // Track time spent every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.saveProgress()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Mock Extensions

extension ClassroomViewModel {
    /// Create a mock view model for previews
    static var mock: ClassroomViewModel {
        let vm = ClassroomViewModel()
        vm.loadLesson(.mockLesson1)
        vm.loadCuratedContent()
        vm.xpEarned = 30
        vm.quizAccuracy = 0.85
        // Mock notes
        if let lessonId = vm.currentLesson?.id {
            vm.notes = [
                LessonNote(lessonId: lessonId, timestamp: 30, content: "Swift was created by Apple in 2014"),
                LessonNote(lessonId: lessonId, timestamp: 120, content: "Key takeaway: Swift is a modern, safe, and expressive language designed for iOS, macOS, and beyond.")
            ]
        }
        return vm
    }
}
