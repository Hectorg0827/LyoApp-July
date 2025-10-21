import SwiftUI

// MARK: - Resource Curation Models

struct CuratedResource: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let url: String
    let type: ResourceType
    let thumbnail: String?
    let author: String?
    let rating: Double?
    let duration: String?
    
    enum ResourceType: String, Codable {
        case book = "book"
        case video = "video"
        case article = "article"
        case documentation = "documentation"
        case tutorial = "tutorial"
        case forum = "forum"
        case course = "course"
        
        var icon: String {
            switch self {
            case .book: return "book.fill"
            case .video: return "play.rectangle.fill"
            case .article: return "doc.text.fill"
            case .documentation: return "doc.plaintext.fill"
            case .tutorial: return "lightbulb.fill"
            case .forum: return "bubble.left.and.bubble.right.fill"
            case .course: return "graduationcap.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .book: return .blue
            case .video: return .red
            case .article: return .green
            case .documentation: return .purple
            case .tutorial: return .orange
            case .forum: return .cyan
            case .course: return .indigo
            }
        }
        
        var displayName: String {
            switch self {
            case .book: return "Book"
            case .video: return "Video"
            case .article: return "Article"
            case .documentation: return "Docs"
            case .tutorial: return "Tutorial"
            case .forum: return "Forum"
            case .course: return "Course"
            }
        }
    }
}

// MARK: - Resource Curation Bar View

struct ResourceCurationBar: View {
    let topic: String
    @State private var resources: [CuratedResource] = []
    @State private var isLoading = false
    @State private var selectedFilter: CuratedResource.ResourceType? = nil
    @State private var isExpanded = true
    
