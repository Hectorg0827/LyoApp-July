import SwiftUI

/// XP Progress Bar component showing current level, XP, and progress to next level
struct XPProgressBar: View {
    let currentXP: Int
    let currentLevel: Int
    let nextLevelXP: Int
    let showDetails: Bool
    
    init(currentXP: Int = 0, currentLevel: Int = 1, nextLevelXP: Int = 100, showDetails: Bool = true) {
        self.currentXP = currentXP
        self.currentLevel = currentLevel
        self.nextLevelXP = nextLevelXP
        self.showDetails = showDetails
    }
    
    private var levelName: String {
        switch currentLevel {
        case 1: return "Novice"
        case 2: return "Learner"
        case 3: return "Explorer"
        case 4: return "Achiever"
        case 5: return "Expert"
        case 6: return "Master"
        case 7: return "Virtuoso"
        case 8: return "Champion"
        case 9: return "Hero"
        case 10: return "Legend"
        default: return "Level \(currentLevel)"
        }
    }
    
    private var progress: Double {
        guard nextLevelXP > 0 else { return 0 }
        let previousLevelXP = GamificationService.shared.getXPForLevel(currentLevel)
        let xpInCurrentLevel = currentXP - previousLevelXP
        let xpNeededForLevel = nextLevelXP - previousLevelXP
        return Double(xpInCurrentLevel) / Double(xpNeededForLevel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showDetails {
                HStack {
                    // Level badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text("Lv \(currentLevel)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.15))
                    )
                    
                    Spacer()
                    
                    // XP counter
                    Text("\(currentXP) / \(nextLevelXP) XP")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignTokens.Colors.surfaceSecondary)
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
            
            if showDetails {
                // Level name
                Text(levelName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.surfacePrimary)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Preview

#Preview("XP Progress Bar - Full") {
    VStack(spacing: 20) {
        XPProgressBar(currentXP: 350, currentLevel: 3, nextLevelXP: 500, showDetails: true)
        XPProgressBar(currentXP: 75, currentLevel: 1, nextLevelXP: 100, showDetails: true)
        XPProgressBar(currentXP: 850, currentLevel: 5, nextLevelXP: 1000, showDetails: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("XP Progress Bar - Compact") {
    VStack(spacing: 20) {
        XPProgressBar(currentXP: 350, currentLevel: 3, nextLevelXP: 500, showDetails: false)
        XPProgressBar(currentXP: 75, currentLevel: 1, nextLevelXP: 100, showDetails: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
