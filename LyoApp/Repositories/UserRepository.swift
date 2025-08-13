import Foundation
import CoreData

// MARK: - User Repository
@MainActor
class UserRepository: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    @Published var users: [User] = []
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Current User Management
    func setCurrentUser(_ user: User) {
        currentUser = user
        // Save to UserDefaults for session persistence
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }
    
    // MARK: - User Operations
    func createUser(
        username: String,
        email: String,
        fullName: String,
        bio: String? = nil,
        profileImageURL: String? = nil
    ) async -> Result<User, Error> {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if user already exists
            if await userExists(username: username, email: email) {
                throw UserRepositoryError.userAlreadyExists
            }
            
            let coreDataUser = coreDataManager.createUser(
                username: username,
                email: email,
                fullName: fullName,
                bio: bio,
                profileImageURL: profileImageURL
            )
            
            let user = coreDataUser.toUser()
            await loadAllUsers()
            
            return .success(user)
        } catch {
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }
    
    func fetchUser(by id: UUID) async -> User? {
        return coreDataManager.fetchUser(by: id)?.toUser()
    }
    
    func loadAllUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        let coreDataUsers = coreDataManager.fetchAllUsers()
        users = coreDataUsers.map { $0.toUser() }
    }
    
    func updateUser(_ user: User) async -> Result<User, Error> {
        isLoading = true
        defer { isLoading = false }
        
        guard let coreDataUser = coreDataManager.fetchUser(by: user.id) else {
            let error = UserRepositoryError.userNotFound
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        // Update Core Data entity
        coreDataUser.username = user.username
        coreDataUser.email = user.email
        coreDataUser.fullName = user.fullName
        coreDataUser.bio = user.bio
        coreDataUser.profileImageURL = user.profileImageURL
        coreDataUser.followerCount = Int32(user.followers)
        coreDataUser.followingCount = Int32(user.following)
        coreDataUser.level = Int32(user.level)
        coreDataUser.experience = Int32(user.experience)
        
        coreDataManager.save()
        await loadAllUsers()
        
        return .success(user)
    }
    
    private func userExists(username: String, email: String) async -> Bool {
        let allUsers = coreDataManager.fetchAllUsers()
        return allUsers.contains { user in
            user.username == username || user.email == email
        }
    }
}

// MARK: - User Repository Errors
enum UserRepositoryError: LocalizedError {
    case userAlreadyExists
    case userNotFound
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .userAlreadyExists:
            return "A user with this username or email already exists"
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid username or password"
        }
    }
}
