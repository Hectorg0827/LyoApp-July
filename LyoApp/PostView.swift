import SwiftUI
import AVFoundation

// MARK: - PostType Enum
enum PostType: String, CaseIterable {
    case reel = "Reel"
    case story = "Story"
    case course = "Course"
    case post = "Post"
    
    var icon: String {
        switch self {
        case .reel: return "video.fill"
        case .story: return "circle.dashed"
        case .course: return "book.fill"
        case .post: return "photo.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .reel: return DesignTokens.Colors.neonPink
        case .story: return DesignTokens.Colors.neonOrange
        case .course: return DesignTokens.Colors.neonGreen
        case .post: return DesignTokens.Colors.neonBlue
        }
    }
    
    var description: String {
        switch self {
        case .reel: return "Short video"
        case .story: return "24hr story"
        case .course: return "Educational"
        case .post: return "Photo & text"
        }
    }
}

// MARK: - MediaSourceType
enum MediaSourceType {
    case camera
    case gallery
}

// MARK: - PostPrivacy
enum PostPrivacy: String, CaseIterable {
    case publicPost = "Public"
    case friends = "Friends"
    case privatePost = "Private"
    
    var icon: String {
        switch self {
        case .publicPost: return "globe"
        case .friends: return "person.2"
        case .privatePost: return "lock"
        }
    }
}

