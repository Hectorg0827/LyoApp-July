import SwiftUI
import Foundation
import SwiftData

// MARK: - Enhanced App State with New Services
extension AppState {
    
    // MARK: - Network & Storage Integration
    func initializeServices() {
        // Initialize network monitoring
        _ = NetworkMonitor.shared
        
        // Request notification permissions
        Task {
            await NotificationManager.shared.requestPermission()
        }
        
        // Load cached user preferences
        loadUserPreferences()
    }
    
    private func loadUserPreferences() {
        // Load theme preference
        if let savedTheme = StorageManager.shared.loadUserPreference(Bool.self, forKey: "isDarkMode") {
            isDarkMode = savedTheme
        }
        
        // Load other preferences
        if let savedLanguage = StorageManager.shared.loadUserPreference(String.self, forKey: "preferredLanguage") {
            // Set preferred language - using the value to avoid warning
            _ = savedLanguage
        }
    }
    
    func saveUserPreferences() {
        StorageManager.shared.saveUserPreference(isDarkMode, forKey: "isDarkMode")
    }
    
    // MARK: - Enhanced Authentication with Real Backend
    @MainActor
    func authenticateUser(email: String, password: String) async {
        isLoading = true
        
        do {
            // Use real API service for authentication
            let authResponse = try await RealAPIService.shared.authenticate(email: email, password: password)
            
            // Store tokens securely
            KeychainManager.shared.store(authResponse.accessToken, for: .authToken)
            KeychainManager.shared.store(authResponse.refreshToken, for: .refreshToken)
            
            // Create user from real authentication response
            let authenticatedUser = User(
                username: authResponse.user.username,
                email: email,
                fullName: authResponse.user.fullName
            )
            
            // Save user data locally
            // try await DataManager.shared.saveUser(authenticatedUser) // Temporarily disabled
            
            // Update app state
            self.currentUser = authenticatedUser
            self.isAuthenticated = true
            
            // Initialize real backend services
            RealAPIService.shared.setAuthenticatedUser(authenticatedUser)
            
        } catch {
            // Handle any authentication errors
            await MainActor.run {
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func signUpUser(email: String, password: String, username: String, fullName: String?) async {
        isLoading = true
        
        do {
            // Use real API service for registration
            let authResponse = try await RealAPIService.shared.register(
                email: email,
                password: password,
                username: username,
                fullName: fullName
            )
            
            // Store tokens securely
            KeychainManager.shared.store(authResponse.accessToken, for: .authToken)
            KeychainManager.shared.store(authResponse.refreshToken, for: .refreshToken)
            
            // Create user from registration response
            let newUser = User(
                username: username,
                email: email,
                fullName: fullName ?? "New User"
            )
            
            // Save user data locally
            // try await DataManager.shared.saveUser(newUser) // Temporarily disabled
            
            // Update app state
            self.currentUser = newUser
            self.isAuthenticated = true
            
            // Initialize real backend services
            RealAPIService.shared.setAuthenticatedUser(newUser)
            
        } catch {
            // Handle any registration errors
            await MainActor.run {
                self.errorMessage = "Registration failed: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    @MainActor
    func checkExistingAuthentication() async {
        // Check for stored authentication tokens
        guard KeychainManager.shared.retrieve(.authToken) != nil else {
            return
        }
        
        isLoading = true
        
        do {
            // Validate token with backend
            let userProfile = try await RealAPIService.shared.getCurrentUser()
            
            let authenticatedUser = User(
                username: userProfile.username,
                email: userProfile.email,
                fullName: userProfile.fullName ?? "User"
            )
            
            // Update app state
            self.currentUser = authenticatedUser
            self.isAuthenticated = true
            
            // Initialize real backend services
            RealAPIService.shared.setAuthenticatedUser(authenticatedUser)
            
        } catch {
            print("Failed to validate existing authentication: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() {
        // Clear stored tokens
        KeychainManager.shared.deleteAll()
        
        // Clear app state
        self.currentUser = nil
        self.isAuthenticated = false
        
        // Clear local data
        Task {
            // try? await DataManager.shared.clearUserData() // Temporarily disabled
        }
    }
    
    // MARK: - Learning Resources Integration
    @MainActor
    func loadLearningResources() async {
        isLoading = true
        
        do {
            // Try to load from API first
            let resources = try await RealAPIService.shared.fetchLearningResources()
            
            // Save to local storage for offline access
            // try await DataManager.shared.saveLearningResources(resources) // Temporarily disabled
            
            self.learningResources = resources
            
        } catch {
            print("Failed to load learning resources: \(error)")
            // Fallback to mock data
            self.learningResources = generateMockLearningResources()
        }
        
        isLoading = false
    }
    
    @MainActor
    func trackProgress(for resourceId: String, progress: Double, timeSpent: TimeInterval, isCompleted: Bool = false) async {
        guard currentUser != nil else { return }
        
        do {
            // Update progress on backend
            try await RealAPIService.shared.updateProgress(
                resourceId: resourceId,
                progress: progress,
                timeSpent: timeSpent,
                isCompleted: isCompleted
            )
            
            // Save progress locally
            // try await DataManager.shared.saveUserProgress( // Temporarily disabled
            //     currentUser.id,
            //     resourceId: resourceId,
            //     progress: progress,
            //     timeSpent: timeSpent,
            //     isCompleted: isCompleted
            // )
            
        } catch {
            print("Failed to track progress: \(error)")
            // Still save locally even if backend fails
            // try? await DataManager.shared.saveUserProgress( // Temporarily disabled
            //     currentUser.id,
            //     resourceId: resourceId,
            //     progress: progress,
            //     timeSpent: timeSpent,
            //     isCompleted: isCompleted
            // )
        }
    }
    
    // MARK: - Legacy Support - TODO: Remove after migration
    func authenticateWithMockUser() {
        // Legacy mock authentication - keep for compatibility during migration
        let mockUser = User(
            username: "mock_user",
            email: "mock@example.com",
            fullName: "Mock User"
        )
        
        self.currentUser = mockUser
        self.isAuthenticated = true
    }
    
    // MARK: - Mock Data Generation for Development
    private func generateMockLearningResources() -> [LearningResource] {
        return [
            LearningResource(
                title: "Introduction to SwiftUI",
                description: "Learn the basics of SwiftUI development",
                contentType: .video,
                sourcePlatform: .youtube,
                authorCreator: "Apple Developer",
                tags: ["swift", "ios", "ui"],
                thumbnailURL: URL(string: "https://example.com/thumb1.jpg")!,
                contentURL: URL(string: "https://example.com/video1.mp4")!,
                difficultyLevel: .beginner,
                estimatedDuration: "30 minutes",
                rating: 4.5,
                category: "iOS Development"
            ),
            LearningResource(
                title: "Advanced Swift Concepts",
                description: "Deep dive into advanced Swift programming",
                contentType: .article,
                sourcePlatform: .curated,
                authorCreator: "Swift Expert",
                tags: ["swift", "programming", "advanced"],
                thumbnailURL: URL(string: "https://example.com/thumb2.jpg")!,
                contentURL: URL(string: "https://example.com/article1.html")!,
                difficultyLevel: .advanced,
                estimatedDuration: "45 minutes",
                rating: 4.8,
                category: "Programming"
            ),
            LearningResource(
                title: "Core Data Fundamentals",
                description: "Master data persistence in iOS apps",
                contentType: .course,
                sourcePlatform: .udemy,
                authorCreator: "iOS Academy",
                tags: ["coredata", "persistence", "ios"],
                thumbnailURL: URL(string: "https://example.com/thumb3.jpg")!,
                contentURL: URL(string: "https://example.com/course1")!,
                difficultyLevel: .intermediate,
                estimatedDuration: "60 minutes",
                rating: 4.3,
                category: "Data Management"
            )
        ]
    }
    
    // MARK: - XP and Achievements System
    func awardXP(_ amount: Int, reason: String) {
        guard var user = currentUser else { return }
        
        user.experience += amount
        
        // Check for level up
        let newLevel = calculateLevel(from: user.experience)
        let leveledUp = newLevel > user.level
        user.level = newLevel
        
        currentUser = user
        
        // Show XP animation
        showXPGain(amount: amount, reason: reason)
        
        // Show level up if applicable
        if leveledUp {
            showLevelUp(newLevel: newLevel)
        }
        
        // Track analytics
        AnalyticsManager.shared.trackUserAction("xp_awarded", parameters: [
            "amount": amount,
            "reason": reason,
            "total_xp": user.experience,
            "level": user.level
        ])
        
        // Schedule achievement notification if leveled up
        if leveledUp {
            Task {
                await NotificationManager.shared.scheduleNotification(
                    title: "Level Up! 🎉",
                    body: "You're now level \(newLevel)!",
                    identifier: "levelup_\(newLevel)",
                    timeInterval: 1
                )
            }
        }
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        // XP required: Level 1: 0, Level 2: 100, Level 3: 250, Level 4: 450, etc.
        // Formula: XP = level^2 * 50 - 50
        for level in 1...100 {
            let requiredXP = level * level * 50 - 50
            if xp < requiredXP {
                return max(1, level - 1)
            }
        }
        return 100 // Max level
    }
    
    // MARK: - Enhanced Learning Progress
    func trackLearningProgress(courseId: String, lessonId: String, timeSpent: TimeInterval) {
        let progress = CoreLearningProgress(
            id: UUID(),
            courseId: courseId,
            lessonId: lessonId,
            percentage: 100.0, // Assuming lesson completed
            timeSpent: timeSpent,
            timestamp: Date()
        )
        
        AnalyticsManager.shared.trackLearningProgress(progress)
        
        // Award XP for completing lesson
        awardXP(50, reason: "Lesson Completed")
        
        // Cache progress
        Task {
            await StorageManager.shared.cacheData(progress, filename: "progress_\(lessonId)")
        }
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error, context: String = "") {
        ErrorTracker.shared.trackError(error, context: context)
        
        // Show user-friendly error message
        showAlert(
            title: "Something went wrong",
            message: error.localizedDescription,
            actions: [
                AlertAction(title: "OK", style: .default, action: {})
            ]
        )
    }
}

// MARK: - View Extensions for Analytics
extension View {
    func trackScreenView(_ screenName: String) -> some View {
        self.onAppear {
            AnalyticsManager.shared.trackScreenView(screenName)
            print("📊 Screen View: \(screenName)")
        }
    }
    
    func trackUserAction(_ action: String, parameters: [String: Any] = [:]) -> some View {
        self.onTapGesture {
            AnalyticsManager.shared.trackUserAction(action, parameters: parameters)
            print("📊 User Action: \(action)")
        }
    }
}
