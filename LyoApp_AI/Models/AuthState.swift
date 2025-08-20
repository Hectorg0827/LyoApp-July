import SwiftUI
import Combine

// MARK: - Authentication State Manager
class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: String?
    
    init() {
        // Initialize with any stored auth state if needed
    }
    
    func login(with tokens: AuthTokens) async {
        await MainActor.run {
            self.isLoading = true
            self.authError = nil
        }
        
        // Simulate authentication process
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            self.isAuthenticated = true
            self.isLoading = false
            // Create mock user for now
            self.currentUser = User(
                id: "mock_user_id",
                displayName: "Lyo User",
                email: "user@lyo.app",
                profilePictureURL: nil
            )
        }
    }
    
    func logout() async {
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
            self.authError = nil
        }
    }
}

// MARK: - AuthTokens Model
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}