// MARK: - Main PostView
struct PostView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var apiClient: APIClient
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPostType: PostType = .post
    @State private var content = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideo: URL?
    @State private var showingMediaPicker = false
    @State private var showingCamera = false
    @State private var mediaSourceType: MediaSourceType = .gallery
    @State private var tags: [String] = []
    @State private var currentTag = ""
    @State private var isPosting = false
    @State private var showAIAssistant = false
    @State private var aiSuggestions: [String] = []
    @State private var postPrivacy: PostPrivacy = .publicPost
    @State private var location = ""
    @State private var mood = ""
    @State private var showLocationPicker = false
    @State private var showMoodSelector = false
    @State private var showTextEditor = false
    @State private var cameraPermissionGranted = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern dark background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.8),
                        Color.gray.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerView
                        
                        // Content Type Selector (YouTube-style horizontal scroll)
                        contentTypeSelector
                        
                        // Main Content Area (adapts based on selected type)
                        mainContentArea
                        
                        // Additional Options
                        additionalOptionsSection
                        
                        Spacer(minLength: 100) // Space for floating button
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Extra space for floating button
                }
                
                // Floating Create Button
                VStack {
                    Spacer()
                    floatingCreateButton
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            ModernMediaPicker(
                selectedImages: $selectedImages,
                selectedVideo: $selectedVideo,
                sourceType: .photoLibrary,
                mediaTypes: mediaTypesForCurrentSelection
            )
        }
        .sheet(isPresented: $showingCamera) {
            ModernCameraPicker(
                selectedImages: $selectedImages,
                selectedVideo: $selectedVideo,
                mediaTypes: mediaTypesForCurrentSelection
            )
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Text("Create")
                .font(DesignTokens.font.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Button("AI") {
                showAIAssistant.toggle()
            }
            .foregroundColor(DesignTokens.Colors.neonPink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(DesignTokens.Colors.neonPink.opacity(0.2))
            )
        }
        .padding(.top, 10)
    }
    
    // MARK: - Content Type Selector
    private var contentTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose content type")
                .font(DesignTokens.font.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .padding(.leading, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(PostType.allCases, id: \.self) { type in
                        ContentTypeButton(
                            type: type,
                            isSelected: selectedPostType == type
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPostType = type
                                resetContent()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Main Content Area
    private var mainContentArea: some View {
        VStack(spacing: 20) {
            switch selectedPostType {
            case .reel:
                reelContentView
            case .story:
                storyContentView
            case .course:
                courseContentView
            case .post:
                postContentView
            }
        }
    }
    
    // MARK: - Content Views
    private var reelContentView: some View {
        VStack(spacing: 16) {
            Text("Create a Reel")
                .font(DesignTokens.font.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Share short, engaging videos with your community")
                .font(DesignTokens.font.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let videoURL = selectedVideo {
                VideoPreviewCard(videoURL: videoURL) {
                    selectedVideo = nil
                }
            } else {
                VStack(spacing: 12) {
                    MediaSourceButton(
                        icon: "video.fill",
                        title: "Record Video",
                        subtitle: "Up to 60 seconds",
                        color: DesignTokens.Colors.neonPink
                    ) {
                        mediaSourceType = .camera
                        showingCamera = true
                    }
                    
                    MediaSourceButton(
                        icon: "video.badge.plus",
                        title: "Upload from Gallery",
                        subtitle: "Choose existing video",
                        color: DesignTokens.Colors.neonBlue
                    ) {
                        mediaSourceType = .gallery
                        showingMediaPicker = true
                    }
                }
            }
            
            if selectedVideo != nil {
                captionAndTagsSection
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.neonPink.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var storyContentView: some View {
        VStack(spacing: 16) {
            Text("Create a Story")
                .font(DesignTokens.font.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Share moments that disappear after 24 hours")
                .font(DesignTokens.font.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if !selectedImages.isEmpty || selectedVideo != nil || !content.isEmpty {
                mediaPreviewSection
                captionAndTagsSection
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        MediaSourceButton(
                            icon: "camera.fill",
                            title: "Camera",
                            subtitle: "Take photo/video",
                            color: DesignTokens.Colors.neonOrange
                        ) {
                            mediaSourceType = .camera
                            showingCamera = true
                        }
                        
                        MediaSourceButton(
                            icon: "photo.fill",
                            title: "Gallery",
                            subtitle: "Choose media",
                            color: DesignTokens.Colors.neonBlue
                        ) {
                            mediaSourceType = .gallery
                            showingMediaPicker = true
                        }
                    }
                    
                    MediaSourceButton(
                        icon: "textformat",
                        title: "Text Story",
                        subtitle: "Create with just text",
                        color: DesignTokens.Colors.neonGreen
                    ) {
                        showTextEditor = true
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.neonOrange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var courseContentView: some View {
        VStack(spacing: 16) {
            Text("Create a Course")
                .font(DesignTokens.font.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Share educational content and teach your community")
                .font(DesignTokens.font.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                MediaSourceButton(
                    icon: "book.fill",
                    title: "Course Material",
                    subtitle: "Add lesson content",
                    color: DesignTokens.Colors.neonGreen
                ) {
                    // Course creation logic
                }
                
                MediaSourceButton(
                    icon: "video.fill",
                    title: "Video Lesson",
                    subtitle: "Record or upload video",
                    color: DesignTokens.Colors.neonBlue
                ) {
                    mediaSourceType = .camera
                    showingCamera = true
                }
                
                MediaSourceButton(
                    icon: "doc.text.fill",
                    title: "Text Lesson",
                    subtitle: "Write course content",
                    color: DesignTokens.Colors.neonPurple
                ) {
                    showTextEditor = true
                }
            }
            
            if !selectedImages.isEmpty || selectedVideo != nil || !content.isEmpty {
                captionAndTagsSection
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.neonGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var postContentView: some View {
        VStack(spacing: 16) {
            Text("Create a Post")
                .font(DesignTokens.font.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Share photos, thoughts, and updates with your community")
                .font(DesignTokens.font.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if !selectedImages.isEmpty || !content.isEmpty {
                if !selectedImages.isEmpty {
                    mediaPreviewSection
                }
                captionAndTagsSection
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        MediaSourceButton(
                            icon: "camera.fill",
                            title: "Camera",
                            subtitle: "Take photo",
                            color: DesignTokens.Colors.neonBlue
                        ) {
                            mediaSourceType = .camera
                            showingCamera = true
                        }
                        
                        MediaSourceButton(
                            icon: "photo.fill",
                            title: "Gallery",
                            subtitle: "Choose photos",
                            color: DesignTokens.Colors.neonPurple
                        ) {
                            mediaSourceType = .gallery
                            showingMediaPicker = true
                        }
                    }
                    
                    MediaSourceButton(
                        icon: "text.bubble.fill",
                        title: "Text Post",
                        subtitle: "Share your thoughts",
                        color: DesignTokens.Colors.neonGreen
                    ) {
                        showTextEditor = true
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.neonBlue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Common Sections
    private var mediaPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Media Preview")
                    .font(DesignTokens.font.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("Edit") {
                    // Open media editor
                }
                .foregroundColor(DesignTokens.Colors.neonBlue)
            }
            
            if let videoURL = selectedVideo {
                VideoPreviewCard(videoURL: videoURL) {
                    selectedVideo = nil
                }
            } else if !selectedImages.isEmpty {
                MediaPreviewGrid(images: selectedImages, video: selectedVideo) { index in
                    if index < selectedImages.count {
                        selectedImages.remove(at: index)
                    } else {
                        selectedVideo = nil
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var captionAndTagsSection: some View {
        VStack(spacing: 16) {
            // Caption Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Caption")
                        .font(DesignTokens.font.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(content.count)/2200")
                        .font(DesignTokens.font.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                TextField("Write a caption...", text: $content, axis: .vertical)
                    .font(DesignTokens.font.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(3...8)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
            }
            
            // Tags Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(DesignTokens.Colors.neonBlue)
                    
                    Text("Tags")
                        .font(DesignTokens.font.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(tags.count)/10")
                        .font(DesignTokens.font.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                HStack {
                    TextField("Add tags...", text: $currentTag)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .onSubmit {
                            addTag()
                        }
                    
                    Button("Add") {
                        addTag()
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignTokens.Colors.neonBlue)
                    .cornerRadius(15)
                    .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
                
                if !tags.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Additional Options
    private var additionalOptionsSection: some View {
        VStack(spacing: 16) {
            // Privacy and Location
            HStack(spacing: 16) {
                // Privacy
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy")
                        .font(DesignTokens.font.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Menu {
                        ForEach(PostPrivacy.allCases, id: \.self) { privacy in
                            Button {
                                postPrivacy = privacy
                            } label: {
                                HStack {
                                    Image(systemName: privacy.icon)
                                    Text(privacy.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: postPrivacy.icon)
                                .foregroundColor(DesignTokens.Colors.neonBlue)
                            
                            Text(postPrivacy.rawValue)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Image(systemName: "chevron.down")
                                .font(DesignTokens.font.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
                
                // Location
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location")
                        .font(DesignTokens.font.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(DesignTokens.Colors.neonOrange)
                            
                            Text(location.isEmpty ? "Add location" : location)
                                .foregroundColor(location.isEmpty ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.textPrimary)
                            
                            if !location.isEmpty {
                                Button {
                                    location = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Floating Create Button
    private var floatingCreateButton: some View {
        HStack {
            Spacer()
            
            Button {
                createPost()
            } label: {
                HStack(spacing: 8) {
                    if isPosting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(DesignTokens.Colors.textPrimary)
                    } else {
                        Image(systemName: selectedPostType.icon)
                            .font(DesignTokens.font.title2)
                    }
                    
                    Text(isPosting ? "Creating..." : "Share \(selectedPostType.rawValue)")
                        .font(DesignTokens.font.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    canPost && !isPosting ?
                    LinearGradient(
                        colors: [selectedPostType.color, selectedPostType.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [DesignTokens.Colors.backgroundSecondary, DesignTokens.Colors.backgroundSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(
                    color: canPost && !isPosting ? selectedPostType.color.opacity(0.4) : Color.clear,
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
            .disabled(!canPost || isPosting)
            .scaleEffect(canPost && !isPosting ? 1.0 : 0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canPost)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPosting)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    private var canPost: Bool {
        switch selectedPostType {
        case .post:
            return !selectedImages.isEmpty || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .story:
            return !selectedImages.isEmpty || selectedVideo != nil || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .reel:
            return selectedVideo != nil
        case .course:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty || selectedVideo != nil
        }
    }
    
    private var mediaTypesForCurrentSelection: [String] {
        switch selectedPostType {
        case .reel:
            return ["public.movie"]
        case .story:
            return ["public.image", "public.movie"]
        case .course:
            return ["public.image", "public.movie"]
        case .post:
            return ["public.image"]
        }
    }
    
    // MARK: - Functions
    private func resetContent() {
        selectedImages.removeAll()
        selectedVideo = nil
        content = ""
        tags.removeAll()
        location = ""
        mood = ""
    }
    
    private func addTag() {
        let tag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) && tags.count < 10 {
            tags.append(tag)
            currentTag = ""
        }
    }
    
    private func createPost() {
        guard canPost else { return }
        
        isPosting = true
        
        Task {
            do {
                // For now, we are not handling media uploads.
                // This would require a separate service to upload media to a cloud storage
                // and get back the URLs. We will pass empty media URLs for now.
                let mediaUrls: [String] = []
                
                _ = try await apiClient.createPost(content, mediaUrls: mediaUrls)
                
                // Show success notification on the main thread
                await MainActor.run {
                    isPosting = false
                    dismiss()
                    
                    let notification = AppNotification(
                        title: "\(selectedPostType.rawValue) Created!",
                        message: "Your \(selectedPostType.rawValue.lowercased()) has been shared successfully!",
                        type: .success,
                        timestamp: Date()
                    )
                    appState.addNotification(notification)
                }
            } catch {
                // Show error notification on the main thread
                await MainActor.run {
                    isPosting = false
                    let errorMessage = (error as? APIClientError)?.errorDescription ?? "An unknown error occurred."
                    let notification = AppNotification(
                        title: "Error Creating Post",
                        message: errorMessage,
                        type: .error,
                        timestamp: Date()
                    )
                    appState.addNotification(notification)
                }
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionGranted = granted
                }
            }
        default:
            break
        }
    }
}

// MARK: - Supporting Views

struct ContentTypeButton: View {
    let type: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [type.color, type.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [DesignTokens.Colors.backgroundSecondary, DesignTokens.Colors.backgroundSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? type.color : DesignTokens.Colors.backgroundSecondary,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    Image(systemName: type.icon)
                        .font(DesignTokens.font.title2)
                        .foregroundColor(isSelected ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                }
                
                VStack(spacing: 2) {
                    Text(type.rawValue)
                        .font(DesignTokens.font.subheadline)
                        .foregroundColor(isSelected ? type.color : DesignTokens.Colors.textPrimary)
                        .fontWeight(isSelected ? .semibold : .medium)
                    
                    Text(type.description)
                        .font(DesignTokens.font.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

struct MediaSourceButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(DesignTokens.font.caption)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(DesignTokens.font.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(DesignTokens.font.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(DesignTokens.font.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(DesignTokens.font.caption)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(DesignTokens.font.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.neonBlue.opacity(0.3))
        )
    }
}

struct VideoPreviewCard: View {
    let videoURL: URL
    let onRemove: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .frame(height: 200)
            
            VStack {
                Image(systemName: "play.circle.fill")
                    .font(DesignTokens.font.largeTitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Video Preview")
                    .font(DesignTokens.font.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(DesignTokens.font.title2)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(8)
        }
    }
}

struct MediaPreviewGrid: View {
    let images: [UIImage]
    let video: URL?
    let onRemove: (Int) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(8)
                    
                    Button(action: { onRemove(index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
            }
            
            if video != nil {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.white)
                                .font(.title)
                        )
                    
                    Button(action: { onRemove(images.count) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
            }
        }
    }
}

// MARK: - UIKit Wrappers

struct ModernMediaPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideo: URL?
    let sourceType: UIImagePickerController.SourceType
    let mediaTypes: [String]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes.isEmpty ? ["public.image"] : mediaTypes
        picker.allowsEditing = true
        
        if mediaTypes.contains("public.movie") {
            picker.videoMaximumDuration = 60.0
            picker.videoQuality = .typeHigh
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ModernMediaPicker
        
        init(_ parent: ModernMediaPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideo = videoURL
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ModernCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideo: URL?
    let mediaTypes: [String]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = mediaTypes.isEmpty ? ["public.image"] : mediaTypes
        picker.allowsEditing = true
        picker.cameraFlashMode = .auto
        
        if mediaTypes.contains("public.movie") {
            picker.videoMaximumDuration = 60.0
            picker.videoQuality = .typeHigh
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ModernCameraPicker
        
        init(_ parent: ModernCameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideo = videoURL
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PostView()
        .environmentObject(AppState())
        .environmentObject(APIClient.shared)
}
