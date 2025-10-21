import SwiftUI

/// Learning Hub Landing View - Chat-driven course creation with Netflix-style cards
struct LearningHubLandingView: View {
    @StateObject private var chatVM = LearningChatViewModel()
    @StateObject private var dataManager = LearningDataManager.shared
    @StateObject private var voiceService = VoiceRecognitionService()
    @State private var showRecommendations = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0A0E27"), Color(hex: "1A1F3A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top: Netflix-style course carousel (80px)
                NetflixStyleCourseStrip(
                    title: "Continue Learning",
                    courses: dataManager.learningResources.filter { ($0.progress ?? 0) > 0 }
                )
                .frame(height: 80)
                .padding(.top, 8)
                
                // Main: iMessage-style chat interface
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message (always visible)
                            if chatVM.messages.isEmpty {
                                WelcomeMessageView(userName: "Hector")
                                    .padding(.top, 20)
                            }
                            
                            // Chat messages with iMessage style
                            ForEach(chatVM.messages) { message in
                                iMessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: message.isFromUser ? .trailing : .leading)
                                            .combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            
                            // Quick action buttons (appears after AI asks questions)
                            if let quickActions = chatVM.currentQuickActions {
                                QuickActionButtonsView(
                                    actions: quickActions,
                                    onSelect: chatVM.handleQuickAction
                                )
                                .padding(.top, 8)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Course Journey Preview Card
                            if let journey = chatVM.generatedJourney {
                                CourseJourneyPreviewCard(
                                    journey: journey,
                                    countdown: chatVM.countdown,
                                    onStart: chatVM.launchCourse
                                )
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Typing indicator
                            if chatVM.isProcessing {
                                TypingIndicatorView()
                                    .padding(.leading, 16)
                                    .transition(.opacity)
                            }
                            
                            // Spacer for input bar and recommendations
                            Color.clear.frame(height: showRecommendations ? 200 : 100)
                        }
                        .padding(.horizontal, 8)
                        .onChange(of: chatVM.messages.count) { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                if let lastId = chatVM.messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: chatVM.generatedJourney) { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                if let lastId = chatVM.messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Bottom: iMessage-style input bar
                iMessageInputBar(
                    text: $chatVM.inputText,
                    isProcessing: chatVM.isProcessing,
                    isRecording: voiceService.isRecording,
                    onSend: chatVM.sendMessage,
                    onVoice: {
                        Task {
                            if voiceService.isRecording {
                                voiceService.stopRecording()
                                if !voiceService.transcribedText.isEmpty {
                                    chatVM.inputText = voiceService.transcribedText
                                    chatVM.sendMessage()
                                }
                            } else {
                                try? await voiceService.startRecording()
                            }
                        }
                    }
                )
                .frame(height: 60)
                .background(Color(hex: "1A1F3A").opacity(0.95))
            }
            
            // Recommendations sheet (slides up from bottom)
            VStack {
                Spacer()
                NetflixStyleRecommendationsSheet(
                    courses: dataManager.recommendedResources,
                    completedCourses: dataManager.learningResources.filter { ($0.progress ?? 0) >= 1.0 },
                    isShowing: $showRecommendations
                )
                .offset(y: showRecommendations ? 0 : 400)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRecommendations)
            }
            
            // UNITY INTEGRATION: Dynamic Classroom Overlay
            if dataManager.showDynamicClassroom,
               let selectedResource = dataManager.selectedResource {
                UnityClassroomOverlay(
                    resource: selectedResource,
                    isPresented: $dataManager.showDynamicClassroom
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999) // Above everything
            }
        }
        .onAppear {
            // Track screen view
            LearningHubAnalytics.shared.trackScreenView(screenName: "Learning Hub Landing")
            LearningHubAnalytics.shared.startNewSession()
            
            Task {
                await dataManager.loadLearningResources()
                await dataManager.generatePersonalizedRecommendations()
                chatVM.startConversation()
            }
        }
        .onDisappear {
            LearningHubAnalytics.shared.endSession()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        showRecommendations = true
                    } else if value.translation.height > 50 {
                        showRecommendations = false
                    }
                }
        )
    }
}

// MARK: - Welcome Message
struct WelcomeMessageView: View {
    let userName: String
    
