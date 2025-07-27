import SwiftUI
import UIKit
import AVFoundation

enum PostType: String, CaseIterable {
    case reel = "Reel"
    case story = "Story"
    case course = "Course"
    case post = "Post"
    
    var icon: String {
        switch self {
        case .reel: return "video.fill"
        case .story: return "circle.fill"
        case .course: return "graduationcap.fill"
        case .post: return "photo.on.rectangle"
        }
    }
    
    var color: Color {
        switch self {
        case .reel: return DesignTokens.Colors.neonPurple
        case .story: return DesignTokens.Colors.neonPink
        case .course: return DesignTokens.Colors.neonBlue
        case .post: return DesignTokens.Colors.neonGreen
        }
    }
    
    var title: String {
        switch self {
        case .reel: return "Reel"
        case .story: return "Story"
        case .course: return "Course"
        case .post: return "Post"
        }
    }
    
    var subtitle: String {
        switch self {
        case .reel: return "Short vertical videos"
        case .story: return "24h disappearing content"
        case .course: return "Educational content"
        case .post: return "Photos & videos"
        }
    }
}

struct PostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: PostType = .reel
    @State private var content: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideo: URL?
    @State private var showingMediaPicker = false
    @State private var showingCamera = false
    @State private var isCreatingPost = false
    @State private var courseTitle = ""
    @State private var courseDescription = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedPrivacy: PostPrivacy = .publicPost
    @State private var location = ""
    @State private var enableComments = true
    @State private var enableLikes = true
    @State private var enableSharing = true
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content Type Selector
                contentTypeSelector
                
                // Main Content Area
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // Content-specific view
                        contentSpecificView
                        
                        // Media section (if applicable)
                        if shouldShowMediaSection {
                            mediaSection
                        }
                        
                        // Additional options
                        additionalOptionsSection
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.bottom, 100) // Space for floating button
                }
                
                Spacer()
            }
            
            // Floating Create Button
            VStack {
                Spacer()
                createButton
                    .padding(.bottom, 34) // Safe area padding
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingMediaPicker) {
            ModernMediaPicker(
                selectedImages: $selectedImages,
                selectedVideo: $selectedVideo,
                sourceType: .photoLibrary,
                mediaTypes: [selectedType.rawValue]
            )
        }
        .sheet(isPresented: $showingCamera) {
            ModernCameraPicker(
                selectedImages: $selectedImages,
                selectedVideo: $selectedVideo,
                mediaTypes: [selectedType.rawValue]
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            .font(DesignTokens.Typography.body)
            
            Spacer()
            
            Text("Create")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Next") {
                // Handle next action
            }
            .foregroundColor(selectedType.color)
            .font(DesignTokens.Typography.bodyBold)
            .opacity(canProceed ? 1.0 : 0.5)
            .disabled(!canProceed)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    // MARK: - Content Type Selector
    private var contentTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(PostType.allCases, id: \.self) { type in
                    ContentTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedType = type
                                resetContent()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    // MARK: - Content Specific Views
    @ViewBuilder
    private var contentSpecificView: some View {
        switch selectedType {
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
    
    private var reelContentView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Video placeholder or preview
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 400)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Add a video")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Record or upload a video up to 60 seconds")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                )
                .onTapGesture {
                    showingCamera = true
                }
            
            // Caption
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Add a caption")
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundColor(.white)
                
                TextEditor(text: $content)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .frame(minHeight: 100)
            }
        }
    }
    
    private var storyContentView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Story canvas
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Create your story")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Add photos, videos, or text")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
                .onTapGesture {
                    showingCamera = true
                }
        }
    }
    
    private var courseContentView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Course title
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Course Title")
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundColor(.white)
                
                TextField("Enter course title", text: $courseTitle)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Course description
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Description")
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundColor(.white)
                
                TextEditor(text: $courseDescription)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .frame(minHeight: 120)
            }
            
            // Course thumbnail
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Add course thumbnail")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                )
                .onTapGesture {
                    showingMediaPicker = true
                }
        }
    }
    
    private var postContentView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Post content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("What's on your mind?")
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundColor(.white)
                
                TextEditor(text: $content)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .frame(minHeight: 120)
            }
        }
    }
    
    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if selectedImages.isEmpty && selectedVideo == nil {
                Button(action: { showingMediaPicker = true }) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(selectedType.color)
                        
                        VStack(alignment: .leading) {
                            Text("Add photos or videos")
                                .font(DesignTokens.Typography.bodyBold)
                                .foregroundColor(.white)
                            
                            Text("Choose from gallery")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: { showingCamera = true }) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(selectedType.color)
                        
                        VStack(alignment: .leading) {
                            Text("Take photo or video")
                                .font(DesignTokens.Typography.bodyBold)
                                .foregroundColor(.white)
                            
                            Text("Use camera")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                // Media preview
                MediaPreviewGrid(
                    images: selectedImages,
                    video: selectedVideo,
                    onRemove: { index in
                        if index < selectedImages.count {
                            selectedImages.remove(at: index)
                        } else {
                            selectedVideo = nil
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Additional Options
    private var additionalOptionsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Tags
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Tags")
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundColor(.white)
                
                HStack {
                    TextField("Add tag", text: $newTag)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.white)
                        .onSubmit {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                    
                    Button("Add") {
                        if !newTag.isEmpty {
                            tags.append(newTag)
                            newTag = ""
                        }
                    }
                    .foregroundColor(selectedType.color)
                    .disabled(newTag.isEmpty)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                if !tags.isEmpty {
                    TagFlow(tags: tags, selectedColor: selectedType.color) { tag in
                        tags.removeAll { $0 == tag }
                    }
                }
            }
            
            // Privacy settings
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Who can see this?")
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundColor(.white)
                
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(PostPrivacy.allCases, id: \.self) { privacy in
                        Button(action: { selectedPrivacy = privacy }) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: privacy.icon)
                                Text(privacy.rawValue)
                                    .font(DesignTokens.Typography.caption)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                selectedPrivacy == privacy ? 
                                selectedType.color.opacity(0.2) : 
                                Color.gray.opacity(0.1)
                            )
                            .foregroundColor(
                                selectedPrivacy == privacy ? 
                                selectedType.color : 
                                .white.opacity(0.7)
                            )
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: createPost) {
            HStack {
                if isCreatingPost {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: selectedType.icon)
                        .font(.title2)
                }
                
                Text(isCreatingPost ? "Creating..." : "Create \(selectedType.title)")
                    .font(DesignTokens.Typography.bodyBold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [selectedType.color, selectedType.color.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .disabled(isCreatingPost || !canProceed)
            .opacity(canProceed ? 1.0 : 0.6)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Computed Properties
    private var canProceed: Bool {
        switch selectedType {
        case .reel:
            return selectedVideo != nil
        case .story:
            return !selectedImages.isEmpty || selectedVideo != nil
        case .course:
            return !courseTitle.isEmpty && !courseDescription.isEmpty
        case .post:
            return !content.isEmpty || !selectedImages.isEmpty || selectedVideo != nil
        }
    }
    
    private var shouldShowMediaSection: Bool {
        switch selectedType {
        case .reel, .story:
            return false // Handled in content-specific views
        case .course, .post:
            return true
        }
    }
    
    // MARK: - Helper Methods
    private func resetContent() {
        content = ""
        selectedImages = []
        selectedVideo = nil
        courseTitle = ""
        courseDescription = ""
        tags = []
        newTag = ""
    }
    
    private func createPost() {
        isCreatingPost = true
        
        // Simulate post creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCreatingPost = false
            dismiss()
        }
    }
}

// MARK: - Content Type Button
struct ContentTypeButton: View {
    let type: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? type.color : .white.opacity(0.6))
                
                Text(type.title)
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? type.color : .white.opacity(0.6))
            }
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? type.color.opacity(0.1) : Color.clear)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Tag Flow
struct TagFlow: View {
    let tags: [String]
    let selectedColor: Color
    let onRemove: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text("#\(tag)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(selectedColor)
                    
                    Button(action: { onRemove(tag) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedColor.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

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

struct PostView: View {
    @EnvironmentObject var appState: AppState
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
    @State private var isCreatingPost = false
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
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignTokens.Colors.primaryBg,
                        DesignTokens.Colors.primaryBg.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        // User Profile Header
                        userProfileHeader
                        
                        // Post Type Selector
                        postTypeSelector
                        
                        // Content Area
                        contentArea
                        
                        // Media Preview
                        if selectedPostType != .text {
                            mediaPreviewSection
                        }
                        
                        // Content Input
                        if selectedPostType == .text || !content.isEmpty || selectedPostType == .post {
                            contentInputSection
                        }
                        
                        // AI Assistant
                        aiAssistantSection
                        
                        // Tags and Mentions
                        tagsSection
                        
                        // Post Options
                        postOptionsSection
                        
                        // Privacy and Location
                        privacyLocationSection
                        
                        // Create Post Button
                        createPostButton
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            ModernMediaPicker(
                selectedImages: $selectedImages,
                selectedVideo: $selectedVideo,
                sourceType: .photoLibrary,
                mediaTypes: [selectedPostType.rawValue]
            )
        }
        .sheet(isPresented: $showingCamera) {
            ModernCameraPicker(
                selectedImages: $selectedImages,
                selectedVideo: $selectedVideo,
                mediaTypes: [selectedPostType.rawValue]
            )
        }
        .sheet(isPresented: $showTextEditor) {
            TextPostEditor(
                content: $content,
                showAIAssistant: .constant(false),
                generateAISuggestions: { _ in }
            )
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    // MARK: - Helper Functions
    private func sharePost() {
        isCreatingPost = true
        // TODO: Implement actual post sharing logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCreatingPost = false
            dismiss()
        }
    }
    
    // MARK: - UI Components
    
    private var userProfileHeader: some View {
        HStack {
            DesignSystem.Avatar(
                imageURL: appState.currentUser?.profileImageURL,
                name: appState.currentUser?.fullName ?? "User",
                size: 50
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [DesignTokens.Colors.neonBlue, DesignTokens.Colors.neonPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser?.fullName ?? "User")
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Share your moment")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            // Quick filters/effects button
            Button {
                // Open filters
            } label: {
                Image(systemName: "camera.filters")
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.neonPink)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
    
    private var postTypeSelector: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("What do you want to create?")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(PostType.allCases, id: \.self) { type in
                    PostTypeCard(
                        type: PostType.text,
                        isSelected: selectedPostType == type
                    ) {
                        withAnimation(DesignTokens.Animations.quick) {
                            selectedPostType = type
                            resetContent()
                        }
                    }
                }
            }
        }
    }
    
    private var contentArea: some View {
        Group {
            switch selectedPostType {
            case .post:
                postContentArea
            case .story:
                storyContentArea
            case .reel:
                reelContentArea
            case .text:
                textContentArea
            }
        }
    }
    
    private var postContentArea: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Create a Post")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            HStack(spacing: DesignTokens.Spacing.lg) {
                MediaSourceButton(
                    icon: "camera.fill",
                    title: "Camera",
                    subtitle: "Take photo",
                    color: DesignTokens.Colors.neonOrange
                ) {
                    mediaSourceType = .camera
                    showingCamera = true
                }
                
                MediaSourceButton(
                    icon: "photo.on.rectangle",
                    title: "Gallery",
                    subtitle: "Choose photo",
                    color: DesignTokens.Colors.neonBlue
                ) {
                    mediaSourceType = .gallery
                    showingMediaPicker = true
                }
            }
        }
    }
    
    private var storyContentArea: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Create a Story")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Stories disappear after 24 hours")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            HStack(spacing: DesignTokens.Spacing.lg) {
                MediaSourceButton(
                    icon: "camera.viewfinder",
                    title: "Camera",
                    subtitle: "Take photo/video",
                    color: DesignTokens.Colors.neonPurple
                ) {
                    mediaSourceType = .camera
                    showingCamera = true
                }
                
                MediaSourceButton(
                    icon: "photo.stack",
                    title: "Gallery",
                    subtitle: "Choose media",
                    color: DesignTokens.Colors.neonBlue
                ) {
                    mediaSourceType = .gallery
                    showingMediaPicker = true
                }
                
                MediaSourceButton(
                    icon: "textformat",
                    title: "Text",
                    subtitle: "Create text story",
                    color: DesignTokens.Colors.neonGreen
                ) {
                    showTextEditor = true
                }
            }
        }
    }
    
    private var reelContentArea: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Create a Reel")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Share a short video to engage your audience")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                MediaSourceButton(
                    icon: "video.camera.fill",
                    title: "Record Video",
                    subtitle: "Up to 60 seconds",
                    color: DesignTokens.Colors.neonPink
                ) {
                    mediaSourceType = .camera
                    showingCamera = true
                }
                
                MediaSourceButton(
                    icon: "video.badge.plus",
                    title: "Upload Video",
                    subtitle: "From gallery",
                    color: DesignTokens.Colors.neonBlue
                ) {
                    mediaSourceType = .gallery
                    showingMediaPicker = true
                }
            }
        }
    }
    
    private var textContentArea: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Create Text Post")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Button {
                showTextEditor = true
            } label: {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DesignTokens.Colors.neonGreen)
                    
                    Text("Tap to write")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Share your thoughts with text only")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.glassBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [DesignTokens.Colors.neonGreen.opacity(0.3), DesignTokens.Colors.neonBlue.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2,
                                    antialiased: true
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var mediaPreviewSection: some View {
        Group {
            if !selectedImages.isEmpty || selectedVideo != nil {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Text("Media Preview")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Button("Edit") {
                            // Open media editor
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                    }
                    
                    if let videoURL = selectedVideo {
                        VideoPreviewCard(videoURL: videoURL) {
                            selectedVideo = nil
                        }
                    } else {
                        MediaPreviewGrid(images: selectedImages) { index in
                            selectedImages.remove(at: index)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.glassBg)
                )
            }
        }
    }
    
    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Caption")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(content.count)/2200")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            TextField("Write a caption...", text: $content, axis: .vertical)
                .font(DesignTokens.Typography.body)
                .lineLimit(3...8)
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                        )
                )
                .onChange(of: content) { _, newValue in
                    if newValue.count > 2200 {
                        content = String(newValue.prefix(2200))
                    }
                    generateAISuggestions(for: newValue)
                }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var aiAssistantSection: some View {
        Group {
            if !content.isEmpty || showAIAssistant {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(DesignTokens.Colors.neonPink)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Assistant")
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Text("Get suggestions to improve your post")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(DesignTokens.Animations.quick) {
                                showAIAssistant.toggle()
                            }
                        } label: {
                            Image(systemName: showAIAssistant ? "chevron.up" : "chevron.down")
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                    }
                    
                    if showAIAssistant && !aiSuggestions.isEmpty {
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(aiSuggestions, id: \.self) { suggestion in
                                Button {
                                    content = suggestion
                                    showAIAssistant = false
                                } label: {
                                    HStack {
                                        Text(suggestion)
                                            .font(DesignTokens.Typography.body)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
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
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Button("Ask Lyo AI for more help") {
                                // Open AI chat
                            }
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(DesignTokens.Spacing.md)
                            .background(
                                LinearGradient(
                                    colors: [DesignTokens.Colors.neonPink, DesignTokens.Colors.neonPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.glassBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [DesignTokens.Colors.neonPink.opacity(0.3), DesignTokens.Colors.neonPurple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "number")
                    .foregroundColor(DesignTokens.Colors.neonBlue)
                
                Text("Tags & Mentions")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(tags.count)/10")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            HStack {
                TextField("Add tags or @mention friends", text: $currentTag)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add") {
                    addTag()
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.neonBlue)
                .cornerRadius(DesignTokens.Radius.button)
                .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            
            if !tags.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: DesignTokens.Spacing.sm) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var postOptionsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Post Options")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.md) {
                PostOptionButton(
                    icon: "music.note",
                    title: "Add Music",
                    subtitle: "Choose a song",
                    color: DesignTokens.Colors.neonOrange
                ) {
                    // Add music functionality
                }
                
                PostOptionButton(
                    icon: "face.smiling",
                    title: "Add Mood",
                    subtitle: mood.isEmpty ? "How are you feeling?" : mood,
                    color: DesignTokens.Colors.neonYellow
                ) {
                    showMoodSelector = true
                }
                
                PostOptionButton(
                    icon: "person.2",
                    title: "Tag People",
                    subtitle: "Tag friends",
                    color: DesignTokens.Colors.neonGreen
                ) {
                    // Tag people functionality
                }
                
                PostOptionButton(
                    icon: "gift",
                    title: "Boost Post",
                    subtitle: "Promote to more users",
                    color: DesignTokens.Colors.neonPink
                ) {
                    // Boost post functionality
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var privacyLocationSection: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Privacy Selector
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Privacy")
                    .font(DesignTokens.Typography.caption)
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
                            .foregroundColor(DesignTokens.Colors.primary)
                        
                        Text(postPrivacy.rawValue)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
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
            
            // Location
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Location")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Button {
                    showLocationPicker = true
                } label: {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(DesignTokens.Colors.neonOrange)
                        
                        Text(location.isEmpty ? "Add location" : location)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(location.isEmpty ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !location.isEmpty {
                            Button {
                                location = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
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
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var createPostButton: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if isPosting {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(DesignTokens.Colors.primary)
                    
                    Text("Creating your \(selectedPostType.rawValue.lowercased())...")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .frame(height: 60)
            } else {
                Button {
                    createPost()
                } label: {
                    HStack {
                        Image(systemName: selectedPostType.icon)
                            .font(.title2)
                        
                        Text("Share \(selectedPostType.rawValue)")
                            .font(DesignTokens.Typography.buttonLabel)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        canPost ? 
                        LinearGradient(
                            colors: [selectedPostType.color, selectedPostType.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [DesignTokens.Colors.textSecondary.opacity(0.3), DesignTokens.Colors.textSecondary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.Radius.button)
                    .shadow(
                        color: canPost ? selectedPostType.color.opacity(0.3) : Color.clear,
                        radius: 10,
                        x: 0,
                        y: 5
                    )
                }
                .disabled(!canPost)
                .scaleEffect(canPost ? 1.0 : 0.95)
                .animation(DesignTokens.Animations.quick, value: canPost)
            }
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
        case .text:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        
        // Simulate posting with different delays based on post type
        let delay: Double = {
            switch selectedPostType {
            case .text: return 1.0
            case .post: return 2.0
            case .story: return 1.5
            case .reel: return 3.0
            }
        }()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isPosting = false
            dismiss()
            
            // Show success notification
            let notification = AppNotification(
                title: "\(selectedPostType.rawValue) Created!",
                message: "Your \(selectedPostType.rawValue.lowercased()) has been shared successfully!",
                type: .success,
                timestamp: Date()
            )
            appState.addNotification(notification)
        }
    }
    
    private func generateAISuggestions(for text: String) {
        guard !text.isEmpty else {
            aiSuggestions = []
            return
        }
        
        // Enhanced AI suggestions based on post type and content
        let baseSuggestions: [String] = {
            switch selectedPostType {
            case .post:
                return [
                    "Share what you learned today and inspire others! 📚✨",
                    "Ask your community: What's your experience with \(text.prefix(20))?",
                    "Behind the scenes: Here's how I approach \(text.prefix(20))..."
                ]
            case .story:
                return [
                    "Quick tip: \(text.prefix(30))... What do you think?",
                    "Today's mood: \(text.prefix(20)) 💭",
                    "Real talk: \(text.prefix(30))"
                ]
            case .reel:
                return [
                    "Watch me \(text.prefix(20)) in 60 seconds! 🎬",
                    "Step-by-step: \(text.prefix(25)) tutorial 📖",
                    "Before & After: \(text.prefix(20)) transformation"
                ]
            case .text:
                return [
                    "Thoughts on \(text.prefix(20)): Here's my perspective...",
                    "Discussion time: Let's talk about \(text.prefix(20))",
                    "Personal reflection: \(text.prefix(30))"
                ]
            }
        }()
        
        aiSuggestions = Array(baseSuggestions.prefix(3))
        showAIAssistant = true
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

struct PostTypeCard: View {
    let type: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
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
                                colors: [DesignTokens.Colors.glassBg, DesignTokens.Colors.glassBg],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? type.color : DesignTokens.Colors.glassBorder,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
                }
                
                VStack(spacing: 2) {
                    Text(type.rawValue)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(isSelected ? type.color : DesignTokens.Colors.textPrimary)
                        .fontWeight(isSelected ? .semibold : .medium)
                    
                    Text(type.description)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(
                        isSelected ?
                        type.color.opacity(0.1) :
                        DesignTokens.Colors.glassBg
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(
                                isSelected ?
                                type.color.opacity(0.3) :
                                DesignTokens.Colors.glassBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(DesignTokens.Animations.quick, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PostOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text(tag)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(DesignTokens.Colors.neonBlue.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .strokeBorder(DesignTokens.Colors.neonBlue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TextPostEditor: View {
    @Binding var content: String
    @Binding var showAIAssistant: Bool
    let generateAISuggestions: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("What's on your mind?")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    generateAISuggestions(content)
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "sparkles")
                        Text("AI Help")
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.neonPink)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .fill(DesignTokens.Colors.neonPink.opacity(0.1))
                    )
                }
                .disabled(content.isEmpty)
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
                    .frame(minHeight: 120)
                
                TextEditor(text: $content)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(DesignTokens.Spacing.md)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                
                if content.isEmpty {
                    Text("Share your thoughts, ask a question, or start a discussion...")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(DesignTokens.Spacing.md)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Text("\(content.count)/2000")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(
                        content.count > 2000 ? DesignTokens.Colors.error :
                        content.count > 1800 ? DesignTokens.Colors.warning :
                        DesignTokens.Colors.textSecondary
                    )
                
                Spacer()
                
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        // Format as bold
                    } label: {
                        Image(systemName: "bold")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Button {
                        // Format as italic
                    } label: {
                        Image(systemName: "italic")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Button {
                        // Add emoji
                    } label: {
                        Image(systemName: "face.smiling")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
        }
        .onChange(of: content) { _, newValue in
            if newValue.count > 2000 {
                content = String(newValue.prefix(2000))
            }
        }
    }
}

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
        picker.mediaTypes = mediaTypes
        picker.allowsEditing = true
        
        if mediaTypes.contains("public.movie") {
            picker.videoMaximumDuration = 60.0 // 60 seconds for reels
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
        picker.mediaTypes = mediaTypes
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

// MARK: - Supporting Views
struct VideoPreviewCard: View {
    let videoURL: URL
    let onRemove: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(Color.black)
                .frame(height: 200)
            
            VStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text("Video Preview")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.white)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(DesignTokens.Spacing.sm)
        }
    }
}

struct MediaPreviewGrid: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.xs), count: 3), spacing: DesignTokens.Spacing.xs) {
            ForEach(images.indices, id: \.self) { index in
                ZStack {
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(DesignTokens.Radius.sm)
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { onRemove(index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
        }
    }
}

#Preview {
    PostView()
        .environmentObject(AppState())
}
