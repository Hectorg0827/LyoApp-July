import SwiftUI

struct LearningView: View {
    @StateObject private var viewModel = LearningViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Segmented Control
                Picker("Learning Section", selection: $selectedTab) {
                    Text("Courses").tag(0)
                    Text("Progress").tag(1)
                    Text("Bookmarks").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedTab) {
                    CoursesTab(viewModel: viewModel)
                        .tag(0)
                    
                    ProgressTab(viewModel: viewModel)
                        .tag(1)
                    
                    BookmarksTab(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Learning")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Search courses
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadCourses()
            }
        }
    }
}

struct CoursesTab: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading && viewModel.courses.isEmpty {
                    ForEach(0..<3) { _ in
                        CourseCardSkeleton()
                    }
                } else {
                    ForEach(viewModel.courses) { course in
                        CourseCard(course: course)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshCourses()
        }
    }
}

struct ProgressTab: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Overview
                VStack(spacing: 16) {
                    Text("Your Learning Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        ProgressStat(title: "Completed", value: "12", subtitle: "Courses")
                        ProgressStat(title: "In Progress", value: "3", subtitle: "Courses")
                        ProgressStat(title: "Study Time", value: "24h", subtitle: "This Week")
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Activity items would go here
                    ForEach(0..<3) { _ in
                        ActivityItem()
                    }
                }
            }
            .padding()
        }
    }
}

struct BookmarksTab: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.bookmarkedCourses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Bookmarks Yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Bookmark courses to save them for later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(viewModel.bookmarkedCourses) { course in
                        CourseCard(course: course)
                    }
                }
            }
            .padding()
        }
    }
}

struct CourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            AsyncImage(url: URL(string: course.thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(course.instructor.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(course.rating, specifier: "%.1f")")
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    Text("\(course.duration / 60)h \(course.duration % 60)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if course.price > 0 {
                    Text("$\(course.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                } else {
                    Text("Free")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CourseCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 140)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: 120)
                
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 14)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 14)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 16)
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shimmer()
    }
}

struct ProgressStat: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityItem: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Completed: Swift Programming Basics")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("2 hours ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

@MainActor
class LearningViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var bookmarkedCourses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func loadCourses() async {
        isLoading = true
        
        do {
            let coursesResponse: CoursesResponse = try await networkManager.get(
                endpoint: BackendConfig.Endpoints.courses,
                responseType: CoursesResponse.self
            )
            courses = coursesResponse.courses
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshCourses() async {
        await loadCourses()
    }
}

struct CoursesResponse: Codable {
    let courses: [Course]
    let totalCount: Int
    let hasMore: Bool
}
