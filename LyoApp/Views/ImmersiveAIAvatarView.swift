import SwiftUI
import Foundation
import AVFoundation

struct ImmersiveAIAvatarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var avatarService = AIAvatarService.shared
    @StateObject private var courseManager = CourseProgressManager.shared
    @StateObject private var immersiveEngine = ImmersiveAvatarEngine()
    
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
    @State private var currentCourseStep: CourseStep?
    
    // Immersive Features
    @State private var conversationMode: ConversationMode = .friendly
    @State private var environmentTheme: EnvironmentTheme = .cosmic
    @State private var avatarPersonality: AvatarPersonality = .mentor
    @State private var learningContext: LearningContext?
    
    var body: some View {
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
        .navigationBarHidden(true)
        .onAppear {
            initializeImmersiveSession()
        }
        .sheet(isPresented: $showingCourseProgress) {
            CourseProgressDetailView()
        }
        .sheet(isPresented: $showingLibrary) {
            PersonalLibraryView()
        }
    }
    
    // MARK: - Immersive Background
    private var immersiveBackground: some View {
        ZStack {
            // Base gradient that changes with conversation
            LinearGradient(
                colors: environmentTheme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(backgroundGradient))
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: backgroundGradient)
            
            // Dynamic neural network pattern
            NeuralNetworkView(complexity: immersiveEngine.networkComplexity)
                .opacity(0.3)
            
            // Floating geometric shapes
            ForEach(0..<environmentTheme.shapeCount, id: \.self) { index in
                FloatingShapeView(
                    index: index,
                    theme: environmentTheme,
                    isActive: immersiveEngine.isThinking
                )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Immersive Avatar Header
    private var immersiveAvatarHeader: some View {
        VStack(spacing: 20) {
            // Exit and Settings
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .background(Circle().fill(.ultraThinMaterial))
                }
                
                Spacer()
                
                HStack {
                    Button {
                        showingCourseProgress = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    
                    Button {
                        showingLibrary = true
                    } label: {
                        Image(systemName: "books.vertical")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            // Central Avatar with Dynamic Hologram
            ZStack {
                // Hologram rings
                ForEach(0..<3) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.8), .blue.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120 + CGFloat(ring * 30))
                        .scaleEffect(hologramEffect ? 1.1 : 0.9)
                        .opacity(hologramEffect ? 0.8 : 0.3)
                        .animation(
                            .easeInOut(duration: 1.5 + Double(ring) * 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(ring) * 0.2),
                            value: hologramEffect
                        )
                }
                
                // Main Avatar Sphere
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: avatarPersonality.glowColors,
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(1.0 + energyPulse * 0.3)
                        .blur(radius: 10)
                    
                    // Core avatar
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: avatarPersonality.coreColors,
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(avatarScale)
                        .overlay(
                            // Dynamic avatar face/icon
                            Image(systemName: avatarPersonality.iconName)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                                .scaleEffect(0.8 + energyPulse * 0.2)
                        )
                    
                    // Thinking particles
                    if immersiveEngine.isThinking {
                        ForEach(0..<8) { particle in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(particle) * .pi / 4) * 70,
                                    y: sin(Double(particle) * .pi / 4) * 70
                                )
                                .scaleEffect(particleAnimation ? 1.5 : 0.5)
                                .opacity(particleAnimation ? 0.0 : 1.0)
                                .animation(
                                    .easeOut(duration: 1.0)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(particle) * 0.1),
                                    value: particleAnimation
                                )
                        }
                    }
                }
            }
            .onTapGesture {
                triggerAvatarInteraction()
            }
            
            // Dynamic Status and Context
            VStack(spacing: 8) {
                // Avatar name and mood
                HStack {
                    Text("Lyo")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.white)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(immersiveEngine.currentMood.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Current activity or course step
                if let courseStep = currentCourseStep {
                    Text("Step \(courseStep.stepNumber): \(courseStep.title)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.ultraThinMaterial))
                } else {
                    Text(immersiveEngine.statusMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
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
                    proxy.scrollTo(immersiveEngine.conversationHistory.last?.id ?? "typing", anchor: .bottom)
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
    
    // MARK: - Immersive Input Area
    private var immersiveInputArea: some View {
        VStack(spacing: 12) {
            // Quick Actions with contextual suggestions
            if immersiveEngine.quickActions.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(immersiveEngine.quickActions) { action in
                            QuickActionButton(
                                action: action,
                                theme: environmentTheme,
                                onTapped: { performQuickAction(action) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Main input area
            HStack(spacing: 16) {
                // Voice input with enhanced visualization
                Button {
                    toggleVoiceInput()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? .red.gradient : .blue.gradient)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: isRecording ? "stop.circle" : "mic")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        if isRecording {
                            // Pulsing ring for recording
                            Circle()
                                .stroke(.white.opacity(0.6), lineWidth: 2)
                                .frame(width: 56, height: 56)
                                .scaleEffect(energyPulse)
                        }
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.spring(response: 0.4), value: isRecording)
                
                // Text input with enhanced styling
                HStack {
                    TextField("Ask Lyo anything...", text: $messageText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.body)
                    
                    if !messageText.isEmpty {
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Methods
    
    private func initializeImmersiveSession() {
        // Start animations
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            energyPulse = 1.0
        }
        
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            backgroundGradient = 360.0
        }
        
        hologramEffect = true
        particleAnimation = true
        
        // Initialize avatar service
        Task {
            await immersiveEngine.startSession()
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
        
        Task {
            await immersiveEngine.processMessage(message)
            
            // Auto-save course progress if in learning mode
            if let course = courseManager.currentCourse {
                await courseManager.updateProgress(for: course.id, with: message)
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
    
    private func performQuickAction(_ action: QuickAction) {
        Task {
            await immersiveEngine.performAction(action)
            
            // Auto-create course if action is course-related
            if action.type == .generateCourse {
                await courseManager.createCourseFromAction(action)
            }
        }
    }
    
    private func handleMessageAction(_ action: MessageAction, for message: ImmersiveMessage) {
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
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                    
                    if !message.actions.isEmpty {
                        HStack {
                            ForEach(message.actions) { action in
                                ActionButton(action: action) {
                                    onActionTapped(action)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(theme.primaryColor.gradient)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.content)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    
                    if !message.actions.isEmpty {
                        HStack {
                            ForEach(message.actions) { action in
                                ActionButton(action: action) {
                                    onActionTapped(action)
                                }
                            }
                        }
                        .padding(.leading, 40)
                    }
                }
                
                Spacer()
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
                    .font(.caption)
                
                Text(action.title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct QuickActionButton: View {
    let action: QuickAction
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
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateScale ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animateScale
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            Spacer()
        }
        .onAppear {
            animateScale = true
        }
    }
}

#Preview {
    ImmersiveAIAvatarView()
        .environmentObject(AppState())
}