import SwiftUI
import AVKit

// MARK: - Story Models

struct Story: Identifiable, Codable, Hashable {
    let id: UUID
    let creator: User
    let segments: [StorySegment]
    let createdAt: Date
    var viewCount: Int
    var isViewed: Bool
    
    init(id: UUID = UUID(), creator: User, segments: [StorySegment], createdAt: Date = Date(), viewCount: Int = 0, isViewed: Bool = false) {
        self.id = id
        self.creator = creator
        self.segments = segments
        self.createdAt = createdAt
        self.viewCount = viewCount
        self.isViewed = isViewed
    }
}

struct StorySegment: Identifiable, Codable, Hashable {
    let id: UUID
    let type: StorySegmentType
    let mediaURL: URL?
    let backgroundColor: String // Hex color for gradient backgrounds
    let duration: TimeInterval
    let text: String?
    let textColor: String?
    
    init(id: UUID = UUID(), type: StorySegmentType, mediaURL: URL? = nil, backgroundColor: String = "#000000", duration: TimeInterval = 5.0, text: String? = nil, textColor: String? = nil) {
        self.id = id
        self.type = type
        self.mediaURL = mediaURL
        self.backgroundColor = backgroundColor
        self.duration = duration
        self.text = text
        self.textColor = textColor
    }
}

enum StorySegmentType: String, Codable, Hashable {
    case photo
    case video
    case text
}

// MARK: - Story Manager

