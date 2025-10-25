import Foundation
import Combine

/// API Service for AI Classroom - integrates with Lyo Backend
/// Backend URL: https://lyo-backend-830162750094.us-central1.run.app
@MainActor
class ClassroomAPIService: ObservableObject {
    static let shared = ClassroomAPIService()

    private let baseURL = "https://lyo-backend-830162750094.us-central1.run.app"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    // MARK: - Course Generation

    /// Generate a full course using AI based on user requirements
    /// Uses Gemini AI directly since backend doesn't have course generation endpoint yet
    func generateCourse(
        topic: String,
        level: LearningLevel,
        outcomes: [String],
        pedagogy: Pedagogy
    ) async throws -> ClassroomCourse {
        
        print("📡 [ClassroomAPI] Generating course for topic: \(topic) at \(level.rawValue) level")
        
        // Build comprehensive prompt for Gemini
        let outcomesText = outcomes.isEmpty ? "Appropriate learning outcomes" : outcomes.joined(separator: ", ")
        
        let prompt = """
        Create a comprehensive course curriculum for: \(topic)
        
        Level: \(level.rawValue)
        Learning Outcomes: \(outcomesText)
        Teaching Style: \(pedagogy.style.rawValue)
        Pace: \(pedagogy.pace.rawValue)
        
        Generate a structured course with:
        1. Course title and description
        2. 3-5 modules, each with:
           - Module title and description
           - 3-5 lessons per module
           - Each lesson should have: title, description, key concepts
        
        Format your response as a clear, structured curriculum. Make it practical and engaging for \(level.rawValue)-level learners.
        """
        
        // Use AIAvatarAPIClient to call Gemini
        let geminiClient = AIAvatarAPIClient.shared
        let aiResponse = try await geminiClient.generateWithGemini(prompt)
        
        print("✅ [ClassroomAPI] Received AI course content, parsing into Course structure...")
        
        // Parse AI response into Course structure
        let course = try parseCourseFromAI(
            aiResponse: aiResponse,
            topic: topic,
            level: level,
            outcomes: outcomes,
            pedagogy: pedagogy
        )
        
        print("✅ [ClassroomAPI] Course generated: \(course.title) with \(course.modules.count) modules")
        
        return course
    }
    
    /// Parse AI-generated text into structured Course model
    private func parseCourseFromAI(
        aiResponse: String,
        topic: String,
        level: LearningLevel,
        outcomes: [String],
        pedagogy: Pedagogy
    ) throws -> ClassroomCourse {
        
        // Extract course title (look for title in first few lines)
        let lines = aiResponse.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let courseTitle = extractTitle(from: lines, fallback: "Course: \(topic)")
        let courseDescription = extractDescription(from: aiResponse, topic: topic)
        
        // Parse modules from AI response
        let modules = parseModules(from: aiResponse, topic: topic, level: level)
        
        // Calculate total duration (estimate 30 min per lesson)
        let totalLessons = modules.reduce(0) { $0 + $1.lessons.count }
        let estimatedDuration = totalLessons * 30
        
        return ClassroomCourse(
            title: courseTitle,
            description: courseDescription,
            scope: "AI-generated course covering \(topic)",
            level: level,
            outcomes: outcomes.isEmpty ? ["Master \(topic) fundamentals", "Apply \(topic) concepts", "Build projects with \(topic)"] : outcomes,
            schedule: Schedule(
                minutesPerDay: 60,
                daysPerWeek: 3,
                startDate: Date(),
                reminderEnabled: true,
                preferredTimeOfDay: .evening
            ),
            pedagogy: pedagogy,
            assessments: [AssessmentType.quiz, AssessmentType.project],
            resourcesEnabled: true,
            modules: modules,
            estimatedDuration: estimatedDuration,
            createdAt: Date()
        )
    }
    
    private func extractTitle(from lines: [String], fallback: String) -> String {
        for line in lines.prefix(10) {
            if line.contains("Course:") {
                return line.replacingOccurrences(of: "Course:", with: "").trimmingCharacters(in: .whitespaces)
            }
            if line.contains("Title:") {
                return line.replacingOccurrences(of: "Title:", with: "").trimmingCharacters(in: .whitespaces)
            }
            // First non-empty substantial line
            if !line.isEmpty && line.count > 10 && !line.hasPrefix("#") {
                return line
            }
        }
        return fallback
    }
    
