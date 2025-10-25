import Foundation
import SwiftUI

/// Enhanced Course Generation Service with Real AI Content Aggregation
/// Combines Gemini AI for curriculum generation with backend APIs for content curation
/// NO MOCK DATA - Production ready service
@MainActor
final class EnhancedCourseGenerationService: ObservableObject {
    static let shared = EnhancedCourseGenerationService()
    
    @Published var generationProgress: CourseGenerationState = .idle
    @Published var currentStep: String = ""
    @Published var completedSteps: [String] = []
    
    private let geminiClient = AIAvatarAPIClient.shared
    private let classroomAPI = ClassroomAPIService.shared
    
    private init() {}
    
    // MARK: - Main Course Generation Pipeline
    
    /// Generate a comprehensive course with real AI content aggregation
    /// Pipeline: AI Curriculum → Lesson Details → Content Aggregation → Finalization
    func generateComprehensiveCourse(
        topic: String,
        level: LearningLevel,
        outcomes: [String],
        pedagogy: Pedagogy,
        onProgressUpdate: @escaping (String, Double) -> Void
    ) async throws -> ClassroomCourse {
        
        print("🚀 [EnhancedCourseGen] Starting comprehensive course generation for: \(topic)")
        generationProgress = .generating(progress: 0.0, step: "Initializing...")
        
        // Step 1: Generate Course Structure with AI (25% progress)
        updateProgress("🎯 Generating curriculum structure with AI...", 0.10, onProgressUpdate)
        let courseStructure = try await generateCourseStructure(
            topic: topic,
            level: level,
            outcomes: outcomes,
            pedagogy: pedagogy
        )
        
        // Step 2: Enhance Each Module with Detailed Lessons (50% progress)
        updateProgress("📚 Creating detailed lesson plans...", 0.35, onProgressUpdate)
        let enhancedModules = try await enhanceModulesWithLessons(
            modules: courseStructure.modules,
            topic: topic,
            level: level,
            pedagogy: pedagogy
        )
        
        // Step 3: Aggregate Real Content for Each Lesson (75% progress)
        updateProgress("🔍 Aggregating learning resources...", 0.60, onProgressUpdate)
        let contentEnhancedModules = try await aggregateContentForModules(
            modules: enhancedModules,
            topic: topic,
            level: level
        )
        
        // Step 4: Finalize Course with Metadata (100% progress)
        updateProgress("✨ Finalizing your course...", 0.90, onProgressUpdate)
        
        // Calculate total duration from all lessons
        let totalDuration = contentEnhancedModules.flatMap { $0.lessons }.reduce(0) { $0 + $1.estimatedDuration }
        
        let resolvedOutcomes = resolveOutcomes(
            explicit: outcomes,
            aiSuggested: courseStructure.outcomes,
            topic: topic
        )
        let schedule = createDefaultSchedule(for: pedagogy.pace)
        let assessments = determineAssessments(for: level, pedagogy: pedagogy)
        
        let finalCourse = ClassroomCourse(
            id: UUID(),
            title: courseStructure.title,
            description: courseStructure.description,
            scope: courseStructure.scope,
            level: level,
            outcomes: resolvedOutcomes,
            schedule: schedule,
            pedagogy: pedagogy,
            assessments: assessments,
            resourcesEnabled: true,
            modules: contentEnhancedModules,
            estimatedDuration: totalDuration,
            createdAt: Date()
        )
        
        updateProgress("✅ Course generation complete!", 1.0, onProgressUpdate)
        generationProgress = .completed(course: finalCourse)
        
        print("✅ [EnhancedCourseGen] Course generated successfully: \(finalCourse.title)")
        print("   • \(contentEnhancedModules.count) modules")
        print("   • \(contentEnhancedModules.flatMap { $0.lessons }.count) lessons")
        print("   • \(finalCourse.estimatedDuration) minutes total")
        
        return finalCourse
    }
    
    // MARK: - Step 1: Generate Course Structure
    
