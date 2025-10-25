import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import OSLog

// MARK: - Media Upload Manager
@MainActor
class MediaUploadManager: NSObject, ObservableObject {
    static let shared = MediaUploadManager()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadedFiles: [UploadedFile] = []
    @Published var uploadError: UploadError?
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "MediaUpload")
    private let apiClient = APIClient.shared
    private let session: URLSession
    
    // Configuration
    private let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB
    private let allowedImageTypes: [UTType] = [.png, .jpeg, .heic, .gif]
    private let allowedVideoTypes: [UTType] = [.mp4, .mov, .quickTimeMovie]
    private let allowedDocumentTypes: [UTType] = [.pdf, .plainText, .rtf]
    
    // Firebase Storage Configuration
    private let firebaseStorageURL = "https://firebasestorage.googleapis.com/v0/b/lyo-app.firebasestorage.app/o"
    private let cloudStorageURL = "gs://lyo-app.firebasestorage.app"
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // 5 minutes for large files
        self.session = URLSession(configuration: config)
        super.init()
        
        logger.info("📤 MediaUploadManager initialized")
    }
    
    // MARK: - Upload Interface
    func uploadMedia(_ mediaItems: [MediaItem]) async throws -> [UploadedFile] {
        guard !mediaItems.isEmpty else { return [] }
        
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        var uploadedFiles: [UploadedFile] = []
        let totalFiles = mediaItems.count
        
        do {
            for (index, mediaItem) in mediaItems.enumerated() {
                logger.info("📤 Uploading file \(index + 1)/\(totalFiles): \(mediaItem.filename)")
                
                let uploadedFile = try await uploadSingleFile(mediaItem)
                uploadedFiles.append(uploadedFile)
                
                // Update progress
                uploadProgress = Double(index + 1) / Double(totalFiles)
            }
            
            self.uploadedFiles.append(contentsOf: uploadedFiles)
            logger.info("✅ Successfully uploaded \(uploadedFiles.count) files")
            
            return uploadedFiles
            
        } catch let error as UploadError {
            uploadError = error
            throw error
        } catch {
            let uploadError = UploadError.uploadFailed(error.localizedDescription)
            self.uploadError = uploadError
            throw uploadError
        }
        
        isUploading = false
    }
    
    private func uploadSingleFile(_ mediaItem: MediaItem) async throws -> UploadedFile {
        // Validate file
        try validateFile(mediaItem)
        
        // Create upload request
        let uploadRequest = try createUploadRequest(for: mediaItem)
        
        // Perform upload
        do {
            let uploadedFile = try await performUpload(uploadRequest, mediaItem: mediaItem)
            logger.info("✅ File uploaded: \(uploadedFile.url)")
            return uploadedFile
            
        } catch {
            logger.error("❌ Upload failed: \(error.localizedDescription)")
            throw UploadError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - File Validation
    private func validateFile(_ mediaItem: MediaItem) throws {
        // Check file size
        if mediaItem.data.count > maxFileSize {
            throw UploadError.fileTooLarge
        }
        
        // Check file type
        let allowedTypes = allowedImageTypes + allowedVideoTypes + allowedDocumentTypes
        guard allowedTypes.contains(mediaItem.type) else {
            throw UploadError.unsupportedFileType
        }
        
        // Additional validations based on type
        switch mediaItem.type {
        case _ where allowedImageTypes.contains(mediaItem.type):
            try validateImageFile(mediaItem)
        case _ where allowedVideoTypes.contains(mediaItem.type):
            try validateVideoFile(mediaItem)
        default:
            break
        }
    }
    
    private func validateImageFile(_ mediaItem: MediaItem) throws {
        // Could add image-specific validations (dimensions, etc.)
        if mediaItem.data.isEmpty {
            throw UploadError.invalidFile("Image data is empty")
        }
    }
    
    private func validateVideoFile(_ mediaItem: MediaItem) throws {
        // Could add video-specific validations (duration, bitrate, etc.)
        if mediaItem.data.isEmpty {
            throw UploadError.invalidFile("Video data is empty")
        }
    }
    
    // MARK: - Upload Request Creation
    private func createUploadRequest(for mediaItem: MediaItem) throws -> URLRequest {
        // Try backend upload endpoint first
        if let backendRequest = try? createBackendUploadRequest(for: mediaItem) {
            return backendRequest
        }
        
        // Fallback to Firebase Storage direct upload
        return try createFirebaseUploadRequest(for: mediaItem)
    }
    
    private func createBackendUploadRequest(for mediaItem: MediaItem) throws -> URLRequest {
        guard let url = URL(string: "https://lyo-backend-830162750094.us-central1.run.app/upload") else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=----Boundary", forHTTPHeaderField: "Content-Type")
        
        // Add auth header if available
        if let token = UserDefaults.standard.string(forKey: "lyo_auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart body
        let boundary = "----Boundary"
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(mediaItem.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mediaItem.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(mediaItem.data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return request
    }
    
    private func createFirebaseUploadRequest(for mediaItem: MediaItem) throws -> URLRequest {
        let fileName = "\(UUID().uuidString)_\(mediaItem.filename)"
        let path = "uploads/\(fileName)"
        
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(firebaseStorageURL)/\(encodedPath)") else {
            throw UploadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(mediaItem.mimeType, forHTTPHeaderField: "Content-Type")
        request.httpBody = mediaItem.data
        
        return request
    }
    
    // MARK: - Upload Execution
    private func performUpload(_ request: URLRequest, mediaItem: MediaItem) async throws -> UploadedFile {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UploadError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                throw UploadError.serverError(httpResponse.statusCode)
            }
            
            // Parse response
            if let backendResponse = try? JSONDecoder().decode(UploadResponse.self, from: data) {
                // Backend upload response
                return UploadedFile(
                    id: backendResponse.fileId ?? UUID().uuidString,
                    filename: mediaItem.filename,
                    originalFilename: mediaItem.filename,
                    url: backendResponse.url,
                    thumbnailUrl: backendResponse.thumbnailUrl,
                    mimeType: mediaItem.mimeType,
                    size: mediaItem.data.count,
                    uploadedAt: Date()
                )
            } else {
                // Firebase direct upload - construct URL
                let fileName = "\(UUID().uuidString)_\(mediaItem.filename)"
                let publicUrl = "\(firebaseStorageURL)/uploads%2F\(fileName)?alt=media"
                
                return UploadedFile(
                    id: UUID().uuidString,
                    filename: mediaItem.filename,
                    originalFilename: mediaItem.filename,
                    url: publicUrl,
                    thumbnailUrl: nil,
                    mimeType: mediaItem.mimeType,
                    size: mediaItem.data.count,
                    uploadedAt: Date()
                )
            }
            
        } catch {
            throw UploadError.networkError(error)
        }
    }
    
    // MARK: - Convenience Methods
    func uploadImage(_ image: UIImage, filename: String? = nil) async throws -> UploadedFile {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw UploadError.invalidFile("Could not convert image to JPEG")
        }
        
        let mediaItem = MediaItem(
            filename: filename ?? "image_\(Int(Date().timeIntervalSince1970)).jpg",
            data: imageData,
            type: .jpeg
        )
        
        let uploadedFiles = try await uploadMedia([mediaItem])
        return uploadedFiles.first!
    }
    
    func uploadVideo(from url: URL) async throws -> UploadedFile {
        do {
            let videoData = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            
            let mediaItem = MediaItem(
                filename: filename,
                data: videoData,
                type: .mp4
            )
            
            let uploadedFiles = try await uploadMedia([mediaItem])
            return uploadedFiles.first!
            
        } catch {
            throw UploadError.invalidFile("Could not read video file")
        }
    }
    
    func uploadDocument(from url: URL) async throws -> UploadedFile {
        do {
            let documentData = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let type = UTType(filenameExtension: url.pathExtension) ?? .data
            
            let mediaItem = MediaItem(
                filename: filename,
                data: documentData,
                type: type
            )
            
            let uploadedFiles = try await uploadMedia([mediaItem])
            return uploadedFiles.first!
            
        } catch {
            throw UploadError.invalidFile("Could not read document file")
        }
    }
    
    // MARK: - File Management
    func deleteUploadedFile(_ fileId: String) async throws {
        do {
            let endpoint = "/upload/\(fileId)"
            let _: EmptyResponse = try await apiClient.delete(endpoint)
            
            // Remove from local cache
            uploadedFiles.removeAll { $0.id == fileId }
            
            logger.info("🗑️ Deleted file: \(fileId)")
            
        } catch {
            logger.error("❌ Failed to delete file: \(error)")
            throw UploadError.deleteFailed
        }
    }
    
    func clearUploadedFiles() {
        uploadedFiles.removeAll()
        uploadProgress = 0.0
        uploadError = nil
    }
    
    // MARK: - Progress Tracking
    func resetProgress() {
        uploadProgress = 0.0
        uploadError = nil
    }
}

// MARK: - Models
struct MediaItem {
    let filename: String
    let data: Data
    let type: UTType
    
    var mimeType: String {
        switch type {
        case .jpeg:
            return "image/jpeg"
        case .png:
            return "image/png"
        case .heic:
            return "image/heic"
        case .gif:
            return "image/gif"
        case .mp4:
            return "video/mp4"
        case .mov, .quickTimeMovie:
            return "video/quicktime"
        case .pdf:
            return "application/pdf"
        case .plainText:
            return "text/plain"
        case .rtf:
            return "text/rtf"
        default:
            return "application/octet-stream"
        }
    }
}

struct UploadedFile: Identifiable, Codable {
    let id: String
    let filename: String
    let originalFilename: String
    let url: String
    let thumbnailUrl: String?
    let mimeType: String
    let size: Int
    let uploadedAt: Date
    
    var isImage: Bool {
        return mimeType.hasPrefix("image/")
    }
    
    var isVideo: Bool {
        return mimeType.hasPrefix("video/")
    }
    
    var isDocument: Bool {
        return !isImage && !isVideo
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

struct UploadResponse: Codable {
    let success: Bool
    let fileId: String?
    let url: String
    let thumbnailUrl: String?
    let message: String?
}

enum UploadError: LocalizedError, Identifiable {
    case fileTooLarge
    case unsupportedFileType
    case invalidFile(String)
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    case uploadFailed(String)
    case deleteFailed
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "File is too large. Maximum size is 50MB."
        case .unsupportedFileType:
            return "File type is not supported."
        case .invalidFile(let message):
            return "Invalid file: \(message)"
        case .invalidURL:
            return "Invalid upload URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .deleteFailed:
            return "Failed to delete file."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileTooLarge:
            return "Try compressing the file or choosing a smaller file."
        case .unsupportedFileType:
            return "Please choose a supported file type (images, videos, or documents)."
        case .networkError:
            return "Check your internet connection and try again."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Upload Progress View
struct UploadProgressView: View {
    @ObservedObject var uploadManager = MediaUploadManager.shared
    
    var body: some View {
        if uploadManager.isUploading {
            VStack(spacing: 16) {
                ProgressView(value: uploadManager.uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("Uploading... \(Int(uploadManager.uploadProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Cancel") {
                    // Implement cancel functionality
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}

// MARK: - File Picker Wrapper
struct DocumentPickerView: UIViewControllerRepresentable {
    let completion: (Result<[URL], Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .image, .movie, .pdf, .plainText, .data
        ], asCopy: true)
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (Result<[URL], Error>) -> Void
        
        init(completion: @escaping (Result<[URL], Error>) -> Void) {
            self.completion = completion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(.success(urls))
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(.failure(UploadError.uploadFailed("User cancelled")))
        }
    }
}