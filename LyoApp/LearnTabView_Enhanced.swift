import SwiftUI

// MARK: - Enhanced Learn Tab View with Netflix-style Design
struct LearnTabView: View {
    @State private var selectedTab: LearningSectionType = .recentlyViewed
    @State private var showingStoryDrawer = false
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @FocusState private var searchFieldFocused: Bool
    
    // Educational content data - TODO: Integrate with UserDataManager
    @State private var courses: [Course] = [] // Course.sampleCourses - using empty array until real data integration
    @State private var videos: [EducationalVideo] = [] // EducationalVideo.sampleVideos - using empty array until real data integration
    @State private var ebooks: [Ebook] = [] // Ebook.sampleEbooks - using empty array until real data integration
    @State private var recentlyViewed: [EducationalContentItem] = []
    @State private var favorites: [EducationalContentItem] = []
    @State private var watchLater: [EducationalContentItem] = []
    
    private let categories = ["All", "Programming", "Design", "Data Science", "Business", "Languages"]
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.Colors.primaryBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search
                    headerSection
                    
                    // Main content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: DesignTokens.Spacing.xl) {
                            // Top tabs for recently viewed, favorites, etc.
                            topTabsSection
                            
                            // Recently viewed horizontal scroll (always at top)
                            if !recentlyViewed.isEmpty {
                                recentlyViewedSection
                            }
                            
