import Foundation
import SwiftUI
import Combine

// MARK: - Dependency Injection Container
class AppContainer: ObservableObject {
    // MARK: - Core Services
    let tokenProvider: TokenProvider
    let httpClient: HTTPClientProtocol
    
    // MARK: - Feature Services
    let authService: AuthServiceProtocol
    let mediaService: MediaServiceProtocol
    let feedService: FeedServiceProtocol
    let courseService: CourseServiceProtocol
    
    // MARK: - State Management
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(useMockServices: Bool = false) {
        // Initialize core services
        self.tokenProvider = TokenProvider()
        
        if useMockServices {
            // Use mock services for development/testing
            self.httpClient = MockHTTPClient()
            self.authService = MockAuthService()
            self.mediaService = MockMediaService()
            self.feedService = MockFeedService()
            self.courseService = MockCourseService()
        } else {
            // Use live services for production
            self.httpClient = LiveHTTPClient(baseURL: "http://localhost:8002", tokenProvider: tokenProvider)
            self.authService = LiveAuthService(httpClient: httpClient)
            self.mediaService = LiveMediaService(httpClient: httpClient)
            self.feedService = LiveFeedService(httpClient: httpClient)
            self.courseService = LiveCourseService(httpClient: httpClient)
        }
        
        setupObservers()
        loadInitialState()
    }
    
    // MARK: - Authentication Methods
    func signOut() async {
        isLoading = true
        do {
            try await authService.signOut()
            await MainActor.run {
                tokenProvider.clearTokens()
                isAuthenticated = false
                currentUser = nil
                isLoading = false
            }
            print("✅ Successfully signed out")
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
    
    func signIn(with provider: String, token: String) async {
        isLoading = true
        do {
            let authResponse: AuthResponse
            
            switch provider.lowercased() {
            case "apple":
                authResponse = try await authService.signInWithApple(token: token)
            case "google":
                authResponse = try await authService.signInWithGoogle(token: token)
            case "meta", "facebook":
                authResponse = try await authService.signInWithMeta(token: token)
            default:
                throw AuthError.unsupportedProvider
            }
            
            // Store tokens and update state
            await MainActor.run {
                tokenProvider.setTokens(
                    accessToken: authResponse.accessToken,
                    refreshToken: authResponse.refreshToken
                )
                isAuthenticated = true
                currentUser = authResponse.user
                isLoading = false
            }
            
            print("✅ Successfully signed in as: \(authResponse.user.displayName)")
            
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("❌ Sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func refreshAuthentication() async {
        guard tokenProvider.refreshToken != nil else { return }
        
        do {
            let authResponse = try await authService.refreshToken()
            await MainActor.run {
                tokenProvider.setTokens(
                    accessToken: authResponse.accessToken,
                    refreshToken: authResponse.refreshToken
                )
                currentUser = authResponse.user
                isAuthenticated = true
            }
            print("✅ Token refreshed successfully")
        } catch {
            // Clear tokens on refresh failure
            await MainActor.run {
                tokenProvider.clearTokens()
                isAuthenticated = false
                currentUser = nil
            }
            print("❌ Token refresh failed: \(error.localizedDescription)")
        }
    }
    
    func loadCurrentUser() async {
        guard tokenProvider.isAuthenticated else { return }
        
        do {
            let user = try await authService.getCurrentUser()
            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
            print("✅ Current user loaded: \(user.displayName)")
        } catch {
            // Handle cases where token might be invalid
            await MainActor.run {
                tokenProvider.clearTokens()
                isAuthenticated = false
                currentUser = nil
            }
            print("❌ Failed to load current user: \(error.localizedDescription)")
        }
    }
    
    private func setupObservers() {
        // Observe token provider authentication state
        tokenProvider.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.isAuthenticated = isAuth
                print("🔐 Authentication state changed: \(isAuth)")
            }
            .store(in: &cancellables)
        
        // Observe authentication state changes
        $isAuthenticated
            .sink { isAuth in
                print("📱 App authentication state: \(isAuth)")
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        // Load authentication state on app start
        if tokenProvider.isAuthenticated {
            Task {
                await loadCurrentUser()
            }
        }
    }
}

// MARK: - Authentication Errors
enum AuthError: Error, LocalizedError {
    case unsupportedProvider
    case invalidToken
    case networkError
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            return "Unsupported authentication provider"
        case .invalidToken:
            return "Invalid authentication token"
        case .networkError:
            return "Network connection error"
        case .tokenExpired:
            return "Authentication token has expired"
        }
    }
}

// MARK: - Configuration
extension AppContainer {
    static func production() -> AppContainer {
        return AppContainer(useMockServices: false)
    }
    
    static func development() -> AppContainer {
        return AppContainer(useMockServices: true)
    }
    
    static func testing() -> AppContainer {
        return AppContainer(useMockServices: true)
    }
}
