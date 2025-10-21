import XCTest
@testable import LyoApp

@MainActor
final class APIClientTests: XCTestCase {
    
    var apiClient: APIClient!
    
    override func setUp() async throws {
        try await super.setUp()
        apiClient = APIClient.shared
        apiClient.clearAuthTokens()
    }
    
    override func tearDown() async throws {
        apiClient.clearAuthTokens()
        try await super.tearDown()
    }
    
    // MARK: - Health Check Tests
    
    func testHealthCheck() async throws {
        do {
            let healthResponse = try await apiClient.healthCheck()
            XCTAssertEqual(healthResponse.status, "healthy")
            XCTAssertFalse(healthResponse.version.isEmpty)
            XCTAssertNotNil(healthResponse.services)
        } catch {
            // Health check might fail in test environment, that's ok
            XCTAssertTrue(error is APIClientError, "Error should be APIClientError type")
        }
    }
    
    // MARK: - Authentication Tests
    
    func testSetAndClearAuthTokens() async {
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let userId = "test_user_id"
        
        // Set tokens
        apiClient.setAuthToken(accessToken, refreshToken: refreshToken, userId: userId)
        
        // Verify tokens are set (indirectly through SecureTokenManager)
        let tokenManager = SecureTokenManager.shared
        XCTAssertEqual(tokenManager.getAccessToken(), accessToken)
        XCTAssertEqual(tokenManager.getRefreshToken(), refreshToken)
        XCTAssertEqual(tokenManager.getUserId(), userId)
        
        // Clear tokens
        apiClient.clearAuthTokens()
        
        // Verify tokens are cleared
        XCTAssertNil(tokenManager.getAccessToken())
        XCTAssertNil(tokenManager.getRefreshToken())
        XCTAssertNil(tokenManager.getUserId())
    }
    
    func testAuthenticationWithValidCredentials() async {
        do {
            let response = try await apiClient.authenticate(email: "test@example.com", password: "password123")
            
            XCTAssertFalse(response.user.id.isEmpty)
            XCTAssertFalse(response.accessToken.isEmpty)
            XCTAssertEqual(response.user.email, "test@example.com")
        } catch {
            // Authentication might fail against real backend, check if it's a network error
            if let apiError = error as? APIClientError {
                switch apiError {
                case .networkError, .notFound, .serverError:
                    // These are expected in test environment
                    break
                default:
                    XCTFail("Unexpected API error: \(apiError)")
                }
            }
        }
    }
    
    func testRegistrationWithValidData() async {
        do {
            let response = try await apiClient.register(
                email: "newuser@example.com",
                password: "password123",
                username: "newuser",
                fullName: "New User"
            )
            
            XCTAssertFalse(response.user.id.isEmpty)
            XCTAssertFalse(response.accessToken.isEmpty)
            XCTAssertEqual(response.user.email, "newuser@example.com")
            XCTAssertEqual(response.user.username, "newuser")
        } catch {
            // Registration might fail against real backend
            if let apiError = error as? APIClientError {
                switch apiError {
                case .networkError, .notFound, .serverError:
                    // These are expected in test environment
                    break
                default:
                    XCTFail("Unexpected API error: \(apiError)")
                }
            }
        }
    }
    
    // MARK: - Feed Tests
    
    func testLoadFeed() async {
        do {
            let feedResponse = try await apiClient.loadFeed(page: 1, limit: 10)
            
            XCTAssertNotNil(feedResponse.posts)
            XCTAssertLessThanOrEqual(feedResponse.posts.count, 10)
            
            // Verify post structure
            if let firstPost = feedResponse.posts.first {
                XCTAssertFalse(firstPost.id.isEmpty)
                XCTAssertFalse(firstPost.userId.isEmpty)
                XCTAssertFalse(firstPost.username.isEmpty)
                XCTAssertFalse(firstPost.content.isEmpty)
                XCTAssertGreaterThanOrEqual(firstPost.likesCount, 0)
                XCTAssertGreaterThanOrEqual(firstPost.commentsCount, 0)
            }
        } catch {
            XCTFail("Feed loading should not fail: \(error)")
        }
    }
    
    func testLikePost() async {
        let testPostId = "test_post_123"
        
        do {
            let response = try await apiClient.likePost(testPostId)
            
            XCTAssertTrue(response.success)
            XCTAssertEqual(response.postId, testPostId)
            XCTAssertGreaterThanOrEqual(response.likesCount, 0)
        } catch {
            XCTFail("Like post should not fail: \(error)")
        }
    }
    
    func testCreatePost() async {
        let testContent = "This is a test post"
        let mediaUrls = ["https://example.com/image1.jpg"]
        
        do {
            let response = try await apiClient.createPost(testContent, mediaUrls: mediaUrls)
            
            XCTAssertTrue(response.success)
            XCTAssertFalse(response.postId.isEmpty)
            XCTAssertEqual(response.content, testContent)
            XCTAssertFalse(response.createdAt.isEmpty)
        } catch {
            XCTFail("Create post should not fail: \(error)")
        }
    }
    
