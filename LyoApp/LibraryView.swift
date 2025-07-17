
import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Programming", "Design", "AI/ML", "Business", "Saved"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Your Library")
                            .font(DesignTokens.Typography.title1)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Courses, tutorials, and saved content")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.md)
                
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(selectedCategory == category ? .white : DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(selectedCategory == category ? DesignTokens.Colors.primary : Color.clear)
                            )
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.lg) {
                        // AI-Recommended Section
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                
                                Text("AI Recommended")
                                    .font(DesignTokens.Typography.title3)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    ForEach(libraryViewModel.aiRecommended) { course in
                                        RecommendedCourseCard(course: course)
                                    }
                                }
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                        }
                        
                        // Continue Learning
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Image(systemName: "play.circle")
                                    .foregroundColor(DesignTokens.Colors.neonGreen)
                                
                                Text("Continue Learning")
                                    .font(DesignTokens.Typography.title3)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            
                            ForEach(libraryViewModel.inProgress) { course in
                                InProgressCourseCard(course: course)
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                        }
                        
                        // Completed Courses
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(DesignTokens.Colors.success)
                                
                                Text("Completed")
                                    .font(DesignTokens.Typography.title3)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            
                            ForEach(libraryViewModel.completed) { course in
                                CompletedCourseCard(course: course)
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                        }
                        
                        // Saved Content
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            HStack {
                                Image(systemName: "bookmark")
                                    .foregroundColor(DesignTokens.Colors.warning)
                                
                                Text("Saved")
                                    .font(DesignTokens.Typography.title3)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            
                            ForEach(libraryViewModel.saved) { item in
                                SavedItemCard(item: item)
                                    .padding(.horizontal, DesignTokens.Spacing.lg)
                            }
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.lg)
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
        }
        .onAppear {
            libraryViewModel.loadLibrary()
        }
    }
}

// MARK: - Recommended Course Card
struct RecommendedCourseCard: View {
    let course: LibraryCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .overlay(
                        Image(systemName: "play.circle")
                            .font(.title)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course.title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(course.instructor)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(DesignTokens.Colors.warning)
                        .font(.caption2)
                    
                    Text("\(course.rating, specifier: "%.1f")")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .frame(width: 160)
    }
}

// MARK: - In Progress Course Card
struct InProgressCourseCard: View {
    let course: LibraryCourse
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .overlay(
                        Image(systemName: "play.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(course.instructor)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                // Progress bar
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("\(Int(course.progress * 100))% complete")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text(course.duration)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    ProgressView(value: course.progress)
                        .tint(DesignTokens.Colors.primary)
                        .background(DesignTokens.Colors.glassBg)
                }
            }
            
            Spacer()
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
    }
}

// MARK: - Completed Course Card
struct CompletedCourseCard: View {
    let course: LibraryCourse
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .overlay(
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .strokeBorder(DesignTokens.Colors.success, lineWidth: 2)
            )
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(course.instructor)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                        .font(.caption)
                    
                    Text("Completed")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.success)
                    
                    Spacer()
                    
                    Text(course.completedDate ?? "")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
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
    }
}

// MARK: - Saved Item Card
struct SavedItemCard: View {
    let item: SavedItem
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .overlay(
                        Image(systemName: item.type == .video ? "play.circle" : "doc.text")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(item.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(item.author)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(DesignTokens.Colors.warning)
                        .font(.caption)
                    
                    Text("Saved")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.warning)
                    
                    Spacer()
                    
                    Text(item.savedDate)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                // Remove from saved
            } label: {
                Image(systemName: "bookmark.slash")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
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
    }
}

// MARK: - Library View Model
class LibraryViewModel: ObservableObject {
    @Published var aiRecommended: [LibraryCourse] = []
    @Published var inProgress: [LibraryCourse] = []
    @Published var completed: [LibraryCourse] = []
    @Published var saved: [SavedItem] = []
    
    func loadLibrary() {
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.aiRecommended = LibraryCourse.sampleRecommended
            self.inProgress = LibraryCourse.sampleInProgress
            self.completed = LibraryCourse.sampleCompleted
            self.saved = SavedItem.sampleSaved
        }
    }
}

// MARK: - Models
struct LibraryCourse: Identifiable {
    let id = UUID()
    let title: String
    let instructor: String
    let thumbnailURL: String
    let rating: Double
    let duration: String
    let progress: Double
    let completedDate: String?
    
    static let sampleRecommended: [LibraryCourse] = [
        LibraryCourse(title: "Advanced SwiftUI Animations", instructor: "John Doe", thumbnailURL: "https://picsum.photos/160/90?random=1", rating: 4.8, duration: "3h 45m", progress: 0.0, completedDate: nil),
        LibraryCourse(title: "Machine Learning Fundamentals", instructor: "Jane Smith", thumbnailURL: "https://picsum.photos/160/90?random=2", rating: 4.9, duration: "8h 30m", progress: 0.0, completedDate: nil),
        LibraryCourse(title: "iOS App Design Patterns", instructor: "Mike Johnson", thumbnailURL: "https://picsum.photos/160/90?random=3", rating: 4.7, duration: "5h 20m", progress: 0.0, completedDate: nil)
    ]
    
    static let sampleInProgress: [LibraryCourse] = [
        LibraryCourse(title: "Building AI-Powered Apps", instructor: "Sarah Wilson", thumbnailURL: "https://picsum.photos/160/90?random=4", rating: 4.9, duration: "12h 15m", progress: 0.65, completedDate: nil),
        LibraryCourse(title: "SwiftUI Mastery", instructor: "David Brown", thumbnailURL: "https://picsum.photos/160/90?random=5", rating: 4.8, duration: "6h 45m", progress: 0.32, completedDate: nil)
    ]
    
    static let sampleCompleted: [LibraryCourse] = [
        LibraryCourse(title: "iOS Development Basics", instructor: "Emily Davis", thumbnailURL: "https://picsum.photos/160/90?random=6", rating: 4.6, duration: "4h 30m", progress: 1.0, completedDate: "2 weeks ago"),
        LibraryCourse(title: "Git & GitHub Essentials", instructor: "Tom Anderson", thumbnailURL: "https://picsum.photos/160/90?random=7", rating: 4.7, duration: "2h 15m", progress: 1.0, completedDate: "1 month ago")
    ]
}

struct SavedItem: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let thumbnailURL: String?
    let type: SavedItemType
    let savedDate: String
    
    enum SavedItemType {
        case video
        case article
        case post
    }
    
    static let sampleSaved: [SavedItem] = [
        SavedItem(title: "10 SwiftUI Tips Every Developer Should Know", author: "Code Master", thumbnailURL: "https://picsum.photos/160/90?random=8", type: .video, savedDate: "Yesterday"),
        SavedItem(title: "The Future of AI in Mobile Development", author: "Tech Insider", thumbnailURL: "https://picsum.photos/160/90?random=9", type: .article, savedDate: "3 days ago"),
        SavedItem(title: "Building Responsive UIs with SwiftUI", author: "UI Expert", thumbnailURL: "https://picsum.photos/160/90?random=10", type: .post, savedDate: "1 week ago")
    ]
}

