import SwiftUI

/// Celebration screen shown when a lesson is completed
struct LessonCompletionOverlay: View {
    let lesson: Lesson
    let accuracy: Double
    let xpEarned: Int
    let onContinue: () -> Void
    let onReview: () -> Void
    let onExit: () -> Void

    @State private var animateIn: Bool = false
    @State private var confettiTrigger: Bool = false

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            // Confetti particles
            ConfettiView(trigger: confettiTrigger)

            VStack(spacing: 32) {
                Spacer()

                // Success animation
                ZStack {
                    // Glow rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(DesignTokens.Colors.success.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                            .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                            .scaleEffect(animateIn ? 1.0 : 0.5)
                            .opacity(animateIn ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(index) * 0.1), value: animateIn)
                    }

                    // Main success icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        DesignTokens.Colors.success,
                                        DesignTokens.Colors.success.opacity(0.8)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: DesignTokens.Colors.success.opacity(0.5), radius: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateIn ? 1.0 : 0.1)
                    .rotationEffect(.degrees(animateIn ? 0 : -180))
                }

                // Title
                VStack(spacing: 12) {
                    Text("Lesson Complete!")
                        .font(DesignTokens.Typography.displayMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .textReadability()

                    Text(lesson.title)
                        .font(DesignTokens.Typography.titleMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateIn ? 1.0 : 0.0)
                .offset(y: animateIn ? 0 : 20)

                // Stats cards
                HStack(spacing: 16) {
                    CompletionStatCard(
                        icon: "target",
                        value: "\(Int(accuracy * 100))%",
                        label: "Accuracy",
                        color: accuracy >= 0.8 ? DesignTokens.Colors.success : DesignTokens.Colors.warning
                    )

                    CompletionStatCard(
                        icon: "star.fill",
                        value: "+\(xpEarned)",
                        label: "XP Earned",
                        color: DesignTokens.Colors.neonYellow
                    )

                    CompletionStatCard(
                        icon: "trophy.fill",
                        value: "100%",
                        label: "Progress",
                        color: DesignTokens.Colors.info
                    )
                }
                .padding(.horizontal)
                .opacity(animateIn ? 1.0 : 0.0)
                .offset(y: animateIn ? 0 : 30)

                // Motivational message
                Text(motivationalMessage)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateIn ? 1.0 : 0.0)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.success()
                        onContinue()
                    }) {
                        HStack {
                            Text("Continue to Next Lesson")
                                .font(DesignTokens.Typography.titleMedium)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignTokens.Colors.brandGradient)
                                .shadow(color: DesignTokens.Colors.brand.opacity(0.4), radius: 12)
                        )
                    }

                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.light()
                            onReview()
                        }) {
                            Label("Review", systemImage: "arrow.counterclockwise")
                                .font(DesignTokens.Typography.labelLarge)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DesignTokens.Colors.backgroundSecondary)
                                )
                        }

                        Button(action: {
                            HapticManager.shared.light()
                            onExit()
                        }) {
                            Label("Exit", systemImage: "xmark")
                                .font(DesignTokens.Typography.labelLarge)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DesignTokens.Colors.backgroundSecondary)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(animateIn ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateIn = true
            }

            // Trigger confetti after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiTrigger = true
                HapticManager.shared.success()
            }
        }
    }

    private var motivationalMessage: String {
        if accuracy >= 0.9 {
            return "Outstanding work! You've truly mastered this lesson! 🌟"
        } else if accuracy >= 0.75 {
            return "Great job! You're making excellent progress! 🎯"
        } else {
            return "Good effort! Keep practicing to improve! 💪"
        }
    }
}

/// Stat card for completion screen
struct CompletionStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var animateValue: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            Text(value)
                .font(DesignTokens.Typography.titleLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .scaleEffect(animateValue ? 1.2 : 1.0)

            Text(label)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.5)) {
                animateValue = true
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) {
                animateValue = false
            }
        }
    }
}

/// Animated confetti particles
struct ConfettiView: View {
    let trigger: Bool

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiParticleView(particle: particle)
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                generateConfetti()
            }
        }
    }

    private func generateConfetti() {
        particles.removeAll()

        let colors: [Color] = [
            DesignTokens.Colors.neonBlue,
            DesignTokens.Colors.neonPink,
            DesignTokens.Colors.neonYellow,
            DesignTokens.Colors.neonGreen,
            DesignTokens.Colors.neonPurple,
            DesignTokens.Colors.neonOrange
        ]

        for _ in 0..<50 {
            let particle = ConfettiParticle(
                color: colors.randomElement() ?? .blue,
                x: CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2),
                y: -UIScreen.main.bounds.height/2,
                velocity: CGFloat.random(in: 200...400),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let velocity: CGFloat
    let rotation: Double
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle

    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: 10, height: 20)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .offset(x: particle.x, y: particle.y + yOffset)
            .onAppear {
                withAnimation(.easeOut(duration: 3.0)) {
                    yOffset = UIScreen.main.bounds.height + 100
                    opacity = 0.0
                }

                withAnimation(.linear(duration: 3.0).repeatCount(5, autoreverses: true)) {
                    rotation = particle.rotation + 360
                }
            }
    }
}

#Preview {
    LessonCompletionOverlay(
        lesson: .mockLesson1,
        accuracy: 0.92,
        xpEarned: 50,
        onContinue: {},
        onReview: {},
        onExit: {}
    )
}