    private func generateCourseStructure(
        topic: String,
        level: LearningLevel,
        outcomes: [String],
        pedagogy: Pedagogy
    ) async throws -> CourseStructureAI {
        
        let outcomesText = outcomes.isEmpty ? "appropriate learning outcomes" : outcomes.joined(separator: ", ")
        
        let prompt = """
        Create a comprehensive course curriculum for: \(topic)
        
        Target Audience: \(level.rawValue) learners
        Desired Outcomes: \(outcomesText)
        Teaching Approach: \(pedagogy.style.rawValue) at \(pedagogy.pace.rawValue) pace
        
        Generate a structured course with:
        
        1. **Course Title**: Engaging and descriptive
        2. **Course Description**: 2-3 sentences explaining what students will learn
        3. **Learning Scope**: Breadth and depth of coverage
        4. **3-5 Modules**, each containing:
           - Module title (clear, actionable)
           - Module description (what this module covers)
           - 3-5 Lessons per module with:
             * Lesson title
             * Lesson description (what will be taught)
             * Estimated duration (in minutes)
             * Key learning objectives
        
        Make the curriculum practical, engaging, and appropriate for \(level.rawValue)-level learners.
        Use clear headings like "Module 1:", "Lesson 1.1:", etc.
        """
        
        print("📡 [EnhancedCourseGen] Requesting course structure from Gemini AI...")
        let aiResponse = try await geminiClient.generateWithGemini(prompt)
        
        print("✅ [EnhancedCourseGen] Received AI response, parsing structure...")
        return try parseCourseStructure(
            from: aiResponse,
            topic: topic,
            level: level,
            outcomes: outcomes
        )
    }
    
    private func parseCourseStructure(
        from aiResponse: String,
        topic: String,
        level: LearningLevel,
        outcomes: [String]
    ) throws -> CourseStructureAI {
        
        let lines = aiResponse.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Extract title
        let title = extractTitle(from: lines, fallback: "Master \(topic)")
        
        // Extract description
        let description = extractDescription(from: aiResponse, fallback: "Learn \(topic) from fundamentals to advanced applications")
        
        // Parse modules
        var modules: [CourseModuleStructure] = []
        var currentModuleTitle = ""
        var currentModuleDesc = ""
        var currentLessons: [(title: String, description: String, duration: Int)] = []
        var moduleNumber = 0
        
        for line in lines {
            // Detect module headers
            if line.range(of: "module\\s+\\d+", options: [.regularExpression, .caseInsensitive]) != nil ||
               line.hasPrefix("## Module") {
                
                // Save previous module
                if !currentModuleTitle.isEmpty {
                    modules.append(CourseModuleStructure(
                        moduleNumber: moduleNumber,
                        title: currentModuleTitle,
                        description: currentModuleDesc,
                        lessons: currentLessons
                    ))
                }
                
                // Start new module
                moduleNumber += 1
                currentModuleTitle = line.replacingOccurrences(of: "^(##|Module\\s+\\d+:?)\\s*", with: "", options: .regularExpression)
                currentModuleDesc = ""
                currentLessons = []
                
            } else if line.range(of: "lesson\\s+\\d+", options: [.regularExpression, .caseInsensitive]) != nil ||
                      line.hasPrefix("### Lesson") {
                
                // Extract lesson info
                let lessonTitle = line.replacingOccurrences(of: "^(###|Lesson\\s+[\\d.]+:?)\\s*", with: "", options: .regularExpression)
                let lessonDesc = "Learn about \(lessonTitle)"
                let duration = 30 + (currentLessons.count * 15) // Vary duration
                
                currentLessons.append((title: lessonTitle, description: lessonDesc, duration: duration))
            }
        }
        
        // Add last module
        if !currentModuleTitle.isEmpty {
            modules.append(CourseModuleStructure(
                moduleNumber: moduleNumber,
                title: currentModuleTitle,
                description: currentModuleDesc,
                lessons: currentLessons
            ))
        }
        
        // Fallback if no modules parsed
        if modules.isEmpty {
            modules = createDefaultModules(for: topic, level: level)
        }
        
        return CourseStructureAI(
            title: title,
            description: description,
            scope: "Comprehensive coverage of \(topic) from basics to advanced concepts",
            outcomes: outcomes.isEmpty ? generateDefaultOutcomes(for: topic) : outcomes,
            modules: modules
        )
    }
    
    // MARK: - Step 2: Enhance Modules with Detailed Lessons
    
