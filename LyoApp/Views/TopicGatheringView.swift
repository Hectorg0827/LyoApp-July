import SwiftUI

/// Step 1: User enters what they want to learn
struct TopicGatheringView: View {
    @ObservedObject var coordinator: CourseBuilderCoordinator

    @State private var avatarScale: CGFloat = 1.0
    @State private var showingSuggestions: Bool = false
    @State private var isRecording: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    private let suggestions = [
        "Swift Programming",
        "Machine Learning Basics",
        "UI/UX Design",
        "Digital Marketing",
        "Photography",
        "Spanish Language",
        "Financial Literacy",
        "Public Speaking"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Floating AI Avatar
                avatarSection

                // Main question
                VStack(spacing: 12) {
                    Text("What would you like to learn?")
                        .font(DesignTokens.Typography.displaySmall)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textReadability()

                    Text("Tell me anything - I'll create a personalized course just for you")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Input section
                VStack(spacing: 16) {
                    // Text input
                    HStack(spacing: 12) {
                        TextField("e.g., Swift programming, photography, Spanish...", text: $coordinator.topic, axis: .vertical)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .font(DesignTokens.Typography.bodyLarge)
                            .lineLimit(3)
                            .focused($isTextFieldFocused)

                        // Voice input button
                        Button(action: toggleVoiceInput) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                                    .frame(width: 48, height: 48)

                                Image(systemName: isRecording ? "waveform" : "mic.fill")
                                    .font(.title3)
                                    .foregroundColor(isRecording ? .red : .white.opacity(0.7))
                                    .symbolEffect(.variableColor, isActive: isRecording)
                            }
                        }
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isRecording)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        coordinator.topic.isEmpty ? Color.white.opacity(0.1) : DesignTokens.Colors.brand,
                                        lineWidth: 2
                                    )
                            )
                    )
                    .padding(.horizontal)

                    // Optional: Learning goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your goal? (Optional)")
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(.white.opacity(0.6))

                        TextField("", text: $coordinator.learningGoal, axis: .vertical)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .font(DesignTokens.Typography.bodyMedium)
                            .lineLimit(2)
                            .placeholder(when: coordinator.learningGoal.isEmpty) {
                                Text("e.g., Build an iOS app, start a side business...")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(DesignTokens.Typography.bodyMedium)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                    .padding(.horizontal)
                }

                // Suggestions
                if showingSuggestions && coordinator.topic.isEmpty {
                    suggestionsSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Continue button
                Button(action: {
                    isTextFieldFocused = false
                    coordinator.nextStep()
                }) {
                    HStack {
                        Text("Continue")
                            .font(DesignTokens.Typography.titleMedium)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                coordinator.canProceed
                                    ? DesignTokens.Colors.brandGradient
                                    : LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .disabled(!coordinator.canProceed)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Animate avatar on appear
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                avatarScale = 1.2
            }

            // Show suggestions after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showingSuggestions = true
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        ZStack {
            // Glow rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(DesignTokens.Colors.brand.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                    .frame(width: 140 + CGFloat(index * 40), height: 140 + CGFloat(index * 40))
                    .scaleEffect(avatarScale * (1.0 + Double(index) * 0.1))
            }

            // Main avatar
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignTokens.Colors.brand,
                                DesignTokens.Colors.neonBlue.opacity(0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: DesignTokens.Colors.brand.opacity(0.5), radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(avatarScale * 0.9)
            }
            .scaleEffect(avatarScale)
        }
        .frame(height: 200)
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Topics")
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            withAnimation {
                                coordinator.topic = suggestion
                                showingSuggestions = false
                            }
                            HapticManager.shared.light()
                        }) {
                            Text(suggestion)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(DesignTokens.Colors.brand.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Methods

    private func toggleVoiceInput() {
        isRecording.toggle()

        if isRecording {
            // TODO: Start voice recognition
            HapticManager.shared.medium()
        } else {
            // TODO: Stop voice recognition and process
            HapticManager.shared.light()
        }
    }
}

// MARK: - View Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        TopicGatheringView(coordinator: CourseBuilderCoordinator())
    }
}
