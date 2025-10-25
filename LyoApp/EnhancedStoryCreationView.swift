import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Enhanced Story Creation View
struct EnhancedStoryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storyCreator = StoryCreationViewModel()
    @State private var selectedStoryType: StoryType = .photo
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var storyText = ""
    @State private var selectedBackgroundColor: Color = .blue
    @State private var showingTextEditor = false
    @State private var animateEntry = false
    
    enum StoryType: CaseIterable {
        case photo, video, text, ai, poll, quiz
        
        var title: String {
            switch self {
            case .photo: return "Photo"
            case .video: return "Video"
            case .text: return "Text"
            case .ai: return "AI Art"
            case .poll: return "Poll"
            case .quiz: return "Quiz"
            }
        }
        
        var icon: String {
            switch self {
            case .photo: return "camera.fill"
            case .video: return "video.fill"
            case .text: return "text.quote"
            case .ai: return "sparkles"
            case .poll: return "chart.bar.fill"
            case .quiz: return "questionmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .photo: return .blue
            case .video: return .red
            case .text: return .green
            case .ai: return .purple
            case .poll: return .orange
            case .quiz: return .pink
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            DesignTokens.Gradients.primary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if animateEntry {
                    mainContentView
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                animateEntry = true
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImage: $capturedImage)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(capturedImage: $capturedImage)
        }
        .sheet(isPresented: $showingTextEditor) {
            TextStoryEditor(
                text: $storyText,
                backgroundColor: $selectedBackgroundColor,
                onSave: { saveTextStory() }
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                HapticManager.shared.light()
                dismiss()
            }
            .font(DesignTokens.font.body)
            .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Text("Create Story")
                .font(DesignTokens.font.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Button("Share") {
                HapticManager.shared.medium()
                shareStory()
            }
            .font(DesignTokens.font.body)
            .foregroundColor(DesignTokens.Colors.brand)
            .disabled(!storyCreator.canShare)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 30) {
            // Story type selector
            storyTypeSelector
            
            // Preview area
            storyPreviewArea
            
            // Quick actions
            quickActionsView
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Story Type Selector
    private var storyTypeSelector: some View {
        VStack(spacing: 15) {
            Text("Choose Story Type")
                .font(DesignTokens.font.headline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(StoryType.allCases, id: \.self) { type in
                        storyTypeCard(type)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func storyTypeCard(_ type: StoryType) -> some View {
        Button(action: {
            HapticManager.shared.light()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedStoryType = type
            }
            handleStoryTypeSelection(type)
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            selectedStoryType == type
                            ? type.color
                            : DesignTokens.Colors.fillTertiary
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedStoryType == type
                                    ? DesignTokens.Colors.strokePrimary.opacity(0.3)
                                    : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: type.icon)
                        .font(DesignTokens.font.title2)
                        .foregroundColor(
                            selectedStoryType == type ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary
                        )
                }
                
                Text(type.title)
                    .font(DesignTokens.font.caption)
                    .foregroundColor(
                        selectedStoryType == type ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary
                    )
            }
        }
        .scaleEffect(selectedStoryType == type ? 1.1 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedStoryType)
    }
    
    // MARK: - Story Preview Area
    private var storyPreviewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.large)
                .fill(.ultraThinMaterial)
                .frame(width: 200, height: 350)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.large)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.brand.opacity(0.5),
                                    DesignTokens.Colors.accent.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
            
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 190, height: 340)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.medium))
            } else {
                VStack(spacing: 15) {
                    Image(systemName: selectedStoryType.icon)
                        .font(DesignTokens.font.largeTitle)
                        .foregroundColor(selectedStoryType.color)
                    
                    Text("Story Preview")
                        .font(DesignTokens.font.headline)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("Tap actions below to create")
                        .font(DesignTokens.font.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if !storyText.isEmpty && selectedStoryType == .text {
                VStack {
                    Spacer()
                    Text(storyText)
                        .font(DesignTokens.font.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(selectedBackgroundColor.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.small))
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Quick Actions View
    private var quickActionsView: some View {
        VStack(spacing: 20) {
            Text("Quick Actions")
                .font(DesignTokens.font.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                quickActionButton("Camera", "camera.fill", .blue) {
                    showingCamera = true
                }
                
                quickActionButton("Photos", "photo.fill", .green) {
                    showingPhotoPicker = true
                }
                
                quickActionButton("Text", "text.quote", .orange) {
                    showingTextEditor = true
                }
                
                quickActionButton("AI Art", "sparkles", .purple) {
                    generateAIArt()
                }
                
                quickActionButton("Poll", "chart.bar.fill", .pink) {
                    createPoll()
                }
                
                quickActionButton("Music", "music.note", .red) {
                    addMusic()
                }
            }
        }
    }
    
    private func quickActionButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                    
                    Image(systemName: icon)
                        .font(DesignTokens.font.body)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(DesignTokens.font.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Action Methods
    private func handleStoryTypeSelection(_ type: StoryType) {
        switch type {
        case .photo:
            showingPhotoPicker = true
        case .video:
            showingCamera = true
        case .text:
            showingTextEditor = true
        case .ai:
            generateAIArt()
        case .poll:
            createPoll()
        case .quiz:
            createQuiz()
        }
    }
    
    private func generateAIArt() {
        print("🎨 Generating AI art...")
        // Integration point for AI art generation
        storyCreator.generateAIContent()
    }
    
    private func createPoll() {
        print("📊 Creating poll...")
        // Integration point for poll creation
    }
    
    private func createQuiz() {
        print("❓ Creating quiz...")
        // Integration point for quiz creation
    }
    
    private func addMusic() {
        print("🎵 Adding music...")
        // Integration point for music selection
    }
    
    private func saveTextStory() {
        print("💾 Saving text story...")
        storyCreator.saveTextStory(text: storyText, backgroundColor: selectedBackgroundColor)
    }
    
    private func shareStory() {
        print("📤 Sharing story...")
        HapticManager.shared.success()
        storyCreator.shareStory()
        dismiss()
    }
}

// MARK: - Story Creation ViewModel
@MainActor
class StoryCreationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var canShare = false
    @Published var currentStory: UserStory?
    
    func generateAIContent() {
        isLoading = true
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
            self.canShare = true
            print("✨ AI content generated!")
        }
    }
    
    func saveTextStory(text: String, backgroundColor: Color) {
        canShare = !text.isEmpty
        print("📝 Text story saved: \(text)")
    }
    
    func shareStory() {
        print("🚀 Story shared successfully!")
        // Integration point for backend story upload
    }
}

// MARK: - Supporting Models
struct UserStory {
    let id = UUID()
    let content: StoryContent
    let createdAt = Date()
    let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
}

enum StoryContent {
    case photo(UIImage)
    case video(URL)
    case text(String, Color)
    case ai(String)
    case poll(String, [String])
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Text Story Editor
struct TextStoryEditor: View {
    @Binding var text: String
    @Binding var backgroundColor: Color
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    let backgroundColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .cyan
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.large)
                        .fill(backgroundColor.gradient)
                        .frame(height: 200)
                    
                    Text(text.isEmpty ? "Type your story..." : text)
                        .font(DesignTokens.font.title1)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding(.horizontal)
                
                // Text input
                TextField("What's on your mind?", text: $text, axis: .vertical)
                    .font(DesignTokens.font.body)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.small))
                    .lineLimit(3...6)
                
                // Color selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(backgroundColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            backgroundColor == color ? DesignTokens.Colors.strokePrimary : .clear,
                                            lineWidth: 3
                                        )
                                )
                                .onTapGesture {
                                    backgroundColor = color
                                    HapticManager.shared.light()
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Text Story")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    onSave()
                    dismiss()
                }
                .disabled(text.isEmpty)
            )
        }
    }
}

#Preview {
    EnhancedStoryCreationView()
}
