import SwiftUI
import SwiftUI
import Foundation
import AVFoundation

// MARK: - Course Models

/// Represents a complete course with modules and metadata
public struct ClassroomCourse: Codable, Identifiable {
    public var id = UUID()
    public var title: String
    public var description: String
    public var scope: String
    public var level: LearningLevel
    public var outcomes: [String]
    public var schedule: Schedule
    public var pedagogy: Pedagogy
    public var assessments: [AssessmentType]
    public var resourcesEnabled: Bool
    public var modules: [CourseModule]
    public var coverImageURL: URL?
    public var estimatedDuration: Int // in minutes
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        scope: String,
        level: LearningLevel = .beginner,
        outcomes: [String] = [],
        schedule: Schedule = Schedule(),
        pedagogy: Pedagogy = Pedagogy(),
        assessments: [AssessmentType] = [.quiz],
        resourcesEnabled: Bool = true,
        modules: [CourseModule] = [],
        coverImageURL: URL? = nil,
        estimatedDuration: Int = 60,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.scope = scope
        self.level = level
        self.outcomes = outcomes
        self.schedule = schedule
        self.pedagogy = pedagogy
        self.assessments = assessments
        self.resourcesEnabled = resourcesEnabled
        self.modules = modules
        self.coverImageURL = coverImageURL
        self.estimatedDuration = estimatedDuration
        self.createdAt = createdAt
    }
}

/// Learning difficulty level
public enum LearningLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"

    public var displayName: String {
        rawValue.capitalized
    }

    public var icon: String {
        switch self {
        case .beginner: return "star.fill"
        case .intermediate: return "star.leadinghalf.filled"
        case .advanced: return "star.circle.fill"
        case .expert: return "crown.fill"
        }
    }
}

/// Course schedule configuration
public struct Schedule: Codable {
    public var minutesPerDay: Int
    public var daysPerWeek: Int
    public var startDate: Date
    public var reminderEnabled: Bool
    public var preferredTimeOfDay: TimeOfDay

    public init(
        minutesPerDay: Int = 30,
        daysPerWeek: Int = 5,
        startDate: Date = Date(),
        reminderEnabled: Bool = true,
        preferredTimeOfDay: TimeOfDay = .evening
    ) {
        self.minutesPerDay = minutesPerDay
        self.daysPerWeek = daysPerWeek
        self.startDate = startDate
        self.reminderEnabled = reminderEnabled
        self.preferredTimeOfDay = preferredTimeOfDay
    }

    public enum TimeOfDay: String, Codable {
        case morning, afternoon, evening, night
    }
}

/// Learning approach/style for course content
public enum LearningStyle: String, Codable, CaseIterable {
    case examplesFirst = "examplesFirst"
    case theoryFirst = "theoryFirst"
    case projectsFirst = "projectsFirst"
    case hybrid = "hybrid"

    public var displayName: String {
        switch self {
        case .examplesFirst: return "Examples First"
        case .theoryFirst: return "Theory First"
        case .projectsFirst: return "Projects First"
        case .hybrid: return "Balanced Mix"
        }
    }
}

/// Learning style and pedagogy preferences
public struct Pedagogy: Codable {
    public var style: LearningStyle
    public var preferVideo: Bool
    public var preferText: Bool
    public var preferInteractive: Bool
    public var pace: LearningPace

    public init(
        style: LearningStyle = .examplesFirst,
        preferVideo: Bool = true,
        preferText: Bool = true,
        preferInteractive: Bool = true,
        pace: LearningPace = .moderate
    ) {
        self.style = style
        self.preferVideo = preferVideo
        self.preferText = preferText
        self.preferInteractive = preferInteractive
        self.pace = pace
    }

    public enum LearningPace: String, Codable, CaseIterable {
        case slow = "slow"
        case moderate = "moderate"
        case fast = "fast"

        public var displayName: String {
            rawValue.capitalized
        }
    }
}

public enum AssessmentType: String, Codable {
    case quiz, spaced, project, practice
}

// MARK: - Module Models

/// A module within a course containing multiple lessons
public struct CourseModule: Codable, Identifiable {
    public var id = UUID()
    public var moduleNumber: Int
    public var title: String
    public var description: String
    public var lessons: [Lesson]
    public var estimatedDuration: Int // in minutes
    public var isUnlocked: Bool
    public var progress: Double // 0.0 to 1.0

