import Foundation
import Combine

/// Complete API service for the Learning System
/// Leverages ALL backend endpoints for full functionality
class LearningAPIService: ObservableObject {
    static let shared = LearningAPIService()

    // MARK: - Configuration

    private let baseURL: String
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Production URL - change based on environment
        #if DEBUG
        self.baseURL = "http://localhost:8000/api/v1"
        #else
        self.baseURL = "https://api.lyoapp.com/api/v1"
        #endif

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    // MARK: - Authentication

    private var authToken: String? {
        // TODO: Get from KeychainManager or UserDefaults
        UserDefaults.standard.string(forKey: "auth_token")
    }

    private func authorizedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Course Compilation

    struct CompileCourseRequest: Codable {
        let goal: String
        let timeBudgetMinPerDay: Int
        let deadlineIso: String?
        let priorKnowledgeIds: [String]

        enum CodingKeys: String, CodingKey {
            case goal
            case timeBudgetMinPerDay = "time_budget_min_per_day"
            case deadlineIso = "deadline_iso"
            case priorKnowledgeIds = "prior_knowledge_ids"
        }
    }

    /// Compile a new course from user goal
    func compileCourse(goal: String, timeBudgetMinPerDay: Int = 20, priorKnowledge: [String] = []) async throws -> Course {
        let url = URL(string: "\(baseURL)/courses/compile")!
        var request = authorizedRequest(url: url, method: "POST")

        let requestBody = CompileCourseRequest(
            goal: goal,
            timeBudgetMinPerDay: timeBudgetMinPerDay,
            deadlineIso: nil,
            priorKnowledgeIds: priorKnowledge
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let course = try decoder.decode(Course.self, from: data)

        print("✅ [API] Course compiled: \(course.id)")
        return course
    }

    /// Get course plan by ID
    func getCoursePlan(courseId: UUID) async throws -> Course {
        let url = URL(string: "\(baseURL)/courses/\(courseId)/plan")!
        let request = authorizedRequest(url: url)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.notFound
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Course.self, from: data)
    }