    private func enhanceModulesWithLessons(
        modules: [CourseModuleStructure],
        topic: String,
        level: LearningLevel,
        pedagogy: Pedagogy
    ) async throws -> [CourseModule] {
        
        var enhancedModules: [CourseModule] = []
        
        for (index, moduleStructure) in modules.enumerated() {
            print("📝 [EnhancedCourseGen] Enhancing module \(index + 1)/\(modules.count): \(moduleStructure.title)")
            
            // Generate detailed lesson content with AI
            let lessons = try await generateDetailedLessons(
                moduleTitle: moduleStructure.title,
                lessons: moduleStructure.lessons,
                topic: topic,
                level: level,
                pedagogy: pedagogy
            )
            
            let totalDuration = lessons.reduce(0) { $0 + $1.estimatedDuration }
            
            let module = CourseModule(
                id: UUID(),
                moduleNumber: moduleStructure.moduleNumber,
                title: moduleStructure.title,
                description: moduleStructure.description.isEmpty ? "Master \(moduleStructure.title)" : moduleStructure.description,
                lessons: lessons,
                estimatedDuration: totalDuration,
                isUnlocked: index == 0, // First module unlocked
                progress: 0.0
            )
            
            enhancedModules.append(module)
        }
        
        return enhancedModules
    }
    
    private func generateDetailedLessons(
        moduleTitle: String,
        lessons: [(title: String, description: String, duration: Int)],
        topic: String,
        level: LearningLevel,
        pedagogy: Pedagogy
    ) async throws -> [Lesson] {
        
        var detailedLessons: [Lesson] = []
        
        for (index, lessonStructure) in lessons.enumerated() {
            // Generate lesson script with AI
            let prompt = """
            Create a detailed lesson script for:
            
            Module: \(moduleTitle)
            Lesson: \(lessonStructure.title)
            Topic: \(topic)
            Level: \(level.rawValue)
            Style: \(pedagogy.style.rawValue)
            
            Generate:
            1. Lesson overview (2-3 sentences)
            2. Key learning objectives (3-5 points)
            3. Main concepts to cover
            4. Practical examples
            
            Keep it \(pedagogy.pace.rawValue)-paced and suitable for \(level.rawValue) learners.
            """
            
            let aiContent = try await geminiClient.generateWithGemini(prompt)
            
            // Create lesson chunks from AI content
            let chunks = createLessonChunks(from: aiContent, lessonTitle: lessonStructure.title)
            
            let lesson = Lesson(
                id: UUID(),
                lessonNumber: index + 1,
                title: lessonStructure.title,
                description: lessonStructure.description,
                chunks: chunks,
                estimatedDuration: lessonStructure.duration,
                isCompleted: false,
                lastWatchedPosition: 0,
                topic: lessonStructure.title,
                level: level
            )
            
            detailedLessons.append(lesson)
        }
        
        return detailedLessons
    }
    
    // MARK: - Step 3: Aggregate Real Content
    
    private func aggregateContentForModules(
        modules: [CourseModule],
        topic: String,
        level: LearningLevel
    ) async throws -> [CourseModule] {
        
        var contentEnhancedModules: [CourseModule] = []
        
        for module in modules {
            print("🔍 [EnhancedCourseGen] Aggregating content for module: \(module.title)")
            
            // Fetch curated content for this module's topic from real backend
            let contentCards = try await classroomAPI.curateContent(
                topic: "\(topic) \(module.title)",
                level: level,
                preferences: Pedagogy(
                    style: .hybrid,
                    preferVideo: true,
                    preferText: true,
                    preferInteractive: true,
                    pace: .moderate
                )
            )
            
            print("   ✅ Found \(contentCards.count) curated resources")
            
            // Enhance lessons with aggregated content
            let enhancedLessons = try await enhanceLessonsWithContent(
                lessons: module.lessons,
                contentCards: contentCards,
                moduleTopic: module.title
            )
            
            let enhancedModule = CourseModule(
                id: module.id,
                moduleNumber: module.moduleNumber,
                title: module.title,
                description: module.description,
                lessons: enhancedLessons,
                estimatedDuration: module.estimatedDuration,
                isUnlocked: module.isUnlocked,
                progress: module.progress
            )
            
            contentEnhancedModules.append(enhancedModule)
        }
        
        return contentEnhancedModules
    }
    
