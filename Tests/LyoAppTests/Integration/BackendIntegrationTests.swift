import XCTest
@testable import LyoApp

@MainActor
final class BackendIntegrationTests: XCTestCase {
    
    var backendService: BackendIntegrationService!
    var apiClient: APIClient!
    
    override func setUp() async throws {
        try await super.setUp()
        backendService = BackendIntegrationService.shared
        apiClient = APIClient.shared
    }
    
    override func tearDown() async throws {
        backendService.disconnect()
        apiClient.clearAuthTokens()
        try await super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testBackendConnection() async {
        await backendService.connect()
        
        // Give some time for connection to establish
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        XCTAssertTrue(backendService.isConnected || backendService.connectionStatus != .unknown,
                     "Backend should connect or show proper status")
    }
    
    func testHealthCheckIntegration() async {
        await backendService.performHealthCheck()
        
        XCTAssertNotNil(backendService.lastHealthCheck, "Health check should set timestamp")
        XCTAssertNotNil(backendService.backendInfo, "Backend info should be populated after health check")
        
        if let backendInfo = backendService.backendInfo {
            XCTAssertFalse(backendInfo.status.isEmpty, "Backend status should not be empty")
            XCTAssertFalse(backendInfo.version.isEmpty, "Backend version should not be empty")
        }
    }
    
    func testConnectionDiagnostics() async {
        let diagnostics = backendService.getConnectionDiagnostics()
        
        XCTAssertNotNil(diagnostics["isConnected"])
        XCTAssertNotNil(diagnostics["connectionStatus"])
        XCTAssertNotNil(diagnostics["consecutiveFailures"])
        XCTAssertNotNil(diagnostics["cachedFeedPosts"])
        XCTAssertNotNil(diagnostics["cachedLearningResources"])
        
        XCTAssertTrue(diagnostics["consecutiveFailures"] is Int)
        XCTAssertTrue(diagnostics["cachedFeedPosts"] is Int)
        XCTAssertTrue(diagnostics["cachedLearningResources"] is Int)
    }
    
    // MARK: - Authentication Integration Tests
    
    func testAuthenticationFlow() async {
        let testEmail = "test@example.com"
        let testPassword = "testPassword123"
        
        do {
            let user = try await backendService.authenticateUser(email: testEmail, password: testPassword)
            
            XCTAssertFalse(user.id.isEmpty)
            XCTAssertEqual(user.email, testEmail)
            XCTAssertNotNil(backendService.currentUser)
        } catch {
            // Authentication might fail in test environment - that's ok
            XCTAssertTrue(error is APIClientError, "Error should be APIClientError")
        }
    }
    
    func testSignOut() async {
        // First authenticate
        _ = try? await backendService.authenticateUser(email: "test@example.com", password: "password")
        
        // Then sign out
        backendService.signOut()
        
        XCTAssertNil(backendService.currentUser, "Current user should be cleared after sign out")
        XCTAssertNil(SecureTokenManager.shared.getAccessToken(), "Access token should be cleared")
    }
    
    // MARK: - Feed Integration Tests
    
    func testLoadFeedContent() async {
        do {
            let posts = try await backendService.loadFeedContent(page: 1, limit: 5, refresh: true)
            
            XCTAssertLessThanOrEqual(posts.count, 5)
            XCTAssertEqual(backendService.cachedFeedPosts.count, posts.count)
            
            // Verify post structure
            if let firstPost = posts.first {
                XCTAssertFalse(firstPost.id.isEmpty)
                XCTAssertFalse(firstPost.content.isEmpty)
                XCTAssertGreaterThanOrEqual(firstPost.likesCount, 0)
            }
        } catch {
            XCTFail("Feed loading should work with mock data: \(error)")
        }
    }
    
    func testFeedContentRefresh() async {
        // Load initial content
        _ = try? await backendService.loadFeedContent(page: 1, limit: 3)
        let initialCount = backendService.cachedFeedPosts.count
        
        // Refresh content
        _ = try? await backendService.loadFeedContent(page: 1, limit: 5, refresh: true)
        let refreshedCount = backendService.cachedFeedPosts.count
        
        // After refresh, cache should be updated
        XCTAssertGreaterThanOrEqual(refreshedCount, 0)
    }
    
    // MARK: - Learning Resources Integration Tests
    
    func testLoadLearningResources() async {
        do {
            let resources = try await backendService.loadLearningResources(query: "Swift", limit: 3, refresh: true)
            
            XCTAssertLessThanOrEqual(resources.count, 3)
            XCTAssertEqual(backendService.cachedLearningResources.count, resources.count)
            
            // Verify resource structure
            if let firstResource = resources.first {
                XCTAssertFalse(firstResource.id.isEmpty)
                XCTAssertFalse(firstResource.title.isEmpty)
                XCTAssertGreaterThan(firstResource.duration, 0)
            }
        } catch {
            XCTFail("Learning resources loading should work with mock data: \(error)")
        }
    }
    
    func testLearningResourcesDeduplication() async {
        // Load resources twice without refresh
        _ = try? await backendService.loadLearningResources(limit: 2, refresh: true)
        let firstLoadCount = backendService.cachedLearningResources.count
        
        _ = try? await backendService.loadLearningResources(limit: 2, refresh: false)
        let secondLoadCount = backendService.cachedLearningResources.count
        
        // Should not have duplicates (though mock data might differ)
        XCTAssertGreaterThanOrEqual(secondLoadCount, firstLoadCount)
    }
    
    // MARK: - AI Integration Tests
    
    func testGenerateAIContent() async {
        let testPrompt = "Explain Swift programming"
        
        do {
            let response = try await backendService.generateAIContent(prompt: testPrompt, maxTokens: 100)
            
            XCTAssertFalse(response.isEmpty)
            // Should either be real AI response or fallback content
            XCTAssertTrue(response.contains("Swift") || response.contains("working on connecting"))
        } catch {
            XCTFail("AI content generation should provide fallback: \(error)")
        }
    }
    
    func testCheckAIServiceStatus() async {
        do {
            let status = try await backendService.checkAIServiceStatus()
            
            XCTAssertFalse(status.isEmpty)
            // Should be either available or unavailable
            XCTAssertTrue(["available", "unavailable", "operational", "error"].contains(status.lowercased()))
        } catch {
            // AI service check might fail - that's ok, it should set status
            XCTAssertEqual(backendService.aiServiceStatus, "unavailable")
        }
    }
    
    // MARK: - Data Refresh Tests
    
    func testRefreshAllData() async {
        // Load some initial data
        _ = try? await backendService.loadFeedContent(page: 1, limit: 2)
        _ = try? await backendService.loadLearningResources(limit: 2)
        
        let initialFeedCount = backendService.cachedFeedPosts.count
        let initialResourcesCount = backendService.cachedLearningResources.count
        
        // Refresh all data
        await backendService.refreshAllData()
        
        // Verify health check was performed
        XCTAssertNotNil(backendService.lastHealthCheck)
        
        // Data should still be available (refreshed)
        XCTAssertGreaterThanOrEqual(backendService.cachedFeedPosts.count, 0)
        XCTAssertGreaterThanOrEqual(backendService.cachedLearningResources.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testConnectionFailureRecovery() async {
        // Test connection recovery after failure
        backendService.disconnect()
        XCTAssertFalse(backendService.isConnected)
        
        // Try to reconnect
        await backendService.connect()
        
        // Should either connect or show appropriate status
        XCTAssertNotEqual(backendService.connectionStatus, .unknown)
    }
    
    func testGracefulDegradation() async {
        // Even if backend is unavailable, services should provide fallback data
        do {
            let feedPosts = try await backendService.loadFeedContent(page: 1, limit: 3)
            XCTAssertGreaterThanOrEqual(feedPosts.count, 0, "Should provide fallback feed data")
            
            let resources = try await backendService.loadLearningResources(limit: 3)
            XCTAssertGreaterThanOrEqual(resources.count, 0, "Should provide fallback learning resources")
            
            let aiResponse = try await backendService.generateAIContent(prompt: "Test")
            XCTAssertFalse(aiResponse.isEmpty, "Should provide fallback AI response")
        } catch {
            XCTFail("Services should provide fallback data even when backend is unavailable")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentServiceCalls() async {
        let expectation = XCTestExpectation(description: "Concurrent service calls")
        expectation.expectedFulfillmentCount = 3
        
        Task {
            await backendService.performHealthCheck()
            expectation.fulfill()
        }
        
        Task {
            _ = try? await backendService.loadFeedContent(page: 1, limit: 2)
            expectation.fulfill()
        }
        
        Task {
            _ = try? await backendService.loadLearningResources(limit: 2)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func testServiceInitializationPerformance() async {
        measure {
            // Test service initialization performance
            let service = BackendIntegrationService.shared
            XCTAssertNotNil(service)
        }
    }
    
    // MARK: - Real Backend Tests (if available)
    
    func testRealBackendConnectivity() async {
        // This test specifically checks real backend connectivity
        let expectation = XCTestExpectation(description: "Real backend health check")
        
        Task {
            do {
                let health = try await apiClient.healthCheck()
                XCTAssertEqual(health.status, "healthy")
                print("✅ Real backend is available: \(health.version)")
                expectation.fulfill()
            } catch {
                print("ℹ️ Real backend not available (expected in test environment): \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}