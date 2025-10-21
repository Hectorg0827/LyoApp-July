import SwiftUI
import AVKit

// MARK: - Complete Stories Drawer with Auto-Hide

struct StoriesDrawerView: View {
    @StateObject private var storyManager = StorySystemManager()
    @Binding var isExpanded: Bool
    @State private var selectedStory: StoryContent?
    @State private var showingStoryViewer = false
    @State private var showingStoryCreation = false
    
    var headerIcons: [HeaderIcon] {
        [
            HeaderIcon(icon: "magnifyingglass", action: {}),
            HeaderIcon(icon: "bell", action: {}),
            HeaderIcon(icon: "message", action: {}),
            HeaderIcon(icon: "plus.app", action: {
                showingStoryCreation = true
            })
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawer Handle
            drawerHandle
            
            // Content based on expansion state
            if isExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .background(
            RoundedRectangle(cornerRadius: isExpanded ? 24 : 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .fullScreenCover(item: $selectedStory) { story in
            StoryViewerView(story: story, allStories: storyManager.stories, isPresented: $showingStoryViewer)
                .onDisappear {
                    storyManager.recordInteraction()
                }
        }
        .onChange(of: storyManager.shouldHideStories()) { shouldHide in
            if shouldHide && isExpanded {
                withAnimation {
                    isExpanded = false
                }
            }
        }
        .fullScreenCover(isPresented: $showingStoryCreation) {
            StoryCreationView { newStory in
                storyManager.addStory(newStory)
            }
        }
    }
    
    // Drawer Handle
    private var drawerHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .onTapGesture {
                storyManager.recordInteraction()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
    }
    
    // Collapsed State (Just Story Orbs)
    private var collapsedContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(storyManager.stories.prefix(8)) { story in
                    StoryOrbView(story: story, size: 64)
                        .onTapGesture {
                            storyManager.recordInteraction()
                            selectedStory = story
                            showingStoryViewer = true
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 88)
    }
    
    // Expanded State (Header Icons + Story Orbs)
    private var expandedContent: some View {
        VStack(spacing: 20) {
            // Header Icons Section
            headerIconsSection
            
            Divider()
                .padding(.horizontal, 20)
            
            // Story Orbs Section
            storyOrbsSection
        }
        .padding(.vertical, 12)
    }
    
    private var headerIconsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 24) {
                ForEach(headerIcons) { icon in
                    HeaderIconButton(icon: icon) {
                        storyManager.recordInteraction()
                        icon.action()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var storyOrbsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stories")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(storyManager.stories) { story in
                        VStack(spacing: 8) {
                            StoryOrbView(story: story, size: 70)
                                .onTapGesture {
                                    storyManager.recordInteraction()
                                    selectedStory = story
                                    showingStoryViewer = true
                                }
                            
                            Text(story.creator.username)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(width: 70)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Story Orb View (Distinct from Instagram)
struct StoryOrbView: View {
    let story: StoryContent
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Outer gradient ring (distinct design)
            Circle()
                .strokeBorder(
                    story.isViewed ?
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(hex: "#FF1493"),  // Deep Pink
                                Color(hex: "#FF69B4"),  // Hot Pink
                                Color(hex: "#FFB6C1"),  // Light Pink
                                Color(hex: "#DDA0DD")   // Plum
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: 3
                )
                .frame(width: size, height: size)
            
            // Profile Image or Initial
            Circle()
                .fill(Color(hex: story.segments.first?.backgroundColor ?? "#6C5CE7"))
                .frame(width: size - 8, height: size - 8)
                .overlay(
                    Text(String(story.creator.username.prefix(1)).uppercased())
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
}

// MARK: - Header Icon Button
struct HeaderIconButton: View {
    let icon: HeaderIcon
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    )
                
                Text(icon.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct HeaderIcon: Identifiable {
    let id = UUID()
    let icon: String
    let action: () -> Void
    
    var label: String {
        switch icon {
        case "magnifyingglass": return "Search"
        case "bell": return "Alerts"
        case "message": return "Messages"
        case "plus.app": return "Create"
        default: return "Action"
        }
    }
}

// MARK: - Story Viewer (Full Screen)
struct StoryViewerView: View {
    let story: StoryContent
    let allStories: [StoryContent]
    @Binding var isPresented: Bool
    
    @State private var currentSegmentIndex = 0
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var isPaused = false
    @State private var showReactions = false
    @State private var showReplyInput = false
    @State private var replyText = ""
    @StateObject private var storyManager = StorySystemManager()
    
    let quickReactions = ["❤️", "🔥", "😂", "😮", "😢", "👏"]
    
    var currentSegment: StorySegment {
        story.segments[currentSegmentIndex]
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: currentSegment.backgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bars
                progressBars
                    .padding(.horizontal)
                    .padding(.top, 50)
                
                // Story Header
                storyHeader
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                Spacer()
                
                // Segment Content
                segmentContent
                
                Spacer()
            }
            
            // Tap Areas for Navigation
            HStack(spacing: 0) {
                // Previous Segment
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        previousSegment()
                    }
                
                // Next Segment
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        nextSegment()
                    }
            }
            
            // Reactions Bar
            if showReactions {
                reactionsBar
            }
            
            // Reply Input
            if showReplyInput {
                replyInputBar
            }
            
            // Bottom Action Bar
            VStack {
                Spacer()
                actionBar
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<story.segments.count, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                        
                        // Progress
                        Capsule()
                            .fill(Color.white)
                            .frame(width: progressWidth(for: index, totalWidth: geometry.size.width))
                    }
                }
                .frame(height: 3)
            }
        }
    }
    
    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentSegmentIndex {
            return totalWidth
        } else if index == currentSegmentIndex {
            return totalWidth * progress
        } else {
            return 0
        }
    }
    
    private var storyHeader: some View {
        HStack(spacing: 12) {
            StoryOrbView(story: story, size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(story.creator.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(timeAgoString(from: story.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
    
    @ViewBuilder
    private var segmentContent: some View {
        switch currentSegment.type {
        case .photo:
            if let url = currentSegment.mediaURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
            
        case .video:
            if let url = currentSegment.mediaURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
            
        case .text:
            if let text = currentSegment.text {
                Text(text)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: currentSegment.textColor ?? "#FFFFFF"))
                    .multilineTextAlignment(.center)
                    .padding(40)
            }
        }
    }
    
    // Timer Control
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isPaused {
                progress += 0.1 / currentSegment.duration
                if progress >= 1.0 {
                    nextSegment()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func nextSegment() {
        if currentSegmentIndex < story.segments.count - 1 {
            currentSegmentIndex += 1
            progress = 0
        } else {
            dismiss()
        }
    }
    
    private func previousSegment() {
        if currentSegmentIndex > 0 {
            currentSegmentIndex -= 1
            progress = 0
        }
    }
    
    private func dismiss() {
        isPresented = false
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        if hours < 1 {
            return "\(Int(interval / 60))m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
    
    // MARK: - Reactions Bar
    private var reactionsBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                ForEach(quickReactions, id: \.self) { emoji in
                    Button(action: {
                        addReaction(emoji: emoji)
                    }) {
                        Text(emoji)
                            .font(.system(size: 40))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .blur(radius: 10)
            )
            .padding(.bottom, 120)
        }
        .transition(.move(edge: .bottom))
    }
    
    // MARK: - Reply Input Bar
    private var replyInputBar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                TextField("Reply to story...", text: $replyText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                    .foregroundColor(.white)
                
                Button(action: sendReply) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF1493"), Color(hex: "#FF69B4")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .disabled(replyText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom))
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 30) {
            // React Button
            Button(action: {
                withAnimation {
                    showReactions.toggle()
                    if showReactions {
                        showReplyInput = false
                    }
                }
            }) {
                Image(systemName: showReactions ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Reply Button
            Button(action: {
                withAnimation {
                    showReplyInput.toggle()
                    if showReplyInput {
                        showReactions = false
                    }
                }
            }) {
                Image(systemName: "message")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Share Button
            Button(action: {
                // Share functionality
            }) {
                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // More Options
            Button(action: {
                // More options (save to highlights, etc.)
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
    
    // MARK: - Actions
    private func addReaction(emoji: String) {
        storyManager.addReaction(to: story.id, emoji: emoji)
        
        withAnimation {
            showReactions = false
        }
        
        // Show brief confirmation
        // TODO: Add haptic feedback
    }
    
    private func sendReply() {
        guard !replyText.isEmpty else { return }
        
        storyManager.replyToStory(story.id, message: replyText)
        
        withAnimation {
            showReplyInput = false
        }
        
        replyText = ""
        
        // Show confirmation
        // TODO: Navigate to messenger
    }
}

// MARK: - Color Extension for Hex
// Color(hex:) extension removed - using canonical version from DesignTokens.swift
