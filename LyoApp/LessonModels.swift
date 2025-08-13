import Foundation

// MARK: - Lesson Content Data Models
// These models define the structure for dynamic AI-generated lesson content
// that can be rendered by the AI Classroom UI components

/// Main lesson content structure
struct LessonContent: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let blocks: [LessonBlock]
    let metadata: LessonMetadata
    
    init(id: UUID = UUID(), title: String, description: String, blocks: [LessonBlock], metadata: LessonMetadata) {
        self.id = id
        self.title = title
        self.description = description
        self.blocks = blocks
        self.metadata = metadata
    }
}

/// Individual content block within a lesson
struct LessonBlock: Codable, Identifiable {
    let id: UUID
    let type: LessonBlockType
    let data: BlockData
    let order: Int
    
    init(id: UUID = UUID(), type: LessonBlockType, data: BlockData, order: Int) {
        self.id = id
        self.type = type
        self.data = data
        self.order = order
    }
}

/// Types of content blocks supported by the AI Classroom
enum LessonBlockType: String, Codable, CaseIterable {
    case heading = "heading"
    case paragraph = "paragraph"
    case bulletList = "bullet_list"
    case numberedList = "numbered_list"
    case image = "image"
    case video = "video"
    case codeBlock = "code_block"
    case quote = "quote"
    case callout = "callout"
    case divider = "divider"
    case youtube = "youtube"
    case interactiveElement = "interactive_element"
    case quiz = "quiz"
    case diagram = "diagram"
    case table = "table"
    case spacer = "spacer"
}

/// Union type for block data - contains the actual content for each block type
enum BlockData: Codable {
    case heading(HeadingData)
    case paragraph(ParagraphData)
    case bulletList(BulletListData)
    case numberedList(NumberedListData)
    case image(ImageData)
    case video(VideoData)
    case codeBlock(CodeBlockData)
    case quote(QuoteData)
    case callout(CalloutData)
    case divider(DividerData)
    case youtube(YouTubeData)
    case interactiveElement(InteractiveElementData)
    case quiz(QuizData)
    case diagram(DiagramData)
    case table(TableData)
    case spacer(SpacerData)
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    // MARK: - Decodable Implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "heading":
            let data = try container.decode(HeadingData.self, forKey: .data)
            self = .heading(data)
        case "paragraph":
            let data = try container.decode(ParagraphData.self, forKey: .data)
            self = .paragraph(data)
        case "bullet_list":
            let data = try container.decode(BulletListData.self, forKey: .data)
            self = .bulletList(data)
        case "numbered_list":
            let data = try container.decode(NumberedListData.self, forKey: .data)
            self = .numberedList(data)
        case "image":
            let data = try container.decode(ImageData.self, forKey: .data)
            self = .image(data)
        case "video":
            let data = try container.decode(VideoData.self, forKey: .data)
            self = .video(data)
        case "code_block":
            let data = try container.decode(CodeBlockData.self, forKey: .data)
            self = .codeBlock(data)
        case "quote":
            let data = try container.decode(QuoteData.self, forKey: .data)
            self = .quote(data)
        case "callout":
            let data = try container.decode(CalloutData.self, forKey: .data)
            self = .callout(data)
        case "divider":
            let data = try container.decode(DividerData.self, forKey: .data)
            self = .divider(data)
        case "youtube":
            let data = try container.decode(YouTubeData.self, forKey: .data)
            self = .youtube(data)
        case "interactive_element":
            let data = try container.decode(InteractiveElementData.self, forKey: .data)
            self = .interactiveElement(data)
        case "quiz":
            let data = try container.decode(QuizData.self, forKey: .data)
            self = .quiz(data)
        case "diagram":
            let data = try container.decode(DiagramData.self, forKey: .data)
            self = .diagram(data)
        case "table":
            let data = try container.decode(TableData.self, forKey: .data)
            self = .table(data)
        case "spacer":
            let data = try container.decode(SpacerData.self, forKey: .data)
            self = .spacer(data)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown block type: \(type)")
        }
    }
    
    // MARK: - Encodable Implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .heading(let data):
            try container.encode("heading", forKey: .type)
            try container.encode(data, forKey: .data)
        case .paragraph(let data):
            try container.encode("paragraph", forKey: .type)
            try container.encode(data, forKey: .data)
        case .bulletList(let data):
            try container.encode("bullet_list", forKey: .type)
            try container.encode(data, forKey: .data)
        case .numberedList(let data):
            try container.encode("numbered_list", forKey: .type)
            try container.encode(data, forKey: .data)
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .data)
        case .video(let data):
            try container.encode("video", forKey: .type)
            try container.encode(data, forKey: .data)
        case .codeBlock(let data):
            try container.encode("code_block", forKey: .type)
            try container.encode(data, forKey: .data)
        case .quote(let data):
            try container.encode("quote", forKey: .type)
            try container.encode(data, forKey: .data)
        case .callout(let data):
            try container.encode("callout", forKey: .type)
            try container.encode(data, forKey: .data)
        case .divider(let data):
            try container.encode("divider", forKey: .type)
            try container.encode(data, forKey: .data)
        case .youtube(let data):
            try container.encode("youtube", forKey: .type)
            try container.encode(data, forKey: .data)
        case .interactiveElement(let data):
            try container.encode("interactive_element", forKey: .type)
            try container.encode(data, forKey: .data)
        case .quiz(let data):
            try container.encode("quiz", forKey: .type)
            try container.encode(data, forKey: .data)
        case .diagram(let data):
            try container.encode("diagram", forKey: .type)
            try container.encode(data, forKey: .data)
        case .table(let data):
            try container.encode("table", forKey: .type)
            try container.encode(data, forKey: .data)
        case .spacer(let data):
            try container.encode("spacer", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}