    var filteredResources: [CuratedResource] {
        if let filter = selectedFilter {
            return resources.filter { $0.type == filter }
        }
        return resources
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            resourceBarHeader
            
            // Filter tabs
            if isExpanded {
                filterTabs
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Resources scroll
            if isExpanded {
                resourcesScrollView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(DesignTokens.Colors.secondaryBg)
        .onAppear {
            loadResources()
        }
    }
    
    // MARK: - Header
    private var resourceBarHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.title3)
                    .foregroundColor(DesignTokens.Colors.primary)
                
                Text("Curated Resources")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
            
            // Resource count badge
            if !resources.isEmpty {
                Text("\(resources.count)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignTokens.Colors.primary)
                    .clipShape(Capsule())
            }
            
            // Expand/collapse button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignTokens.Colors.secondaryBg)
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All filter
                FilterChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    count: resources.count,
                    isSelected: selectedFilter == nil,
                    color: .gray
                ) {
                    withAnimation {
                        selectedFilter = nil
                    }
                }
                
                // Type filters
                ForEach([
                    CuratedResource.ResourceType.video,
                    .book,
                    .article,
                    .documentation,
                    .tutorial,
                    .forum
                ], id: \.self) { type in
                    let count = resources.filter { $0.type == type }.count
                    if count > 0 {
                        FilterChip(
                            title: type.displayName,
                            icon: type.icon,
                            count: count,
                            isSelected: selectedFilter == type,
                            color: type.color
                        ) {
                            withAnimation {
                                selectedFilter = selectedFilter == type ? nil : type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(DesignTokens.Colors.primaryBg.opacity(0.5))
    }
    
    // MARK: - Resources Scroll View
    private var resourcesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                if isLoading {
                    // Loading placeholders
                    ForEach(0..<5, id: \.self) { _ in
                        ResourceCardSkeleton()
                    }
                } else if filteredResources.isEmpty {
                    // Empty state
                    emptyResourcesView
                } else {
                    // Resource cards
                    ForEach(filteredResources) { resource in
                        ResourceCard(resource: resource)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private var emptyResourcesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("Finding the best resources for you...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // MARK: - Load Resources
    private func loadResources() {
        isLoading = true
        
        // Simulate API call with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            resources = generateMockResources(for: topic)
            isLoading = false
        }
        
        // TODO: Replace with real API call
        // Task {
        //     do {
        //         resources = try await ResourceCurationAPI.fetchResources(topic: topic)
        //         isLoading = false
        //     } catch {
        //         print("Failed to load resources: \(error)")
        //         isLoading = false
        //     }
        // }
    }
    
    // MARK: - Mock Data Generator
    private func generateMockResources(for topic: String) -> [CuratedResource] {
        [
            CuratedResource(
                id: "1",
                title: "\(topic) Fundamentals - Google Books",
                description: "Comprehensive textbook covering core concepts and practical applications",
                url: "https://books.google.com",
                type: .book,
                thumbnail: nil,
                author: "Expert Authors",
                rating: 4.5,
                duration: nil
            ),
            CuratedResource(
                id: "2",
                title: "\(topic) Tutorial - YouTube",
                description: "Step-by-step video guide from beginner to advanced",
                url: "https://youtube.com",
                type: .video,
                thumbnail: nil,
                author: "Tech Channel",
                rating: 4.8,
                duration: "2h 30m"
            ),
            CuratedResource(
                id: "3",
                title: "Official \(topic) Documentation",
                description: "Complete reference guide with examples and best practices",
                url: "https://docs.example.com",
                type: .documentation,
                thumbnail: nil,
                author: "Official Docs",
                rating: 4.9,
                duration: nil
            ),
            CuratedResource(
                id: "4",
                title: "Understanding \(topic) - Medium",
                description: "In-depth article explaining key concepts with real-world examples",
                url: "https://medium.com",
                type: .article,
                thumbnail: nil,
                author: "Tech Writer",
                rating: 4.3,
                duration: "15 min read"
            ),
            CuratedResource(
                id: "5",
                title: "\(topic) Interactive Tutorial",
                description: "Hands-on coding exercises with instant feedback",
                url: "https://codecademy.com",
                type: .tutorial,
                thumbnail: nil,
                author: "Codecademy",
                rating: 4.7,
                duration: "3 hours"
            ),
            CuratedResource(
                id: "6",
                title: "\(topic) Q&A - Stack Overflow",
                description: "Community discussions and solutions to common problems",
                url: "https://stackoverflow.com",
                type: .forum,
                thumbnail: nil,
                author: "Community",
                rating: 4.6,
                duration: nil
            ),
            CuratedResource(
                id: "7",
                title: "Complete \(topic) Course - Coursera",
                description: "University-level course with certificate",
                url: "https://coursera.org",
                type: .course,
                thumbnail: nil,
                author: "Stanford University",
                rating: 4.9,
                duration: "6 weeks"
            ),
            CuratedResource(
                id: "8",
                title: "Advanced \(topic) Video Series",
                description: "Deep dive into advanced concepts and optimization techniques",
                url: "https://youtube.com",
                type: .video,
                thumbnail: nil,
                author: "Expert Channel",
                rating: 4.7,
                duration: "4h 15m"
            )
        ]
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(DesignTokens.Typography.caption)
                
                Text("(\(count))")
                    .font(.system(size: 10))
                    .opacity(0.8)
            }
            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : DesignTokens.Colors.glassBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Resource Card Component
struct ResourceCard: View {
    let resource: CuratedResource
    @State private var isPressed = false
    
    var body: some View {
        Button {
            openResource()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Type badge and icon
                HStack {
                    Image(systemName: resource.type.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(resource.type.color)
                        )
                    
                    Spacer()
                    
                    Text(resource.type.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(resource.type.color)
                        .clipShape(Capsule())
                }
                
                // Title
                Text(resource.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Description
                Text(resource.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Footer with author and rating
                VStack(alignment: .leading, spacing: 4) {
                    if let author = resource.author {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text(author)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        if let rating = resource.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }
                        
                        if let duration = resource.duration {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(duration)
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                }
                
                // Open link button
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.title3)
                        .foregroundColor(resource.type.color)
                }
            }
            .padding(16)
            .frame(width: 280, height: 240)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(resource.type.color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func openResource() {
        // Open URL in Safari or in-app browser
        if let url = URL(string: resource.url) {
            UIApplication.shared.open(url)
        }
        
        // TODO: Add analytics tracking
        print("📖 Opening resource: \(resource.title)")
    }
}

// MARK: - Loading Skeleton
struct ResourceCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            // Title placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 20)
            
            // Description placeholder
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
            }
            
            Spacer()
            
            // Footer placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 12)
        }
        .padding(16)
        .frame(width: 280, height: 240)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
#Preview {
    ResourceCurationBar(topic: "Python Programming")
        .frame(height: 300)
}
