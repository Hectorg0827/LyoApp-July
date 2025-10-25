import SwiftUI

struct GamificationOverlay: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var gamificationService = GamificationService.shared
    
    var body: some View {
        ZStack {
            // Achievement Notifications
            ForEach(gamificationService.pendingAchievements) { achievement in
                AchievementNotification(achievement: achievement)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(Double(achievement.id.hashValue))
            }
            
            // Level Up Notifications
            ForEach(gamificationService.levelUpNotifications) { notification in
                LevelUpNotification(notification: notification)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .zIndex(Double(notification.id.hashValue))
            }
            
            // XP Animations
            ForEach(gamificationService.xpAnimations) { animation in
                XPAnimation(animation: animation)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(Double(animation.id.hashValue))
            }
        }
        .animation(DesignTokens.Animations.bouncy, value: gamificationService.pendingAchievements.count)
        .animation(DesignTokens.Animations.bouncy, value: gamificationService.levelUpNotifications.count)
        .animation(DesignTokens.Animations.gentle, value: gamificationService.xpAnimations.count)
    }
}

// MARK: - Achievement Notification
struct AchievementNotification: View {
    let achievement: AchievementData
    @StateObject private var gamificationService = GamificationService.shared
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: achievement.badge.iconName)
                            .font(.title2)
                            .foregroundColor(achievement.badge.rarity.color)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(achievement.badge.rarity.color.opacity(0.1))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Achievement Unlocked!")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                            
                            Text(achievement.badge.name)
                                .font(DesignTokens.Typography.bodyMedium)
                            
                            Text(achievement.badge.description)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                                .lineLimit(2)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .fill(DesignTokens.Colors.background)
                        .shadow(
                            color: DesignTokens.Shadows.elevation4.color,
                            radius: DesignTokens.Shadows.elevation4.radius,
                            x: DesignTokens.Shadows.elevation4.x,
                            y: DesignTokens.Shadows.elevation4.y
                        )
                )
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0.0)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.xl)
            
            Spacer()
        }
        .onAppear {
            withAnimation(DesignTokens.Animations.bouncy) {
                isVisible = true
            }
            
            // Auto dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismiss()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    private func dismiss() {
        withAnimation(DesignTokens.Animations.quick) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            gamificationService.dismissAchievement(achievement.id)
        }
    }
}

// MARK: - Level Up Notification
struct LevelUpNotification: View {
    let notification: LevelUpNotificationData
    @StateObject private var gamificationService = GamificationService.shared
    @State private var isVisible = false
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .opacity(isVisible ? 1.0 : 0.0)
            
            // Particles
            ForEach(particles) { particle in
                GamificationParticleView(particle: particle)
            }
            
            // Main content
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                    
                    VStack {
                        Text("LEVEL")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(notification.newLevel)")
                            .font(DesignTokens.Typography.hero)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Level Up!")
                        .font(DesignTokens.Typography.title1)
                        .foregroundColor(.white)
                    
                    Text("You've reached level \(notification.newLevel)!")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    if !notification.unlockedFeatures.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("New Features Unlocked:")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(notification.unlockedFeatures, id: \.self) { feature in
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(DesignTokens.Colors.secondary)
                                    Text(feature)
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(.white.opacity(0.1))
                        )
                    }
                }
                
                Button("Continue") {
                    dismiss()
                }
                .primaryButton()
                .frame(width: 200)
            }
            .padding(DesignTokens.Spacing.xl)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(DesignTokens.Animations.bouncy.delay(0.1)) {
                isVisible = true
            }
            
            // Generate particles
            generateParticles()
        }
    }
    
    private func dismiss() {
        withAnimation(DesignTokens.Animations.quick) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            gamificationService.dismissLevelUp(notification.id)
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                color: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary, .yellow, .orange].randomElement()!
            )
        }
    }
}

