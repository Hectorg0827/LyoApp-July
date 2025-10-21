import Foundation
import SwiftUI

// MARK: - Gamification Service
/// Comprehensive gamification system with XP, levels, badges, streaks, and leaderboards

@MainActor
final class GamificationService: ObservableObject {
    static let shared = GamificationService()
    
    // MARK: - Published Properties
    @Published var currentLevel: UserLevel = .bronze
    @Published var totalXP: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var earnedBadges: [Badge] = []
    @Published var recentAchievements: [Achievement] = []
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let xpKey = "gamification_totalXP"
    private let levelKey = "gamification_level"
    private let streakKey = "gamification_currentStreak"
    private let longestStreakKey = "gamification_longestStreak"
    private let lastActivityKey = "gamification_lastActivity"
    private let badgesKey = "gamification_badges"
    
    private init() {
        loadGamificationData()
    }
    
    // MARK: - XP & Leveling System
    
    /// Award XP and check for level ups
    func awardXP(_ amount: Int, reason: String) {
        totalXP += amount
        saveGamificationData()
        
        print("🎖️ [Gamification] +\(amount) XP - \(reason)")
        
        // Check for level up
        checkLevelUp()
        
        // Record achievement
        let achievement = Achievement(
            title: reason,
            xpAwarded: amount,
            timestamp: Date()
        )
        recentAchievements.insert(achievement, at: 0)
        
        // Keep only last 10 achievements
        if recentAchievements.count > 10 {
            recentAchievements = Array(recentAchievements.prefix(10))
        }
    }
    
    /// Check if user leveled up
    private func checkLevelUp() {
        let newLevel = UserLevel.fromXP(totalXP)
        
        if newLevel != currentLevel {
            let oldLevel = currentLevel
            currentLevel = newLevel
            saveGamificationData()
            
            print("🎉 [Gamification] LEVEL UP! \(oldLevel.displayName) → \(newLevel.displayName)")
            
            // Award level-up badge
            awardBadge(.levelUp(level: newLevel))
            
            // Create level-up achievement
            let achievement = Achievement(
                title: "Level Up to \(newLevel.displayName)!",
                xpAwarded: 0,
                timestamp: Date(),
                isMilestone: true
            )
            recentAchievements.insert(achievement, at: 0)
        }
    }
    
    /// Get progress to next level (0.0 - 1.0)
    var progressToNextLevel: Double {
        let nextLevel = currentLevel.nextLevel
        let currentLevelXP = currentLevel.xpRequired
        let nextLevelXP = nextLevel?.xpRequired ?? currentLevelXP
        
        let progressXP = totalXP - currentLevelXP
        let requiredXP = nextLevelXP - currentLevelXP
        
        return min(1.0, max(0.0, Double(progressXP) / Double(requiredXP)))
    }
    
    /// XP needed for next level
    var xpToNextLevel: Int {
        guard let nextLevel = currentLevel.nextLevel else { return 0 }
        return max(0, nextLevel.xpRequired - totalXP)
    }
    
    // MARK: - Streak System
    
    /// Update streak (call this when user completes a lesson)
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastActivity = userDefaults.object(forKey: lastActivityKey) as? Date {
            let lastActivityDay = calendar.startOfDay(for: lastActivity)
            let daysDifference = calendar.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Same day - no change
                print("🔥 [Gamification] Streak maintained: \(currentStreak) days")
            } else if daysDifference == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
                print("🔥 [Gamification] Streak increased: \(currentStreak) days")
                