    private func extractDescription(from text: String, topic: String) -> String {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        for (index, line) in lines.enumerated() {
            if line.contains("Description:") && index + 1 < lines.count {
                return lines[index + 1]
            }
        }
        
        // Extract first paragraph after title
        let paragraphs = text.components(separatedBy: "\n\n")
        if paragraphs.count > 1 {
            let desc = paragraphs[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if desc.count > 20 && desc.count < 500 {
                return desc
            }
        }
        
        return "A comprehensive course on \(topic) designed to help you master the fundamentals and build practical skills."
    }
    
    private func parseModules(from text: String, topic: String, level: LearningLevel) -> [CourseModule] {
        var modules: [CourseModule] = []
        
        let lines = text.components(separatedBy: "\n")
        var currentModule: (title: String, description: String, lessons: [(title: String, description: String)]) = ("", "", [])
        var inModule = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Detect module headers (e.g., "Module 1:", "## Module 1", "1. Module:")
            if trimmed.range(of: "module\\s+\\d+", options: [.regularExpression, .caseInsensitive]) != nil ||
               trimmed.hasPrefix("##") && trimmed.lowercased().contains("module") {
                
                // Save previous module if exists
                if inModule && !currentModule.title.isEmpty {
                    modules.append(createModule(from: currentModule, moduleNumber: modules.count + 1, level: level))
                }
                
                // Start new module
                let moduleTitle = trimmed
                    .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                
                currentModule = (moduleTitle, "", [])
                inModule = true
                
            } else if inModule {
                // Look for lesson indicators
                if trimmed.range(of: "lesson\\s+\\d+|^-\\s+", options: [.regularExpression, .caseInsensitive]) != nil {
                    let lessonTitle = trimmed
                        .replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "lesson\\s+\\d+:\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                        .trimmingCharacters(in: .whitespaces)
                    
                    if !lessonTitle.isEmpty {
                        currentModule.lessons.append((lessonTitle, "Learn about \(lessonTitle)"))
                    }
                } else if !trimmed.isEmpty && currentModule.description.isEmpty && !trimmed.lowercased().contains("module") {
                    // First substantial line after module title is description
                    currentModule.description = trimmed
                }
            }
        }
        
        // Add last module
        if inModule && !currentModule.title.isEmpty {
            modules.append(createModule(from: currentModule, moduleNumber: modules.count + 1, level: level))
        }
        
        // If no modules were parsed, create default structure
        if modules.isEmpty {
            modules = [
                CourseModule(
                    id: UUID(),
                    moduleNumber: 1,
                    title: "Introduction to \(topic)",
                    description: "Foundational concepts and basics",
                    lessons: [
                        Lesson(id: UUID(), lessonNumber: 1, title: "Getting Started with \(topic)", description: "Overview and fundamentals", estimatedDuration: 30, level: level),
                        Lesson(id: UUID(), lessonNumber: 2, title: "Core Concepts", description: "Essential principles", estimatedDuration: 45, level: level),
                        Lesson(id: UUID(), lessonNumber: 3, title: "Practical Applications", description: "Hands-on practice", estimatedDuration: 60, level: level)
                    ],
                    estimatedDuration: 135,
                    isUnlocked: true,
                    progress: 0.0
                ),
                CourseModule(
                    id: UUID(),
                    moduleNumber: 2,
                    title: "Advanced \(topic)",
                    description: "Advanced techniques and best practices",
                    lessons: [
                        Lesson(id: UUID(), lessonNumber: 1, title: "Advanced Techniques", description: "Master advanced topics", estimatedDuration: 60, level: level),
                        Lesson(id: UUID(), lessonNumber: 2, title: "Real-World Projects", description: "Build practical projects", estimatedDuration: 90, level: level)
                    ],
                    estimatedDuration: 150,
                    isUnlocked: false,
                    progress: 0.0
                )
            ]
        }
        
        return modules
    }
    
    private func createModule(from moduleData: (title: String, description: String, lessons: [(title: String, description: String)]), moduleNumber: Int, level: LearningLevel) -> CourseModule {
        let lessons = moduleData.lessons.enumerated().map { index, lesson in
            Lesson(
                id: UUID(),
                lessonNumber: index + 1,
                title: lesson.title,
                description: lesson.description,
                chunks: [],
                estimatedDuration: 30 + (index * 10), // Vary duration
                isCompleted: false,
                lastWatchedPosition: 0,
                topic: lesson.title,
                level: level
            )
        }
        
        // If no lessons parsed, create default lessons
        let finalLessons = lessons.isEmpty ? [
            Lesson(id: UUID(), lessonNumber: 1, title: "Introduction", description: "Getting started", estimatedDuration: 30, level: level),
            Lesson(id: UUID(), lessonNumber: 2, title: "Core Concepts", description: "Essential topics", estimatedDuration: 45, level: level)
        ] : lessons
        
        let totalDuration = finalLessons.reduce(0) { $0 + $1.estimatedDuration }
        
        return CourseModule(
            id: UUID(),
            moduleNumber: moduleNumber,
            title: moduleData.title,
            description: moduleData.description.isEmpty ? "Learn about \(moduleData.title)" : moduleData.description,
            lessons: finalLessons,
            estimatedDuration: totalDuration,
            isUnlocked: moduleNumber == 1,
            progress: 0.0
        )
    }

