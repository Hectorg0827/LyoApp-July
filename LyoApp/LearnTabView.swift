import SwiftUI

struct LearnTabView: View {
    @State private var selectedSegment: LearnSegment = .courses
    @State private var userCourses: [Course] = []
    @State private var engagementLevels: [String: Double] = [:]
    @State private var apiCourses: [Course] = []
    @State private var videos: [EducationalVideo] = []
    @State private var ebooks: [Ebook] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Content Type", selection: $selectedSegment) {
                    ForEach(LearnSegment.allCases, id: \ .self) { segment in
                        Text(segment.title)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    switch selectedSegment {
                    case .courses:
                        CoursesSection(userCourses: userCourses, apiCourses: apiCourses, engagementLevels: engagementLevels)
                    case .videos:
                        VideosSection(videos: videos)
                    case .ebooks:
                        EbooksSection(ebooks: ebooks)
                    }
                }
            }
            .navigationTitle("Learn")
            .onAppear {
                loadUserCourses()
                loadApiCourses()
                loadVideos()
                loadEbooks()
            }
        }
    }
    
    private func loadUserCourses() {
        // TODO: Load user's started courses and engagement levels
    }
    private func loadApiCourses() {
        // TODO: Fetch courses from external APIs
    }
    private func loadVideos() {
        // TODO: Fetch educational videos
    }
    private func loadEbooks() {
        // TODO: Fetch ebooks
    }
}

enum LearnSegment: CaseIterable {
    case courses, videos, ebooks
    var title: String {
        switch self {
        case .courses: return "Courses"
        case .videos: return "Videos"
        case .ebooks: return "Ebooks"
        }
    }
}

struct CoursesSection: View {
    let userCourses: [Course]
    let apiCourses: [Course]
    let engagementLevels: [String: Double]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !userCourses.isEmpty {
                Text("Your Courses")
                    .font(.headline)
                ForEach(userCourses) { course in
                    CourseCard(course: course, engagement: engagementLevels[course.id.uuidString] ?? 0)
                }
            }
            if !apiCourses.isEmpty {
                Text("Recommended Courses")
                    .font(.headline)
                ForEach(apiCourses) { course in
                    CourseCard(course: course, engagement: nil)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct VideosSection: View {
    let videos: [EducationalVideo]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(videos) { video in
                VideoCard(video: video)
            }
        }
        .padding(.horizontal)
    }
}

struct EbooksSection: View {
    let ebooks: [Ebook]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ebooks) { ebook in
                EbookCard(ebook: ebook)
            }
        }
        .padding(.horizontal)
    }
}

// Placeholder models and cards
struct EducationalVideo: Identifiable {
    let id: String
    let title: String
    let url: URL
}
struct Ebook: Identifiable {
    let id: String
    let title: String
    let author: String
}
struct CourseCard: View {
    let course: Course
    let engagement: Double?
    var body: some View {
        VStack(alignment: .leading) {
            Text(course.title).font(.headline)
            Text(course.description).font(.subheadline)
            if let engagement = engagement {
                Text("Engagement: \(Int(engagement * 100))%")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("Progress: \(Int(course.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
struct VideoCard: View {
    let video: EducationalVideo
    var body: some View {
        VStack(alignment: .leading) {
            Text(video.title).font(.headline)
            Text(video.url.absoluteString).font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
struct EbookCard: View {
    let ebook: Ebook
    var body: some View {
        VStack(alignment: .leading) {
            Text(ebook.title).font(.headline)
            Text("by \(ebook.author)").font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