// MARK: - XP Animation
struct XPAnimation: View {
    let animation: XPAnimationData
    @StateObject private var gamificationService = GamificationService.shared
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Text("+\(animation.xpGained) XP")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.success)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(DesignTokens.Colors.success.opacity(0.1))
                            .strokeBorder(DesignTokens.Colors.success, lineWidth: 1)
                    )
                    .offset(y: offset)
                    .opacity(opacity)
                
                Spacer()
            }
            
            Spacer()
                .frame(height: 100) // Bottom spacing
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                offset = -50
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                gamificationService.dismissXPAnimation(animation.id)
            }
        }
    }
}

// MARK: - Particle Effect
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    var scale: CGFloat = CGFloat.random(in: 0.5...1.5)
    var opacity: Double = Double.random(in: 0.6...1.0)
}

struct GamificationParticleView: View {
    let particle: Particle
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: 8 * particle.scale, height: 8 * particle.scale)
            .opacity(isAnimating ? 0 : particle.opacity)
            .scaleEffect(isAnimating ? 2 : particle.scale)
            .position(x: particle.x, y: particle.y)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Gamification Service
@MainActor
class GamificationService: ObservableObject {
    static let shared = GamificationService()
    
    @Published var pendingAchievements: [AchievementData] = []
    @Published var levelUpNotifications: [LevelUpNotificationData] = []
    @Published var xpAnimations: [XPAnimationData] = []
    
    private init() {}
    
    func showAchievement(_ badge: UserBadge) {
        let notification = AchievementData(
            id: UUID(),
            badge: badge,
            timestamp: Date()
        )
        pendingAchievements.append(notification)
    }
    
    func showLevelUp(newLevel: Int, unlockedFeatures: [String] = []) {
        let notification = LevelUpNotificationData(
            id: UUID(),
            newLevel: newLevel,
            unlockedFeatures: unlockedFeatures,
            timestamp: Date()
        )
        levelUpNotifications.append(notification)
    }
    
    func showXPGain(_ amount: Int) {
        let animation = XPAnimationData(
            id: UUID(),
            xpGained: amount,
            timestamp: Date()
        )
        xpAnimations.append(animation)
    }
    
    func dismissAchievement(_ id: UUID) {
        pendingAchievements.removeAll { $0.id == id }
    }
    
    func dismissLevelUp(_ id: UUID) {
        levelUpNotifications.removeAll { $0.id == id }
    }
    
    func dismissXPAnimation(_ id: UUID) {
        xpAnimations.removeAll { $0.id == id }
    }
    
    // Simulate gamification events
    func simulateProgress() {
        // Show XP gain
        showXPGain(25)
        
        // Sometimes show achievement
        if Bool.random() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                let sampleBadges = [
                    UserBadge(
                        id: UUID(),
                        name: "First Steps",
                        description: "Completed your first lesson",
                        iconName: "star.fill",
                        color: "gold",
                        rarity: .common,
                        earnedAt: Date()
                    ),
                    UserBadge(
                        id: UUID(),
                        name: "Knowledge Seeker",
                        description: "Read 10 articles",
                        iconName: "book.fill",
                        color: "blue",
                        rarity: .rare,
                        earnedAt: Date()
                    ),
                    UserBadge(
                        id: UUID(),
                        name: "AI Explorer",
                        description: "Used AI chat feature",
                        iconName: "brain.head.profile",
                        color: "purple",
                        rarity: .epic,
                        earnedAt: Date()
                    )
                ]
                let badge = sampleBadges.randomElement()!
                self?.showAchievement(badge)
            }
        }
        
        // Rarely show level up
        if Int.random(in: 1...10) == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.showLevelUp(
                    newLevel: Int.random(in: 2...10),
                    unlockedFeatures: ["New Course Categories", "Advanced AI Features"]
                )
            }
        }
    }
}

// MARK: - Supporting Types
struct AchievementData: Identifiable {
    let id: UUID
    let badge: UserBadge
    let timestamp: Date
}

struct LevelUpNotificationData: Identifiable {
    let id: UUID
    let newLevel: Int
    let unlockedFeatures: [String]
    let timestamp: Date
}

struct XPAnimationData: Identifiable {
    let id: UUID
    let xpGained: Int
    let timestamp: Date
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        GamificationOverlay()
            .environmentObject(AppState())
    }
}