@MainActor
class StoryManager: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isLoading = false
    @Published var lastInteractionTime: Date?
    
    private var hideTimer: Timer?
    private let autoHideDelay: TimeInterval = 40.0
    
    init() {
        generateMockStories()
        startAutoHideTimer()
    }
    
    // MARK: - Auto-hide Logic
    
    func recordInteraction() {
        lastInteractionTime = Date()
        resetAutoHideTimer()
    }
    
    func shouldHideStories() -> Bool {
        guard let lastTime = lastInteractionTime else { return false }
        return Date().timeIntervalSince(lastTime) >= autoHideDelay
    }
    
    private func startAutoHideTimer() {
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.objectWillChange.send()
            }
        }
    }
    
    private func resetAutoHideTimer() {
        hideTimer?.invalidate()
        startAutoHideTimer()
    }
    
    deinit {
        hideTimer?.invalidate()
    }
    
    // MARK: - Mock Data Generation
    
    func generateMockStories() {
        let mockUsers = [
            User(id: UUID(), username: "sarah_tech", displayName: "Sarah Chen", email: "sarah@example.com", profileImageURL: nil, bio: "Tech enthusiast", followerCount: 12500, followingCount: 450, postCount: 89, isFollowing: true, joinDate: Date()),
            User(id: UUID(), username: "design_mike", displayName: "Mike Johnson", email: "mike@example.com", profileImageURL: nil, bio: "UI/UX Designer", followerCount: 8900, followingCount: 320, postCount: 156, isFollowing: false, joinDate: Date()),
            User(id: UUID(), username: "code_emma", displayName: "Emma Davis", email: "emma@example.com", profileImageURL: nil, bio: "iOS Developer", followerCount: 15600, followingCount: 890, postCount: 234, isFollowing: true, joinDate: Date()),
            User(id: UUID(), username: "alex_learns", displayName: "Alex Rivera", email: "alex@example.com", profileImageURL: nil, bio: "Lifelong learner", followerCount: 6700, followingCount: 540, postCount: 67, isFollowing: false, joinDate: Date()),
            User(id: UUID(), username: "julia_creates", displayName: "Julia Kim", email: "julia@example.com", profileImageURL: nil, bio: "Content creator", followerCount: 23400, followingCount: 670, postCount: 456, isFollowing: true, joinDate: Date()),
            User(id: UUID(), username: "ryan_builds", displayName: "Ryan Park", email: "ryan@example.com", profileImageURL: nil, bio: "Full-stack dev", followerCount: 11200, followingCount: 390, postCount: 178, isFollowing: false, joinDate: Date())
        ]
        
        let captions = [
            "Check out this new SwiftUI trick! 🚀",
            "Just launched my new app design",
            "Learning something new every day 📚",
            "Behind the scenes of coding",
            "Quick tutorial on animations",
            nil, // Some stories don't need captions
            "Excited to share this with you!",
            "Day in the life of a developer"
        ]
        
        storyGroups = mockUsers.enumerated().map { index, user in
            let storyCount = Int.random(in: 1...5)
            let stories = (0..<storyCount).map { storyIndex in
                Story(
                    id: UUID(),
                    creator: user,
                    mediaURL: URL(string: "https://picsum.photos/400/\(700 + index * 10 + storyIndex)")!,
                    mediaType: storyIndex % 3 == 0 ? .video : .image,
                    caption: captions.randomElement() ?? nil,
                    createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                    viewCount: Int.random(in: 50...5000),
                    isViewed: index > 2 // First 3 users have unviewed stories
                )
            }
            return StoryGroup(id: UUID(), creator: user, stories: stories)
        }
    }
    
    // MARK: - Story Actions
    
    func openStoryGroup(_ group: StoryGroup) {
        selectedGroup = group
        currentStoryIndex = 0
        startAutoHideTimer()
    }
    
    func closeStories() {
        selectedGroup = nil
        currentStoryIndex = 0
        stopAutoHideTimer()
    }
    
    func nextStory() {
        guard let group = selectedGroup else { return }
        
        if currentStoryIndex < group.stories.count - 1 {
            currentStoryIndex += 1
            resetAutoHideTimer()
        } else {
            // Move to next group
            if let currentIndex = storyGroups.firstIndex(where: { $0.id == group.id }),
               currentIndex < storyGroups.count - 1 {
                openStoryGroup(storyGroups[currentIndex + 1])
            } else {
                closeStories()
            }
        }
    }
    
    func previousStory() {
        if currentStoryIndex > 0 {
            currentStoryIndex -= 1
            resetAutoHideTimer()
        } else if let group = selectedGroup,
                  let currentIndex = storyGroups.firstIndex(where: { $0.id == group.id }),
                  currentIndex > 0 {
            let previousGroup = storyGroups[currentIndex - 1]
            selectedGroup = previousGroup
            currentStoryIndex = previousGroup.stories.count - 1
            resetAutoHideTimer()
        }
    }
    
    func markAsViewed(_ story: Story) {
        guard let groupIndex = storyGroups.firstIndex(where: { $0.id == selectedGroup?.id }),
              let storyIndex = storyGroups[groupIndex].stories.firstIndex(where: { $0.id == story.id }) else {
            return
        }
        storyGroups[groupIndex].stories[storyIndex].isViewed = true
    }
    
    // MARK: - Auto-hide Timer
    
    private func startAutoHideTimer() {
        stopAutoHideTimer()
        hideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDuration, repeats: false) { [weak self] _ in
            self?.closeStories()
        }
    }
    
    private func resetAutoHideTimer() {
        startAutoHideTimer()
    }
    
    private func stopAutoHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
}

// MARK: - Story Orbs Row