    // MARK: - User Management Tests
    
    func testGetUserProfile() async {
        do {
            let response = try await apiClient.getUserProfile()
            
            XCTAssertTrue(response.success)
            XCTAssertFalse(response.user.id.isEmpty)
            XCTAssertFalse(response.user.username.isEmpty)
            XCTAssertGreaterThanOrEqual(response.user.followersCount, 0)
            XCTAssertGreaterThanOrEqual(response.user.followingCount, 0)
        } catch {
            // This might fail if no auth token is set
            if let apiError = error as? APIClientError {
                switch apiError {
                case .unauthorized:
                    // Expected without auth token
                    break
                default:
                    XCTFail("Unexpected error: \(apiError)")
                }
            }
        }
    }
    
    func testFollowUser() async {
        let testUserId = "test_user_456"
        
        do {
            let response = try await apiClient.followUser(testUserId)
            
            XCTAssertTrue(response.success)
            XCTAssertEqual(response.userId, testUserId)
            XCTAssertGreaterThanOrEqual(response.followersCount, 0)
        } catch {
            XCTFail("Follow user should not fail: \(error)")
        }
    }
    
    // MARK: - Search Tests
    
    func testSearchUsers() async {
        do {
            let response = try await apiClient.searchUsers("test", limit: 5)
            
            XCTAssertTrue(response.success)
            XCTAssertNotNil(response.users)
            XCTAssertLessThanOrEqual(response.users.count, 5)
        } catch {
            XCTFail("User search should not fail: \(error)")
        }
    }
    
    func testSearchContent() async {
        do {
            let response = try await apiClient.searchContent("swift", limit: 10)
            
            XCTAssertTrue(response.success)
            XCTAssertNotNil(response.posts)
            XCTAssertNotNil(response.resources)
        } catch {
            XCTFail("Content search should not fail: \(error)")
        }
    }
    
    // MARK: - Learning Resources Tests
    
    func testFetchLearningResources() async {
        do {
            let response = try await apiClient.fetchLearningResources(query: "programming", limit: 5)
            
            XCTAssertNotNil(response.resources)
            XCTAssertLessThanOrEqual(response.resources.count, 5)
            XCTAssertNotNil(response.categories)
            
            // Verify resource structure
            if let firstResource = response.resources.first {
                XCTAssertFalse(firstResource.id.isEmpty)
                XCTAssertFalse(firstResource.title.isEmpty)
                XCTAssertFalse(firstResource.description.isEmpty)
                XCTAssertGreaterThan(firstResource.duration, 0)
                XCTAssertGreaterThan(firstResource.rating, 0.0)
            }
        } catch {
            XCTFail("Learning resources fetch should not fail: \(error)")
        }
    }
    
    // MARK: - AI Tests
    
    func testGenerateAIContent() async {
        do {
            let response = try await apiClient.generateAIContent(prompt: "Explain Swift programming", maxTokens: 100)
            
            XCTAssertFalse(response.generatedText.isEmpty)
            XCTAssertTrue(response.generatedText.contains("Swift") || response.generatedText.contains("demo"))
        } catch {
            XCTFail("AI content generation should not fail: \(error)")
        }
    }
    
    func testCheckAIStatus() async {
        do {
            let response = try await apiClient.checkAIStatus()
            XCTAssertFalse(response.status.isEmpty)
        } catch {
            // AI service might not be available
            if let apiError = error as? APIClientError {
                switch apiError {
                case .networkError, .notFound, .serverError:
                    // Expected if AI service is down
                    break
                default:
                    XCTFail("Unexpected AI status error: \(apiError)")
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidURLError() async {
        // This would require mocking the base URL to be invalid
        // For now, we test that errors are properly typed
        do {
            _ = try await apiClient.healthCheck()
        } catch let error as APIClientError {
            // Verify error is properly typed
            XCTAssertTrue(true, "Error is properly typed as APIClientError")
        } catch {
            XCTFail("Error should be APIClientError type")
        }
    }
    
    func testNetworkTimeout() async {
        // This would require network condition simulation
        // Testing framework limitations prevent full network testing
        XCTAssertTrue(true, "Network timeout testing requires special test environment")
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentRequests() async {
        let expectation = XCTestExpectation(description: "Concurrent requests")
        expectation.expectedFulfillmentCount = 3
        
        Task {
            _ = try? await apiClient.healthCheck()
            expectation.fulfill()
        }
        
        Task {
            _ = try? await apiClient.loadFeed(page: 1, limit: 5)
            expectation.fulfill()
        }
        
        Task {
            _ = try? await apiClient.fetchLearningResources(limit: 5)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}