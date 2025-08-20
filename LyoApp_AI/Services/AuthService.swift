import Foundation
import Combine

// MARK: - Authentication Service Protocol
protocol AuthServiceProtocol {
    func signInWithApple(token: String) async throws -> AuthResponse
    func signInWithGoogle(token: String) async throws -> AuthResponse
    func signInWithMeta(token: String) async throws -> AuthResponse
    func refreshToken() async throws -> AuthResponse
    func signOut() async throws
    func getCurrentUser() async throws -> User
}

// MARK: - Authentication Models
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: User
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
    }
}

struct SignInRequest: Codable {
    let token: String
    let provider: String
}

// MARK: - Live Authentication Service
class LiveAuthService: AuthServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let baseURL: URL
    
    init(httpClient: HTTPClientProtocol, baseURL: String = "http://localhost:8002") {
        self.httpClient = httpClient
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
    }
    
    func signInWithApple(token: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("/api/v1/auth/apple")
        let request = try HTTPRequest.post(
            url: url,
            body: SignInRequest(token: token, provider: "apple")
        )
        
        return try await httpClient.request(request, responseType: AuthResponse.self)
    }
    
    func signInWithGoogle(token: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("/api/v1/auth/google")
        let request = try HTTPRequest.post(
            url: url,
            body: SignInRequest(token: token, provider: "google")
        )
        
        return try await httpClient.request(request, responseType: AuthResponse.self)
    }
    
    func signInWithMeta(token: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("/api/v1/auth/meta")
        let request = try HTTPRequest.post(
            url: url,
            body: SignInRequest(token: token, provider: "meta")
        )
        
        return try await httpClient.request(request, responseType: AuthResponse.self)
    }
    
    func refreshToken() async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("/api/v1/auth/refresh")
        let request = HTTPRequest.post(url: url, headers: [:])
        
        return try await httpClient.request(request, responseType: AuthResponse.self)
    }
    
    func signOut() async throws {
        let url = baseURL.appendingPathComponent("/api/v1/auth/logout")
        let request = HTTPRequest.post(url: url, headers: [:])
        
        try await httpClient.request(request)
    }
    
    func getCurrentUser() async throws -> User {
        let url = baseURL.appendingPathComponent("/api/v1/auth/me")
        let request = HTTPRequest.get(url: url)
        
        return try await httpClient.request(request, responseType: User.self)
    }
}

// MARK: - Mock Authentication Service
class MockAuthService: AuthServiceProtocol {
    var shouldFail = false
    var failureDelay: Double = 1.0
    
    func signInWithApple(token: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: UInt64(failureDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Apple sign in failed"])
        }
        
        return createMockAuthResponse(provider: "apple")
    }
    
    func signInWithGoogle(token: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: UInt64(failureDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Google sign in failed"])
        }
        
        return createMockAuthResponse(provider: "google")
    }
    
    func signInWithMeta(token: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: UInt64(failureDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Meta sign in failed"])
        }
        
        return createMockAuthResponse(provider: "meta")
    }
    
    func refreshToken() async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldFail {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token refresh failed"])
        }
        
        return createMockAuthResponse(provider: "refresh")
    }
    
    func signOut() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Mock sign out completed")
    }
    
    func getCurrentUser() async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldFail {
            throw NSError(domain: "AuthError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return User(
            id: "mock_current_user",
            email: "mock@example.com",
            displayName: "Mock Current User",
            profilePictureURL: nil,
            isEmailVerified: true,
            preferences: UserPreferences(
                learningGoals: ["iOS Development"],
                difficultyLevel: .intermediate,
                studyReminders: true,
                contentLanguage: "en"
            ),
            stats: UserStats(totalPoints: 150, streak: 5, completedCourses: 3),
            createdAt: Date(),
            lastActiveAt: Date()
        )
    }
    
    private func createMockAuthResponse(provider: String) -> AuthResponse {
        return AuthResponse(
            accessToken: "mock_\(provider)_access_token",
            refreshToken: "mock_\(provider)_refresh_token",
            tokenType: "Bearer",
            expiresIn: 3600,
            user: User(
                id: "\(provider)_user_123",
                email: "\(provider).user@example.com",
                displayName: "\(provider.capitalized) User",
                profilePictureURL: nil,
                isEmailVerified: true,
                preferences: UserPreferences(
                    learningGoals: ["iOS Development"],
                    difficultyLevel: .beginner,
                    studyReminders: true,
                    contentLanguage: "en"
                ),
                stats: UserStats(totalPoints: 0, streak: 0, completedCourses: 0),
                createdAt: Date(),
                lastActiveAt: Date()
            )
        )
    }
}
