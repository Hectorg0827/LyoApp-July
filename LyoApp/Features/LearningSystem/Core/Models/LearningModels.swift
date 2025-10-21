import Foundation

// MARK: - Knowledge Component

struct KnowledgeComponent: Codable, Identifiable {
    let id: UUID
    let slug: String
    let title: String
    let description: String?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, slug, title, description, tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Learning Objective

struct LearningObjective: Codable, Identifiable {
    let id: UUID
    let kcId: UUID
    let verb: String
    let context: String?
    let difficulty: Int
    let rubric: [String: AnyCodable]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, verb, context, difficulty, rubric
        case kcId = "kc_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - ALO Type

enum ALOType: String, Codable {
    case explain
    case example
    case exercise
    case quiz
    case project

    var displayName: String {
        switch self {
        case .explain: return "Explanation"
        case .example: return "Example"
        case .exercise: return "Exercise"
        case .quiz: return "Quiz"
        case .project: return "Project"
        }
    }

    var iconName: String {
        switch self {
        case .explain: return "book.fill"
        case .example: return "lightbulb.fill"
        case .exercise: return "pencil.and.outline"
        case .quiz: return "questionmark.circle.fill"
        case .project: return "hammer.fill"
        }
    }

    var color: String {
        switch self {
        case .explain: return "blue"
        case .example: return "purple"
        case .exercise: return "orange"
        case .quiz: return "green"
        case .project: return "red"
        }
    }
}

// MARK: - ALO Content Types

struct ExplainContent: Codable {
    let markdown: String
    let assetUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case markdown
        case assetUrls = "asset_urls"
    }
}

struct ExampleContent: Codable {
    let markdown: String
    let code: String?
    let language: String?
    let assetUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case markdown, code, language
        case assetUrls = "asset_urls"
    }
}

struct ExerciseContent: Codable {
    let prompt: String
    let starterCode: String?
    let language: String?
    let inputs: [String: AnyCodable]?
    let hints: [String]?

    enum CodingKeys: String, CodingKey {
        case prompt, language, inputs, hints
        case starterCode = "starter_code"
    }
}

struct QuizContent: Codable {
    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case question, choices, explanation
        case answerIndex = "answer_index"
    }
}

struct ProjectContent: Codable {
    let brief: String
    let acceptanceTests: [String]
    let rubric: [String: AnyCodable]
    let starterFiles: [String: String]?
    let resources: [String]?

    enum CodingKeys: String, CodingKey {
        case brief, rubric, resources
        case acceptanceTests = "acceptance_tests"
        case starterFiles = "starter_files"
    }
}

// MARK: - ALO

struct ALO: Codable, Identifiable {
    let id: UUID
    let loId: UUID
    let aloType: ALOType
    let estTimeSec: Int
    let content: [String: AnyCodable]
    let assessmentSpec: [String: AnyCodable]?
    let difficulty: Int
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, difficulty, tags, content
        case loId = "lo_id"
        case aloType = "alo_type"
        case estTimeSec = "est_time_sec"
        case assessmentSpec = "assessment_spec"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Convenience accessors
    var explainContent: ExplainContent? {
        try? JSONDecoder().decode(ExplainContent.self, from: JSONSerialization.data(withJSONObject: content.mapValues { $0.value }))
    }

    var exampleContent: ExampleContent? {
        try? JSONDecoder().decode(ExampleContent.self, from: JSONSerialization.data(withJSONObject: content.mapValues { $0.value }))
    }

    var exerciseContent: ExerciseContent? {
        try? JSONDecoder().decode(ExerciseContent.self, from: JSONSerialization.data(withJSONObject: content.mapValues { $0.value }))
    }

    var quizContent: QuizContent? {
        try? JSONDecoder().decode(QuizContent.self, from: JSONSerialization.data(withJSONObject: content.mapValues { $0.value }))
    }

    var projectContent: ProjectContent? {
        try? JSONDecoder().decode(ProjectContent.self, from: JSONSerialization.data(withJSONObject: content.mapValues { $0.value }))
    }
}

// MARK: - Skill Graph

struct SkillGraph: Codable {
    let kcs: [KnowledgeComponent]
    let edges: [[String: UUID]]
    let los: [LearningObjective]
    let alos: [ALO]
}

// MARK: - Course

struct Course: Codable, Identifiable {
    let id: UUID
    let goal: String
    let skillGraph: SkillGraph
    let schedule: [SessionScheduleItem]
    let estimatedTotalTimeMin: Int

