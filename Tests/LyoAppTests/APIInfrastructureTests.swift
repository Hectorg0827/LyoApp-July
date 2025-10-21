import XCTest
@testable import LyoApp

/// Tests for the production API infrastructure
final class APIInfrastructureTests: XCTestCase {
    
    var authManager: AuthManager!
    var apiClient: APIClient!
    
    override func setUp() async throws {
        authManager = AuthManager()
        apiClient = APIClient(environment: .dev, authManager: authManager)
    }
    
    override func tearDown() async throws {
        await authManager.clearTokens()
    }
    
    // MARK: - AuthManager Tests
    
    func testTokenStorage() async throws {
        // Test token storage and retrieval
        await authManager.setTokens(access: "test_access_token", refresh: "test_refresh_token")
        
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.currentAccessToken, "test_access_token")
        
        // Test token clearing
        await authManager.clearTokens()
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentAccessToken)
    }
    
    func testRequestAuthorization() async throws {
        await authManager.setTokens(access: "test_token", refresh: "test_refresh")
        
        var request = URLRequest(url: URL(string: "https://example.com")!)
        await authManager.authorize(&request)
        
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer test_token")
    }
    
    // MARK: - Problem Details Tests
    
    func testProblemDetailsDecoding() throws {
        let json = """
        {
            "type": "https://example.com/problems/not-found",
            "title": "Resource Not Found",
            "status": 404,
            "detail": "The requested resource could not be found",
            "instance": "/courses/123"
        }
        """.data(using: .utf8)!
        
        let problemDetails = try JSONDecoder().decode(ProblemDetails.self, from: json)
        
        XCTAssertEqual(problemDetails.title, "Resource Not Found")
        XCTAssertEqual(problemDetails.status, 404)
        XCTAssertEqual(problemDetails.detail, "The requested resource could not be found")
        XCTAssertTrue(problemDetails.isClientError)
        XCTAssertFalse(problemDetails.isServerError)
    }
    
    func testProblemDetailsErrorTypes() {
        let unauthorized = ProblemDetails.unauthorized()
        XCTAssertEqual(unauthorized.status, 401)
        XCTAssertTrue(unauthorized.isAuthError)
        
        let rateLimited = ProblemDetails.rateLimited()
        XCTAssertEqual(rateLimited.status, 429)
        XCTAssertTrue(rateLimited.isRateLimitError)
        
        let serverError = ProblemDetails.internalServerError()
        XCTAssertEqual(serverError.status, 500)
        XCTAssertTrue(serverError.isServerError)
    }
    
    // MARK: - Task Event Tests
    
    func testTaskEventDecoding() throws {
        let json = """
        {
            "state": "running",
            "progressPct": 45,
            "message": "Processing content items...",
            "resultId": null
        }
        """.data(using: .utf8)!
        
        let taskEvent = try JSONDecoder().decode(TaskEvent.self, from: json)
        
        XCTAssertEqual(taskEvent.state, .running)
        XCTAssertEqual(taskEvent.progressPct, 45)
        XCTAssertEqual(taskEvent.message, "Processing content items...")
        XCTAssertNil(taskEvent.resultId)
        XCTAssertFalse(taskEvent.isTerminal)
    }
    
    func testTaskEventTerminalStates() throws {
        let doneEvent = TaskEvent(state: .done, progressPct: 100, message: "Complete", resultId: "course_123", error: nil)
        XCTAssertTrue(doneEvent.isTerminal)
        
        let errorEvent = TaskEvent(state: .error, progressPct: nil, message: "Failed", resultId: nil, error: "Network timeout")
        XCTAssertTrue(errorEvent.isTerminal)
        
        let runningEvent = TaskEvent(state: .running, progressPct: 50, message: "Processing", resultId: nil, error: nil)
        XCTAssertFalse(runningEvent.isTerminal)
    }
    
    // MARK: - Data Normalization Tests
    
    func testContentItemValidation() throws {
        let validItem = ContentItemDTO(
            id: "item_123",
            type: "video",
            title: "Test Video",
            source: "YouTube",
            sourceUrl: "https://youtube.com/watch?v=123",
            thumbnailUrl: "https://img.youtube.com/vi/123/maxresdefault.jpg",
            durationSec: 300,
            pages: nil,
            summary: "A test video",
            attribution: "Test Author",
            tags: ["swift", "programming"],
            courseId: "course_123",
            lessonId: nil
        )
        
        XCTAssertEqual(validItem.id, "item_123")
        XCTAssertEqual(validItem.type, "video")
        XCTAssertEqual(validItem.durationSec, 300)
        XCTAssertEqual(validItem.tags?.count, 2)
        XCTAssertTrue(validItem.tags?.contains("swift") ?? false)
    }
    
    // MARK: - Environment Configuration Tests
    
    func testAPIEnvironmentURLs() {
        let devEnv = APIEnvironment.dev
        XCTAssertEqual(devEnv.base.absoluteString, "https://api.dev.lyo.app")
        XCTAssertEqual(devEnv.v1.absoluteString, "https://api.dev.lyo.app/v1")
        
        let prodEnv = APIEnvironment.prod
        XCTAssertEqual(prodEnv.base.absoluteString, "https://api.lyo.app")
        XCTAssertEqual(prodEnv.v1.absoluteString, "https://api.lyo.app/v1")
    }
    
    // MARK: - Performance Tests
    
    func testProblemDetailsCreationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = ProblemDetails.invalidRequest(detail: "Test error message")
            }
        }
    }
    
    func testTaskEventDecodingPerformance() throws {
        let json = """
        {
            "state": "running",
            "progressPct": 45,
            "message": "Processing content items...",
            "resultId": null
        }
        """.data(using: .utf8)!
        
        measure {
            for _ in 0..<1000 {
                let _ = try? JSONDecoder().decode(TaskEvent.self, from: json)
            }
        }
    }
}

// MARK: - Mock Task Event for Testing
extension TaskEvent {
    init(state: State, progressPct: Int?, message: String?, resultId: String?, error: String?) {
        self.state = state
        self.progressPct = progressPct
        self.message = message
        self.resultId = resultId
        self.error = error
    }
}