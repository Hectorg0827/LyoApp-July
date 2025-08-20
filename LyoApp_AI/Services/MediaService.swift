import Foundation
import UIKit
import Combine

// MARK: - Media Service Protocol
protocol MediaServiceProtocol {
    func uploadImage(_ image: UIImage, type: MediaType) async throws -> MediaUploadResponse
    func uploadVideo(_ videoURL: URL, type: MediaType) async throws -> MediaUploadResponse
    func getMediaURL(mediaId: String) async throws -> URL
    func deleteMedia(mediaId: String) async throws
}

// MARK: - Media Models
struct MediaUploadResponse: Codable {
    let mediaId: String
    let url: String
    let type: String
    let metadata: MediaMetadata
    
    private enum CodingKeys: String, CodingKey {
        case mediaId = "media_id"
        case url
        case type
        case metadata
    }
}

struct MediaMetadata: Codable {
    let fileSize: Int
    let dimensions: MediaDimensions?
    let duration: Double?
    let format: String
    let uploadedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case fileSize = "file_size"
        case dimensions
        case duration
        case format
        case uploadedAt = "uploaded_at"
    }
}

struct MediaDimensions: Codable {
    let width: Int
    let height: Int
}

enum MediaType: String, Codable {
    case profilePicture = "profile_picture"
    case courseContent = "course_content"
    case userGeneratedContent = "user_generated_content"
    case attachment = "attachment"
}

// MARK: - Live Media Service
class LiveMediaService: MediaServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let baseURL: URL
    
    init(httpClient: HTTPClientProtocol, baseURL: String = "http://localhost:8002") {
        self.httpClient = httpClient
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
    }
    
    func uploadImage(_ image: UIImage, type: MediaType) async throws -> MediaUploadResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MediaError.invalidImageData
        }
        
        let url = baseURL.appendingPathComponent("/api/v1/media/upload")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        let request = createMultipartRequest(
            url: url,
            data: imageData,
            fileName: "image.jpg",
            mimeType: "image/jpeg",
            fieldName: "file",
            boundary: boundary,
            additionalFields: ["type": type.rawValue]
        )
        
        return try await httpClient.request(request, responseType: MediaUploadResponse.self)
    }
    
    func uploadVideo(_ videoURL: URL, type: MediaType) async throws -> MediaUploadResponse {
        let videoData = try Data(contentsOf: videoURL)
        let url = baseURL.appendingPathComponent("/api/v1/media/upload")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        let request = createMultipartRequest(
            url: url,
            data: videoData,
            fileName: "video.mp4",
            mimeType: "video/mp4",
            fieldName: "file",
            boundary: boundary,
            additionalFields: ["type": type.rawValue]
        )
        
        return try await httpClient.request(request, responseType: MediaUploadResponse.self)
    }
    
    func getMediaURL(mediaId: String) async throws -> URL {
        let url = baseURL.appendingPathComponent("/api/v1/media/\(mediaId)")
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.request(request, responseType: MediaURLResponse.self)
        
        guard let mediaURL = URL(string: response.url) else {
            throw MediaError.invalidURL
        }
        
        return mediaURL
    }
    
    func deleteMedia(mediaId: String) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/media/\(mediaId)")
        let request = HTTPRequest.delete(url: url)
        
        try await httpClient.request(request)
    }
    
    private func createMultipartRequest(
        url: URL,
        data: Data,
        fileName: String,
        mimeType: String,
        fieldName: String,
        boundary: String,
        additionalFields: [String: String] = [:]
    ) -> HTTPRequest {
        var body = Data()
        
        // Add additional fields
        for (key, value) in additionalFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let headers = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        
        return HTTPRequest(method: .POST, url: url, headers: headers, body: body)
    }
}

// MARK: - Media URL Response
struct MediaURLResponse: Codable {
    let url: String
    let expiresAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case url
        case expiresAt = "expires_at"
    }
}

// MARK: - Media Errors
enum MediaError: Error, LocalizedError {
    case invalidImageData
    case invalidURL
    case unsupportedFormat
    case fileTooLarge
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Unable to convert image to data"
        case .invalidURL:
            return "Invalid media URL"
        case .unsupportedFormat:
            return "Unsupported media format"
        case .fileTooLarge:
            return "File size exceeds maximum limit"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}

// MARK: - Mock Media Service
class MockMediaService: MediaServiceProtocol {
    var shouldFail = false
    var uploadDelay: Double = 2.0
    
    func uploadImage(_ image: UIImage, type: MediaType) async throws -> MediaUploadResponse {
        try await Task.sleep(nanoseconds: UInt64(uploadDelay * 1_000_000_000))
        
        if shouldFail {
            throw MediaError.uploadFailed("Mock upload failure")
        }
        
        return MediaUploadResponse(
            mediaId: "mock_image_\(UUID().uuidString)",
            url: "https://example.com/media/mock_image.jpg",
            type: "image",
            metadata: MediaMetadata(
                fileSize: 1024 * 1024, // 1MB
                dimensions: MediaDimensions(width: 1080, height: 1080),
                duration: nil,
                format: "jpeg",
                uploadedAt: Date()
            )
        )
    }
    
    func uploadVideo(_ videoURL: URL, type: MediaType) async throws -> MediaUploadResponse {
        try await Task.sleep(nanoseconds: UInt64(uploadDelay * 1_000_000_000))
        
        if shouldFail {
            throw MediaError.uploadFailed("Mock video upload failure")
        }
        
        return MediaUploadResponse(
            mediaId: "mock_video_\(UUID().uuidString)",
            url: "https://example.com/media/mock_video.mp4",
            type: "video",
            metadata: MediaMetadata(
                fileSize: 10 * 1024 * 1024, // 10MB
                dimensions: MediaDimensions(width: 1920, height: 1080),
                duration: 30.0,
                format: "mp4",
                uploadedAt: Date()
            )
        )
    }
    
    func getMediaURL(mediaId: String) async throws -> URL {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        
        if shouldFail {
            throw MediaError.invalidURL
        }
        
        return URL(string: "https://example.com/media/\(mediaId)")!
    }
    
    func deleteMedia(mediaId: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        
        if shouldFail {
            throw MediaError.uploadFailed("Mock delete failure")
        }
        
        print("Mock deleted media: \(mediaId)")
    }
}
