import Foundation
import SwiftUI

// MARK: - AI Course Generation Service
/// Real AI-powered course generation using backend API

@MainActor
final class AICourseGenerationService: ObservableObject {
    static let shared = AICourseGenerationService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var generationStatus: String = ""
    @Published var error: String?
    
    private let apiService = ClassroomAPIService.shared
    private let geminiClient = AIAvatarAPIClient.shared
    
    private init() {}
    
    // MARK: - Course Generation
    
    /// Generate a full course using real AI backend
    func generateCourse(
        topic: String,
        level: LearningLevel,
        outcomes: [String] = [],
        pedagogy: Pedagogy? = nil
    ) async throws -> GeneratedCourse {
        
        isGenerating = true
        generationProgress = 0.0
        error = nil
        
        do {
            // Step 1: Enhance outcomes with AI if empty (20%)
            updateProgress(0.2, status: "Analyzing learning goals...")
            let enhancedOutcomes = outcomes.isEmpty ? try await generateLearningOutcomes(topic: topic, level: level) : outcomes
            
            // Step 2: Determine optimal pedagogy (40%)
            updateProgress(0.4, status: "Designing course structure...")
            let coursePedagogy = pedagogy ?? createOptimalPedagogy(level: level)
            
            // Step 3: Generate course via backend API (80%)
            updateProgress(0.8, status: "Generating course content...")
            let course = try await apiService.generateCourse(
                topic: topic,
                level: level,
                outcomes: enhancedOutcomes,
                pedagogy: coursePedagogy
            )
            
            // Step 4: Convert to local format (100%)
            updateProgress(1.0, status: "Finalizing course...")
            let generatedCourse = convertToGeneratedCourse(course, topic: topic, level: level)
            
            isGenerating = false
            print("✅ [AICourseGen] Course generated successfully: \(generatedCourse.title)")
            
            return generatedCourse
            
        } catch {
            isGenerating = false
            self.error = error.localizedDescription
            print("❌ [AICourseGen] Failed to generate course: \(error.localizedDescription)")
            
            // DO NOT generate fallback - throw error properly
            throw NSError(
                domain: "AICourseGenerationService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to generate course: \(error.localizedDescription). Please check your internet connection and try again."]
            )
        }
    }
    
    /// Generate learning outcomes using AI
    private func generateLearningOutcomes(topic: String, level: LearningLevel) async throws -> [String] {
        let prompt = """
        Generate 3-5 specific learning outcomes for a \(level.rawValue)-level course on: \(topic)
        
        Format each outcome as:
        - "Understand [concept]"
        - "Apply [skill]"
        - "Create [deliverable]"
        
        Be specific and actionable. Return only the outcomes, one per line.
        """
        
        print("🎯 [AICourseGen] Generating learning outcomes...")
        
        let response = try await geminiClient.generateWithGemini(prompt)
        
        // Parse outcomes from response
        let outcomes = response
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains("Understand") || $0.contains("Apply") || $0.contains("Create") || $0.contains("Learn") || $0.contains("Master") }
            .prefix(5)
            .map { String($0) }
        
        print("✅ [AICourseGen] Generated \(outcomes.count) learning outcomes")
        return Array(outcomes)
    }
    
    /// Create optimal pedagogy based on level
    private func createOptimalPedagogy(level: LearningLevel) -> Pedagogy {
        switch level {
        case .beginner:
            return Pedagogy(
                style: .visual,
                preferVideo: true,
                preferText: false,
                preferInteractive: true,
                pace: .slow
            )
        case .intermediate:
            return Pedagogy(
                style: .balanced,
                preferVideo: true,
                preferText: true,
                preferInteractive: true,
                pace: .moderate
            )
        case .advanced:
            return Pedagogy(
                style: .projectBased,
                preferVideo: false,
                preferText: true,
                preferInteractive: true,
                pace: .fast
            )
        }
    }
    
    /// Convert backend Course to GeneratedCourse format
    private func convertToGeneratedCourse(_ course: Course, topic: String, level: LearningLevel) -> GeneratedCourse {
        let lessons = course.modules.flatMap { module in
            module.lessons.map { lesson in
                LessonOutline(
                    title: lesson.title,
                    description: lesson.description,
                    contentType: inferContentType(from: lesson.content),
                    estimatedDuration: lesson.estimatedDuration
                )
            }
        }
        
        return GeneratedCourse(
            id: course.id,
            title: course.title,
            description: course.description,
            topic: topic,
            level: level,
            lessons: lessons,
            totalDuration: lessons.reduce(0) { $0 + $1.estimatedDuration },
            modules: course.modules
        )
    }
    
    /// Infer content type from lesson content
    private func inferContentType(from content: String?) -> LessonContentType {
        guard let content = content?.lowercased() else { return .text }
        
        if content.contains("quiz") || content.contains("question") {
            return .quiz
        } else if content.contains("practice") || content.contains("exercise") || content.contains("interactive") {
            return .interactive
        } else if content.contains("video") || content.contains("watch") {
            return .video
        } else {
            return .text
        }
    }
    
    // REMOVED: generateFallbackCourse() - No fallback, fail properly with error
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double, status: String) {
        generationProgress = progress
        generationStatus = status
        print("📊 [AICourseGen] \(Int(progress * 100))% - \(status)")
    }
}

// MARK: - Generated Course Model

struct GeneratedCourse: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let topic: String
    let level: LearningLevel
    let lessons: [LessonOutline]
    let totalDuration: Int // in minutes
    let modules: [CourseModule]
    
    var totalXP: Int? // Total XP available for course completion
    
    var totalDurationFormatted: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var lessonCount: Int {
        lessons.count
    }
    
    // Calculate XP based on course content
    var calculatedTotalXP: Int {
        if let explicit = totalXP {
            return explicit
        }
        
        // Base XP: 100 per lesson
        let baseXP = lessons.count * 100
        
        // Difficulty multiplier
        let difficultyMultiplier: Double = switch level {
            case .beginner: 1.0
            case .intermediate: 1.5
            case .advanced: 2.0
        }
        
        // Duration bonus (1 XP per minute)
        let durationBonus = totalDuration
        
        return Int(Double(baseXP) * difficultyMultiplier) + durationBonus
    }
}

// MARK: - Lesson Outline (already exists, but adding for clarity)

enum LessonContentType: String, Codable {
    case text = "text"
    case video = "video"
    case interactive = "interactive"
    case quiz = "quiz"
    
    var icon: String {
        switch self {
        case .text: return "📖"
        case .video: return "🎥"
        case .interactive: return "💻"
        case .quiz: return "✏️"
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "Reading"
        case .video: return "Video"
        case .interactive: return "Interactive"
        case .quiz: return "Quiz"
        }
    }
    
    var iconName: String {
        switch self {
        case .text: return "book.fill"
        case .video: return "film.fill"
        case .interactive: return "laptopcomputer"
        case .quiz: return "pencil.and.clipboard"
        }
    }
}

struct LessonOutline: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let contentType: LessonContentType
    let estimatedDuration: Int // in minutes
    
    var durationFormatted: String {
        "\(estimatedDuration) min"
    }
}

// MARK: - Course Module Extension

extension CourseModule {
    var totalDuration: Int {
        lessons.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    var lessonCount: Int {
        lessons.count
    }
}

// MARK: - Pedagogy Extension

extension Pedagogy {
    static var balanced: Pedagogy {
        Pedagogy(
            style: .balanced,
            preferVideo: true,
            preferText: true,
            preferInteractive: true,
            pace: .moderate
        )
    }
}