    public init(
        id: UUID = UUID(),
        moduleNumber: Int,
        title: String,
        description: String,
        lessons: [Lesson] = [],
        estimatedDuration: Int = 30,
        isUnlocked: Bool = true,
        progress: Double = 0.0
    ) {
        self.id = id
        self.moduleNumber = moduleNumber
        self.title = title
        self.description = description
        self.lessons = lessons
        self.estimatedDuration = estimatedDuration
        self.isUnlocked = isUnlocked
        self.progress = progress
    }
}

// MARK: - Lesson Models

/// A single lesson within a module, broken into chunks
public struct Lesson: Codable, Identifiable {
    public var id = UUID()
    public var lessonNumber: Int
    public var title: String
    public var description: String
    public var chunks: [LessonChunk]
    public var estimatedDuration: Int // in minutes
    public var isCompleted: Bool
    public var lastWatchedPosition: TimeInterval
    public var topic: String? // Added for content curation
    public var level: LearningLevel // Added for content curation

    public init(
        id: UUID = UUID(),
        lessonNumber: Int,
        title: String,
        description: String,
        chunks: [LessonChunk] = [],
        estimatedDuration: Int = 10,
        isCompleted: Bool = false,
        lastWatchedPosition: TimeInterval = 0,
        topic: String? = nil,
        level: LearningLevel = .beginner
    ) {
        self.id = id
        self.lessonNumber = lessonNumber
        self.title = title
        self.description = description
        self.chunks = chunks
        self.estimatedDuration = estimatedDuration
        self.isCompleted = isCompleted
        self.lastWatchedPosition = lastWatchedPosition
        self.topic = topic
        self.level = level
    }
}

/// A short segment of a lesson (3-7 minutes)
public struct LessonChunk: Codable, Identifiable {
    public var id = UUID()
    public var chunkNumber: Int
    public var title: String
    public var contentType: ChunkContentType
    public var videoURL: URL?
    public var scriptContent: String?
    public var duration: TimeInterval
    public var quiz: MicroQuiz?
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        chunkNumber: Int,
        title: String,
        contentType: ChunkContentType = .video,
        videoURL: URL? = nil,
        scriptContent: String? = nil,
        duration: TimeInterval = 300,
        quiz: MicroQuiz? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.chunkNumber = chunkNumber
        self.title = title
        self.contentType = contentType
        self.videoURL = videoURL
        self.scriptContent = scriptContent
        self.duration = duration
        self.quiz = quiz
        self.isCompleted = isCompleted
    }
}

public enum ChunkContentType: String, Codable {
    case video, animation, slides, interactive
}

// MARK: - Quiz Models

/// A short quiz between lesson chunks
public struct MicroQuiz: Codable, Identifiable {
    public var id = UUID()
    public var questions: [QuizQuestion]
    public var passThreshold: Double // 0.0 to 1.0
    public var attemptCount: Int

    public init(
        id: UUID = UUID(),
        questions: [QuizQuestion] = [],
        passThreshold: Double = 0.7,
        attemptCount: Int = 0
    ) {
        self.id = id
        self.questions = questions
        self.passThreshold = passThreshold
        self.attemptCount = attemptCount
    }
}

/// A single quiz question
public struct QuizQuestion: Codable, Identifiable {
    public var id = UUID()
    public var question: String
    public var answers: [String]
    public var correctAnswerIndex: Int
    public var explanation: String
    public var difficulty: QuestionDifficulty

    public init(
        id: UUID = UUID(),
        question: String,
        answers: [String],
        correctAnswerIndex: Int,
        explanation: String = "",
        difficulty: QuestionDifficulty = .easy
    ) {
        self.id = id
        self.question = question
        self.answers = answers
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
        self.difficulty = difficulty
    }

    public enum QuestionDifficulty: String, Codable {
        case easy, medium, hard
    }
}

// MARK: - Content Card Models

/// External curated content (videos, ebooks, articles)
public struct ContentCard: Codable, Identifiable {
    public var id = UUID()
    public var kind: CardKind
    public var title: String
    public var source: String
    public var url: URL
    public var estMinutes: Int
    public var tags: [String]
    public var summary: String
    public var citation: String
    public var thumbnailURL: URL?
    public var relevanceScore: Double // 0.0 to 1.0
    public var isSaved: Bool

