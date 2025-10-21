import SwiftUI
import AVKit

// MARK: - Complete Stories System with Auto-Hide Drawer

// Story Models
struct StoryContent: Identifiable, Codable, Hashable {
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
    let backgroundColor: String
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

// Story Manager with Auto-Hide and Backend Integration
@MainActor
class StorySystemManager: ObservableObject {
    @Published var stories: [StoryContent] = []
    @Published var isLoading = false
    @Published var lastInteractionTime: Date?
    @Published var error: StoriesError?
    
    private var hideTimer: Timer?
    private let autoHideDelay: TimeInterval = 40.0
    private let apiService = StoriesAPIService.shared
    
    init() {
        startAutoHideTimer()
        Task {
            await fetchStoriesFromBackend()
        }
    }
    
    // Auto-hide Logic
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
    
    // Backend Integration Methods
    
    /// Fetch stories from backend
    func fetchStoriesFromBackend() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedStories = try await apiService.fetchStories()
            stories = fetchedStories
            saveStories()
        } catch let storiesError as StoriesError {
            error = storiesError
            // Fallback to mock data if backend fails
            if stories.isEmpty {
                generateMockStories()
            }
        } catch {
            self.error = .networkError(error)
            if stories.isEmpty {
                generateMockStories()
            }
        }
        
        isLoading = false
    }
    
    /// Refresh stories (pull to refresh)
    func refreshStories() async {
        await fetchStoriesFromBackend()
    }
    
    // Story Actions with Backend Sync
    func markStoryAsViewed(_ storyId: UUID) {
        // Update locally first for instant feedback
        if let index = stories.firstIndex(where: { $0.id == storyId }) {
            stories[index].isViewed = true
            stories[index].viewCount += 1
            saveStories()
        }
        
        // Sync with backend
        Task {
            do {
                try await apiService.markStoryAsViewed(storyId: storyId)
            } catch {
                print("Failed to sync view with backend: \(error)")
            }
        }
    }
    
    func addStory(_ story: StoryContent) {
        stories.insert(story, at: 0)
        saveStories()
    }
    
    func deleteStory(_ storyId: UUID) {
        stories.removeAll { $0.id == storyId }
        saveStories()
        
        // Sync with backend
        Task {
            do {
                try await apiService.deleteStory(storyId: storyId)
            } catch {
                print("Failed to delete story from backend: \(error)")
            }
        }
    }
    
    func addReaction(to storyId: UUID, emoji: String) {
        Task {
            do {
                try await apiService.addReaction(storyId: storyId, emoji: emoji)
            } catch {
                print("Failed to add reaction: \(error)")
            }
        }
    }
    
    func replyToStory(_ storyId: UUID, message: String) {
        Task {
            do {
                try await apiService.replyToStory(storyId: storyId, message: message)
            } catch {
                print("Failed to send reply: \(error)")
            }
        }
    }
    
    func getAnalytics(for storyId: UUID) async -> StoryAnalytics? {
        do {
            return try await apiService.getStoryAnalytics(storyId: storyId)
        } catch {
            print("Failed to fetch analytics: \(error)")
            return nil
        }
    }
    
    // Persistence
    private func saveStories() {
        if let encoded = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(encoded, forKey: "savedStoriesSystem")
        }
    }
    
    private func loadStories() {
        if let data = UserDefaults.standard.data(forKey: "savedStoriesSystem"),
           let decoded = try? JSONDecoder().decode([StoryContent].self, from: data) {
            stories = decoded
        }
    }
    
    // Mock Data
    func generateMockStories() {
        let mockUsers = [
            User(id: UUID(), username: "tech_guru", displayName: "Tech Guru", email: "tech@example.com", profileImageURL: nil, bio: "Technology enthusiast", followerCount: 12500, followingCount: 340, postCount: 89, isFollowing: false, joinDate: Date()),
            User(id: UUID(), username: "design_wizard", displayName: "Design Wizard", email: "design@example.com", profileImageURL: nil, bio: "UX/UI Designer", followerCount: 8900, followingCount: 210, postCount: 156, isFollowing: true, joinDate: Date()),
            User(id: UUID(), username: "code_ninja", displayName: "Code Ninja", email: "code@example.com", profileImageURL: nil, bio: "Full-stack developer", followerCount: 15600, followingCount: 420, postCount: 234, isFollowing: false, joinDate: Date()),
            User(id: UUID(), username: "data_scientist", displayName: "Data Scientist", email: "data@example.com", profileImageURL: nil, bio: "ML & AI researcher", followerCount: 9800, followingCount: 180, postCount: 67, isFollowing: true, joinDate: Date()),
            User(id: UUID(), username: "creative_mind", displayName: "Creative Mind", email: "creative@example.com", profileImageURL: nil, bio: "Digital artist", followerCount: 21300, followingCount: 540, postCount: 412, isFollowing: false, joinDate: Date())
        ]
        
        stories = mockUsers.enumerated().map { index, user in
            let segmentCount = Int.random(in: 1...5)
            let segments = (0..<segmentCount).map { segmentIndex -> StorySegment in
                let types: [StorySegmentType] = [.photo, .video, .text]
                let type = types.randomElement()!
                
                switch type {
                case .photo:
                    return StorySegment(
                        type: .photo,
                        mediaURL: nil,
                        backgroundColor: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8"].randomElement()!,
                        duration: 5.0
                    )
                case .video:
                    return StorySegment(
                        type: .video,
                        mediaURL: nil,
                        backgroundColor: "#000000",
                        duration: 15.0
                    )
                case .text:
                    let texts = [
                        "Just launched my new course! 🚀",
                        "Learning something new every day ��",
                        "Check out this amazing tip! 💡",
                        "Who else loves coding? 💻",
                        "New project coming soon... 👀"
                    ]
                    return StorySegment(
                        type: .text,
                        backgroundColor: ["#6C5CE7", "#A29BFE", "#FD79A8", "#FDCB6E", "#00B894"].randomElement()!,
                        duration: 5.0,
                        text: texts.randomElement(),
                        textColor: "#FFFFFF"
                    )
                }
            }
            
            return StoryContent(
                creator: user,
                segments: segments,
                createdAt: Date().addingTimeInterval(-Double.random(in: 300...7200)),
                viewCount: Int.random(in: 50...5000),
                isViewed: index > 2
            )
        }
    }
}