// MARK: - Block Data Structures

struct HeadingData: Codable {
    let text: String
    let level: Int // 1-6 for h1-h6
    let style: HeadingStyle?
    
    enum HeadingStyle: String, Codable {
        case normal = "normal"
        case emphasized = "emphasized"
        case subtitle = "subtitle"
    }
}

struct ParagraphData: Codable {
    let text: String
    let style: ParagraphStyle?
    
    enum ParagraphStyle: String, Codable {
        case normal = "normal"
        case emphasized = "emphasized"
        case muted = "muted"
        case centered = "centered"
    }
}

struct BulletListData: Codable {
    let items: [ListItem]
    let style: ListStyle?
    
    enum ListStyle: String, Codable {
        case bullet = "bullet"
        case dash = "dash"
        case checkmark = "checkmark"
    }
}

struct NumberedListData: Codable {
    let items: [ListItem]
    let startNumber: Int?
    let style: NumberedListStyle?
    
    enum NumberedListStyle: String, Codable {
        case decimal = "decimal"
        case roman = "roman"
        case letter = "letter"
    }
}

struct ListItem: Codable {
    let text: String
    let subItems: [ListItem]?
}

struct ImageData: Codable {
    let url: String
    let altText: String
    let caption: String?
    let width: CGFloat?
    let height: CGFloat?
    let alignment: ImageAlignment?
    
    enum ImageAlignment: String, Codable {
        case left = "left"
        case center = "center"
        case right = "right"
    }
}

struct VideoData: Codable {
    let url: String
    let title: String
    let description: String?
    let thumbnailUrl: String?
    let duration: TimeInterval?
    let autoplay: Bool?
}

struct CodeBlockData: Codable {
    let code: String
    let language: String?
    let title: String?
    let showLineNumbers: Bool?
    let highlightedLines: [Int]?
}

struct QuoteData: Codable {
    let text: String
    let author: String?
    let source: String?
    let style: QuoteStyle?
    
    enum QuoteStyle: String, Codable {
        case normal = "normal"
        case emphasized = "emphasized"
        case inspirational = "inspirational"
    }
}

struct CalloutData: Codable {
    let text: String
    let type: CalloutType
    let title: String?
    let icon: String?
    
    enum CalloutType: String, Codable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case success = "success"
        case tip = "tip"
    }
}

struct DividerData: Codable {
    let style: DividerStyle?
    let spacing: CGFloat?
    
    enum DividerStyle: String, Codable {
        case line = "line"
        case dotted = "dotted"
        case thick = "thick"
        case decorative = "decorative"
    }
}

struct YouTubeData: Codable {
    let videoId: String
    let title: String
    let description: String?
    let startTime: TimeInterval?
    let endTime: TimeInterval?
}

struct InteractiveElementData: Codable {
    let type: InteractiveType
    let content: String
    let config: [String: String]?
    
    enum InteractiveType: String, Codable {
        case button = "button"
        case slider = "slider"
        case toggleSwitch = "toggle_switch"
        case textInput = "text_input"
        case multipleChoice = "multiple_choice"
        case dragAndDrop = "drag_and_drop"
        case codeEditor = "code_editor"
    }
}

struct QuizData: Codable {
    let questions: [QuizQuestion]
    let title: String?
    let description: String?
    let showResults: Bool?
}

