import Foundation

// MARK: - Course Builder Models
// These models are specifically for the course creation wizard and complement CourseModels.swift

/// Extended course information captured during course builder wizard
struct CourseBlueprint: Codable, Identifiable {
    var id = UUID()
    var topic: String
    var scope: String // Brief description of what's covered
    var level: CourseLevel
    var outcomes: [String] = []
    var schedule: StudySchedule
    var pedagogy: TeachingStyle
    var assessments: [AssessmentPreference] = []
    var resourcesEnabled: Bool = true
    var createdDate: Date = Date()
    
    // Avatar personality influences default pedagogy
    init(
        topic: String = "",
        scope: String = "",
        level: CourseLevel = .beginner,
        schedule: StudySchedule = StudySchedule(),
        pedagogy: TeachingStyle = .balanced,
        avatarPersonality: Personality? = nil
    ) {
        self.topic = topic
        self.scope = scope
        self.level = level
        self.schedule = schedule
        
        // Map avatar personality to teaching style
        if let personality = avatarPersonality {
            self.pedagogy = TeachingStyle.fromPersonality(personality)
        } else {
            self.pedagogy = pedagogy
        }
    }
}

// MARK: - Course Level

enum CourseLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var description: String {
        switch self {
        case .beginner: return "Just starting out"
        case .intermediate: return "Some background knowledge"
        case .advanced: return "Deep dive & mastery"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🚀"
        case .advanced: return "🎯"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "purple"
        }
    }
}

// MARK: - Study Schedule

struct StudySchedule: Codable, Hashable {
    var minutesPerDay: Int = 30
    var daysPerWeek: Int = 5
    var startDate: Date = Date()
    var preferredTime: PreferredTime = .evening
    var pacePreference: Pace = .balanced
    
    var totalMinutesPerWeek: Int {
        minutesPerDay * daysPerWeek
    }
    
    var formattedSchedule: String {
        "\(minutesPerDay) min/day, \(daysPerWeek) days/week"
    }
}

enum PreferredTime: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case flexible = "Flexible"
    
    var emoji: String {
        switch self {
        case .morning: return "🌅"
        case .afternoon: return "☀️"
        case .evening: return "🌙"
        case .flexible: return "⏰"
        }
    }
    
    var description: String {
        switch self {
        case .morning: return "6 AM - 12 PM"
        case .afternoon: return "12 PM - 6 PM"
        case .evening: return "6 PM - 11 PM"
        case .flexible: return "Anytime"
        }
    }
}

enum Pace: String, Codable, CaseIterable {
    case gentle = "Gentle"
    case balanced = "Balanced"
    case intensive = "Intensive"
    
    var description: String {
        switch self {
        case .gentle: return "Take it slow, lots of review"
        case .balanced: return "Steady progress with check-ins"
        case .intensive: return "Fast-paced, push my limits"
        }
    }
    
    var emoji: String {
        switch self {
        case .gentle: return "🐢"
        case .balanced: return "🚶"
        case .intensive: return "🏃"
        }
    }
}

// MARK: - Teaching Style (Pedagogy)

enum TeachingStyle: String, Codable, CaseIterable {
    case examplesFirst = "Examples First"
    case theoryFirst = "Theory First"
    case projectBased = "Project-Based"
    case balanced = "Balanced Mix"
    
    var description: String {
        switch self {
        case .examplesFirst: return "Learn by doing, then understand why"
        case .theoryFirst: return "Understand concepts, then practice"
        case .projectBased: return "Build real things while learning"
        case .balanced: return "Mix theory, examples, and practice"
        }
    }
    
    var emoji: String {
        switch self {
        case .examplesFirst: return "💡"
        case .theoryFirst: return "📚"
        case .projectBased: return "🛠️"
        case .balanced: return "⚖️"
        }
    }
    
    var icon: String {
        switch self {
        case .examplesFirst: return "lightbulb.fill"
        case .theoryFirst: return "book.fill"
        case .projectBased: return "hammer.fill"
        case .balanced: return "scale.3d"
        }
    }
    
    // Map avatar personality to default teaching style
    static func fromPersonality(_ personality: Personality) -> TeachingStyle {
        switch personality {
        case .friendlyCurious: // Lyo
            return .balanced
        case .energeticCoach: // Max
            return .examplesFirst
        case .calmReflective: // Luna
            return .theoryFirst
        case .wisePatient: // Sage
            return .theoryFirst
        }
    }
    
    // Preferred card kinds for each teaching style
    var preferredCardKinds: [CardKind] {
        switch self {
        case .examplesFirst:
            return [.video, .exercise, .infographic]
        case .theoryFirst:
            return [.ebook, .article, .infographic]
        case .projectBased:
            return [.exercise, .dataset, .video]
        case .balanced:
            return [.video, .article, .exercise]
        }
    }
}

// MARK: - Assessment Preferences

enum AssessmentPreference: String, Codable, CaseIterable {
    case quiz = "Quick Quizzes"
    case spaced = "Spaced Repetition"
    case project = "Projects"
    case reflection = "Reflections"
    
    var description: String {
        switch self {
        case .quiz: return "Test understanding after each module"
        case .spaced: return "Review material at optimal intervals"
        case .project: return "Apply learning to real projects"
        case .reflection: return "Journal and self-assess"
        }
    }
    
    var emoji: String {
        switch self {
        case .quiz: return "✍️"
        case .spaced: return "🔄"
        case .project: return "🎨"
        case .reflection: return "💭"
        }
    }
    
    var icon: String {
        switch self {
        case .quiz: return "checkmark.circle.fill"
        case .spaced: return "arrow.triangle.2.circlepath"
        case .project: return "folder.fill"
        case .reflection: return "text.bubble.fill"
        }
    }
}

// MARK: - Course Store (Persistence)

@MainActor
final class CourseStore: ObservableObject {
    static let shared = CourseStore()
    
    @Published var currentBlueprint: CourseBlueprint?
    @Published var activeCourse: CourseOutlineLocal?
    @Published var userSignals = UserSignals()
    @Published var savedNotes: [SessionNote] = []
    @Published var isGenerating = false
    
    private let blueprintKey = "course_blueprint.json"
    private let notesKey = "course_notes.json"
    private let signalsKey = "user_signals.json"
    
    private init() {
        load()
    }
    
    // MARK: - Persistence
    
    func load() {
        currentBlueprint = loadFromDisk(key: blueprintKey)
        savedNotes = loadFromDisk(key: notesKey) ?? []
        userSignals = loadFromDisk(key: signalsKey) ?? UserSignals()
    }
    
    func save() {
        saveToDisk(currentBlueprint, key: blueprintKey)
        saveToDisk(savedNotes, key: notesKey)
        saveToDisk(userSignals, key: signalsKey)
    }
    
    func completeBlueprint(with blueprint: CourseBlueprint) {
        currentBlueprint = blueprint
        save()
    }
    
    func saveNote(_ note: SessionNote) {
        savedNotes.append(note)
        save()
    }
    
    func updateUserSignals(_ signals: UserSignals) {
        userSignals = signals
        save()
    }
    
    private func loadFromDisk<T: Codable>(key: String) -> T? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(key)
        
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        
        return decoded
    }
    
    private func saveToDisk<T: Codable>(_ object: T?, key: String) {
        guard let object = object else { return }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(key)
        
        guard let data = try? JSONEncoder().encode(object) else { return }
        try? data.write(to: fileURL)
    }
}