    /// List all courses
    func listCourses(statusFilter: String? = nil) async throws -> [CourseListItem] {
        var urlString = "\(baseURL)/courses/"
        if let status = statusFilter {
            urlString += "?status_filter=\(status)"
        }

        let url = URL(string: urlString)!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CourseListItem].self, from: data)
    }

    struct CourseListItem: Codable, Identifiable {
        let id: UUID
        let goal: String
        let status: String
        let createdAt: Date
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case id, goal, status
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// Update course status
    func updateCourseStatus(courseId: UUID, newStatus: String) async throws {
        let url = URL(string: "\(baseURL)/courses/\(courseId)/status?new_status=\(newStatus)")!
        var request = authorizedRequest(url: url, method: "PATCH")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.updateFailed
        }

        print("✅ [API] Course status updated: \(newStatus)")
    }

    // MARK: - Progress Tracking

    /// Get user progress
    func getProgress(courseId: UUID? = nil) async throws -> Progress {
        var urlString = "\(baseURL)/progress/"
        if let courseId = courseId {
            urlString += "?course_id=\(courseId)"
        }

        let url = URL(string: urlString)!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let progress = try decoder.decode(Progress.self, from: data)

        print("✅ [API] Progress loaded: \(progress.thetaByKc.count) KCs, streak=\(progress.streak)")
        return progress
    }

    /// Get detailed mastery estimates
    func getMasteryEstimates(kcSlug: String? = nil) async throws -> [MasteryEstimate] {
        var urlString = "\(baseURL)/progress/mastery"
        if let slug = kcSlug {
            urlString += "?kc_slug=\(slug)"
        }

        let url = URL(string: urlString)!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MasteryEstimate].self, from: data)
    }

    /// Get due reviews
    func getDueReviews() async throws -> [ReviewQueueItem] {
        let url = URL(string: "\(baseURL)/progress/reviews/due")!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ReviewQueueItem].self, from: data)
    }

    /// Get upcoming reviews
    func getUpcomingReviews(daysAhead: Int = 7) async throws -> [ReviewQueueItem] {
        let url = URL(string: "\(baseURL)/progress/reviews/upcoming?days_ahead=\(daysAhead)")!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ReviewQueueItem].self, from: data)
    }

    /// Get learning statistics
    func getLearningStats(courseId: UUID? = nil) async throws -> LearningStats {
        var urlString = "\(baseURL)/progress/stats"
        if let courseId = courseId {
            urlString += "?course_id=\(courseId)"
        }

        let url = URL(string: urlString)!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        return try JSONDecoder().decode(LearningStats.self, from: data)
    }

    struct LearningStats: Codable {
        let totalLearningTimeMin: Int
        let completedAlos: Int
        let totalAttempts: Int
        let accuracyPercent: Double
        let activeCourses: Int
        let completedCourses: Int

        enum CodingKeys: String, CodingKey {
            case totalLearningTimeMin = "total_learning_time_min"
            case completedAlos = "completed_alos"
            case totalAttempts = "total_attempts"
            case accuracyPercent = "accuracy_percent"
            case activeCourses = "active_courses"
            case completedCourses = "completed_courses"
        }
    }

    // MARK: - Evidence Submission

    /// Submit evidence for assessment
    func submitEvidence(aloId: UUID, artifacts: [EvidenceArtifact], checks: [CheckResult]) async throws -> SubmitEvidenceResponse {
        let url = URL(string: "\(baseURL)/evidence/submit")!
        var request = authorizedRequest(url: url, method: "POST")

        let requestBody = SubmitEvidenceRequest(
            aloId: aloId,
            artifacts: artifacts,
            checks: checks
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.submitFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(SubmitEvidenceResponse.self, from: data)

        print("✅ [API] Evidence submitted: passed=\(result.passed)")
        return result
    }

    /// Get ALO requirements
    func getALORequirements(aloId: UUID) async throws -> ALORequirements {
        let url = URL(string: "\(baseURL)/evidence/\(aloId)/requirements")!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ALORequirements.self, from: data)
    }

    struct ALORequirements: Codable {
        let aloId: UUID
        let aloType: String
        let assessmentSpec: [String: AnyCodable]
        let difficulty: Int
        let estimatedTimeSec: Int

        enum CodingKeys: String, CodingKey {
            case difficulty
            case aloId = "alo_id"
            case aloType = "alo_type"
            case assessmentSpec = "assessment_spec"
            case estimatedTimeSec = "estimated_time_sec"
        }
    }

    // MARK: - Session Management

    /// Create a new learning session
    func createSession(courseId: UUID) async throws -> LearningSession {
        let url = URL(string: "\(baseURL)/sessions/")!
        var request = authorizedRequest(url: url, method: "POST")

        let requestBody = ["course_id": courseId.uuidString]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.sessionCreationFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(LearningSession.self, from: data)

        print("✅ [API] Session created: \(session.id)")
        return session
    }

    /// Get session details
    func getSession(sessionId: UUID) async throws -> SessionDetails {
        let url = URL(string: "\(baseURL)/sessions/\(sessionId)")!
        let request = authorizedRequest(url: url)

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SessionDetails.self, from: data)
    }

    struct SessionDetails: Codable {
        let sessionId: UUID
        let courseId: UUID
        let status: String
        let startedAt: String
        let endedAt: String?
        let attemptsCount: Int
        let correctCount: Int

        enum CodingKeys: String, CodingKey {
            case status
            case sessionId = "session_id"
            case courseId = "course_id"
            case startedAt = "started_at"
            case endedAt = "ended_at"
            case attemptsCount = "attempts_count"
            case correctCount = "correct_count"
        }
    }

    // MARK: - Error Handling

    enum APIError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int, data: Data)
        case notFound
        case updateFailed
        case submitFailed
        case sessionCreationFailed
        case decodingError(Error)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let statusCode, _):
                return "HTTP error: \(statusCode)"
            case .notFound:
                return "Resource not found"
            case .updateFailed:
                return "Failed to update resource"
            case .submitFailed:
                return "Failed to submit evidence"
            case .sessionCreationFailed:
                return "Failed to create session"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}
