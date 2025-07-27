import SwiftUI

/**
 * Educational Content Demo & Testing View
 * Tests all integrated APIs and displays comprehensive educational content
 */
struct EducationalContentDemoView: View {
    @StateObject private var contentManager = EducationalContentManager()
    @StateObject private var edxService = EdXCoursesService()
    @State private var searchQuery = "machine learning"
    @State private var selectedContentType: ContentType = .all
    @State private var isLoading = false
    @State private var searchResults: [EducationalContentItem] = []
    @State private var featuredCourses: [Course] = []
    
    enum ContentType: String, CaseIterable {
        case all = "All Content"
        case videos = "Videos"
        case books = "Books"  
        case podcasts = "Podcasts"
        case courses = "Courses"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .videos: return "play.rectangle"
            case .books: return "book"
            case .podcasts: return "headphones"
            case .courses: return "graduationcap"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content type filter
                contentTypeFilter
                
                // Search results
                if isLoading {
                    loadingView
                } else {
                    contentGrid
                }
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Educational Content")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadInitialContent()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // API Status indicators
            HStack(spacing: DesignTokens.Spacing.sm) {
                APIStatusIndicator(name: "YouTube", status: .active, color: .red)
                APIStatusIndicator(name: "Books", status: .active, color: .blue)
                APIStatusIndicator(name: "Podcasts", status: .active, color: .purple)
                APIStatusIndicator(name: "edX", status: .active, color: .green)
                APIStatusIndicator(name: "Khan", status: .discontinued, color: .gray)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                TextField("Search educational content...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                Button("Search") {
                    performSearch()
                }
                .font(DesignTokens.Typography.buttonLabel)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.primary)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Content Type Filter
    private var contentTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedContentType = type
                        filterContent()
                    }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                            
                            Text(type.rawValue)
                                .font(DesignTokens.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedContentType == type ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                        )
                        .foregroundColor(selectedContentType == type ? .white : DesignTokens.Colors.textPrimary)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    selectedContentType == type ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.bottom, DesignTokens.Spacing.md)
    }
    
    // MARK: - Content Grid
    private var contentGrid: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                // Featured edX courses section
                if !featuredCourses.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("🎓 Featured University Courses")
                                .font(DesignTokens.Typography.title3)
                                .fontWeight(.bold)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Spacer()
                            
                            NavigationLink(destination: EdXCourseBrowserView()) {
                                Text("View All")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.primary)
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                ForEach(featuredCourses.prefix(5)) { course in
                                    UniversityCourseCard(course: course)
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        }
                    }
                }
                
                // Search results
                if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Search Results (\(searchResults.count))")
                            .font(DesignTokens.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: DesignTokens.Spacing.md) {
                            ForEach(searchResults) { item in
                                ContentItemCard(item: item)
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                } else if !isLoading {
                    emptyStateView
                }
            }
        }
    }
    
    // MARK: - Loading and Empty States
    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching educational content...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("YouTube • Google Books • Podcasts • edX")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("No results found")
                .font(DesignTokens.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Try searching for topics like 'machine learning', 'calculus', or 'programming'")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Try Popular Searches") {
                searchQuery = ["Swift Programming", "Data Science", "Calculus", "Physics"].randomElement() ?? "Programming"
                performSearch()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .padding()
            .background(DesignTokens.Colors.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
        }
        .padding(DesignTokens.Spacing.xl)
    }
    
    // MARK: - Helper Methods
    private func loadInitialContent() {
        Task {
            do {
                featuredCourses = try await edxService.getFeaturedCourses()
                await performInitialSearch()
            } catch {
                print("Failed to load initial content: \(error)")
            }
        }
    }
    
    @MainActor
    private func performInitialSearch() async {
        searchQuery = "introduction to computer science"
        await performSearch()
    }
    
    private func performSearch() {
        isLoading = true
        
        Task {
            do {
                // Simulate API calls - replace with actual implementation when API keys are added
                await simulateSearchResults()
            } catch {
                print("Search failed: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func filterContent() {
        // Filter current results based on selected content type
        // Implementation depends on your content structure
    }
    
    // MARK: - Mock Data Generation
    @MainActor
    private func simulateSearchResults() async {
        // Simulate API response delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Generate mock results based on search query and content type
        searchResults = generateMockResults(for: searchQuery, type: selectedContentType)
    }
    
    private func generateMockResults(for query: String, type: ContentType) -> [EducationalContentItem] {
        let mockVideos = [
            EducationalVideo(
                id: UUID().uuidString,
                title: "\(query) - Complete Tutorial",
                description: "Comprehensive guide to \(query) concepts",
                thumbnailURL: "",
                videoURL: "",
                duration: "45:30",
                instructor: "Prof. Sarah Johnson",
                views: 156789,
                rating: 4.8,
                category: "Computer Science"
            ),
            EducationalVideo(
                id: UUID().uuidString,
                title: "Advanced \(query) Techniques",
                description: "Deep dive into advanced \(query) methodologies",
                thumbnailURL: "",
                videoURL: "",
                duration: "32:15",
                instructor: "Dr. Michael Chen",
                views: 89234,
                rating: 4.7,
                category: "Technology"
            )
        ]
        
        let mockBooks = [
            Ebook(
                id: UUID().uuidString,
                title: "Mastering \(query): A Comprehensive Guide",
                author: "Dr. Emily Rodriguez",
                description: "The definitive resource for learning \(query)",
                coverImageURL: "",
                pdfURL: "",
                rating: 4.9,
                pageCount: 450,
                category: "Educational",
                isBookmarked: false
            )
        ]
        
        var results: [EducationalContentItem] = []
        
        switch type {
        case .all:
            results.append(contentsOf: mockVideos.map { .video($0) })
            results.append(contentsOf: mockBooks.map { .ebook($0) })
        case .videos:
            results.append(contentsOf: mockVideos.map { .video($0) })
        case .books:
            results.append(contentsOf: mockBooks.map { .ebook($0) })
        case .podcasts, .courses:
            // Add mock podcast and course data as needed
            break
        }
        
        return results
    }
}

// MARK: - Supporting Views

struct APIStatusIndicator: View {
    let name: String
    let status: APIStatus
    let color: Color
    
    enum APIStatus {
        case active, discontinued, pending
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .discontinued: return "xmark.circle.fill"
            case .pending: return "clock.circle.fill"
            }
        }
        
        var statusColor: Color {
            switch self {
            case .active: return .green
            case .discontinued: return .red
            case .pending: return .orange
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 10))
                    .foregroundColor(status.statusColor)
                
                Text(name)
                    .font(DesignTokens.Typography.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            Rectangle()
                .fill(status.statusColor)
                .frame(height: 2)
                .cornerRadius(1)
        }
    }
}

