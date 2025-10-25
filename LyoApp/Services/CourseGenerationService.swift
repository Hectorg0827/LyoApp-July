import Foundation
import SwiftUI
import os.log

// MARK: - Course Generation Service

@MainActor
class CourseGenerationService: ObservableObject {
    
    static let shared = CourseGenerationService()
    
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Int = 0  // 0-100
    @Published var currentStatus: String = ""
    @Published var lastError: Error?
    
    private let apiClient = APIClient.shared
    private let logger = Logger(subsystem: "com.lyoapp", category: "CourseGeneration")
    
    private init() {}
    
    // MARK: - Generate Course from Blueprint
    
    /// Generates a complete course using the backend's AI-powered course generation
    /// - Parameters:
    ///   - blueprint: The course blueprint from CourseBuilderFlowView
    ///   - userId: The user ID (optional, for personalization)
    /// - Returns: A fully generated Course object
    func generateCourse(from blueprint: CourseBlueprint, userId: Int? = nil) async throws -> Course {
        logger.info("🚀 Starting course generation for topic: \(blueprint.topic)")
        
        isGenerating = true
        generationProgress = 0
        currentStatus = "Preparing course generation..."
        lastError = nil
        
        defer {
            isGenerating = false
        }
        
        // Map CourseBlueprint to API request
        let request = GenerateCourseRequest(
            topic: blueprint.topic,
            level: blueprint.level.rawValue,
            outcomes: blueprint.outcomes,
            teachingStyle: blueprint.pedagogy.style.apiValue,
            minutesPerDay: blueprint.schedule?.minutesPerDay,
            daysPerWeek: blueprint.schedule?.daysPerWeek
        )
        
        do {
            // Call backend API
            currentStatus = "Contacting AI course generator..."
            generationProgress = 20
            
            let response: GenerateCourseResponse = try await apiClient.post(
                "/api/content/generate-course",
                body: request,
                requiresAuth: false  // Update if auth is required
            )
            
            logger.info("✅ Received course structure: \(response.modules.count) modules, ~\(response.estimatedDurationHours)h")
            
            // Convert DTO to Course model
            currentStatus = "Building course structure..."
            generationProgress = 60
            
            let course = try await assembleCourse(from: response, blueprint: blueprint)
            
            // Fetch detailed content for first lesson (lazy load rest)
            currentStatus = "Loading initial content..."
            generationProgress = 80
            
            if let firstModule = course.modules.first,
               let firstLesson = firstModule.lessons.first {
                try await enrichLesson(lessonId: firstLesson.id, topic: firstLesson.title)
            }
            
            currentStatus = "Course generation complete!"
            generationProgress = 100
            
            logger.info("🎉 Course generation complete: \(course.title)")
            
            return course
            
        } catch {
            logger.error("❌ Course generation failed: \(error.localizedDescription)")
            lastError = error
            currentStatus = "Generation failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Assemble Lesson Content
    
    /// Fetches rich content for a specific lesson from the backend
    /// - Parameters:
    ///   - lessonId: The lesson ID
    ///   - topic: The lesson topic
    /// - Returns: Enriched lesson content
    func enrichLesson(lessonId: String, topic: String) async throws -> LessonContentDTO {
        logger.info("📚 Enriching lesson: \(topic)")
        
        let request = AssembleLessonRequest(
            topic: topic,
            level: "beginner",  // TODO: Pass actual level
            learningObjectives: [],  // TODO: Pass from lesson
            contentPreferences: ContentPreferences(
                preferVideo: true,
                maxDurationMinutes: 15,
                includeExercises: true,
                sources: ["youtube", "wikipedia"]
            )
        )
        
        let response: AssembleLessonResponse = try await apiClient.post(
            "/api/content/assemble-lesson",
            body: request,
            requiresAuth: false
        )
        
        logger.info("✅ Lesson enriched with \(response.sources.count) sources")
        
        return response.content
    }
    
    // MARK: - Course Assembly
    
    private func assembleCourse(from dto: GenerateCourseResponse, blueprint: CourseBlueprint) async throws -> Course {
        
        // Convert modules
        var modules: [Module] = []
        
        for (index, moduleDTO) in dto.modules.enumerated() {
            let lessons = moduleDTO.lessons.map { lessonDTO in
                Lesson(
                    id: lessonDTO.id,
                    title: lessonDTO.title,
                    summary: lessonDTO.description,
                    estimatedMinutes: lessonDTO.estimatedMinutes,
                    contentBlocks: [], // Will be populated lazily
                    objectives: [],
                    quizItems: []
                )
            }
            
            let module = Module(
                id: moduleDTO.id,
                order: index,
                title: moduleDTO.title,
                subtitle: moduleDTO.description,
                emoji: getModuleEmoji(for: index),
                lessons: lessons,
                objectives: [],
                estimatedMinutes: moduleDTO.estimatedMinutes
            )
            
            modules.append(module)
        }
        
        // Create course
        let course = Course(
            id: dto.courseId,
            createdAt: Date(),
            updatedAt: Date(),
            title: dto.title,
            subtitle: "AI-generated course for \(blueprint.level.displayName) learners",
            emoji: getTopicEmoji(for: dto.topic),
            topic: dto.topic,
            level: blueprint.level,
            bannerColor: Color.blue,
            tagline: "Master \(dto.topic) with personalized AI-powered lessons",
            estimatedHours: dto.estimatedDurationHours,
            objectives: blueprint.outcomes,
            modules: modules,
            personalizedTo: nil  // TODO: Add avatar personalization
        )
        
        return course
    }
    
    // MARK: - Helper Methods
    
    private func getModuleEmoji(for index: Int) -> String {
        let emojis = ["📖", "🎯", "🚀", "⚡️", "🎓", "💡", "🔥"]
        return emojis[index % emojis.count]
    }
    
    private func getTopicEmoji(for topic: String) -> String {
        let lowercased = topic.lowercased()
        
        if lowercased.contains("python") || lowercased.contains("programming") {
            return "🐍"
        } else if lowercased.contains("math") || lowercased.contains("calculus") {
            return "📐"
        } else if lowercased.contains("science") || lowercased.contains("physics") {
            return "🔬"
        } else if lowercased.contains("history") {
            return "📜"
        } else if lowercased.contains("art") || lowercased.contains("design") {
            return "🎨"
        } else if lowercased.contains("music") {
            return "🎵"
        } else if lowercased.contains("language") || lowercased.contains("english") {
            return "📚"
        } else {
            return "📘"
        }
    }
    
    // MARK: - Progress Simulation (for testing)
    
    /// Simulates progress updates (use this for testing UI without backend)
    func simulateProgress() async {
        let steps = [
            (20, "Analyzing learning objectives..."),
            (40, "Generating curriculum structure..."),
            (60, "Sourcing educational content..."),
            (80, "Personalizing to your learning style..."),
            (100, "Course ready!")
        ]
        
        for (progress, status) in steps {
            generationProgress = progress
            currentStatus = status
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        }
    }
}

// MARK: - TeachingStyle API Mapping

extension TeachingStyle {
    var apiValue: String {
        switch self {
        case .examplesFirst:
            return "examples-first"
        case .theoryFirst:
            return "theory-first"
        case .projectsFirst:
            return "project-based"
        case .balanced:
            return "balanced"
        }
    }
}

// MARK: - Course Conversion Extensions

extension Course {
    /// Converts backend DTO to Course model
    static func from(dto: GenerateCourseResponse, blueprint: CourseBlueprint) -> Course {
        // This is handled in CourseGenerationService.assembleCourse
        // Included here for reference
        fatalError("Use CourseGenerationService.assembleCourse instead")
    }
}

// MARK: - Lesson Content Enrichment

extension Lesson {
    /// Enriches lesson with backend content
    mutating func enrich(with content: LessonContentDTO) {
        var blocks: [ContentBlock] = []
        
        // Add introduction
        if let intro = content.introduction {
            blocks.append(ContentBlock(
                id: UUID().uuidString,
                type: .text,
                content: intro,
                order: 0
            ))
        }
        
        // Add video
        if let videoUrl = content.videoUrl, let url = URL(string: videoUrl) {
            blocks.append(ContentBlock(
                id: UUID().uuidString,
                type: .video,
                content: videoUrl,
                order: 1,
                metadata: ["source": "youtube"]
            ))
        }
        
        // Add Wikipedia summary
        if let summary = content.wikipediaSummary {
            blocks.append(ContentBlock(
                id: UUID().uuidString,
                type: .text,
                content: summary,
                order: 2,
                metadata: ["source": "wikipedia"]
            ))
        }
        
        // Add examples
        if let examples = content.examples {
            for (index, example) in examples.enumerated() {
                blocks.append(ContentBlock(
                    id: UUID().uuidString,
                    type: .code,
                    content: example,
                    order: 3 + index
                ))
            }
        }
        
        // Add key points
        if let keyPoints = content.keyPoints {
            let bulletPoints = keyPoints.map { "• \($0)" }.joined(separator: "\n")
            blocks.append(ContentBlock(
                id: UUID().uuidString,
                type: .text,
                content: bulletPoints,
                order: 100
            ))
        }
        
        self.contentBlocks = blocks
        
        // Add exercises
        if let exercises = content.practiceExercises {
            self.quizItems = exercises.map { exercise in
                QuizItem(
                    id: exercise.id,
                    question: exercise.question,
                    options: exercise.options ?? [],
                    correctAnswer: exercise.correctAnswer ?? "",
                    explanation: exercise.explanation ?? ""
                )
            }
        }
    }
}

// MARK: - ContentBlock Model (if not already defined)

struct ContentBlock: Identifiable, Codable {
    let id: String
    let type: ContentBlockType
    let content: String
    let order: Int
    var metadata: [String: String]?
    
    enum ContentBlockType: String, Codable {
        case text
        case video
        case image
        case code
        case quiz
        case interactive
    }
}