struct StoryOrbsRow: View {
    @ObservedObject var storiesManager: StoriesManager
    let onOrbTapped: (StoryGroup) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(storiesManager.storyGroups) { group in
                    StoryOrbView(group: group) {
                        onOrbTapped(group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Story Orb (Individual Circle)

struct StoryOrbView: View {
    let group: StoryGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    // Gradient ring for unviewed stories
                    if group.hasUnviewed {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#FF1493"), // Deep pink
                                        Color(hex: "#FF69B4"), // Hot pink
                                        Color(hex: "#FFB6C1")  // Light pink
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 72, height: 72)
                    } else {
                        // Gray ring for viewed stories
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 72, height: 72)
                    }
                    
                    // Profile image
                    if let imageURL = group.creator.profileImageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                    } else {
                        // Placeholder with initials
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(group.creator.displayName.prefix(1))
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Username
                Text(group.creator.username)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Story Viewer (Full Screen)

struct StoryViewerView: View {
    @ObservedObject var storiesManager: StoriesManager
    @Binding var isPresented: Bool
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var isPaused = false
    
    var currentStory: Story? {
        guard let group = storiesManager.selectedGroup,
              storiesManager.currentStoryIndex < group.stories.count else {
            return nil
        }
        return group.stories[storiesManager.currentStoryIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let story = currentStory {
                // Story content
                StoryContentView(story: story)
                
                VStack {
                    // Top bar with progress indicators
                    topBar(for: story)
                    
                    Spacer()
                    
                    // Bottom caption
                    if let caption = story.caption {
                        bottomCaption(caption)
                    }
                }
                .padding()
                
                // Tap zones for navigation
                tapZones
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            startTimer()
            if let story = currentStory {
                storiesManager.markAsViewed(story)
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Top Bar
    
    private func topBar(for story: Story) -> some View {
        VStack(spacing: 12) {
            // Progress bars
            if let group = storiesManager.selectedGroup {
                HStack(spacing: 4) {
                    ForEach(Array(group.stories.enumerated()), id: \.element.id) { index, _ in
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 2)
                                
                                // Progress fill
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: progressWidth(for: index, in: geometry), height: 2)
                            }
                        }
                        .frame(height: 2)
                    }
                }
            }
            
            // User info
            HStack(spacing: 12) {
                // Profile picture
                if let imageURL = story.creator.profileImageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(story.creator.displayName.prefix(1))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.creator.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(timeAgo(from: story.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    isPresented = false
                    storiesManager.closeStories()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    // MARK: - Bottom Caption
    
    private func bottomCaption(_ caption: String) -> some View {
        Text(caption)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Tap Zones
    
    private var tapZones: some View {
        HStack(spacing: 0) {
            // Left tap zone - previous story
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    storiesManager.previousStory()
                    stopTimer()
                    progress = 0
                    startTimer()
                }
            
            // Right tap zone - next story
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    storiesManager.nextStory()
                    stopTimer()
                    progress = 0
                    startTimer()
                }
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in
                    isPaused = true
                    stopTimer()
                }
                .onEnded { _ in
                    isPaused = false
                    startTimer()
                }
        )
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        guard let story = currentStory else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            progress += 0.05 / story.duration
            
            if progress >= 1.0 {
                storiesManager.nextStory()
                progress = 0
                
                // Check if we're still showing stories
                if storiesManager.selectedGroup == nil {
                    isPresented = false
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Helper Functions
    
    private func progressWidth(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        if index < storiesManager.currentStoryIndex {
            return geometry.size.width
        } else if index == storiesManager.currentStoryIndex {
            return geometry.size.width * progress
        } else {
            return 0
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        if hours < 1 {
            return "Just now"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
}

// MARK: - Story Content View

struct StoryContentView: View {
    let story: Story
    
    var body: some View {
        Group {
            switch story.mediaType {
            case .image:
                AsyncImage(url: story.mediaURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                
            case .video:
                // For now, show placeholder - full video support would use AVPlayer
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    VStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("Video Story")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Collapsible Story Drawer

struct StoryDrawer: View {
    @ObservedObject var storiesManager: StoriesManager
    @Binding var isExpanded: Bool
    @State private var dragOffset: CGFloat = 0
    let onStoryTapped: (StoryGroup) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawer handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.vertical, 8)
            
            if isExpanded {
                // Story orbs
                StoryOrbsRow(storiesManager: storiesManager, onOrbTapped: onStoryTapped)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if value.translation.height > 50 {
                            isExpanded = false
                        } else if value.translation.height < -50 {
                            isExpanded = true
                        }
                        dragOffset = 0
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Color Extension

// Color(hex:) extension removed - using canonical version from DesignTokens.swift
