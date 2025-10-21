import SwiftUI
import Foundation
import Combine
import os.log

struct AIAvatarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var courseManager = CourseProgressManager.shared
    @StateObject private var immersiveEngine = ImmersiveAvatarEngine()
    @StateObject private var avatarManager = AvatarCustomizationManager()
    
    // Error handling
    @State private var initializationError: String?
    
    // Animation States
    @State private var avatarScale: CGFloat = 1.0
    @State private var energyPulse: CGFloat = 0.0
    @State private var particleAnimation = false
    @State private var hologramEffect = false
    @State private var backgroundGradient = 0.0
    
    // Interaction States
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var showingCourseProgress = false
    @State private var showingLibrary = false
    @State private var showingCourseFlow = false
    @State private var showingAvatarPicker = false
    // @State private var currentCourseStep: CourseStep? // Removed - CourseStep type doesn't exist
    
    // Immersive Features
    @State private var conversationMode: ConversationMode = .friendly
    @State private var environmentTheme: EnvironmentTheme = .cosmic
    @State private var avatarPersonality: AvatarPersonality = .mentor
    @State private var learningContext: LearningContext?
    
    var body: some View {
        Group {
            if let error = initializationError {
                // Show error state
                errorView(error)
            } else {
                // Show normal view
                mainContentView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🤖 AIAvatarView onAppear called")
            initializeImmersiveSession()
            checkAvatarSelection()
        }
        .sheet(isPresented: $showingCourseProgress) {
            CourseProgressDetailView()
        }
        .sheet(isPresented: $showingLibrary) {
            LibraryView()
        }
        .fullScreenCover(isPresented: $showingAvatarPicker) {
            QuickAvatarPickerView(
                onComplete: { preset, name in
                    avatarManager.selectPreset(preset)
                    avatarManager.setName(name)
                    showingAvatarPicker = false
                },
                onSkip: {
                    showingAvatarPicker = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingCourseFlow) {
            CourseBuilderView()
                .environmentObject(appState)
        }
    }
    
    private func checkAvatarSelection() {
        // ⚠️ FORCE SHOW FOR TESTING - Remove this line after testing
        // Uncomment the line below to always show avatar picker:
        // showingAvatarPicker = true
        
        // Check if this is first launch (no avatar selected)
        let hasSelectedAvatar = UserDefaults.standard.data(forKey: "userSelectedAvatar") != nil
        
        if !hasSelectedAvatar {
            // Show avatar picker on first launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingAvatarPicker = true
            }
        }
    }
    
    private var mainContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background Environment
                immersiveBackground
                
                // Particle Effects
                ParticleSystemView(isActive: $particleAnimation, theme: environmentTheme)
                
                // Main Content
                VStack(spacing: 0) {
                    // Immersive Header with Avatar
                    immersiveAvatarHeader
                    
                    // Dynamic Content Area
                    dynamicContentArea
                    
                    // Course Progress Indicator (if active)
                    if courseManager.hasActiveCourse {
                        courseProgressBar
                    }
                    
                    // Enhanced Input System
                    immersiveInputArea
                }
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("AI Avatar Error")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button {
                    initializationError = nil
                    initializeImmersiveSession()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private var contentWithErrorHandling: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background Environment
                immersiveBackground
                
                // Particle Effects
                ParticleSystemView(isActive: $particleAnimation, theme: environmentTheme)
                
                // Main Content
                VStack(spacing: 0) {
                    // Immersive Header with Avatar
                    immersiveAvatarHeader
                    
                    // Dynamic Content Area
                    dynamicContentArea
                    
                    // Course Progress Indicator (if active)
                    if courseManager.hasActiveCourse {
                        courseProgressBar
                    }
                    
                    // Enhanced Input System
                    immersiveInputArea
                }
            }
        }
    }
    
    // MARK: - Immersive Background (Enhanced Modern Design)
    private var immersiveBackground: some View {
        ZStack {
            // Deep slate-black base for modern tech aesthetic
            Color(red: 0.02, green: 0.05, blue: 0.13)
                .ignoresSafeArea()

            // Animated gradient orbs - top right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.25),
                            Color.blue.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 150, y: -150)
                .scaleEffect(1.0 + sin(backgroundGradient * .pi / 180) * 0.1)
                .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: backgroundGradient)

            // Animated gradient orbs - bottom left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.25),
                            Color.purple.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -150, y: 200)
                .scaleEffect(1.0 + cos(backgroundGradient * .pi / 180) * 0.1)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.0), value: backgroundGradient)

            // Subtle neural network pattern
            NeuralNetworkView(complexity: immersiveEngine.networkComplexity)
                .opacity(0.15)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Immersive Avatar Header (Enhanced Modern Design)
    private var immersiveAvatarHeader: some View {
        VStack(spacing: 16) {
            // Status bar style top
            HStack {
                Text("Lyo AI")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                HStack(spacing: 8) {
                    // Active status indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .opacity(0.3)
                                .scaleEffect(energyPulse)
                        )

                    Text("READY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Floating Orb Avatar
            ZStack {
                // Outer glow ring - subtle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.4),
                                Color.purple.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .scaleEffect(1.0 + energyPulse * 0.15)

                // Main gradient orb with border
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color(red: 0.5, green: 0.3, blue: 0.8), // Purple
                                Color(red: 0.9, green: 0.3, blue: 0.6)  // Pink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .scaleEffect(avatarScale)

                // Inner dark circle for contrast
                Circle()
                    .fill(Color(red: 0.02, green: 0.05, blue: 0.13))
                    .frame(width: 80, height: 80)
                    .scaleEffect(avatarScale)

                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.blue.opacity(0.9))
                    .scaleEffect(0.9 + energyPulse * 0.1)

                // Active pulse indicator - bottom right
                if immersiveEngine.isThinking {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                                .opacity(0.4)
                                .scaleEffect(energyPulse)
                        )
                        .offset(x: 36, y: 36)
                } else {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.02, green: 0.05, blue: 0.13), lineWidth: 3)
                        )
                        .offset(x: 36, y: 36)
                }
            }
            .onTapGesture {
                triggerAvatarInteraction()
            }

            // Title with gradient text
            VStack(spacing: 4) {
                Text("Lyo")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .opacity(0.3)
                        )

                    Text(immersiveEngine.statusMessage.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                }
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Dynamic Content Area
    private var dynamicContentArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(immersiveEngine.conversationHistory) { message in
                        ImmersiveMessageBubble(
                            message: message,
                            theme: environmentTheme,
                            onActionTapped: { action in
                                handleMessageAction(action, for: message)
                            }
                        )
                        .id(message.id)
                    }
                    
                    // Typing indicator with enhanced animation
                    if immersiveEngine.isTyping {
                        ImmersiveTypingIndicator(theme: environmentTheme)
                            .id("typing")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: immersiveEngine.conversationHistory.count) { _, _ in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if let lastMessage = immersiveEngine.conversationHistory.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Course Progress Bar
    private var courseProgressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text(courseManager.currentCourse?.title ?? "Current Course")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(courseManager.overallProgress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Enhanced progress bar with milestones
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(height: 8)
                    
                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * courseManager.overallProgress, height: 8)
                    
                    // Milestone markers
                    ForEach(courseManager.milestones, id: \.id) { milestone in
                        Circle()
                            .fill(milestone.isCompleted ? .white : .white.opacity(0.5))
                            .frame(width: 12, height: 12)
                            .offset(x: geometry.size.width * milestone.progressPercentage - 6)
                    }
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Immersive Input Area (Enhanced Modern Design)
    private var immersiveInputArea: some View {
        VStack(spacing: 12) {
            // Quick Actions with floating pill style
            if immersiveEngine.quickActions.count > 0 {
                HStack(spacing: 8) {
                    ForEach(immersiveEngine.quickActions) { action in
                        Button(action: { performQuickAction(action) }) {
                            Text(action.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .background(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            // Main input area
            HStack(spacing: 12) {
                // Voice button with modern styling
                Button {
                    toggleVoiceInput()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isRecording
                                    ? LinearGradient(
                                        colors: [Color.red, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )

                        // Microphone icon
                        Circle()
                            .fill(isRecording ? Color.white : Color.white.opacity(0.7))
                            .frame(width: 16, height: 16)

                        if isRecording {
                            // Pulsing outer ring
                            Circle()
                                .stroke(Color.red.opacity(0.6), lineWidth: 2)
                                .frame(width: 64, height: 64)
                                .scaleEffect(energyPulse)
                        }
                    }
                }
                .scaleEffect(isRecording ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isRecording)

                // Text input with glassmorphism
                HStack(spacing: 8) {
                    TextField("Ask Lyo anything...", text: $messageText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .placeholder(when: messageText.isEmpty) {
                            Text("Ask Lyo anything...")
                                .foregroundColor(.white.opacity(0.4))
                                .font(.system(size: 15))
                        }

                    if !messageText.isEmpty {
                        Button {
                            sendMessage()
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Methods
    
    private func initializeImmersiveSession() {
        print("🤖 [AIAvatar] Starting initialization...")
        
        // Wrap everything in a safe block
        guard initializationError == nil else {
            print("⚠️ [AIAvatar] Skipping initialization - error already present")
            return
        }
        
        print("🤖 [AIAvatar] Setting up animations...")
        
        // Start animations safely
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            energyPulse = 1.0
        }
        
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            backgroundGradient = 360.0
        }
        
        hologramEffect = true
        particleAnimation = true
        
        print("✅ [AIAvatar] Animations started successfully")
        
        // Initialize avatar service
        Task { @MainActor in
            print("🤖 [AIAvatar] Starting immersive engine session...")
            await immersiveEngine.startSession()
            print("✅ [AIAvatar] Engine session started successfully")
        }
    }
    
    private func triggerAvatarInteraction() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            avatarScale = 1.2
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            avatarScale = 1.0
        }
        
        // Change avatar personality randomly
        avatarPersonality = AvatarPersonality.allCases.randomElement() ?? .mentor
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        // Check if user is requesting a course
        let courseKeywords = ["create a course", "create course", "make a course", "teach me", "learn about", "course on"]
        let lowercasedMessage = message.lowercased()
        let isCourseRequest = courseKeywords.contains(where: { lowercasedMessage.contains($0) })
        
        if isCourseRequest {
            // Transition to course creation flow
            showingCourseFlow = true
        } else {
            Task {
                await immersiveEngine.processMessage(message)
                
                // Auto-save course progress if in learning mode
                if let course = courseManager.currentCourse {
                    await courseManager.updateProgress(for: course.id, with: message)
                }
            }
        }
    }
    
    private func toggleVoiceInput() {
        isRecording.toggle()
        
        if isRecording {
            // Start voice recording
            immersiveEngine.startVoiceRecording()
        } else {
            // Stop and process voice
            immersiveEngine.stopVoiceRecording()
        }
    }
    
    private func performQuickAction(_ action: ImmersiveQuickAction) {
        Task {
            // If creating a course, transition to classroom flow
            if action.type == .generateCourse {
                // Transition to AIOnboardingFlowView which handles:
                // 1. Ask user for topic (TopicGatheringView)
                // 2. Generate course (GenesisScreenView)
                // 3. Show interactive classroom (AIClassroomView)
                await MainActor.run {
                    showingCourseFlow = true
                }
            } else {
                await immersiveEngine.performAction(action)
            }
        }
    }
    
    private func handleMessageAction(_ action: MessageAction, for message: ImmersiveMessage) {
        // Check if this is a course creation action
        if action.title.contains("Course") || action.title.contains("Start") {
            print("🎓 [AIAvatarView] Triggering course creation flow")
            showingCourseFlow = true
            return
        }
        
        Task {
            await immersiveEngine.handleMessageAction(action, for: message)
        }
    }
}

// MARK: - Supporting Views

struct ImmersiveMessageBubble: View {
    let message: ImmersiveMessage
    let theme: EnvironmentTheme
    let onActionTapped: (MessageAction) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 40)

                VStack(alignment: .trailing, spacing: 8) {
                    // User message bubble with gradient
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.9),
                                            Color.purple.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    if !message.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.actions) { action in
                                ActionButton(action: action) {
                                    onActionTapped(action)
                                }
                            }
                        }
                    }
                }
            } else {
                // AI avatar icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    // AI message with glassmorphism
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )

                    if !message.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.actions) { action in
                                ActionButton(action: action) {
                                    onActionTapped(action)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }
}

struct ActionButton: View {
    let action: MessageAction
    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: 6) {
                Image(systemName: action.iconName)
                    .font(.system(size: 11, weight: .medium))

                Text(action.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Scale button style for better feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct QuickActionButton: View {
    let action: ImmersiveQuickAction
    let theme: EnvironmentTheme
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 6) {
                Image(systemName: action.iconName)
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
                
                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.primaryColor.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

struct ImmersiveTypingIndicator: View {
    let theme: EnvironmentTheme
    @State private var animateScale = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI avatar icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )

            // Typing dots with glassmorphism
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateScale ? 1.2 : 0.6)
                        .opacity(animateScale ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: animateScale
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )

            Spacer(minLength: 40)
        }
        .onAppear {
            animateScale = true
        }
    }
}

// MARK: - TextField Placeholder Extension
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
    AIAvatarView()
        .environmentObject(AppState())
}