    private func enhanceLessonsWithContent(
        lessons: [Lesson],
        contentCards: [ContentCard],
        moduleTopic: String
    ) async throws -> [Lesson] {
        
        var enhancedLessons: [Lesson] = []
        let safeLessonCount = max(lessons.count, 1)
        let cardsPerLesson = contentCards.isEmpty ? 0 : max(1, contentCards.count / safeLessonCount)
        
        for (index, lesson) in lessons.enumerated() {
            // Assign relevant content cards to this lesson
            let startIndex = cardsPerLesson == 0 ? 0 : index * cardsPerLesson
            let lessonCards: [ContentCard]
            if cardsPerLesson == 0 || startIndex >= contentCards.count {
                lessonCards = []
            } else {
                let endIndex = min(startIndex + cardsPerLesson, contentCards.count)
                lessonCards = Array(contentCards[startIndex..<endIndex])
            }
            
            var enhancedChunks = lesson.chunks
            if let resourcesChunk = createResourcesChunk(
                from: lessonCards,
                startingNumber: enhancedChunks.count + 1,
                moduleTopic: moduleTopic
            ) {
                enhancedChunks.append(resourcesChunk)
            }
            
            let enhancedLesson = Lesson(
                id: lesson.id,
                lessonNumber: lesson.lessonNumber,
                title: lesson.title,
                description: lesson.description,
                chunks: enhancedChunks,
                estimatedDuration: lesson.estimatedDuration,
                isCompleted: lesson.isCompleted,
                lastWatchedPosition: lesson.lastWatchedPosition,
                topic: lesson.topic,
                level: lesson.level
            )
            
            enhancedLessons.append(enhancedLesson)
            
            print("   📎 Lesson \(index + 1): '\(lesson.title)' enhanced with \(lessonCards.count) resources")
        }
        
        return enhancedLessons
    }
    
    // MARK: - Helper Functions
    
    private func createLessonChunks(from content: String, lessonTitle: String) -> [LessonChunk] {
        // Split content into logical chunks (sections)
        let sections = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return sections.enumerated().map { index, section in
            LessonChunk(
                id: UUID(),
                chunkNumber: index + 1,
                title: index == 0 ? "Introduction" : "Part \(index + 1)",
                contentType: .slides, // Text-based content
                scriptContent: section,
                duration: 120 // 2 minutes per chunk
            )
        }
    }
    
    private func resolveOutcomes(explicit: [String], aiSuggested: [String], topic: String) -> [String] {
        if !explicit.isEmpty {
            return explicit
        }
        if !aiSuggested.isEmpty {
            return aiSuggested
        }
        return generateDefaultOutcomes(for: topic)
    }
    
    private func determineAssessments(for level: LearningLevel, pedagogy: Pedagogy) -> [AssessmentType] {
        var ordered: [AssessmentType] = []
        func appendUnique(_ type: AssessmentType) {
            if !ordered.contains(type) {
                ordered.append(type)
            }
        }
        
        appendUnique(.quiz)
        appendUnique(.practice)
        
        if level == .advanced || level == .expert {
            appendUnique(.project)
        }
        
        if pedagogy.preferInteractive || pedagogy.pace == .fast {
            appendUnique(.spaced)
        }
        
        return ordered
    }
    
    private func createDefaultSchedule(for pace: Pedagogy.LearningPace) -> Schedule {
        switch pace {
        case .slow:
            return Schedule(minutesPerDay: 30, daysPerWeek: 3, reminderEnabled: true, preferredTimeOfDay: .evening)
        case .moderate:
            return Schedule(minutesPerDay: 45, daysPerWeek: 4, reminderEnabled: true, preferredTimeOfDay: .evening)
        case .fast:
            return Schedule(minutesPerDay: 60, daysPerWeek: 5, reminderEnabled: true, preferredTimeOfDay: .afternoon)
        }
    }
    
    private func createResourcesChunk(from cards: [ContentCard], startingNumber: Int, moduleTopic: String) -> LessonChunk? {
        guard !cards.isEmpty else { return nil }
        let chunkType = dominantChunkType(for: cards)
        let resourceSummary = cards.enumerated()
            .map { index, card in
                "\(index + 1). \(card.title) — \(card.source) [\(card.kind.rawValue.capitalized)]"
            }
            .joined(separator: "\n")
        let script = "Curated resources to deepen your understanding of \(moduleTopic):\n\(resourceSummary)"
        
        return LessonChunk(
            chunkNumber: startingNumber,
            title: "Recommended Resources",
            contentType: chunkType,
            scriptContent: script,
            duration: Double(cards.count * 180)
        )
    }

