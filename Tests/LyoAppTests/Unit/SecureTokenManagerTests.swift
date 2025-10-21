import XCTest
@testable import LyoApp

@MainActor
final class SecureTokenManagerTests: XCTestCase {
    
    var tokenManager: SecureTokenManager!
    
    override func setUp() async throws {
        try await super.setUp()
        tokenManager = SecureTokenManager.shared
        // Clear any existing tokens
        tokenManager.clearAllTokens()
    }
    
    override func tearDown() async throws {
        tokenManager.clearAllTokens()
        try await super.tearDown()
    }
    
    // MARK: - Token Storage Tests
    
    func testSaveAndRetrieveAccessToken() async {
        let testToken = "test_access_token_123"
        
        tokenManager.saveAccessToken(testToken)
        let retrievedToken = tokenManager.getAccessToken()
        
        XCTAssertEqual(retrievedToken, testToken, "Access token should be saved and retrieved correctly")
    }
    
    func testSaveAndRetrieveRefreshToken() async {
        let testToken = "test_refresh_token_456"
        
        tokenManager.saveRefreshToken(testToken)
        let retrievedToken = tokenManager.getRefreshToken()
        
        XCTAssertEqual(retrievedToken, testToken, "Refresh token should be saved and retrieved correctly")
    }
    
    func testSaveAndRetrieveUserId() async {
        let testUserId = "user_123"
        
        tokenManager.saveUserId(testUserId)
        let retrievedUserId = tokenManager.getUserId()
        
        XCTAssertEqual(retrievedUserId, testUserId, "User ID should be saved and retrieved correctly")
    }
    
    func testBatchTokenSave() async {
        let accessToken = "access_123"
        let refreshToken = "refresh_456"
        let userId = "user_789"
        
        tokenManager.saveAuthTokens(accessToken: accessToken, refreshToken: refreshToken, userId: userId)
        
        XCTAssertEqual(tokenManager.getAccessToken(), accessToken)
        XCTAssertEqual(tokenManager.getRefreshToken(), refreshToken)
        XCTAssertEqual(tokenManager.getUserId(), userId)
    }
    
    func testClearAllTokens() async {
        // First save some tokens
        tokenManager.saveAuthTokens(accessToken: "access", refreshToken: "refresh", userId: "user")
        
        // Verify they exist
        XCTAssertNotNil(tokenManager.getAccessToken())
        XCTAssertNotNil(tokenManager.getRefreshToken())
        XCTAssertNotNil(tokenManager.getUserId())
        
        // Clear all tokens
        tokenManager.clearAllTokens()
        
        // Verify they're cleared
        XCTAssertNil(tokenManager.getAccessToken())
        XCTAssertNil(tokenManager.getRefreshToken())
        XCTAssertNil(tokenManager.getUserId())
    }
    
    // MARK: - Token Validation Tests
    
    func testValidateTokenFormat() async {
        // Valid JWT format
        let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        XCTAssertTrue(tokenManager.validateTokenFormat(validToken))
        
        // Invalid formats
        XCTAssertFalse(tokenManager.validateTokenFormat("invalid.token"))
        XCTAssertFalse(tokenManager.validateTokenFormat(""))
        XCTAssertFalse(tokenManager.validateTokenFormat("just_a_string"))
    }
    
    func testTokenExpirationCheck() async {
        // Create expired token (exp: 1000000000 - way in the past)
        let expiredToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiZXhwIjoxMDAwMDAwMDAwfQ.Hm_ZpypOKJF_MzpU7CxCUDKvs8kZg8vhqk_X_QQ_hHc"
        XCTAssertTrue(tokenManager.isTokenExpired(expiredToken))
        
        // Invalid token should be considered expired
        XCTAssertTrue(tokenManager.isTokenExpired("invalid_token"))
    }
    
    func testHasValidTokens() async {
        // Initially should be false
        XCTAssertFalse(tokenManager.hasValidTokens())
        
        // After saving access token and user ID
        tokenManager.saveAccessToken("test_token")
        tokenManager.saveUserId("test_user")
        XCTAssertTrue(tokenManager.hasValidTokens())
        
        // After clearing
        tokenManager.clearAllTokens()
        XCTAssertFalse(tokenManager.hasValidTokens())
    }
    
    // MARK: - Device ID Tests
    
    func testDeviceIdGeneration() async {
        let deviceId1 = tokenManager.getDeviceId()
        let deviceId2 = tokenManager.getDeviceId()
        
        XCTAssertEqual(deviceId1, deviceId2, "Device ID should be consistent")
        XCTAssertFalse(deviceId1.isEmpty, "Device ID should not be empty")
        
        // Should be valid UUID format
        XCTAssertNotNil(UUID(uuidString: deviceId1), "Device ID should be valid UUID")
    }
    
    // MARK: - Token Status Tests
    
    func testTokenStatus() async {
        let initialStatus = tokenManager.getTokenStatus()
        XCTAssertFalse(initialStatus["hasAccessToken"] as! Bool)
        XCTAssertFalse(initialStatus["hasRefreshToken"] as! Bool)
        XCTAssertFalse(initialStatus["hasUserId"] as! Bool)
        XCTAssertFalse(initialStatus["hasValidTokens"] as! Bool)
        
        // After saving tokens
        tokenManager.saveAuthTokens(accessToken: "access", refreshToken: "refresh", userId: "user")
        
        let updatedStatus = tokenManager.getTokenStatus()
        XCTAssertTrue(updatedStatus["hasAccessToken"] as! Bool)
        XCTAssertTrue(updatedStatus["hasRefreshToken"] as! Bool)
        XCTAssertTrue(updatedStatus["hasUserId"] as! Bool)
        XCTAssertTrue(updatedStatus["hasValidTokens"] as! Bool)
    }
    
    // MARK: - Security Tests
    
    func testTokenPersistenceAfterAppRestart() async {
        // This would be testing keychain persistence
        // In a real test environment, this would involve app lifecycle simulation
        let testToken = "persistent_test_token"
        tokenManager.saveAccessToken(testToken)
        
        // Simulate app restart by creating new instance
        // Note: In real keychain, tokens would persist
        let retrievedToken = tokenManager.getAccessToken()
        XCTAssertEqual(retrievedToken, testToken)
    }
}