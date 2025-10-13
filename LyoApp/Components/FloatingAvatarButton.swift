import SwiftUI

/// Floating avatar button that appears on all screens
/// Uses AvatarStore for persistent state and personality
struct FloatingAvatarButton: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @Binding var showingChat: Bool

    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 75, y: UIScreen.main.bounds.height - 250)
    @State private var isDragging = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var isPulsing = false
    @State private var showNotificationDot = false

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (avatarStore.avatar?.gradientColors.first ?? .blue).opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.3 : 0.7)

            // Main avatar circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: avatarStore.avatar?.gradientColors ?? [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    // Avatar emoji
                    Text(avatarStore.avatar?.displayEmoji ?? "🤖")
                        .font(.system(size: 32))
                )
                .overlay(
                    // Mood ring
                    Circle()
                        .stroke(avatarStore.currentMood.color, lineWidth: 3)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                )
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .shadow(
                    color: (avatarStore.avatar?.gradientColors.first ?? .blue).opacity(0.5),
                    radius: 20,
                    x: 0,
                    y: 10
                )

            // Mood indicator badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(avatarStore.currentMood.emoji)
                        .font(.caption)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 3)
                        )
                        .offset(x: 8, y: 8)
                }
            }
            .frame(width: 64, height: 64)

            // Notification dot (if avatar has something to say)
            if showNotificationDot {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 8, y: -8)
                    }
                    Spacer()
                }
                .frame(width: 64, height: 64)
            }
        }
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    isDragging = false
                    updatePosition(with: value.translation)
                }
        )
        .onTapGesture {
            if !isDragging {
                handleTap()
            }
        }
        .onAppear {
            startPulseAnimation()

            // Check if avatar has anything to say
            checkForNotifications()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)
        .accessibilityLabel("\(avatarStore.avatar?.name ?? "AI") Assistant")
        .accessibilityHint("Tap to chat with your learning companion")
    }

    // MARK: - Actions

    private func handleTap() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Record interaction
        avatarStore.state.recordInteraction()

        // Clear notification dot
        showNotificationDot = false

        // Open chat
        showingChat = true

        // Speak greeting
        if let greeting = avatarStore.avatar?.personality.sampleGreeting {
            avatarStore.speak(greeting)
        }
    }

    private func updatePosition(with translation: CGSize) {
        let newX = position.x + translation.width
        let newY = position.y + translation.height

        let screenBounds = UIScreen.main.bounds
        let buttonSize: CGFloat = 64
        let padding: CGFloat = 20

        // Keep within screen bounds with padding
        position.x = max(buttonSize/2 + padding, min(screenBounds.width - buttonSize/2 - padding, newX))
        position.y = max(buttonSize/2 + padding, min(screenBounds.height - buttonSize/2 - padding, newY))
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }

    private func checkForNotifications() {
        // Show notification dot if avatar hasn't been interacted with recently
        let timeSinceLastInteraction = Date().timeIntervalSince(avatarStore.state.lastInteraction)

        if timeSinceLastInteraction > 1800 { // 30 minutes
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showNotificationDot = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var avatarStore = AvatarStore()
        @State private var showingChat = false

        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()

                FloatingAvatarButton(showingChat: $showingChat)
                    .environmentObject(avatarStore)
            }
            .onAppear {
                // Set up a test avatar
                if avatarStore.avatar == nil {
                    avatarStore.avatar = Avatar(name: "Lyo")
                }
            }
        }
    }

    return PreviewWrapper()
}