    public init(
        id: UUID = UUID(),
        kind: CardKind,
        title: String,
        source: String,
        url: URL,
        estMinutes: Int,
        tags: [String] = [],
        summary: String,
        citation: String,
        thumbnailURL: URL? = nil,
        relevanceScore: Double = 0.5,
        isSaved: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.source = source
        self.url = url
        self.estMinutes = estMinutes
        self.tags = tags
        self.summary = summary
        self.citation = citation
        self.thumbnailURL = thumbnailURL
        self.relevanceScore = relevanceScore
        self.isSaved = isSaved
    }
}

public enum CardKind: String, Codable, CaseIterable {
    case video, ebook, article, exercise, infographic, dataset, podcast

    public var iconName: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .ebook: return "book.fill"
        case .article: return "doc.text.fill"
        case .exercise: return "pencil.and.list.clipboard"
        case .infographic: return "chart.bar.doc.horizontal"
        case .dataset: return "tablecells.fill"
        case .podcast: return "waveform"
        }
    }

    public var color: Color {
        switch self {
        case .video: return .red
        case .ebook: return .orange
        case .article: return .blue
        case .exercise: return .green
        case .infographic: return .purple
        case .dataset: return .cyan
        case .podcast: return .pink
        }
    }
}

// MARK: - Progress & State Models

/// User's progress through a course
public struct CourseProgress: Codable, Identifiable {
    public var id = UUID()
    public var courseId: UUID
    public var overallProgress: Double // 0.0 to 1.0
    public var currentModuleId: UUID?
    public var currentLessonId: UUID?
    public var totalTimeSpent: TimeInterval
    public var lastAccessedAt: Date
    public var milestones: [ProgressMilestone]
    public var completedLessons: [UUID]
    public var quizScores: [UUID: Double] // lessonId: score

    public init(
        id: UUID = UUID(),
        courseId: UUID,
        overallProgress: Double = 0.0,
        currentModuleId: UUID? = nil,
        currentLessonId: UUID? = nil,
        totalTimeSpent: TimeInterval = 0,
        lastAccessedAt: Date = Date(),
        milestones: [ProgressMilestone] = [],
        completedLessons: [UUID] = [],
        quizScores: [UUID: Double] = [:]
    ) {
        self.id = id
        self.courseId = courseId
        self.overallProgress = overallProgress
        self.currentModuleId = currentModuleId
        self.currentLessonId = currentLessonId
        self.totalTimeSpent = totalTimeSpent
        self.lastAccessedAt = lastAccessedAt
        self.milestones = milestones
        self.completedLessons = completedLessons
        self.quizScores = quizScores
    }
}

/// A milestone achievement in a course
public struct ProgressMilestone: Codable, Identifiable {
    public var id = UUID()
    public var title: String
    public var progressPercentage: Double
    public var isCompleted: Bool
    public var unlockedAt: Date?
    public var badgeIconName: String

    public init(
        id: UUID = UUID(),
        title: String,
        progressPercentage: Double,
        isCompleted: Bool = false,
        unlockedAt: Date? = nil,
        badgeIconName: String = "star.fill"
    ) {
        self.id = id
        self.title = title
        self.progressPercentage = progressPercentage
        self.isCompleted = isCompleted
        self.unlockedAt = unlockedAt
        self.badgeIconName = badgeIconName
    }
}

// MARK: - Lesson Note Models

/// A note taken during a lesson
public struct LessonNote: Codable, Identifiable {
    public var id = UUID()
    public var lessonId: UUID
    public var timestamp: TimeInterval
    public var content: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        lessonId: UUID,
        timestamp: TimeInterval,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.lessonId = lessonId
        self.timestamp = timestamp
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Classroom State Models

/// Current state of the classroom view
public struct ClassroomViewState {
    public var orientation: ClassroomOrientation
    public var playbackState: PlaybackState
    public var controlsVisible: Bool
    public var selectedContentCard: ContentCard?
    public var showingQuiz: Bool
    public var currentChunkIndex: Int
    public var avatarMood: AvatarMood

    public init(
        orientation: ClassroomOrientation = .horizontal,
        playbackState: PlaybackState = .paused,
        controlsVisible: Bool = true,
        selectedContentCard: ContentCard? = nil,
        showingQuiz: Bool = false,
        currentChunkIndex: Int = 0,
        avatarMood: AvatarMood = .friendly
    ) {
        self.orientation = orientation
        self.playbackState = playbackState
        self.controlsVisible = controlsVisible
        self.selectedContentCard = selectedContentCard
        self.showingQuiz = showingQuiz
        self.currentChunkIndex = currentChunkIndex
        self.avatarMood = avatarMood
    }