                // Check for streak badges
                checkStreakBadges()
            } else {
                // Streak broken
                print("💔 [Gamification] Streak broken! Was \(currentStreak) days")
                currentStreak = 1
            }
        } else {
            // First activity
            currentStreak = 1
            longestStreak = 1
            print("🔥 [Gamification] Streak started: 1 day")
        }
        
        // Update last activity
        userDefaults.set(Date(), forKey: lastActivityKey)
        saveGamificationData()
    }
    
    private func checkStreakBadges() {
        if currentStreak == 7 {
            awardBadge(.streak(days: 7))
        } else if currentStreak == 30 {
            awardBadge(.streak(days: 30))
        } else if currentStreak == 100 {
            awardBadge(.streak(days: 100))
        }
    }
    
    // MARK: - Badge System
    
    /// Award a badge to the user
    func awardBadge(_ badge: Badge) {
        // Check if already earned
        guard !earnedBadges.contains(where: { $0.id == badge.id }) else {
            return
        }
        
        earnedBadges.append(badge)
        saveGamificationData()
        
        print("🏆 [Gamification] Badge earned: \(badge.title)")
        
        // Create achievement for badge
        let achievement = Achievement(
            title: "🏆 \(badge.title)",
            xpAwarded: badge.xpReward,
            timestamp: Date(),
            isMilestone: true
        )
        recentAchievements.insert(achievement, at: 0)
        
        // Award XP for badge
        if badge.xpReward > 0 {
            awardXP(badge.xpReward, reason: "Earned badge: \(badge.title)")
        }
    }
    
    /// Check and award badges based on achievements
    func checkAndAwardBadges(
        lessonsCompleted: Int,
        coursesCompleted: Int,
        quizScore: Double? = nil,
        timeSpent: TimeInterval
    ) {
        // Lesson completion badges
        if lessonsCompleted == 1 {
            awardBadge(.firstLesson)
        } else if lessonsCompleted == 10 {
            awardBadge(.lessonCount(count: 10))
        } else if lessonsCompleted == 50 {
            awardBadge(.lessonCount(count: 50))
        } else if lessonsCompleted == 100 {
            awardBadge(.lessonCount(count: 100))
        }
        
        // Course completion badges
        if coursesCompleted == 1 {
            awardBadge(.firstCourse)
        } else if coursesCompleted == 5 {
            awardBadge(.courseCount(count: 5))
        } else if coursesCompleted == 20 {
            awardBadge(.courseCount(count: 20))
        }
        
        // Perfect score badge
        if let score = quizScore, score >= 1.0 {
            awardBadge(.perfectScore)
        }
        
        // Time-based badges
        let hoursSpent = Int(timeSpent / 3600)
        if hoursSpent >= 10 {
            awardBadge(.timeSpent(hours: 10))
        }
        if hoursSpent >= 50 {
            awardBadge(.timeSpent(hours: 50))
        }
        if hoursSpent >= 100 {
            awardBadge(.timeSpent(hours: 100))
        }
    }
    
    // MARK: - Leaderboard (Local/Mock for now)
    
    /// Get leaderboard rankings
    func getLeaderboard() -> [LeaderboardEntry] {
        // TODO: Replace with real backend API call
        // For now, return mock data with current user
        
        let currentUserEntry = LeaderboardEntry(
            rank: calculateRank(xp: totalXP),
            username: "You",
            level: currentLevel,
            xp: totalXP,
            streak: currentStreak,
            isCurrentUser: true
        )
        
        return [currentUserEntry] + generateMockLeaderboard()
    }
    
    private func calculateRank(xp: Int) -> Int {
        // Simple ranking based on XP
        // TODO: Replace with real ranking from backend
        if xp >= 10000 { return 1 }
        if xp >= 5000 { return 2 }
        if xp >= 2500 { return 3 }
        if xp >= 1000 { return 4 }
        if xp >= 500 { return 5 }
        return 6
    }
    
    private func generateMockLeaderboard() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(rank: 1, username: "CodeMaster", level: .platinum, xp: 15000, streak: 45),
            LeaderboardEntry(rank: 2, username: "SwiftNinja", level: .gold, xp: 8500, streak: 30),
            LeaderboardEntry(rank: 3, username: "DevPro", level: .gold, xp: 6200, streak: 25),
            LeaderboardEntry(rank: 4, username: "TechGuru", level: .silver, xp: 3800, streak: 15),
            LeaderboardEntry(rank: 5, username: "LearningFan", level: .silver, xp: 2100, streak: 12)
        ]
    }
    
    // MARK: - Persistence
    
    private func loadGamificationData() {
        totalXP = userDefaults.integer(forKey: xpKey)
        currentStreak = userDefaults.integer(forKey: streakKey)
        longestStreak = userDefaults.integer(forKey: longestStreakKey)
        
        if let levelRaw = userDefaults.string(forKey: levelKey),
           let level = UserLevel(rawValue: levelRaw) {
            currentLevel = level
        }
        
        if let badgesData = userDefaults.data(forKey: badgesKey),
           let badges = try? JSONDecoder().decode([Badge].self, from: badgesData) {
            earnedBadges = badges
        }
        
        // Recalculate level based on XP (in case XP was manually adjusted)
        currentLevel = UserLevel.fromXP(totalXP)
        
        print("📦 [Gamification] Loaded: \(totalXP) XP, Level \(currentLevel.displayName), \(currentStreak)-day streak")
    }
    
    private func saveGamificationData() {
        userDefaults.set(totalXP, forKey: xpKey)
        userDefaults.set(currentLevel.rawValue, forKey: levelKey)
        userDefaults.set(currentStreak, forKey: streakKey)
        userDefaults.set(longestStreak, forKey: longestStreakKey)
        
        if let badgesData = try? JSONEncoder().encode(earnedBadges) {
            userDefaults.set(badgesData, forKey: badgesKey)
        }
        
        print("💾 [Gamification] Saved: \(totalXP) XP, \(currentLevel.displayName)")
    }
    
    // MARK: - Reset (for testing)
    
    func resetGamification() {
        totalXP = 0
        currentLevel = .bronze
        currentStreak = 0
        longestStreak = 0
        earnedBadges = []
        recentAchievements = []
        
        userDefaults.removeObject(forKey: xpKey)
        userDefaults.removeObject(forKey: levelKey)
        userDefaults.removeObject(forKey: streakKey)
        userDefaults.removeObject(forKey: longestStreakKey)
        userDefaults.removeObject(forKey: lastActivityKey)
        userDefaults.removeObject(forKey: badgesKey)
        
        print("🔄 [Gamification] Reset complete")
    }
}