struct QuizQuestion: Codable, Identifiable {
    let id: UUID
    let question: String
    let type: QuizQuestionType
    let options: [QuizOption]?
    let correctAnswer: String
    let explanation: String?
    let points: Int?
    
    init(id: UUID = UUID(), question: String, type: QuizQuestionType, options: [QuizOption]? = nil, correctAnswer: String, explanation: String? = nil, points: Int? = nil) {
        self.id = id
        self.question = question
        self.type = type
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.points = points
    }
}

struct QuizOption: Codable, Identifiable {
    let id: UUID
    let text: String
    let isCorrect: Bool
    
    init(id: UUID = UUID(), text: String, isCorrect: Bool) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
    }
}

enum QuizQuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"
    case shortAnswer = "short_answer"
    case essay = "essay"
    case fillInTheBlank = "fill_in_the_blank"
}

struct DiagramData: Codable {
    let type: DiagramType
    let content: String
    let title: String?
    let description: String?
    let style: DiagramStyle?
    
    enum DiagramType: String, Codable {
        case flowchart = "flowchart"
        case mindMap = "mind_map"
        case timeline = "timeline"
        case orgChart = "org_chart"
        case processFlow = "process_flow"
    }
    
    enum DiagramStyle: String, Codable {
        case minimal = "minimal"
        case detailed = "detailed"
        case colorful = "colorful"
    }
}

struct TableData: Codable {
    let headers: [String]
    let rows: [[String]]
    let title: String?
    let style: TableStyle?
    
    enum TableStyle: String, Codable {
        case basic = "basic"
        case striped = "striped"
        case bordered = "bordered"
    }
}

struct SpacerData: Codable {
    let height: CGFloat
}

// MARK: - Lesson Metadata

struct LessonMetadata: Codable {
    let difficulty: DifficultyLevel
    let estimatedDuration: TimeInterval // in seconds
    let tags: [String]
    let prerequisites: [String]
    let learningObjectives: [String]
    let createdAt: Date
    let lastModified: Date
    let version: String
    let language: String
    let accessibility: AccessibilityInfo?
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "#4CAF50"
        case .intermediate: return "#FF9800"
        case .advanced: return "#F44336"
        case .expert: return "#9C27B0"
        }
    }
}

struct AccessibilityInfo: Codable {
    let hasAltText: Bool
    let hasTranscripts: Bool
    let hasSubtitles: Bool
    let readingLevel: ReadingLevel?
    let colorContrast: ColorContrast?
}

enum ReadingLevel: String, Codable {
    case elementary = "elementary"
    case middle = "middle"
    case high = "high"
    case college = "college"
}

enum ColorContrast: String, Codable {
    case aa = "aa"
    case aaa = "aaa"
}

// MARK: - Sample Data Removed and Utilities

extension LessonContent {
    // MARK: - Sample Data Removed
    // Sample lesson function removed - use UserDataManager for real lesson content
    // static func sampleLesson() -> LessonContent { ... } // Use UserDataManager.shared.getLessons()
}

// MARK: - Extensions for SwiftUI Integration

extension LessonBlock {
    /// Get the display name for this block type
    var displayName: String {
        switch type {
        case .heading: return "Heading"
        case .paragraph: return "Paragraph"
        case .bulletList: return "Bullet List"
        case .numberedList: return "Numbered List"
        case .image: return "Image"
        case .video: return "Video"
        case .codeBlock: return "Code Block"
        case .quote: return "Quote"
        case .callout: return "Callout"
        case .divider: return "Divider"
        case .youtube: return "YouTube Video"
        case .interactiveElement: return "Interactive Element"
        case .quiz: return "Quiz"
        case .diagram: return "Diagram"
        case .table: return "Table"
        case .spacer: return "Spacer"
        }
    }
    
    /// Get the SF Symbol icon for this block type
    var icon: String {
        switch type {
        case .heading: return "textformat.size"
        case .paragraph: return "doc.text"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .image: return "photo"
        case .video: return "play.rectangle"
        case .codeBlock: return "curlybraces"
        case .quote: return "quote.bubble"
        case .callout: return "exclamationmark.triangle"
        case .divider: return "minus"
        case .youtube: return "play.rectangle.fill"
        case .interactiveElement: return "hand.tap"
        case .quiz: return "questionmark.circle"
        case .diagram: return "flowchart"
        case .table: return "tablecells"
        case .spacer: return "space"
        }
    }
}

// MARK: - JSON Parsing Utilities

extension LessonContent {
    /// Parse lesson content from JSON data
    static func from(jsonData: Data) throws -> LessonContent {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LessonContent.self, from: jsonData)
    }
    
    /// Convert lesson content to JSON data
    func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }
}
