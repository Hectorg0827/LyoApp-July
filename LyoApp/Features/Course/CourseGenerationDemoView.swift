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
        VStack(spacing: 12) {
            Text("🎓")
                .font(.system(size: 48))
            
            Text("Course Generation Demo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Demonstrates the complete course generation flow with real-time progress, error handling, and caching.")
                .font(.body)
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
            Text("Generate Course")
                .font(.headline)
            
            VStack(spacing: 12) {
                TextField("Topic", text: $viewModel.topic)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Interests (comma separated)", text: $viewModel.interestsText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button(action: viewModel.generateCourse) {
                HStack {
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(viewModel.isGenerating ? "Generating..." : "Generate Course")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isGenerating ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isGenerating || viewModel.topic.isEmpty)
            
            if viewModel.isGenerating {
                ProgressSection(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Progress Section

struct ProgressSection: View {
    @ObservedObject var viewModel: CourseGenerationDemoViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(viewModel.progressPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: Double(viewModel.progressPercentage) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            if !viewModel.progressMessage.isEmpty {
                Text(viewModel.progressMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Course Generated!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("ID: \(courseId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button("View Course") {
                onViewCourse()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
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
        ErrorBanner(
            message: message,
            onRetry: onRetry,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Demo View Model

@MainActor
class CourseGenerationDemoViewModel: ObservableObject {
    @Published var topic: String = ""
    @Published var interestsText: String = ""
    @Published var isGenerating = false
    @Published var progressPercentage = 0
    @Published var progressMessage = ""
    @Published var generatedCourseId: String?
    @Published var errorMessage: String = ""
    
    private let orchestrator: TaskOrchestrator
    
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
        let authManager = AuthManager()
        let apiClient = APIClient(environment: .current, authManager: authManager)
        self.orchestrator = TaskOrchestrator(apiClient: apiClient)
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
                let courseId = try await orchestrator.generateCourse(
                    topic: topic,
                    interests: interests
                ) { [weak self] taskEvent in
                    await MainActor.run {
                        self?.updateProgress(from: taskEvent)
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
    
    private func updateProgress(from event: TaskEvent) {
        progressPercentage = event.progressPct ?? 0
        progressMessage = event.message ?? ""
        
        switch event.state {
        case .queued:
            progressMessage = "Queued for processing..."
        case .running:
            progressMessage = event.message ?? "Processing..."
        case .done:
            progressMessage = "Complete!"
        case .error:
            progressMessage = "Error: \(event.error ?? "Unknown error")"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CourseGenerationDemoView_Previews: PreviewProvider {
    static var previews: some View {
        CourseGenerationDemoView()
    }
}
#endif