    var body: some View {
        VStack(spacing: 20) {
            // AI Avatar with pulse animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(Color.cyan, lineWidth: 2)
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .cyan.opacity(0.5), radius: 20)
            
            // Greeting
            VStack(spacing: 8) {
                Text("Hello \(userName)! 👋")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("What would you like to learn about today?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - iMessage-style Chat Bubble
struct iMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isFromUser {
                // AI Avatar (small)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(message.isFromUser ? .white : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if message.isFromUser {
                                // Blue gradient for user (iMessage style)
                                LinearGradient(
                                    colors: [Color(hex: "007AFF"), Color(hex: "0051D5")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                // Dark gray for AI
                                Color(hex: "2C2C2E")
                            }
                        }
                    )
                    .clipShape(BubbleShape(isFromUser: message.isFromUser))
                    .shadow(
                        color: message.isFromUser ? Color(hex: "007AFF").opacity(0.3) : Color.black.opacity(0.2),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                
                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, message.isFromUser ? 12 : 0)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - iMessage Bubble Shape
struct BubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isFromUser ?
                [.topLeft, .topRight, .bottomLeft] :
                [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // AI Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Typing dots
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "2C2C2E"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .onAppear {
            animationPhase = 0
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - iMessage-style Input Bar
struct iMessageInputBar: View {
    @Binding var text: String
    let isProcessing: Bool
    let isRecording: Bool
    let onSend: () -> Void
    let onVoice: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Camera/Media button (left)
            Button(action: {}) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.cyan)
            }
            
            // Text input field
            HStack(spacing: 8) {
                TextField(isRecording ? "Listening..." : "Message", text: $text, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .disabled(isProcessing || isRecording)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                // Voice button (inside text field)
                if text.isEmpty {
                    Button(action: onVoice) {
                        ZStack {
                            if isRecording {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 32, height: 32)
                            }
                            Image(systemName: isRecording ? "mic.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(isRecording ? .red : .gray)
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            .background(Color(hex: "2C2C2E"))
            .cornerRadius(20)
            
            // Send button (right)
            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(
                            text.isEmpty || isProcessing ?
                            Color.gray :
                            LinearGradient(
                                colors: [Color(hex: "007AFF"), Color(hex: "0051D5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(text.isEmpty || isProcessing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Action Buttons
struct QuickActionButtonsView: View {
    let actions: [QuickAction]
    let onSelect: (QuickAction) -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(actions) { action in
                Button(action: { onSelect(action) }) {
                    HStack(spacing: 12) {
                        Text(action.icon)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if let subtitle = action.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                    .padding(16)
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Netflix-style Course Strip
struct NetflixStyleCourseStrip: View {
    let title: String
    let courses: [LearningResource]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !courses.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(courses) { course in
                            NetflixStyleCourseCard(course: course)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Netflix-style Course Card
struct NetflixStyleCourseCard: View {
    let course: LearningResource
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail with gradient overlay
            ZStack(alignment: .bottomLeading) {
                // Background color based on category
                Rectangle()
                    .fill(categoryGradient)
                    .frame(width: 140, height: 80)
                
                // Progress bar at bottom
                if let progress = course.progress, progress > 0 {
                    VStack {
                        Spacer()
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                        .frame(height: 3)
                    }
                }
                
                // Course icon/emoji
                Text(categoryIcon)
                    .font(.system(size: 32))
                    .padding(8)
            }
            .cornerRadius(6)
            
            // Course title
            Text(course.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 140, alignment: .leading)
                .padding(.top, 4)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
                // Launch course
                Task {
                    await LearningDataManager.shared.launchCourse(course)
                }
            }
        }
    }
    
    var categoryGradient: LinearGradient {
        let category = course.category?.lowercased() ?? ""
        
        if category.contains("science") || category.contains("chemistry") {
            return LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "C44569")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if category.contains("history") {
            return LinearGradient(
                colors: [Color(hex: "F8B500"), Color(hex: "D4910F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if category.contains("programming") || category.contains("code") {
            return LinearGradient(
                colors: [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if category.contains("data") {
            return LinearGradient(
                colors: [Color(hex: "A770EF"), Color(hex: "8E54E9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "667EEA"), Color(hex: "4C63D2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var categoryIcon: String {
        let category = course.category?.lowercased() ?? ""
        
        if category.contains("science") || category.contains("chemistry") {
            return "🧪"
        } else if category.contains("history") {
            return "🏛️"
        } else if category.contains("programming") {
            return "💻"
        } else if category.contains("data") {
            return "📊"
        } else if category.contains("design") {
            return "🎨"
        } else {
            return "📚"
        }
    }
}

// MARK: - Netflix-style Recommendations Sheet
struct NetflixStyleRecommendationsSheet: View {
    let courses: [LearningResource]
    let completedCourses: [LearningResource]
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Recommended courses
                    if !courses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("💡 Recommended for You")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(courses.prefix(6)) { course in
                                        NetflixStyleRecommendationCard(course: course)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    // Completed courses
                    if !completedCourses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("✓ Completed")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(completedCourses.prefix(6)) { course in
                                        NetflixStyleRecommendationCard(course: course, isCompleted: true)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1A1F3A"))
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
    }
}

// MARK: - Netflix-style Recommendation Card
struct NetflixStyleRecommendationCard: View {
    let course: LearningResource
    var isCompleted: Bool = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(categoryGradient)
                    .frame(width: 160, height: 90)
                    .cornerRadius(8)
                
                // Completed checkmark
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                        .padding(8)
                }
                
                // Category icon
                Text(categoryIcon)
                    .font(.system(size: 36))
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            // Title
            Text(course.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
            
            // Metadata
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", course.rating ?? 0.0))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text(course.estimatedDuration ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .frame(width: 160, alignment: .leading)
        }
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
                // Launch course
                Task {
                    await LearningDataManager.shared.launchCourse(course)
                }
            }
        }
    }
    
    var categoryGradient: LinearGradient {
        let category = course.category?.lowercased() ?? ""
        
        if category.contains("science") || category.contains("chemistry") {
            return LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "C44569")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if category.contains("history") {
            return LinearGradient(
                colors: [Color(hex: "F8B500"), Color(hex: "D4910F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if category.contains("programming") {
            return LinearGradient(
                colors: [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if category.contains("data") {
            return LinearGradient(
                colors: [Color(hex: "A770EF"), Color(hex: "8E54E9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "667EEA"), Color(hex: "4C63D2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var categoryIcon: String {
        let category = course.category?.lowercased() ?? ""
        
        if category.contains("science") || category.contains("chemistry") {
            return "🧪"
        } else if category.contains("history") {
            return "🏛️"
        } else if category.contains("programming") {
            return "💻"
        } else if category.contains("data") {
            return "📊"
        } else if category.contains("design") {
            return "🎨"
        } else {
            return "📚"
        }
    }
}

// MARK: - Color Extension
// Color(hex:) extension removed - using canonical version from DesignTokens.swift

// MARK: - Preview
#Preview {
    LearningHubLandingView()
        .preferredColorScheme(.dark)
}
