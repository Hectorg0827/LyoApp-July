import Foundation
import LocalAuthentication

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userRepository = UserRepository()
    private let keychain = KeychainHelper()
    
    private init() {
        loadAuthState()
    }
    
    // MARK: - Authentication State
    private func loadAuthState() {
        // Check if we have a stored auth token
        if let _ = keychain.read(service: "LyoApp", account: "authToken") {
            userRepository.loadCurrentUser()
            currentUser = userRepository.currentUser
            isAuthenticated = currentUser != nil
        }
    }
    
    // MARK: - Registration
    func register(
        username: String,
        email: String,
        fullName: String,
        password: String,
        bio: String? = nil
    ) async -> Result<User, AuthenticationError> {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Validate input
        guard !username.isEmpty, !email.isEmpty, !fullName.isEmpty, !password.isEmpty else {
            let error = AuthenticationError.invalidInput
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        guard isValidEmail(email) else {
            let error = AuthenticationError.invalidEmail
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        guard password.count >= 6 else {
            let error = AuthenticationError.passwordTooShort
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        // Create user in repository
        let result = await userRepository.createUser(
            username: username,
            email: email,
            fullName: fullName,
            bio: bio
        )
        
        switch result {
        case .success(let user):
            // Store credentials securely
            keychain.save(password.data(using: .utf8)!, service: "LyoApp", account: "\(user.id)_password")
            
            // Generate and store auth token
            let authToken = generateAuthToken()
            keychain.save(authToken.data(using: .utf8)!, service: "LyoApp", account: "authToken")
            
            // Set current user
            currentUser = user
            userRepository.setCurrentUser(user)
            isAuthenticated = true
            
            return .success(user)
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            return .failure(.registrationFailed)
        }
    }
    
    // MARK: - Login
    func login(username: String, password: String) async -> Result<User, AuthenticationError> {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard !username.isEmpty, !password.isEmpty else {
            let error = AuthenticationError.invalidCredentials
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        // In a real app, this would validate against a backend
        // For now, we'll check against Core Data
        await userRepository.loadAllUsers()
        
        guard let user = userRepository.users.first(where: { 
            $0.username == username || $0.email == username 
        }) else {
            let error = AuthenticationError.userNotFound
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        // Verify password (in a real app, this would be hashed)
        guard let storedPassword = keychain.read(service: "LyoApp", account: "\(user.id)_password"),
              let passwordString = String(data: storedPassword, encoding: .utf8),
              passwordString == password else {
            let error = AuthenticationError.invalidCredentials
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        // Generate and store new auth token
        let authToken = generateAuthToken()
        keychain.save(authToken.data(using: .utf8)!, service: "LyoApp", account: "authToken")
        
        // Set current user
        currentUser = user
        userRepository.setCurrentUser(user)
        isAuthenticated = true
        
        return .success(user)
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async -> Result<Bool, AuthenticationError> {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(.biometricNotAvailable)
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your LyoApp account"
            )
            
            if success && currentUser != nil {
                isAuthenticated = true
                return .success(true)
            } else {
                return .failure(.biometricFailed)
            }
        } catch {
            return .failure(.biometricFailed)
        }
    }
    
    // MARK: - Logout
    func logout() {
        isAuthenticated = false
        currentUser = nil
        
        // Clear stored tokens
        keychain.delete(service: "LyoApp", account: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // MARK: - Utility Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func generateAuthToken() -> String {
        return UUID().uuidString + Date().timeIntervalSince1970.description
    }
    
    // MARK: - Password Reset (Mock Implementation)
    func requestPasswordReset(email: String) async -> Result<Bool, AuthenticationError> {
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        // In a real app, this would send a reset email
        // For now, just simulate success
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return .success(true)
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError {
    case invalidInput
    case invalidEmail
    case invalidCredentials
    case passwordTooShort
    case userNotFound
    case registrationFailed
    case biometricNotAvailable
    case biometricFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all required fields"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidCredentials:
            return "Invalid username or password"
        case .passwordTooShort:
            return "Password must be at least 6 characters long"
        case .userNotFound:
            return "User not found"
        case .registrationFailed:
            return "Failed to create account. Please try again."
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        // Delete any existing item
        SecItemDelete(query)
        
        // Add new item
        SecItemAdd(query, nil)
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return result as? Data
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        SecItemDelete(query)
    }
}
