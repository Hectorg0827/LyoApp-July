import SwiftUI
import AVKit
import SafariServices

// MARK: - Course View
struct CourseView: View {
    let courseId: String
    
    @StateObject private var viewModel: CourseViewModel
    @State private var showingPlayer = false
    @State private var showingSafari = false
    @State private var selectedURL: URL?
    
    init(courseId: String) {
        self.courseId = courseId
        
        // Initialize dependencies
        let authManager = AuthManager()
        let apiClient = APIClient(environment: .current, authManager: authManager)
        let orchestrator = TaskOrchestrator(apiClient: apiClient)
        let repository = CoreDataCourseRepository()
        
        self._viewModel = StateObject(wrappedValue: CourseViewModel(
            courseId: courseId,
            orchestrator: orchestrator,
            repo: repository
        ))
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Course")
                .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.startObserving()
        }
        .sheet(isPresented: $showingPlayer) {
            if let url = selectedURL {
                VideoPlayerView(url: url)
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .generating:
            generatingView
        case .partial:
            partialView
        case .ready:
            readyView
        case .error(let message):
            errorView(message: message)
        }
    }
    
    // MARK: - State Views
    
    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            VStack(spacing: 12) {
                Text("Generating Course")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Creating personalized learning content...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Skeleton content
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.top, 32)
            
            Spacer()
        }
        .padding()
    }
    
    private var partialView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                        
                        Text("Still generating...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text("Some content is ready while we continue generating more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Show available content
                contentGrid
            }
            .padding()
        }
    }
    
    private var readyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Success indicator
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Course Ready")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Show all content
                contentGrid
            }
            .padding()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Text("Generation Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                Button("Retry") {
                    viewModel.retry()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Keep in Background") {
                    // Schedule background completion
                    BackgroundScheduler.shared.scheduleBackgroundCompletion(for: courseId)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Content Grid
    
    private var contentGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(viewModel.items) { item in
                ContentItemCard(item: item) {
                    handleItemTap(item)
                }
            }
        }
    }
    
    private func handleItemTap(_ item: ContentItemViewData) {
        viewModel.open(item)
        
        guard let url = item.url else { return }
        
        // Determine how to open the content based on type and URL
        if isStreamableVideo(url: url) {
            selectedURL = url
            showingPlayer = true
        } else {
            selectedURL = url
            showingSafari = true
        }
    }
    
    private func isStreamableVideo(url: URL) -> Bool {
        let videoExtensions = ["mp4", "m4v", "mov", "avi", "mkv", "webm"]
        let pathExtension = url.pathExtension.lowercased()
        return videoExtensions.contains(pathExtension) || url.absoluteString.contains("stream")
    }
}

// MARK: - Supporting Views

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ContentItemCard: View {
    let item: ContentItemViewData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Content preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(contentTypeColor.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: contentTypeIcon)
                                .font(.system(size: 24))
                                .foregroundColor(contentTypeColor)
                            
                            if let duration = item.duration {
                                Text(formatDuration(duration))
                                    .font(.caption2)
                                    .foregroundColor(contentTypeColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var contentTypeColor: Color {
        switch item.type.lowercased() {
        case "video":
            return .blue
        case "article", "text":
            return .green
        case "quiz", "assessment":
            return .orange
        case "exercise":
            return .purple
        default:
            return .gray
        }
    }
    
    private var contentTypeIcon: String {
        switch item.type.lowercased() {
        case "video":
            return "play.circle.fill"
        case "article", "text":
            return "doc.text.fill"
        case "quiz", "assessment":
            return "questionmark.circle.fill"
        case "exercise":
            return "dumbbell.fill"
        default:
            return "doc.fill"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Video Player View

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#if DEBUG
struct CourseView_Previews: PreviewProvider {
    static var previews: some View {
        CourseView(courseId: "sample-course-id")
    }
}
#endif