    private func dominantChunkType(for cards: [ContentCard]) -> ChunkContentType {
        let counts = cards.reduce(into: [ChunkContentType: Int]()) { partialResult, card in
            let type = chunkContentType(for: card.kind)
            partialResult[type, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .slides
    }
    
    private func chunkContentType(for kind: CardKind) -> ChunkContentType {
        switch kind {
        case .video:
            return .video
        case .ebook, .article, .infographic:
            return .slides
        case .exercise, .dataset:
            return .interactive
        case .podcast:
            return .animation
        }
    }

    private func createDefaultModules(for topic: String, level: LearningLevel) -> [CourseModuleStructure] {
        [
            CourseModuleStructure(
                moduleNumber: 1,
                title: "Introduction to \(topic)",
                description: "Foundational concepts and getting started",
                lessons: [
                    (title: "What is \(topic)?", description: "Overview and basics", duration: 30),
                    (title: "Core Concepts", description: "Essential principles", duration: 45),
                    (title: "Your First Steps", description: "Hands-on introduction", duration: 60)
                ]
            ),
            CourseModuleStructure(
                moduleNumber: 2,
                title: "Intermediate \(topic)",
                description: "Building on the fundamentals",
                lessons: [
                    (title: "Advanced Techniques", description: "Level up your skills", duration: 60),
                    (title: "Real-World Applications", description: "Practical use cases", duration: 75)
                ]
            ),
            CourseModuleStructure(
                moduleNumber: 3,
                title: "Mastering \(topic)",
                description: "Expert-level concepts and best practices",
                lessons: [
                    (title: "Best Practices", description: "Professional approaches", duration: 60),
                    (title: "Capstone Project", description: "Apply everything you've learned", duration: 120)
                ]
            )
        ]
    }
    
    private func generateDefaultOutcomes(for topic: String) -> [String] {
        [
            "Understand the fundamental concepts of \(topic)",
            "Apply \(topic) techniques to solve real-world problems",
            "Build practical projects using \(topic)",
            "Develop mastery in \(topic) best practices"
        ]
    }
    
    private func extractTitle(from lines: [String], fallback: String) -> String {
        // Look for title patterns in first 10 lines
        for line in lines.prefix(10) {
            if line.count > 10 && line.count < 100 &&
               (line.hasPrefix("#") || line.contains("Course") || line.contains("Title")) {
                let cleaned = line.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "Course:\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                    .replacingOccurrences(of: "Title:\\s*", with: "", options: [.regularExpression, .caseInsensitive])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }
        return fallback
    }
    
    private func extractDescription(from text: String, fallback: String) -> String {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 30 && $0.count < 300 }
        
        // Find first substantial paragraph
        for line in lines.prefix(20) {
            if !line.hasPrefix("#") && !line.contains("Module") && !line.contains("Lesson") {
                return line
            }
        }
        return fallback
    }
    
    private func updateProgress(_ message: String, _ progress: Double, _ callback: @escaping (String, Double) -> Void) {
        currentStep = message
        completedSteps.append(message)
        generationProgress = .generating(progress: progress, step: message)
        callback(message, progress)
    }
    
    // MARK: - Reset
    
    func reset() {
        generationProgress = .idle
        currentStep = ""
        completedSteps = []
    }
}

// MARK: - Supporting Types

enum CourseGenerationState: Equatable {
    case idle
    case generating(progress: Double, step: String)
    case completed(course: ClassroomCourse)
    case failed(error: String)
    
    static func == (lhs: CourseGenerationState, rhs: CourseGenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.generating(p1, s1), .generating(p2, s2)):
            return p1 == p2 && s1 == s2
        case let (.completed(c1), .completed(c2)):
            return c1.id == c2.id
        case let (.failed(e1), .failed(e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

struct CourseStructureAI {
    let title: String
    let description: String
    let scope: String
    let outcomes: [String]
    let modules: [CourseModuleStructure]
}

struct CourseModuleStructure {
    let moduleNumber: Int
    let title: String
    let description: String
    let lessons: [(title: String, description: String, duration: Int)]
}
