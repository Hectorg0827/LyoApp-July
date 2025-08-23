import SwiftUI

/// Demo view showing integrated course generation flow with all new components
struct CourseGenerationDemoView: View {
    @StateObject private var viewModel = CourseGenerationDemoViewModel()
    @State private var showingCourse = false
    @State private var generatedCourseId: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HeaderSection()
                
                Divider()
                
                GenerationSection(viewModel: viewModel)
                
                if let courseId = generatedCourseId {
                    Divider()
                    
                    GeneratedCourseSection(courseId: courseId) {
                        showingCourse = true
                    }
                }
                
                Spacer()
                
                if viewModel.hasError {
                    ErrorSection(
                        message: viewModel.errorMessage,
                        onRetry: viewModel.retry,
                        onDismiss: viewModel.clearError
                    )
                }
            }
            .padding()
            .navigationTitle("Course Generation Demo")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCourse) {
            if let courseId = generatedCourseId {
                CourseView(courseId: courseId)
            }
        }
        .onReceive(viewModel.$generatedCourseId) { courseId in
            self.generatedCourseId = courseId
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Course Generation Demo")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Generate personalized courses using AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Generation Section
struct GenerationSection: View {
    @ObservedObject var viewModel: CourseGenerationDemoViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Course Topic")
                    .font(.headline)
                
                TextField("Enter a topic (e.g., Swift Programming)", text: $viewModel.topic)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isGenerating)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Interests (Optional)")
                    .font(.headline)
                
                TextField("Comma-separated interests", text: $viewModel.interestsText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isGenerating)
                
                Text("e.g., mobile development, UI design, testing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Demo mode toggle
            HStack {
                Text("Demo Mode")
                    .font(.subheadline)
                
                Toggle("", isOn: $viewModel.useDemoMode)
                    .disabled(viewModel.isGenerating)
                
                Spacer()
                
                Text(viewModel.useDemoMode ? "Using simulated backend" : "Using real backend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            
            if viewModel.isGenerating {
                ProgressSection(
                    percentage: viewModel.progressPercentage,
                    message: viewModel.progressMessage
                )
            } else {
                Button(action: viewModel.generateCourse) {
                    Text("Generate Course")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.topic.isEmpty ? Color.gray : Color.blue
                        )
                        .cornerRadius(12)
                }
                .disabled(viewModel.topic.isEmpty)
            }
        }
    }
}

// MARK: - Progress Section
struct ProgressSection: View {
    let percentage: Int
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: Double(percentage), total: 100)
                .progressViewStyle(LinearProgressViewStyle())
            
            HStack {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Generated Course Section
struct GeneratedCourseSection: View {
    let courseId: String
    let onViewCourse: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Course Generated!")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("Course ID: \(courseId)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Button("View Course", action: onViewCourse)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Error Section
struct ErrorSection: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Dismiss", action: onDismiss)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button("Retry", action: onRetry)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Button("Dismiss", action: onDismiss)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - View Model
class CourseGenerationDemoViewModel: ObservableObject {
    @Published var topic: String = ""
    @Published var interestsText: String = ""
    @Published var isGenerating = false
    @Published var progressPercentage = 0
    @Published var progressMessage = ""
    @Published var generatedCourseId: String?
    @Published var errorMessage: String = ""
    @Published var useDemoMode = true // Enable demo mode by default
    
    private let orchestrator: TaskOrchestrator
    private let demoOrchestrator: DemoTaskOrchestrator
    
    var interests: [String] {
        return interestsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaceAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var hasError: Bool {
        return !errorMessage.isEmpty
    }
    
    init() {
        let authManager = AuthenticationManager.shared
        let apiClient = LyoAPIService.shared
        self.orchestrator = TaskOrchestrator(apiClient: apiClient)
        self.demoOrchestrator = DemoTaskOrchestrator()
    }
    
    func generateCourse() {
        guard !topic.isEmpty else { return }
        
        isGenerating = true
        progressPercentage = 0
        progressMessage = "Starting generation..."
        generatedCourseId = nil
        clearError()
        
        Task {
            do {
                let courseId: String
                
                if useDemoMode {
                    // Use demo orchestrator for reliable testing
                    courseId = try await demoOrchestrator.generateCourse(
                        topic: topic,
                        interests: interests
                    ) { [weak self] taskEvent in
                        await MainActor.run {
                            self?.updateProgress(from: taskEvent)
                        }
                    }
                } else {
                    // Use real orchestrator (may fail without backend)
                    courseId = try await orchestrator.generateCourse(
                        topic: topic,
                        interests: interests
                    ) { [weak self] taskEvent in
                        await MainActor.run {
                            self?.updateProgress(from: taskEvent)
                        }
                    }
                }
                
                await MainActor.run {
                    self.isGenerating = false
                    self.progressPercentage = 100
                    self.progressMessage = "Complete!"
                    self.generatedCourseId = courseId
                }
                
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.errorMessage = ErrorPresenter.userMessage(for: error)
                    
                    // Show retry suggestion if available
                    if let suggestion = ErrorPresenter.retrySuggestion(for: error) {
                        self.errorMessage += " " + suggestion
                    }
                }
            }
        }
    }
    
    func retry() {
        clearError()
        generateCourse()
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    private func updateProgress(from taskEvent: TaskEvent) {
        switch taskEvent.state {
        case .queued:
            progressPercentage = 10
            progressMessage = "Queued for processing..."
        case .running:
            if let progress = taskEvent.progressPct {
                progressPercentage = max(progress, 20) // Ensure progress moves forward
            } else {
                progressPercentage = 50
            }
            progressMessage = taskEvent.message ?? "Generating course content..."
        case .done:
            progressPercentage = 100
            progressMessage = "Course generation complete!"
        case .error:
            progressMessage = "Generation failed"
        }
    }
}

// MARK: - Placeholder Course View
struct CourseView: View {
    let courseId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "book.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Generated Course")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Course ID: \(courseId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Text("This is a placeholder for the generated course content. In a real implementation, this would show the actual course structure, chapters, and lessons.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Course Details")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CourseGenerationDemoView()
}