// MARK: - User Level

enum UserLevel: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .platinum: return "💎"
        case .diamond: return "💠"
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
        case .diamond: return Color(red: 0.7, green: 0.9, blue: 1.0)
        }
    }
    
    var xpRequired: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 500
        case .gold: return 2000
        case .platinum: return 5000
        case .diamond: return 10000
        }
    }
    
    var nextLevel: UserLevel? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return .platinum
        case .platinum: return .diamond
        case .diamond: return nil
        }
    }
    
    static func fromXP(_ xp: Int) -> UserLevel {
        if xp >= UserLevel.diamond.xpRequired { return .diamond }
        if xp >= UserLevel.platinum.xpRequired { return .platinum }
        if xp >= UserLevel.gold.xpRequired { return .gold }
        if xp >= UserLevel.silver.xpRequired { return .silver }
        return .bronze
    }
}

// MARK: - Badge

struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let xpReward: Int
    let rarity: BadgeRarity
    
    enum BadgeRarity: String, Codable {
        case common
        case rare
        case epic
        case legendary
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
    }
    
    // Predefined badges
    static let firstLesson = Badge(
        id: "first_lesson",
        title: "First Steps",
        description: "Complete your first lesson",
        icon: "🎓",
        xpReward: 50,
        rarity: .common
    )
    
    static let firstCourse = Badge(
        id: "first_course",
        title: "Course Complete",
        description: "Finish your first course",
        icon: "🎯",
        xpReward: 100,
        rarity: .rare
    )
    
    static let perfectScore = Badge(
        id: "perfect_score",
        title: "Perfectionist",
        description: "Get 100% on a quiz",
        icon: "💯",
        xpReward: 75,
        rarity: .rare
    )
    
    static func levelUp(level: UserLevel) -> Badge {
        Badge(
            id: "level_\(level.rawValue)",
            title: "\(level.displayName) Rank",
            description: "Reach \(level.displayName) level",
            icon: level.icon,
            xpReward: 200,
            rarity: .epic
        )
    }
    
    static func streak(days: Int) -> Badge {
        Badge(
            id: "streak_\(days)",
            title: "\(days)-Day Streak",
            description: "Learn for \(days) days in a row",
            icon: "🔥",
            xpReward: days * 10,
            rarity: days >= 30 ? .legendary : .epic
        )
    }
    
    static func lessonCount(count: Int) -> Badge {
        Badge(
            id: "lessons_\(count)",
            title: "\(count) Lessons",
            description: "Complete \(count) lessons",
            icon: "📚",
            xpReward: count * 5,
            rarity: count >= 100 ? .legendary : (count >= 50 ? .epic : .rare)
        )
    }
    
    static func courseCount(count: Int) -> Badge {
        Badge(
            id: "courses_\(count)",
            title: "\(count) Courses",
            description: "Complete \(count) courses",
            icon: "🏆",
            xpReward: count * 50,
            rarity: count >= 20 ? .legendary : .epic
        )
    }
    
    static func timeSpent(hours: Int) -> Badge {
        Badge(
            id: "time_\(hours)",
            title: "\(hours) Hours",
            description: "Spend \(hours) hours learning",
            icon: "⏰",
            xpReward: hours * 10,
            rarity: hours >= 100 ? .legendary : (hours >= 50 ? .epic : .rare)
        )
    }
}

// MARK: - Achievement

struct Achievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let xpAwarded: Int
    let timestamp: Date
    var isMilestone: Bool = false
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let username: String
    let level: UserLevel
    let xp: Int
    let streak: Int
    var isCurrentUser: Bool = false
    
    var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
}

// MARK: - XP Rewards Reference

enum XPReward {
    static let lessonComplete = 50
    static let chunkComplete = 10
    static let quizPerfect = 75
    static let quizPass = 30
    static let courseComplete = 200
    static let dailyGoal = 25
    static let streakMaintained = 15
}
