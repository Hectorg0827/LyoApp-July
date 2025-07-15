import SwiftUI
import UIKit

struct PostView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var content = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var tags: [String] = []
    @State private var currentTag = ""
    @State private var isPosting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // User Info
                    userSection
                    
                    // Content Input
                    contentSection
                    
                    // Media Section
                    mediaSection
                    
                    // Tags Section
                    tagsSection
                    
                    // Post Options
                    optionsSection
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .foregroundColor(canPost ? DesignTokens.Colors.primary : DesignTokens.Colors.gray400)
                    .disabled(!canPost || isPosting)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: $selectedImages)
        }
    }
    
    private var userSection: some View {
        HStack {
            DesignSystem.Avatar(
                imageURL: appState.currentUser?.profileImageURL,
                name: appState.currentUser?.fullName ?? "User",
                size: 40
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.currentUser?.fullName ?? "User")
                    .font(DesignTokens.Typography.bodyMedium)
                
                Text("Posting to your feed")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
            }
            
            Spacer()
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("What's on your mind?")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
            
            TextField("Share your thoughts, ask a question, or start a discussion...", text: $content, axis: .vertical)
                .font(DesignTokens.Typography.body)
                .lineLimit(5...15)
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.gray100)
                )
        }
    }
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Media")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                
                Spacer()
                
                Button("Add Photos") {
                    showingImagePicker = true
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
            }
            
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                                
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            } else {
                Button {
                    showingImagePicker = true
                } label: {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title)
                            .foregroundColor(DesignTokens.Colors.gray400)
                        
                        Text("Add photos to your post")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.gray400)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(DesignTokens.Colors.gray300, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Tags")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
            
            HStack {
                TextField("Add a tag", text: $currentTag)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add") {
                    addTag()
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
                .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.gray100)
            )
            
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Text("#\(tag)")
                                    .font(DesignTokens.Typography.caption)
                                
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primary)
                            )
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Button {
                    // Handle location
                } label: {
                    Label("Add Location", systemImage: "location")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Spacer()
                
                Button {
                    // Handle mood/feeling
                } label: {
                    Label("Add Feeling", systemImage: "face.smiling")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
            
            if isPosting {
                ProgressView("Posting...")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
            }
        }
        .cardStyle()
    }
    
    private var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addTag() {
        let tag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) && tags.count < 5 {
            tags.append(tag)
            currentTag = ""
        }
    }
    
    private func createPost() {
        guard canPost else { return }
        
        isPosting = true
        
        // Simulate posting delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPosting = false
            appState.hidePost()
            dismiss()
            
            // Show success notification
            let notification = AppNotification(
                title: "Post Created",
                message: "Your post has been shared successfully!",
                type: .success,
                timestamp: Date()
            )
            appState.addNotification(notification)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
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
}
