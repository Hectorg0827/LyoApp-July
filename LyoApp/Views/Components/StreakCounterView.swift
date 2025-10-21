import SwiftUI

/// Streak counter component showing daily login streak
struct StreakCounterView: View {
    let currentStreak: Int
    let multiplier: Double
    let compact: Bool
    
    init(currentStreak: Int = 0, multiplier: Double = 1.0, compact: Bool = false) {
        self.currentStreak = currentStreak
        self.multiplier = multiplier
        self.compact = compact
    }
    
    private var streakLevel: StreakLevel {
        if currentStreak >= 100 {
            return .legendary
        } else if currentStreak >= 30 {
            return .epic
        } else if currentStreak >= 7 {
            return .hot
        } else if currentStreak >= 3 {
            return .warming
        } else {
            return .starting
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(streakLevel.color.opacity(0.15))
                    .frame(width: compact ? 36 : 44, height: compact ? 36 : 44)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: compact ? 16 : 20))
                    .foregroundColor(streakLevel.color)
            }
            
            // Streak info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: compact ? 16 : 20, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(currentStreak == 1 ? "day" : "days")
                        .font(.system(size: compact ? 12 : 14, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                if !compact && multiplier > 1.0 {
                    Text("\(String(format: "%.1f", multiplier))x XP bonus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(streakLevel.color)
                }
            }
            
            Spacer()
            
            // Streak level badge
            if !compact {
                Text(streakLevel.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(streakLevel.color)
                    )
            }
        }
        .padding(compact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.surfacePrimary)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Streak Level

enum StreakLevel {
    case starting
    case warming
    case hot
    case epic
    case legendary
    
    var name: String {
        switch self {
        case .starting: return "Starting"
        case .warming: return "Warming Up"
        case .hot: return "On Fire"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: Color {
        switch self {
        case .starting: return .orange
        case .warming: return .orange
        case .hot: return .red
        case .epic: return .purple
        case .legendary: return .indigo
        }
    }
}

// MARK: - Preview

#Preview("Streak Counter - Full") {
    VStack(spacing: 16) {
        StreakCounterView(currentStreak: 1, multiplier: 1.0, compact: false)
        StreakCounterView(currentStreak: 5, multiplier: 1.0, compact: false)
        StreakCounterView(currentStreak: 10, multiplier: 1.5, compact: false)
        StreakCounterView(currentStreak: 35, multiplier: 2.0, compact: false)
        StreakCounterView(currentStreak: 105, multiplier: 3.0, compact: false)
    }
    .padding()
    .background(Color.gray.opacity(0.05))
}

#Preview("Streak Counter - Compact") {
    VStack(spacing: 12) {
        StreakCounterView(currentStreak: 5, multiplier: 1.0, compact: true)
        StreakCounterView(currentStreak: 15, multiplier: 1.5, compact: true)
        StreakCounterView(currentStreak: 50, multiplier: 2.0, compact: true)
    }
    .padding()
    .background(Color.gray.opacity(0.05))
}