    public enum ClassroomOrientation {
        case horizontal, vertical
    }

    public enum PlaybackState {
        case playing, paused, loading, completed
    }
}

// MARK: - Mock Data Helpers

extension ClassroomCourse {
    static var mockCourse: ClassroomCourse {
        ClassroomCourse(
            title: "Introduction to Swift Programming",
            description: "Learn the fundamentals of Swift programming language from scratch. Perfect for beginners!",
            scope: "Covers Swift basics, data types, control flow, functions, and basic OOP concepts",
            level: .beginner,
            outcomes: [
                "Understand Swift syntax and fundamentals",
                "Write basic Swift programs",
                "Use control flow and functions",
                "Grasp object-oriented programming basics"
            ],
            modules: [
                .mockModule1,
                .mockModule2
            ],
            estimatedDuration: 120
        )
    }
}

extension CourseModule {
    static var mockModule1: CourseModule {
        CourseModule(
            moduleNumber: 1,
            title: "Getting Started with Swift",
            description: "Introduction to Swift programming language and basic concepts",
            lessons: [
                .mockLesson1
            ],
            estimatedDuration: 30,
            isUnlocked: true
        )
    }

    static var mockModule2: CourseModule {
        CourseModule(
            moduleNumber: 2,
            title: "Swift Fundamentals",
            description: "Deep dive into Swift data types and control flow",
            lessons: [],
            estimatedDuration: 40,
            isUnlocked: false
        )
    }
}

extension Lesson {
    static var mockLesson1: Lesson {
        Lesson(
            lessonNumber: 1,
            title: "Welcome to Swift",
            description: "Your first steps into the Swift programming language",
            chunks: [
                .mockChunk1,
                .mockChunk2
            ],
            estimatedDuration: 10
        )
    }
}

extension LessonChunk {
    static var mockChunk1: LessonChunk {
        LessonChunk(
            chunkNumber: 1,
            title: "What is Swift?",
            contentType: .video,
            scriptContent: "Swift is a powerful and intuitive programming language created by Apple...",
            duration: 280,
            quiz: .mockQuiz
        )
    }

    static var mockChunk2: LessonChunk {
        LessonChunk(
            chunkNumber: 2,
            title: "Setting Up Your Environment",
            contentType: .video,
            scriptContent: "Let's set up Xcode and create your first Swift playground...",
            duration: 300
        )
    }
}

extension MicroQuiz {
    static var mockQuiz: MicroQuiz {
        MicroQuiz(
            questions: [
                QuizQuestion(
                    question: "What company created Swift?",
                    answers: ["Apple", "Google", "Microsoft", "Facebook"],
                    correctAnswerIndex: 0,
                    explanation: "Swift was created by Apple in 2014 as a replacement for Objective-C."
                ),
                QuizQuestion(
                    question: "Is Swift a compiled or interpreted language?",
                    answers: ["Interpreted", "Compiled", "Both", "Neither"],
                    correctAnswerIndex: 1,
                    explanation: "Swift is a compiled language, which means it's converted to machine code before running."
                )
            ]
        )
    }
}

extension ContentCard {
    static var mockCards: [ContentCard] {
        [
            ContentCard(
                kind: .video,
                title: "Swift in 100 Seconds",
                source: "YouTube - Fireship",
                url: URL(string: "https://youtu.be/nAchMctX4YA")!,
                estMinutes: 2,
                tags: ["swift", "introduction", "quick"],
                summary: "A super quick overview of Swift programming language",
                citation: "Fireship (2021). Swift in 100 Seconds. YouTube.",
                relevanceScore: 0.95
            ),
            ContentCard(
                kind: .article,
                title: "Swift Documentation",
                source: "Apple Developer",
                url: URL(string: "https://docs.swift.org")!,
                estMinutes: 30,
                tags: ["swift", "documentation", "official"],
                summary: "Official Swift programming language documentation from Apple",
                citation: "Apple Inc. (2024). The Swift Programming Language. Apple Developer.",
                relevanceScore: 0.9
            ),
            ContentCard(
                kind: .exercise,
                title: "Swift Basics Practice",
                source: "Exercism",
                url: URL(string: "https://exercism.org/tracks/swift")!,
                estMinutes: 45,
                tags: ["swift", "practice", "exercises"],
                summary: "Interactive coding exercises to practice Swift fundamentals",
                citation: "Exercism (2024). Swift Track. Exercism.org.",
                relevanceScore: 0.85
            )
        ]
    }
}
