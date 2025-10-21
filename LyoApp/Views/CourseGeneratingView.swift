import SwiftUI

/// Step 3: Shows AI generating the course with animated progress
struct CourseGeneratingView: View {
    @ObservedObject var coordinator: CourseBuilderCoordinator

    @State private var avatarRotation: Double = 0
    @State private var particleAnimation: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Animated particles
            ParticleField(isActive: $particleAnimation)

            VStack(spacing: 40) {
                Spacer()

                // Animated AI Avatar
                generatingAvatarView

                // Status text
                VStack(spacing: 12) {
                    Text("Creating Your Course")
                        .font(DesignTokens.Typography.displaySmall)
                        .foregroundColor(.white)
                        .textReadability()

                    if !coordinator.generationStatus.isEmpty {
                        Text(coordinator.generationStatus)
                            .font(DesignTokens.Typography.bodyLarge)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.5), value: coordinator.generationStatus)
                    }
                }

                // Progress bar
                progressBarView
                    .padding(.horizontal, 40)

                // Fun facts or tips
                if coordinator.generationProgress < 0.9 {
                    funFactView
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Error handling
                if let error = coordinator.generationError {
                    errorView(error)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Generating Avatar

    private var generatingAvatarView: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.brand,
                            DesignTokens.Colors.neonBlue,
                            DesignTokens.Colors.neonPurple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(avatarRotation))

            // Middle glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.Colors.brand.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(pulseScale)
                .blur(radius: 10)

            // Inner avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.brand,
                                DesignTokens.Colors.neonBlue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: DesignTokens.Colors.brand.opacity(0.5), radius: 20)

                // Animated sparkles
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-avatarRotation * 0.5))

                // Progress ring
                Circle()
                    .trim(from: 0, to: coordinator.generationProgress)
                    .stroke(Color.white.opacity(0.8), lineWidth: 6)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
            }

            // Floating particles
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(DesignTokens.Colors.brand.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(x: cos(Double(index) * .pi / 6) * 110, y: sin(Double(index) * .pi / 6) * 110)
                    .scaleEffect(particleAnimation ? 1.0 : 0.0)
                    .opacity(particleAnimation ? 0.8 : 0.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: particleAnimation
                    )
            }
        }
        .frame(height: 220)
    }

    // MARK: - Progress Bar

    private var progressBarView: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.brand,
                                    DesignTokens.Colors.neonBlue,
                                    DesignTokens.Colors.neonPurple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * coordinator.generationProgress, height: 8)
                        .shadow(color: DesignTokens.Colors.brand.opacity(0.5), radius: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(coordinator.generationProgress * 100))%")
                .font(DesignTokens.Typography.labelMedium.monospacedDigit())
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Fun Fact

    private var funFactView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.Colors.neonYellow)

                Text("Did you know?")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.neonYellow)
            }

            Text(funFact)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.warning)

            Text(error)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await coordinator.generateCourse()
                }
            }) {
                Text("Try Again")
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(DesignTokens.Colors.brand)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal)
    }

    // MARK: - Methods

    private func startAnimations() {
        // Rotation animation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            avatarRotation = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }

        // Particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            particleAnimation = true
        }
    }

    private var funFact: String {
        let facts = [
            "AI is analyzing thousands of learning patterns to create the perfect course for you",
            "Your personalized course is being optimized based on proven learning science",
            "We're curating the best resources from across the internet just for you",
            "Each lesson is being tailored to match your learning style and pace",
            "Your course will adapt as you learn, getting smarter with every lesson"
        ]

        return facts.randomElement() ?? facts[0]
    }
}

// MARK: - Particle Field

struct ParticleField: View {
    @Binding var isActive: Bool

    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.brand.opacity(0.3),
                                DesignTokens.Colors.neonBlue.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(isActive ? 0.8 : 0.0)
                    .scaleEffect(isActive ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: isActive
                    )
            }
        }
        .blur(radius: 8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        CourseGeneratingView(coordinator: {
            let c = CourseBuilderCoordinator()
            c.topic = "Swift Programming"
            c.generationProgress = 0.45
            c.generationStatus = "Creating engaging lessons..."
            return c
        }())
    }
}
