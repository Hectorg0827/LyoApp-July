import SwiftUI
#if canImport(NukeUI)
import NukeUI
#endif

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

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
            // Image (NukeUI if available, else AsyncImage)
            #if canImport(NukeUI)
            LazyImage(url: URL(string: course.thumbnailURL)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "play.circle")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                }
            }
            #else
            AsyncImage(url: URL(string: course.thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "play.circle")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                }
            }
            #endif
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
            #if canImport(NukeUI)
            LazyImage(url: URL(string: course.thumbnailURL)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "play.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            #else
            AsyncImage(url: URL(string: course.thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "play.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            #endif
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
            #if canImport(NukeUI)
            LazyImage(url: URL(string: course.thumbnailURL)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            #else
            AsyncImage(url: URL(string: course.thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            #endif
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
                    
                    Text(DateFormatter.shortDate.string(from: course.lastAccessed))
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
            #if canImport(NukeUI)
            LazyImage(url: URL(string: item.thumbnailURL)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: item.type == "video" ? "play.circle" : "doc.text")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            #else
            AsyncImage(url: URL(string: item.thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Image(systemName: item.type == "video" ? "play.circle" : "doc.text")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            #endif
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
                    
                    Text(item.savedDate, style: .date)
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
        // Load real data from UserDataManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // For now, create mock data since specific methods don't exist yet
            self.aiRecommended = self.createMockRecommendedCourses()
            self.inProgress = self.createMockInProgressCourses()
            self.completed = self.createMockCompletedCourses()
            self.saved = self.createMockSavedItems()
        }
    }
    
    private func createMockRecommendedCourses() -> [LibraryCourse] {
        return [
            LibraryCourse(
                title: "SwiftUI Advanced Techniques",
                instructor: "Apple Developer",
                progress: 0.0,
                thumbnailURL: "https://images.unsplash.com/photo-1498050108023-c5249f4df085",
                duration: "4h 30m",
                rating: 4.8,
                isCompleted: false,
                lastAccessed: Date()
            )
        ]
    }
    
    private func createMockInProgressCourses() -> [LibraryCourse] {
        return [
            LibraryCourse(
                title: "iOS Development Fundamentals",
                instructor: "CodePath",
                progress: 0.6,
                thumbnailURL: "https://images.unsplash.com/photo-1555099962-4199c345e5dd",
                duration: "8h 15m",
                rating: 4.7,
                isCompleted: false,
                lastAccessed: Date().addingTimeInterval(-86400)
            )
        ]
    }
    
    private func createMockCompletedCourses() -> [LibraryCourse] {
        return [
            LibraryCourse(
                title: "Swift Programming Basics",
                instructor: "Stanford",
                progress: 1.0,
                thumbnailURL: "https://images.unsplash.com/photo-1517077304055-6e89abbf09b0",
                duration: "6h 45m",
                rating: 4.9,
                isCompleted: true,
                lastAccessed: Date().addingTimeInterval(-172800)
            )
        ]
    }
    
    private func createMockSavedItems() -> [SavedItem] {
        return [
            SavedItem(
                title: "Advanced SwiftUI Tutorial",
                author: "Apple Developer",
                type: "video",
                thumbnailURL: "https://images.unsplash.com/photo-1498050108023-c5249f4df085",
                savedDate: Date()
            )
        ]
    }
}

// MARK: - Data Models
struct LibraryCourse: Identifiable {
    let id = UUID()
    let title: String
    let instructor: String
    let progress: Double
    let thumbnailURL: String
    let duration: String
    let rating: Double
    let isCompleted: Bool
    let lastAccessed: Date
}

struct SavedItem: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let type: String
    let thumbnailURL: String
    let savedDate: Date
}

#Preview {
    LibraryView()
        .environmentObject(AppState())
}