    enum CodingKeys: String, CodingKey {
        case id, goal, schedule
        case skillGraph = "skill_graph"
        case estimatedTotalTimeMin = "estimated_total_time_min"
    }
}

struct SessionScheduleItem: Codable {
    let day: Int
    let session: [String: [String]]

    var aloIds: [UUID] {
        (session["alo_ids"] ?? []).compactMap { UUID(uuidString: $0) }
    }
}

// MARK: - Session

struct LearningSession: Codable, Identifiable {
    let id: UUID
    let courseId: UUID
    let startedAt: Date
    let status: SessionStatus

    enum CodingKeys: String, CodingKey {
        case id, status
        case courseId = "course_id"
        case startedAt = "started_at"
    }
}

enum SessionStatus: String, Codable {
    case active
    case ended
}

// MARK: - Mastery & Progress

struct MasteryEstimate: Codable, Identifiable {
    let id = UUID()
    let kcId: UUID
    let kcSlug: String
    let theta: Double
    let attemptsCount: Int
    let correctCount: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case theta
        case kcId = "kc_id"
        case kcSlug = "kc_slug"
        case attemptsCount = "attempts_count"
        case correctCount = "correct_count"
        case updatedAt = "updated_at"
    }

    var percentage: Int {
        Int(theta * 100)
    }

    var level: MasteryLevel {
        switch theta {
        case 0..<0.25: return .beginner
        case 0.25..<0.5: return .learning
        case 0.5..<0.75: return .competent
        case 0.75..<0.9: return .proficient
        default: return .expert
        }
    }
}

enum MasteryLevel {
    case beginner, learning, competent, proficient, expert

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .learning: return "Learning"
        case .competent: return "Competent"
        case .proficient: return "Proficient"
        case .expert: return "Expert"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "gray"
        case .learning: return "blue"
        case .competent: return "green"
        case .proficient: return "orange"
        case .expert: return "purple"
        }
    }
}

struct ReviewQueueItem: Codable, Identifiable {
    let id = UUID()
    let aloId: UUID
    let nextDue: Date
    let intervalDays: Int
    let reps: Int

    enum CodingKeys: String, CodingKey {
        case intervalDays = "interval_days"
        case nextDue = "next_due"
        case aloId = "alo_id"
        case reps
    }

    var isDue: Bool {
        nextDue <= Date()
    }

    var dueIn: String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: nextDue)
        if let days = components.day, days > 0 {
            return "in \(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "in \(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "now"
        }
    }
}

struct Progress: Codable {
    let thetaByKc: [String: Double]
    let streak: Int
    let reviewQueue: [ReviewQueueItem]

    enum CodingKeys: String, CodingKey {
        case streak
        case thetaByKc = "theta_by_kc"
        case reviewQueue = "review_queue"
    }
}

// MARK: - WebSocket Messages

enum WebSocketMessage {
    case alo(ALO)
    case next(ALO?, String?)
    case end([String: Any])
    case error(String)
}

struct ALOMessageResponse: Codable {
    let type: String
    let alo: ALO
}

struct NextMessageResponse: Codable {
    let type: String
    let alo: ALO?
    let reason: String?
}

struct SessionEndMessageResponse: Codable {
    let type: String
    let summary: [String: AnyCodable]
}

struct SignalMessageRequest: Codable {
    let type: String = "signal"
    let aloId: UUID
    let event: String
    let correct: Bool?
    let latencyMs: Int?
    let hintsUsed: Int
    let payload: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case type, event, correct, payload
        case aloId = "alo_id"
        case latencyMs = "latency_ms"
        case hintsUsed = "hints_used"
    }
}

// MARK: - Evidence Submission

struct EvidenceArtifact: Codable {
    let type: String
    let value: String
    let metadata: [String: AnyCodable]?
}

struct CheckResult: Codable {
    let name: String
    let passed: Bool
    let message: String?
}

struct SubmitEvidenceRequest: Codable {
    let aloId: UUID
    let artifacts: [EvidenceArtifact]
    let checks: [CheckResult]

    enum CodingKeys: String, CodingKey {
        case artifacts, checks
        case aloId = "alo_id"
    }
}

struct SubmitEvidenceResponse: Codable {
    let passed: Bool
    let feedback: String
    let thetaUpdated: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case passed, feedback
        case thetaUpdated = "theta_updated"
    }
}

// MARK: - Helper: AnyCodable

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
