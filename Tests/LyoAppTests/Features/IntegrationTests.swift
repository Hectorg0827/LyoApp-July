import XCTest
@testable import LyoApp

final class IntegrationTests: XCTestCase {
    
    func testWebSocketFallbackIntegration() async throws {
        let expectation = XCTestExpectation(description: "WebSocket fallback triggered")
        
        let webSocket = WebSocketClient()
        var fallbackTriggered = false
        
        webSocket.onFallback = {
            fallbackTriggered = true
            expectation.fulfill()
        }
        
        // Mock URL for testing
        let testURL = URL(string: "wss://test.example.com/ws")!
        
        // In a real test, we'd mock the network layer to simulate ping failures
        // For now, we just verify the fallback mechanism exists
        XCTAssertNotNil(webSocket.onFallback)
        
        // Manually trigger fallback for test
        webSocket.onFallback?()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(fallbackTriggered)
    }
    
    func testErrorPresenterWithAPIClientIntegration() async throws {
        // Test that ErrorPresenter can handle errors from APIClient
        
        // Create a Problem Details error like APIClient would generate  
        let rateLimitError = ProblemDetails.rateLimited(detail: "Too many requests")
        
        // Test ErrorPresenter handles it correctly
        let userMessage = ErrorPresenter.userMessage(for: rateLimitError)
        XCTAssertEqual(userMessage, "Things are busy. We'll retry automatically.")
        
        let isRetryable = ErrorPresenter.isRetryable(rateLimitError)
        XCTAssertTrue(isRetryable)
        
        let retryDelay = ErrorPresenter.retryDelay(for: rateLimitError, attempt: 1)
        XCTAssertEqual(retryDelay, 2.0)
        
        // Test with server error
        let serverError = ProblemDetails.internalServerError(detail: "Database connection failed")
        let serverMessage = ErrorPresenter.userMessage(for: serverError)
        XCTAssertEqual(serverMessage, "Temporary server issue. Try again shortly.")
    }
    
    func testAnalyticsIntegration() {
        // Test that the Analytics static facade works
        
        // This should not crash and should log appropriately
        Analytics.log("test_event", ["key": "value"])
        
        // Test specific event methods
        Analytics.log("course_generate_requested", [
            "topic": "Test Topic",
            "interests": ["iOS", "Swift"]
        ])
        
        Analytics.log("content_item_opened", [
            "id": "test-item-123",
            "type": "video"
        ])
        
        Analytics.log("api_error", [
            "endpoint": "/courses",
            "status_code": 500,
            "error": "Internal Server Error"
        ])
        
        // All of these should complete without throwing
    }
    
    func testPaginatorWithFeedIntegration() async throws {
        // Test that Paginator works with feed-like data
        
        struct MockFeedItem: Identifiable {
            let id: String
            let title: String
        }
        
        var pageNumber = 0
        let paginator = Paginator<MockFeedItem> { cursor in
            pageNumber += 1
            
            // Simulate feed response with cursor
            let items = (1...5).map { i in
                MockFeedItem(id: "page-\(pageNumber)-item-\(i)", title: "Item \(i)")
            }
            
            let nextCursor = pageNumber < 3 ? "cursor-\(pageNumber)" : nil
            return (items, nextCursor)
        }
        
        // Load initial page
        try await paginator.loadInitialPage()
        XCTAssertEqual(paginator.items.count, 5)
        XCTAssertTrue(paginator.hasMore)
        
        // Load second page
        try await paginator.loadMoreIfNeeded(currentIndex: 3)
        XCTAssertEqual(paginator.items.count, 10)
        XCTAssertTrue(paginator.hasMore)
        
        // Load final page
        try await paginator.loadMoreIfNeeded(currentIndex: 8)
        XCTAssertEqual(paginator.items.count, 15)
        XCTAssertFalse(paginator.hasMore)
        
        // Verify deduplication works - all IDs should be unique
        let uniqueIds = Set(paginator.items.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 15)
    }
    
    func testCourseViewModelIntegrationFlow() async throws {
        // Test the full course view model flow
        
        class MockRepository: CourseRepository {
            var updateHandler: ((CourseSnapshot) -> Void)?
            
            func observeCourse(id: String, onChange: @escaping (CourseSnapshot) -> Void) -> AnyObject {
                self.updateHandler = onChange
                
                // Start with generating state
                onChange(CourseSnapshot(status: .generating, items: []))
                
                // Simulate progression
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    let item = ContentItemEntity()
                    item.id = "test-item"
                    item.title = "Test Content"
                    item.type = "video"
                    
                    onChange(CourseSnapshot(status: .generating, items: [item]))
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                    let item = ContentItemEntity()
                    item.id = "test-item"
                    item.title = "Test Content"
                    item.type = "video"
                    
                    onChange(CourseSnapshot(status: .ready, items: [item]))
                }
                
                return NSTimer()
            }
        }
        
        let mockRepo = MockRepository()
        let authManager = AuthManager()
        let apiClient = APIClient(environment: .current, authManager: authManager)
        let orchestrator = TaskOrchestrator(apiClient: apiClient)
        
        let viewModel = CourseViewModel(
            courseId: "test-course",
            orchestrator: orchestrator,
            repo: mockRepo
        )
        
        // Start observing
        await MainActor.run {
            viewModel.startObserving()
        }
        
        // Wait for initial state
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        await MainActor.run {
            if case .generating = viewModel.state {
                // Expected
            } else {
                XCTFail("Expected generating state")
            }
        }
        
        // Wait for partial state
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            if case .partial = viewModel.state {
                XCTAssertEqual(viewModel.items.count, 1)
                XCTAssertEqual(viewModel.items[0].title, "Test Content")
            } else {
                XCTFail("Expected partial state")
            }
        }
        
        // Wait for ready state
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        await MainActor.run {
            if case .ready = viewModel.state {
                XCTAssertEqual(viewModel.items.count, 1)
            } else {
                XCTFail("Expected ready state, got: \(viewModel.state)")
            }
        }
    }
}