import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var networkManager: NetworkManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        // Loading skeleton
                        ForEach(0..<5) { _ in
                            FeedItemSkeleton()
                        }
                    } else {
                        ForEach(viewModel.posts) { post in
                            FeedItemView(post: post)
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshFeed()
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Create post action
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadFeed()
            }
        }
    }
}

struct FeedItemView: View {
    let post: FeedPost
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack {
                AsyncImage(url: URL(string: post.user.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user.fullName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(timeAgo(from: post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Media
            if let mediaURL = post.mediaURL, let mediaType = post.mediaType {
                if mediaType == "image" {
                    AsyncImage(url: URL(string: mediaURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                    }
                    .cornerRadius(12)
                }
            }
            
            // Interaction Bar
            HStack(spacing: 20) {
                Button(action: {
                    isLiked.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(post.likesCount)")
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    // Comment action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                        Text("\(post.commentsCount)")
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    // Share action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("\(post.sharesCount)")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // Bookmark action
                }) {
                    Image(systemName: "bookmark")
                }
            }
            .foregroundColor(.primary)
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            isLiked = post.isLiked ?? false
        }
    }
    
    private func timeAgo(from dateString: String) -> String {
        // Simple time ago implementation
        return "2h"
    }
}

struct FeedItemSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .frame(maxWidth: 120)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(maxWidth: 80)
                }
                
                Spacer()
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 60)
            
            HStack {
                ForEach(0..<3) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 20)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shimmer()
    }
}

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [FeedPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadFeed() async {
        isLoading = true
        
        do {
            let feedResponse: FeedResponse = try await networkManager.get(
                endpoint: BackendConfig.Endpoints.feed,
                responseType: FeedResponse.self
            )
            posts = feedResponse.posts
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshFeed() async {
        await loadFeed()
    }
}

struct FeedResponse: Codable {
    let posts: [FeedPost]
    let totalCount: Int
    let hasMore: Bool
}

// Shimmer Effect Extension
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
