import SwiftUI

/// Badge display component showing earned badges
struct BadgeDisplayView: View {
    let badges: [GamificationService.BadgeType]
    let compact: Bool
    
    init(badges: [GamificationService.BadgeType] = [], compact: Bool = false) {
        self.badges = badges
        self.compact = compact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !compact {
                Text("Achievements")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            if badges.isEmpty {
                emptyState
            } else {
                badgeGrid
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("No badges yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("Complete lessons to earn badges!")
                .font(.system(size: 12))
                .foregroundColor(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var badgeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: compact ? 60 : 80), spacing: 12)
        ], spacing: 12) {
            ForEach(badges, id: \.self) { badge in
                BadgeCard(badge: badge, compact: compact)
            }
        }
    }
}

// MARK: - Badge Card

struct BadgeCard: View {
    let badge: GamificationService.BadgeType
    let compact: Bool
    
    private var badgeInfo: (icon: String, color: Color, name: String) {
        switch badge {
        case .firstStep:
            return ("figure.walk", .green, "First Step")
        case .fastLearner:
            return ("bolt.fill", .orange, "Fast Learner")
        case .perfectScore:
            return ("star.fill", .yellow, "Perfect Score")
        case .streakWarrior:
            return ("flame.fill", .red, "Streak Warrior")
        case .marathonRunner:
            return ("figure.run", .blue, "Marathon Runner")
        case .earlyBird:
            return ("sunrise.fill", .orange, "Early Bird")
        case .nightOwl:
            return ("moon.stars.fill", .purple, "Night Owl")
        case .weekendWarrior:
            return ("calendar", .indigo, "Weekend Warrior")
        case .allRounder:
            return ("circle.grid.3x3.fill", .cyan, "All Rounder")
        case .speedster:
            return ("hare.fill", .green, "Speedster")
        case .focused:
            return ("target", .red, "Focused")
        case .social:
            return ("person.2.fill", .pink, "Social")
        case .helper:
            return ("hand.raised.fill", .teal, "Helper")
        case .mentor:
            return ("graduationcap.fill", .indigo, "Mentor")
        case .champion:
            return ("crown.fill", .yellow, "Champion")
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(badgeInfo.color.opacity(0.15))
                    .frame(width: compact ? 50 : 60, height: compact ? 50 : 60)
                
                Image(systemName: badgeInfo.icon)
                    .font(.system(size: compact ? 20 : 26))
                    .foregroundColor(badgeInfo.color)
            }
            
            // Badge name
            if !compact {
                Text(badgeInfo.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Badge Display - Full") {
    ScrollView {
        BadgeDisplayView(badges: [
            .firstStep,
            .fastLearner,
            .perfectScore,
            .streakWarrior,
            .marathonRunner,
            .earlyBird
        ], compact: false)
        .padding()
    }
    .background(Color.gray.opacity(0.05))
}

#Preview("Badge Display - Compact") {
    BadgeDisplayView(badges: [
        .firstStep,
        .fastLearner,
        .perfectScore,
        .streakWarrior
    ], compact: true)
    .padding()
    .background(Color.gray.opacity(0.05))
}

#Preview("Badge Display - Empty") {
    BadgeDisplayView(badges: [], compact: false)
        .padding()
        .background(Color.gray.opacity(0.05))
}