    // MARK: - Lesson Content Generation

    /// Generate lesson chunks with AI-narrated content
    /// POST /api/lessons/{lessonId}/generate-chunks
    func generateLessonChunks(
        lessonId: UUID,
        topic: String,
        objectives: [String]
    ) async throws -> [LessonChunk] {
        let endpoint = "\(baseURL)/api/lessons/\(lessonId)/generate-chunks"

        let requestBody: [String: Any] = [
            "topic": topic,
            "objectives": objectives
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("📡 [ClassroomAPI] Generating lesson chunks for: \(topic)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let chunks = try JSONDecoder().decode([LessonChunk].self, from: data)

        print("✅ [ClassroomAPI] Generated \(chunks.count) lesson chunks")

        return chunks
    }

    // MARK: - Content Curation

    /// Curate external learning resources using AI
    /// POST /api/content/curate
    func curateContent(
        topic: String,
        level: LearningLevel,
        preferences: Pedagogy
    ) async throws -> [ContentCard] {
        let endpoint = "\(baseURL)/api/content/curate"

        let requestBody: [String: Any] = [
            "topic": topic,
            "level": level.rawValue,
            "preferVideo": preferences.preferVideo,
            "preferText": preferences.preferText,
            "preferInteractive": preferences.preferInteractive,
            "maxResults": 10
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("📡 [ClassroomAPI] Curating content for: \(topic)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("⚠️ [ClassroomAPI] Content curation failed, using fallback")
            return ContentCard.mockCards
        }

        let cards = try JSONDecoder().decode([ContentCard].self, from: data)

        print("✅ [ClassroomAPI] Curated \(cards.count) content resources")

        return cards
    }

    // MARK: - Quiz Generation

    /// Generate adaptive quiz questions based on lesson content
    /// POST /api/quizzes/generate
    func generateQuiz(
        lessonId: UUID,
        difficulty: QuizQuestion.QuestionDifficulty,
        questionCount: Int = 3
    ) async throws -> MicroQuiz {
        let endpoint = "\(baseURL)/api/quizzes/generate"

        let requestBody: [String: Any] = [
            "lessonId": lessonId.uuidString,
            "difficulty": difficulty.rawValue,
            "questionCount": questionCount
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("📡 [ClassroomAPI] Generating quiz with \(questionCount) questions")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("⚠️ [ClassroomAPI] Quiz generation failed, using fallback")
            return .mockQuiz
        }

        let quiz = try JSONDecoder().decode(MicroQuiz.self, from: data)

        print("✅ [ClassroomAPI] Generated quiz with \(quiz.questions.count) questions")

        return quiz
    }

    // MARK: - AI Summary Generation

    /// Generate AI summary for lesson chunk
    /// POST /api/ai/summarize
    func generateSummary(
        chunkId: UUID,
        content: String
    ) async throws -> String {
        let endpoint = "\(baseURL)/api/ai/summarize"

        let requestBody: [String: Any] = [
            "chunkId": chunkId.uuidString,
            "content": content,
            "maxLength": 200
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("📡 [ClassroomAPI] Generating AI summary for chunk")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let summary = responseJson?["summary"] as? String else {
            throw APIError.decodingError(NSError(domain: "ClassroomAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode summary"]))
        }

        print("✅ [ClassroomAPI] AI summary generated")

        return summary
    }

    // MARK: - Progress Tracking

    /// Save user progress to backend
    /// POST /api/progress/save
    func saveProgress(_ progress: CourseProgress) async throws {
        let endpoint = "\(baseURL)/api/progress/save"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(progress)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("📡 [ClassroomAPI] Saving progress: \(Int(progress.overallProgress * 100))%")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        print("✅ [ClassroomAPI] Progress saved successfully")
    }

    /// Fetch user progress from backend
    /// GET /api/progress/{courseId}
    func fetchProgress(courseId: UUID) async throws -> CourseProgress {
        let endpoint = "\(baseURL)/api/progress/\(courseId)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        print("📡 [ClassroomAPI] Fetching progress for course: \(courseId)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let progress = try decoder.decode(CourseProgress.self, from: data)

        print("✅ [ClassroomAPI] Progress fetched: \(Int(progress.overallProgress * 100))%")

        return progress
    }

    // MARK: - Analytics

    /// Track learning analytics
    /// POST /api/analytics/track
    func trackAnalytics(
        eventType: AnalyticsEvent,
        lessonId: UUID?,
        metadata: [String: Any]
    ) async throws {
        let endpoint = "\(baseURL)/api/analytics/track"

        var requestBody: [String: Any] = [
            "eventType": eventType.name,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "metadata": metadata
        ]

        if let lessonId = lessonId {
            requestBody["lessonId"] = lessonId.uuidString
        }

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        print("📊 [ClassroomAPI] Tracking analytics: \(eventType.name)")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Don't throw - analytics tracking is non-critical
            print("⚠️ [ClassroomAPI] Analytics tracking failed (non-critical)")
            return
        }

        print("✅ [ClassroomAPI] Analytics tracked")
    }
}

// MARK: - Supporting Types
// NOTE: APIError is defined in APIError.swift (canonical)
// NOTE: AnalyticsEvent is defined in Core/Telemetry/Analytics.swift (canonical)
// Both types are commented out to avoid ambiguity and conflicts with canonical definitions

/*
enum APIError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case networkError
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection failed"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

enum AnalyticsEvent: String {
    case lessonStarted = "lesson_started"
    case lessonCompleted = "lesson_completed"
    case chunkCompleted = "chunk_completed"
    case quizAttempted = "quiz_attempted"
    case quizPassed = "quiz_passed"
    case quizFailed = "quiz_failed"
    case contentCardViewed = "content_card_viewed"
    case noteAdded = "note_added"
    case lessonPaused = "lesson_paused"
    case lessonResumed = "lesson_resumed"
}
*/

// MARK: - Enhanced ViewModel with Backend Integration

extension ClassroomViewModel {
    /// Load curated content from backend API
    func loadCuratedContentFromAPI(topic: String, level: LearningLevel, preferences: Pedagogy) async {
        do {
            curatedCards = try await ClassroomAPIService.shared.curateContent(
                topic: topic,
                level: level,
                preferences: preferences
            )

            print("📚 [Classroom] Loaded \(curatedCards.count) curated resources from API")
        } catch {
            print("⚠️ [Classroom] Failed to load curated content from API: \(error.localizedDescription)")
            // Fallback to mock data
            curatedCards = ContentCard.mockCards
        }
    }

    /// Generate AI summary for current chunk
    func generateAISummaryFromAPI() async {
        guard let chunk = currentChunk, let lesson = currentLesson else { return }

        isProcessing = true

        do {
            let content = chunk.scriptContent ?? chunk.title
            let summary = try await ClassroomAPIService.shared.generateSummary(
                chunkId: chunk.id,
                content: content
            )

            let note = LessonNote(
                lessonId: lesson.id,
                timestamp: 0, // Summary for entire chunk
                content: summary
            )
            notes.append(note)

            print("✨ [Classroom] AI summary generated from API")
        } catch {
            print("❌ [Classroom] Failed to generate AI summary: \(error.localizedDescription)")

            // Fallback to simple summary
            let fallback = "Key concepts from '\(chunk.title)': Understanding the fundamentals and practical applications."
            let note = LessonNote(
                lessonId: lesson.id,
                timestamp: 0,
                content: fallback
            )
            notes.append(note)
        }

        isProcessing = false
    }

    /// Save progress to backend
    func saveProgressToAPI(courseId: UUID) async {
        guard let lesson = currentLesson else { return }

        let progress = CourseProgress(
            courseId: courseId,
            overallProgress: lessonProgress,
            currentLessonId: lesson.id,
            totalTimeSpent: timeSpent,
            completedLessons: lessonProgress >= 1.0 ? [lesson.id] : []
        )

        do {
            try await ClassroomAPIService.shared.saveProgress(progress)
            print("💾 [Classroom] Progress saved to API")
        } catch {
            print("⚠️ [Classroom] Failed to save progress to API: \(error.localizedDescription)")
        }
    }

    /// Track analytics event
    func trackEvent(_ event: AnalyticsEvent, metadata: [String: Any] = [:]) async {
        do {
            try await ClassroomAPIService.shared.trackAnalytics(
                eventType: event,
                lessonId: currentLesson?.id,
                metadata: metadata
            )
        } catch {
            print("⚠️ [Classroom] Failed to track analytics: \(error.localizedDescription)")
        }
    }
}
