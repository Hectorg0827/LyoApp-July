import SwiftUI

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
    
    // MARK: - Enhanced Authentication
    @MainActor
    func authenticateUser(email: String, password: String) async {
        isLoading = true
        
        do {
            // In a real app, authenticate with backend
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            
            // Create mock user
            let user = User(
                id: UUID(),
                username: email.components(separatedBy: "@").first ?? "User",
                email: email,
                fullName: "Demo User",
                bio: "Welcome to LyoApp!",
                profileImageURL: nil,
                followers: 0,
                following: 0,
                posts: 0,
                badges: [],
                level: 1,
                experience: 0,
                joinDate: Date(),
                isVerified: false
            )
            
            currentUser = user
            isAuthenticated = true
            
            // Track analytics
            AnalyticsManager.shared.trackUserAction("user_login", parameters: ["method": "email"])
            
            // Save authentication state
            StorageManager.shared.saveUserPreference(true, forKey: "isAuthenticated")
            StorageManager.shared.saveUserPreference(user, forKey: "currentUser")
            
        } catch {
            ErrorTracker.shared.trackError(error, context: "Authentication")
            // Handle error
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        
        // Clear stored data
        StorageManager.shared.saveUserPreference(false, forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        // Track analytics
        AnalyticsManager.shared.trackUserAction("user_logout")
    }
    
    // MARK: - Enhanced Gamification
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
        let progress = LearningProgress(
            courseId: courseId,
            lessonId: lessonId,
            percentage: 100.0, // Assuming lesson completed
            timeSpent: timeSpent
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
        }
    }
    
    func trackUserAction(_ action: String, parameters: [String: Any] = [:]) -> some View {
        self.onTapGesture {
            AnalyticsManager.shared.trackUserAction(action, parameters: parameters)
        }
    }
}
