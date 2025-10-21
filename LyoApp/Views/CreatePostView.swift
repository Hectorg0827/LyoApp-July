import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var uploadManager = MediaUploadManager.shared
    @ObservedObject private var apiClient = APIClient.shared
    
    @State private var postContent = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideo: URL?
    @State private var isLoading = false
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showDocumentPicker = false
    @State private var uploadError: UploadError?
    
    private let maxContentLength = 500
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content Input
                ScrollView {
                    VStack(spacing: 16) {
                        // Text Input
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $postContent)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                
                                if postContent.isEmpty {
                                    Text("What's on your mind?")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                            
                            // Character Count
                            HStack {
                                Spacer()
                                Text("\(postContent.count)/\(maxContentLength)")
                                    .font(.caption)
                                    .foregroundColor(postContent.count > maxContentLength ? .red : .secondary)
                            }
                        }
                        
                        // Media Preview
                        if !selectedImages.isEmpty || selectedVideo != nil {
                            MediaPreviewView(
                                images: selectedImages,
                                videoURL: selectedVideo,
                                onRemoveImage: { index in
                                    selectedImages.remove(at: index)
                                },
                                onRemoveVideo: {
                                    selectedVideo = nil
                                }
                            )
                        }
                        
                        // Upload Progress
                        if uploadManager.isUploading {
                            UploadProgressView()
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Media Selection Toolbar
                MediaSelectionToolbar(
                    onImageTapped: { showImagePicker = true },
                    onVideoTapped: { showVideoPicker = true },
                    onDocumentTapped: { showDocumentPicker = true }
                )
                .padding()
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
                    .disabled(!canPost || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImageMultiPicker(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPickerView(selectedVideo: $selectedVideo)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { result in
                    switch result {
                    case .success(let urls):
                        handleDocumentSelection(urls)
                    case .failure(let error):
                        print("Document picker error: \(error)")
                    }
                }
            }
            .alert("Upload Error", isPresented: .constant(uploadError != nil)) {
                Button("OK") {
                    uploadError = nil
                }
            } message: {
                Text(uploadError?.localizedDescription ?? "")
            }
        }
    }
    
    private var canPost: Bool {
        (!postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
         !selectedImages.isEmpty || 
         selectedVideo != nil) &&
        postContent.count <= maxContentLength
    }
    
    private func createPost() {
        isLoading = true
        
        Task {
            do {
                var mediaUrls: [String] = []
                
                // Upload images
                if !selectedImages.isEmpty {
                    let imageMediaItems = selectedImages.enumerated().map { (index, image) in
                        MediaItem(
                            filename: "post_image_\(index).jpg",
                            data: image.jpegData(compressionQuality: 0.8) ?? Data(),
                            type: .jpeg
                        )
                    }
                    
                    let uploadedImages = try await uploadManager.uploadMedia(imageMediaItems)
                    mediaUrls.append(contentsOf: uploadedImages.map { $0.url })
                }
                
                // Upload video
                if let videoURL = selectedVideo {
                    let uploadedVideo = try await uploadManager.uploadVideo(from: videoURL)
                    mediaUrls.append(uploadedVideo.url)
                }
                
                // Create post
                let response = try await apiClient.createPost(postContent, mediaUrls: mediaUrls)
                
                print("Post created successfully: \(response.postId)")
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch let error as UploadError {
                uploadError = error
            } catch {
                print("Failed to create post: \(error)")
            }
            
            isLoading = false
        }
    }
    
    private func handleDocumentSelection(_ urls: [URL]) {
        Task {
            do {
                for url in urls {
                    _ = try await uploadManager.uploadDocument(from: url)
                }
            } catch let error as UploadError {
                uploadError = error
            } catch {
                print("Failed to upload documents: \(error)")
            }
        }
    }
}

struct MediaPreviewView: View {
    let images: [UIImage]
    let videoURL: URL?
    let onRemoveImage: (Int) -> Void
    let onRemoveVideo: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Images
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button(action: { onRemoveImage(index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Video
            if let videoURL = videoURL {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 100)
                        .overlay(
                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                                Text("Video Selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                    
                    Button(action: onRemoveVideo) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MediaSelectionToolbar: View {
    let onImageTapped: () -> Void
    let onVideoTapped: () -> Void
    let onDocumentTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            MediaButton(
                icon: "photo",
                title: "Photo",
                action: onImageTapped
            )
            
            MediaButton(
                icon: "video",
                title: "Video",
                action: onVideoTapped
            )
            
            MediaButton(
                icon: "doc",
                title: "Document",
                action: onDocumentTapped
            )
            
            Spacer()
        }
    }
}

struct MediaButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Multi Image Picker
struct ImageMultiPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 5 // Max 5 images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImageMultiPicker
        
        init(_ parent: ImageMultiPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedImages = []
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
            
            parent.dismiss()
        }
    }
}

// MARK: - Video Picker
struct VideoPickerView: UIViewControllerRepresentable {
    @Binding var selectedVideo: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.videoMaximumDuration = 300 // 5 minutes max
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
    CreatePostView()
}