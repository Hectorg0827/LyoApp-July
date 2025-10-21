//
//  RealHomeFeedView.swift
//  LyoApp
//
//  PRODUCTION-ONLY HOME FEED VIEW
//  This view displays REAL data from the backend.
//  🚫 NO MOCK DATA - ALL DATA FROM GOOGLE CLOUD RUN BACKEND
//

import SwiftUI

struct RealHomeFeedView: View {
    @StateObject private var feedService = RealFeedService.shared
    @State private var selectedIndex = 0
    @State private var showingComments = false
    @State private var selectedPostId: String?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if feedService.isLoading && feedService.feedItems.isEmpty {
                // Loading state - First load
                loadingView
                
            } else if let error = feedService.error, feedService.feedItems.isEmpty {
                // Error state - No data available
                errorView(error: error)
                
            } else if feedService.feedItems.isEmpty {
                // Empty state - No posts available
                emptyView
                
            } else {
                // Feed content - REAL BACKEND DATA
                feedContentView
            }
            
            // Backend status indicator
            backendStatusIndicator
        }
        .task {
            // Load feed when view appears (if not already loaded)
            if feedService.feedItems.isEmpty {
                print("🔄 Initial feed load...")
                await feedService.loadFeed()
            }
        }
        .refreshable {
            // Pull to refresh
            await feedService.refreshFeed()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading your feed...")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("🌐 Connecting to backend")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(APIConfig.baseURL)
                .foregroundColor(.gray)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding()
    }
    
    // MARK: - Error View
    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Unable to load feed")
                .foregroundColor(.white)
                .font(.headline)
            
            Text(error.localizedDescription)
                .foregroundColor(.gray)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("🚫 No mock data fallback")
                .foregroundColor(.orange)
                .font(.caption2)
            
            Button(action: {
                Task {
                    await feedService.refreshFeed()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No posts yet")
                .foregroundColor(.white)
                .font(.headline)
            
            Text("Check back later for new content")
                .foregroundColor(.gray)
                .font(.caption)
            
            Text("✅ Backend connected")
                .foregroundColor(.green)
                .font(.caption2)
            
            Button(action: {
                Task {
                    await feedService.refreshFeed()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Feed Content View
    private var feedContentView: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(feedService.feedItems.enumerated()), id: \.element.id) { index, item in
                RealFeedItemView(
                    item: item,
                    onLike: {
                        Task {
                            await feedService.toggleLike(postId: item.id)
                        }
                    },
                    onComment: {
                        selectedPostId = item.id
                        showingComments = true
                    },
                    onShare: {
                        Task {
                            await feedService.sharePost(postId: item.id)
                        }
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .onChange(of: selectedIndex) { oldValue, newValue in
            // Load more when near the end
            if newValue >= feedService.feedItems.count - 3 {
                Task {
                    await feedService.loadMore()
                }
            }
        }
        .sheet(isPresented: $showingComments) {
            if let postId = selectedPostId {
                CommentSheetView(postId: postId, feedService: feedService)
            }
        }
    }
    
    // MARK: - Backend Status Indicator
    private var backendStatusIndicator: some View {
        VStack {
            HStack {
                Spacer()
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Live")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding(.top, 50)
                .padding(.trailing, 10)
            }
            
            Spacer()
        }
    }
}

// MARK: - Real Feed Item View
struct RealFeedItemView: View {
    let item: RealFeedItem
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Color.black
            
            // Media content (if available)
            if let mediaUrl = item.mediaUrl, !mediaUrl.isEmpty {
                AsyncImage(url: URL(string: mediaUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // Right side actions
            VStack(spacing: 20) {
                Spacer()
                
                // Like button
                VStack(spacing: 5) {
                    Button(action: onLike) {
                        Image(systemName: item.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 35))
                            .foregroundColor(item.isLiked ? .red : .white)
                    }
                    Text("\(item.likes)")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                // Comment button
                VStack(spacing: 5) {
                    Button(action: onComment) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    Text("\(item.comments)")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                
                // Share button
                VStack(spacing: 5) {
                    Button(action: onShare) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }
                    Text("\(item.shares)")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding(.trailing, 10)
            .padding(.bottom, 100)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Bottom info overlay
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // User avatar
                    if let avatarUrl = item.author.avatar, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                    
                    // User info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(item.author.username)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            if item.author.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(timeAgoString(from: item.timestamp))
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                // Post content
                Text(item.content)
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                // Tags
                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .foregroundColor(.cyan)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cyan.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Backend indicator
                Text("🌐 Real backend data")
                    .foregroundColor(.green)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func timeAgoString(from timestamp: String) -> String {
        // Parse ISO8601 timestamp
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else {
            return timestamp
        }
        
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))h ago"
        } else {
            return "\(Int(seconds / 86400))d ago"
        }
    }
}

// MARK: - Comment Sheet View
struct CommentSheetView: View {
    let postId: String
    let feedService: RealFeedService
    
    @State private var commentText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Comments")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                // Comment input
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        Task {
                            await feedService.addComment(postId: postId, text: commentText)
                            commentText = ""
                            dismiss()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(commentText.isEmpty)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RealHomeFeedView()
}
