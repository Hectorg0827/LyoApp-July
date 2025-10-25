import SwiftUI

struct CourseListView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject private var viewModel = CourseListViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: CourseCategory? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Header with search
                    searchSection
                    
                    // Featured Course
                    if let featuredCourse = viewModel.featuredCourse {
                        featuredCourseSection(course: featuredCourse)
                    }
                    
                    // Categories
                    categoriesSection
                    
                    // Course List
                    courseListSection
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task {
                await viewModel.loadCourses()
            }
        }
        .searchable(text: $searchText, prompt: "Search courses...")
        .onChange(of: searchText) { _, newValue in
            viewModel.searchCourses(query: newValue)
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextField("Search courses, topics, instructors...", text: $searchText)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func featuredCourseSection(course: Course) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Featured Course")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .foregroundColor(DesignTokens.Colors.accent)
            }
            
            FeaturedCourseCard(course: course) {
                // Handle enrollment
                Task {
                    await viewModel.enrollInCourse(course.id)
                }
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Categories")
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    CategoryChip(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                        viewModel.filterByCategory(nil)
                    }
                    
                    ForEach(CourseCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            viewModel.filterByCategory(category)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            }
        }
    }
    
    private var courseListSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text(selectedCategory?.displayName ?? "All Courses")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.filteredCourses.count) courses")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            if viewModel.isLoading && viewModel.courses.isEmpty {
                ForEach(0..<3) { _ in
                    CourseCardSkeleton()
                }
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(viewModel.filteredCourses) { course in
                        CourseCard(course: course) {
                            // Handle course selection
                            print("Selected course: \(course.title)")
                        }
                    }
                }
            }
        }
    }
}

struct FeaturedCourseCard: View {
    let course: Course
    let enrollAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            OptimizedAsyncImage(url: URL(string: course.thumbnailUrl))
                .aspectRatio(16/9, contentMode: .fill)
                .cornerRadius(DesignTokens.Radius.md)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(course.title)
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(course.description)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
                
                HStack {
                    Label(course.instructor, systemImage: "person.circle")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    Label("\(course.rating, specifier: "%.1f")", systemImage: "star.fill")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.accent)
                }
                
                AccessibleButton(
                    title: "Enroll Now",
                    style: .primary,
                    size: .medium
                ) {
                    enrollAction()
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .cardStyle()
    }
}

struct CourseCard: View {
    let course: Course
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                OptimizedAsyncImage(url: URL(string: course.thumbnailUrl))
                    .frame(width: 80, height: 60)
                    .cornerRadius(DesignTokens.Radius.sm)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(course.title)
                        .font(DesignTokens.Typography.titleSmall)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(course.instructor)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    HStack {
                        Label("\(course.rating, specifier: "%.1f")", systemImage: "star.fill")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.accent)
                        
                        Text("•")
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                        
                        Text(course.difficulty.displayName)
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(isSelected ? .white : DesignTokens.Colors.textSecondary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg
                )
                .cornerRadius(DesignTokens.Radius.full)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.full)
                        .stroke(
                            isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                            lineWidth: 1
                        )
                )
        }
    }
}

struct CourseCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(DesignTokens.Colors.glassBg)
                .frame(width: 80, height: 60)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(width: 100, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(width: 120, height: 10)
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .cardStyle()
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

@MainActor
class CourseListViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var filteredCourses: [Course] = []
    @Published var featuredCourse: Course?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadCourses() async {
        isLoading = true
        
        // Generate mock courses for now
        let mockCourses = generateMockCourses()
        self.courses = mockCourses
        self.filteredCourses = mockCourses
        self.featuredCourse = mockCourses.first
        
        isLoading = false
    }
    
    func searchCourses(query: String) {
        if query.isEmpty {
            filteredCourses = courses
        } else {
            filteredCourses = courses.filter { course in
                course.title.localizedCaseInsensitiveContains(query) ||
                course.description.localizedCaseInsensitiveContains(query) ||
                course.instructor.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func filterByCategory(_ category: CourseCategory?) {
        if let category = category {
            filteredCourses = courses.filter { $0.category == category }
        } else {
            filteredCourses = courses
        }
    }
    
    func enrollInCourse(_ courseId: String) async {
        print("Enrolling in course: \(courseId)")
        // This would use the container's course service
    }
    
    private func generateMockCourses() -> [Course] {
        return [
            Course(
                id: UUID().uuidString,
                title: "SwiftUI Masterclass",
                description: "Learn to build beautiful iOS apps with SwiftUI. From basics to advanced concepts.",
                instructor: "John Appleseed",
                thumbnailUrl: "",
                category: .programming,
                difficulty: .intermediate,
                duration: 8.5,
                rating: 4.8,
                enrollmentCount: 1250,
                isEnrolled: false,
                progress: 0.0,
                lessons: [],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Course(
                id: UUID().uuidString,
                title: "Machine Learning Fundamentals",
                description: "Introduction to machine learning concepts, algorithms, and practical applications.",
                instructor: "Dr. Sarah Chen",
                thumbnailUrl: "",
                category: .datascience,
                difficulty: .beginner,
                duration: 12.0,
                rating: 4.6,
                enrollmentCount: 890,
                isEnrolled: true,
                progress: 0.3,
                lessons: [],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Course(
                id: UUID().uuidString,
                title: "UI/UX Design Principles",
                description: "Master the art of designing user-friendly and beautiful interfaces.",
                instructor: "Maria Rodriguez",
                thumbnailUrl: "",
                category: .design,
                difficulty: .intermediate,
                duration: 6.0,
                rating: 4.9,
                enrollmentCount: 2100,
                isEnrolled: false,
                progress: 0.0,
                lessons: [],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Course(
                id: UUID().uuidString,
                title: "Digital Marketing Strategy",
                description: "Learn effective digital marketing techniques to grow your business online.",
                instructor: "Michael Johnson",
                thumbnailUrl: "",
                category: .business,
                difficulty: .beginner,
                duration: 5.5,
                rating: 4.4,
                enrollmentCount: 750,
                isEnrolled: false,
                progress: 0.0,
                lessons: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}

#Preview {
    CourseListView()
        .environmentObject(AppContainer.development())
}