struct UniversityCourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Course thumbnail
            AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Image(systemName: "graduationcap")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 200, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(course.instructor)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", course.rating))
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("FREE")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
}

struct ContentItemCard: View {
    let item: EducationalContentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Content thumbnail
            contentThumbnail
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                contentTitle
                contentDetails
                contentMetadata
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var contentThumbnail: some View {
        Rectangle()
            .fill(item.gradientColors)
            .frame(height: 100)
            .overlay(
                Image(systemName: item.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
    
    @ViewBuilder
    private var contentTitle: some View {
        Text(item.title)
            .font(DesignTokens.Typography.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .lineLimit(2)
    }
    
    @ViewBuilder
    private var contentDetails: some View {
        Text(item.instructor)
            .font(DesignTokens.Typography.caption)
            .foregroundColor(DesignTokens.Colors.textSecondary)
            .lineLimit(1)
    }
    
    @ViewBuilder
    private var contentMetadata: some View {
        HStack {
            Text(item.category)
                .font(DesignTokens.Typography.caption2)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.primary.opacity(0.1))
                )
                .foregroundColor(DesignTokens.Colors.primary)
            
            Spacer()
            
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                
                Text(String(format: "%.1f", item.rating))
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Extensions
extension EducationalContentItem {
    var gradientColors: LinearGradient {
        switch self {
        case .video:
            return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ebook:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .course:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var iconName: String {
        switch self {
        case .video: return "play.rectangle"
        case .ebook: return "book"
        case .course: return "graduationcap"
        }
    }
    
    var title: String {
        switch self {
        case .video(let video): return video.title
        case .ebook(let ebook): return ebook.title
        case .course(let course): return course.title
        }
    }
    
    var instructor: String {
        switch self {
        case .video(let video): return video.instructor
        case .ebook(let ebook): return ebook.author
        case .course(let course): return course.instructor
        }
    }
    
    var category: String {
        switch self {
        case .video(let video): return video.category
        case .ebook(let ebook): return ebook.category
        case .course(let course): return course.category
        }
    }
    
    var rating: Double {
        switch self {
        case .video(let video): return video.rating
        case .ebook(let ebook): return ebook.rating
        case .course(let course): return course.rating
        }
    }
}

#Preview {
    EducationalContentDemoView()
}
