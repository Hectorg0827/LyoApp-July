import SwiftUI

/// Modern course view that demonstrates the new production-ready infrastructure
struct ModernCourseView: View {
    let course: Course
    
    @StateObject private var viewModel = ModernCourseViewModel()
    @State private var showingGenerationProgress = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Course Header
                    courseHeader
                    
                    // Progress Section
                    if course.progress > 0 {
                        progressSection
                    }
                    
                    // Lessons Section
                    if !course.orderedLessons.isEmpty {
                        lessonsSection
                    }
                    
                    // Content Items Section
                    if !course.courseContentItems.isEmpty {
                        contentItemsSection
                    }
                    
                    // Generate New Content Button
                    generateContentButton
                }
                .padding()
            }
            .navigationTitle(course.title)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.analytics.trackScreenView("course_detail", properties: [
                    "course_id": course.id,
                    "course_status": course.status
                ])
            }
        }
        .sheet(isPresented: $showingGenerationProgress) {
            CourseGenerationProgressView(
                topic: course.topic,
                onComplete: { courseId in
                    showingGenerationProgress = false
                    // Navigate to new course or refresh current
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private var courseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(course.topic)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let summary = course.summary {
                Text(summary)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                StatusBadge(status: course.status)
                Spacer()
                Text("Created: \(course.createdAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.headline)
            
            ProgressView(value: course.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(course.progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lessons (\(course.orderedLessons.count))")
                .font(.headline)
            
            ForEach(course.orderedLessons, id: \.id) { lesson in
                LessonRow(lesson: lesson) {
                    // Track lesson interaction
                    viewModel.analytics.track("lesson_selected", properties: [
                        "lesson_id": lesson.id,
                        "course_id": course.id,
                        "lesson_order": lesson.order
                    ])
                }
            }
        }
    }
    
    private var contentItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content (\(course.courseContentItems.count))")
                .font(.headline)
            
            ForEach(course.courseContentItems, id: \.id) { item in
                ContentItemRow(item: item) {
                    // Track content interaction
                    viewModel.analytics.trackContentItemOpened(
                        itemId: item.id,
                        type: item.type,
                        source: item.source
                    )
                }
            }
        }
    }
    
    private var generateContentButton: some View {
        Button(action: {
            showingGenerationProgress = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Generate More Content")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

// MARK: - Course Generation Progress View
struct CourseGenerationProgressView: View {
    let topic: String
    let onComplete: (String) -> Void
    
    @StateObject private var viewModel = CourseGenerationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress Indicator
                if viewModel.isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Generating course content...")
                            .font(.headline)
                        
                        if let message = viewModel.progressMessage {
                            Text(message)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        if let progress = viewModel.progressPercentage {
                            ProgressView(value: Double(progress), total: 100)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text("\(progress)% Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else if let error = viewModel.error {
                    CourseErrorView(error: error) {
                        Task {
                            await viewModel.generateCourse(topic: topic)
                        }
                    }
                }
                
                Spacer()
                
                // Keep in Background Button
                if viewModel.isGenerating {
                    Button("Keep in Background") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Creating Course")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.generateCourse(topic: topic)
                }
            }
            .onReceive(viewModel.$generatedCourseId) { courseId in
                if let courseId = courseId {
                    onComplete(courseId)
                }
            }
        }
    }
}

// MARK: - View Models
@MainActor
class ModernCourseViewModel: ObservableObject {
    let analytics = Analytics.shared
}

@MainActor
class CourseGenerationViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var progressMessage: String?
    @Published var progressPercentage: Int?
    @Published var generatedCourseId: String?
    @Published var error: Error?
    
    private let taskOrchestrator: TaskOrchestrator
    private let analytics = Analytics.shared
    private let backgroundScheduler = BackgroundScheduler.shared
    
    init() {
        let authManager = AuthManager()
        let apiClient = APIClient(environment: .current, authManager: authManager)
        self.taskOrchestrator = TaskOrchestrator(apiClient: apiClient)
    }
    
    func generateCourse(topic: String) async {
        isGenerating = true
        error = nil
        
        // Track generation start
        analytics.trackCourseGenerationRequested(topic: topic, interests: [])
        
        let startTime = Date()
        
        do {
            let courseId = try await taskOrchestrator.generateCourse(
                topic: topic,
                interests: []
            ) { [weak self] taskEvent in
                Task { @MainActor in
                    self?.handleTaskEvent(taskEvent)
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            analytics.trackCourseGenerationReady(taskId: "unknown", duration: duration)
            
            generatedCourseId = courseId
            isGenerating = false
            
        } catch {
            self.error = error
            isGenerating = false
            
            let duration = Date().timeIntervalSince(startTime)
            analytics.trackCourseGenerationTimeout(taskId: "unknown", duration: duration)
        }
    }
    
    private func handleTaskEvent(_ event: TaskEvent) {
        progressMessage = event.message
        progressPercentage = event.progressPct
        
        if event.state == .running {
            // Schedule background completion
            if let taskId = event.resultId {
                backgroundScheduler.scheduleBackgroundCompletion(for: taskId)
            }
        }
    }
}

// MARK: - Helper Views
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "ready": return .green
        case "generating": return .orange
        case "error": return .red
        default: return .gray
        }
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let summary = lesson.summary {
                        Text(summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text("#\(lesson.order)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentItemRow: View {
    let item: ContentItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Type icon
                Image(systemName: typeIcon)
                    .foregroundColor(typeColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(item.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if item.durationSec > 0 {
                        Text("Duration: \(formatDuration(item.duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var typeIcon: String {
        switch item.type.lowercased() {
        case "video": return "play.rectangle.fill"
        case "article": return "doc.text.fill"
        case "pdf": return "doc.fill"
        case "podcast": return "mic.fill"
        default: return "doc.fill"
        }
    }
    
    private var typeColor: Color {
        switch item.type.lowercased() {
        case "video": return .red
        case "article": return .blue
        case "pdf": return .green
        case "podcast": return .purple
        default: return .gray
        }
    }
}

struct CourseErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Generation Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again", action: onRetry)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Helpers
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}