                            // Content sections by category (Netflix style)
                            contentSectionsView
                        }
                        .padding(.bottom, 100) // Space for floating button
                    }
                }
                
                // Floating action button for downloads
                floatingActionButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadEducationalContent()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Header with drawer button
            HeaderView()
            
            // Search bar
            HStack(spacing: DesignTokens.Spacing.md) {
                searchBarView
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search courses, videos, ebooks...", text: $searchText)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .focused($searchFieldFocused)
                .onChange(of: searchFieldFocused) { _, focused in
                    withAnimation(DesignTokens.Animations.quick) {
                        isSearchFocused = focused
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchFieldFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(
                            isSearchFocused ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                            lineWidth: isSearchFocused ? 2 : 1
                        )
                )
        )
    }
    
    // MARK: - Top Tabs Section
    private var topTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(LearningSectionType.allCases, id: \.self) { tab in
                    topTabButton(for: tab)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
    
    private func topTabButton(for tab: LearningSectionType) -> some View {
        Button {
            withAnimation(DesignTokens.Animations.bouncy) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(tab.displayName)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .foregroundColor(selectedTab == tab ? .white : DesignTokens.Colors.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(selectedTab == tab ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: selectedTab == tab ? 0 : 1)
                    )
            )
        }
        .animation(DesignTokens.Animations.quick, value: selectedTab)
    }
    
    // MARK: - Recently Viewed Section
    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            sectionHeader(title: "Continue Learning", showViewAll: false)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(recentlyViewed.prefix(10)) { item in
                        ContinueLearningCard(item: item)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
    }
    
    // MARK: - Content Sections
    private var contentSectionsView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Courses section
            contentSection(
                title: "Featured Courses",
                content: courses.map { EducationalContentItem.course($0) }
            ) { item in
                if case .course(let course) = item {
                    CourseCard(course: course)
                }
            }
            
            // Videos section
            contentSection(
                title: "Popular Videos",
                content: videos.map { EducationalContentItem.video($0) }
            ) { item in
                if case .video(let video) = item {
                    VideoCard(video: video)
                }
            }
            
            // Ebooks section
            contentSection(
                title: "Recommended E-Books",
                content: ebooks.map { EducationalContentItem.ebook($0) }
            ) { item in
                if case .ebook(let ebook) = item {
                    EbookCard(ebook: ebook)
                }
            }
            
            // Categories sections (Programming, Design, etc.)
            ForEach(categories.dropFirst(), id: \.self) { category in
                categorySection(category: category)
            }
        }
    }
    
    private func contentSection<Content: View>(
        title: String,
        content: [EducationalContentItem],
        @ViewBuilder cardBuilder: @escaping (EducationalContentItem) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            sectionHeader(title: title, showViewAll: true)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(content.prefix(10)) { item in
                        cardBuilder(item)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
    }
    
    private func categorySection(category: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            sectionHeader(title: category, showViewAll: true)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Mix content from all types for this category
                    ForEach(getContentForCategory(category).prefix(10)) { item in
                        switch item {
                        case .course(let course):
                            CourseCard(course: course)
                        case .video(let video):
                            VideoCard(video: video)
                        case .ebook(let ebook):
                            EbookCard(ebook: ebook)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
    }
    
    private func sectionHeader(title: String, showViewAll: Bool) -> some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .fontWeight(.bold)
            
            Spacer()
            
            if showViewAll {
                Button("View All") {
                    // Handle view all action
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button {
                    // Handle downloads action
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(DesignTokens.Colors.primary)
                                .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadEducationalContent() {
        // Simulate loading recently viewed content
        let sampleRecentItems = [
            EducationalContentItem.course(courses.first!),
            EducationalContentItem.video(videos.first!),
            EducationalContentItem.ebook(ebooks.first!)
        ]
        
        recentlyViewed = sampleRecentItems
        favorites = Array(sampleRecentItems.prefix(2))
        watchLater = Array(sampleRecentItems.suffix(2))
    }
    
    private func getContentForCategory(_ category: String) -> [EducationalContentItem] {
        var items: [EducationalContentItem] = []
        
        // Add courses for this category
        items.append(contentsOf: courses.filter { $0.category == category }.map { EducationalContentItem.course($0) })
        
        // Add videos for this category
        items.append(contentsOf: videos.filter { $0.category == category }.map { EducationalContentItem.video($0) })
        
        // Add ebooks for this category
        items.append(contentsOf: ebooks.filter { $0.category == category }.map { EducationalContentItem.ebook($0) })
        
        return items.shuffled()
    }
}

// MARK: - Educational Content Item Wrapper
enum EducationalContentItem: Identifiable {
    case course(Course)
    case video(EducationalVideo)
    case ebook(Ebook)
    
    var id: String {
        switch self {
        case .course(let course): return "course_\(course.id)"
        case .video(let video): return "video_\(video.id)"
        case .ebook(let ebook): return "ebook_\(ebook.id)"
        }
    }
    
    var title: String {
        switch self {
        case .course(let course): return course.title
        case .video(let video): return video.title
        case .ebook(let ebook): return ebook.title
        }
    }
    
    var thumbnailURL: String {
        switch self {
        case .course(let course): return course.thumbnailURL
        case .video(let video): return video.thumbnailURL
        case .ebook(let ebook): return ebook.coverImageURL
        }
    }
    
    var progress: Double {
        switch self {
        case .course(let course): return course.progress
        case .video(let video): return video.watchProgress
        case .ebook(let ebook): return ebook.readProgress
        }
    }
}

// MARK: - Continue Learning Card
struct ContinueLearningCard: View {
    let item: EducationalContentItem
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Handle item tap
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Thumbnail with progress overlay
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: item.thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DesignTokens.Colors.secondaryBg)
                            .overlay(
                                Image(systemName: contentTypeIcon)
                                    .font(.system(size: 24))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            )
                    }
                    .frame(width: 200, height: 112)
                    .clipped()
                    .cornerRadius(DesignTokens.Radius.md)
                    
                    // Progress bar
                    if item.progress > 0 {
                        VStack {
                            Spacer()
                            ProgressView(value: item.progress)
                                .progressViewStyle(LinearProgressViewStyle()).tint(DesignTokens.Colors.primary)
                                .scaleEffect(y: 2)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 4)
                        }
                    }
                    
                    // Content type badge
                    VStack {
                        HStack {
                            Spacer()
                            contentTypeBadge
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                
                // Title and metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if item.progress > 0 {
                        Text("\(Int(item.progress * 100))% complete")
                            .font(.system(size: 12))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .frame(width: 200, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private var contentTypeIcon: String {
        switch item {
        case .course: return "graduationcap.fill"
        case .video: return "play.rectangle.fill"
        case .ebook: return "book.fill"
        }
    }
    
    private var contentTypeBadge: some View {
        Text(contentTypeText)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(contentTypeColor)
            )
    }
    
    private var contentTypeText: String {
        switch item {
        case .course: return "COURSE"
        case .video: return "VIDEO"
        case .ebook: return "EBOOK"
        }
    }
    
    private var contentTypeColor: Color {
        switch item {
        case .course: return DesignTokens.Colors.primary
        case .video: return .red
        case .ebook: return .green
        }
    }
}

// MARK: - Enhanced Course Card
struct CourseCard: View {
    let course: Course
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Handle course tap
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Course thumbnail
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DesignTokens.Colors.secondaryBg)
                            .overlay(
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            )
                    }
                    .frame(width: 160, height: 90)
                    .clipped()
                    .cornerRadius(DesignTokens.Radius.md)
                    
                    // Difficulty badge
                    Text(course.difficulty.rawValue.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(course.difficulty.color)
                        )
                        .padding(8)
                }
                
                // Course info
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(course.instructor)
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", course.rating))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        // Students count
                        Text("\(course.studentsCount)")
                            .font(.system(size: 10))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                    }
                    
                    // Progress bar if enrolled
                    if course.isEnrolled && course.progress > 0 {
                        ProgressView(value: course.progress)
                            .progressViewStyle(LinearProgressViewStyle()).tint(DesignTokens.Colors.primary)
                            .scaleEffect(y: 1.5)
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Enhanced Video Card
struct VideoCard: View {
    let video: EducationalVideo
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Handle video tap
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Video thumbnail
                ZStack {
                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DesignTokens.Colors.secondaryBg)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            )
                    }
                    .frame(width: 160, height: 90)
                    .clipped()
                    .cornerRadius(DesignTokens.Radius.md)
                    
                    // Play button overlay
                    Circle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    // Duration badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(formatDuration(video.duration))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.7))
                                )
                                .padding(8)
                        }
                    }
                    
                    // Progress bar if started
                    if video.watchProgress > 0 {
                        VStack {
                            Spacer()
                            ProgressView(value: video.watchProgress)
                                .progressViewStyle(LinearProgressViewStyle()).tint(.red)
                                .scaleEffect(y: 2)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 4)
                        }
                    }
                }
                
                // Video info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(video.instructor)
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", video.rating))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        // View count
                        Text("\(formatCount(video.viewCount))")
                            .font(.system(size: 10))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Enhanced Ebook Card
struct EbookCard: View {
    let ebook: Ebook
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Handle ebook tap
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Ebook cover
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: ebook.coverImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DesignTokens.Colors.secondaryBg)
                            .overlay(
                                Image(systemName: "book.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            )
                    }
                    .frame(width: 120, height: 160)
                    .clipped()
                    .cornerRadius(DesignTokens.Radius.md)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // Bookmark icon if bookmarked
                    if ebook.isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignTokens.Colors.primary)
                            .padding(8)
                    }
                }
                
                // Ebook info
                VStack(alignment: .leading, spacing: 4) {
                    Text(ebook.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("by \(ebook.author)")
                        .font(.system(size: 12))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", ebook.rating))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        // Pages
                        Text("\(ebook.pages) pages")
                            .font(.system(size: 10))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                    }
                    
                    // Progress bar if started reading
                    if ebook.readProgress > 0 {
                        ProgressView(value: ebook.readProgress)
                            .progressViewStyle(LinearProgressViewStyle()).tint(.green)
                            .scaleEffect(y: 1.5)
                    }
                }
                .frame(width: 120, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

#Preview {
    LearnTabView()
        .environmentObject(AppState())
}
