import Foundation
import Combine

// MARK: - Download Manager for Offline Content
class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var activeDownloads: [String: DownloadTask] = [:]
    @Published var completedDownloads: Set<String> = []
    
    private let urlSession: URLSession
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        // Configure URLSession for downloads
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        self.urlSession = URLSession(configuration: config)
        
        // Get documents directory
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create downloads subdirectory
        let downloadsDir = documentsDirectory.appendingPathComponent("Downloads")
        try? fileManager.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        // Load completed downloads
        loadCompletedDownloads()
    }
    
    // MARK: - Download Operations
    
    func downloadResource(_ resource: LearningResource) {
        Task {
            await downloadResourceContent(resource)
        }
    }
    
    @MainActor
    private func downloadResourceContent(_ resource: LearningResource) async {
        let downloadTask = DownloadTask(
            id: resource.id.uuidString,
            resourceTitle: resource.title,
            totalFiles: countDownloadableFiles(resource)
        )
        
        activeDownloads[resource.id.uuidString] = downloadTask
        
        // Download video if available
        if let videoURL = resource.contentURL,
           resource.contentType == .video {
            await downloadFile(
                url: videoURL,
                resourceId: resource.id.uuidString,
                contentType: .video,
                fileName: "\(resource.id.uuidString)_video.mp4"
            )
        }
        
        // Download audio if available  
        if let audioURL = resource.contentURL,
           resource.contentType == .podcast {
            await downloadFile(
                url: audioURL,
                resourceId: resource.id.uuidString,
                contentType: .audio,
                fileName: "\(resource.id.uuidString)_audio.mp3"
            )
        }
        
        // Download thumbnail if available
        if let thumbnailURL = resource.thumbnailURL {
            await downloadFile(
                url: thumbnailURL,
                resourceId: resource.id.uuidString,
                contentType: .thumbnail,
                fileName: "\(resource.id.uuidString)_thumbnail.jpg"
            )
        }
        
        // Mark as completed if all files downloaded
        await MainActor.run {
            if downloadTask.completedFiles >= downloadTask.totalFiles {
                completeDownload(resourceId: resource.id.uuidString)
            }
        }
    }
    
    private func downloadFile(url: URL, resourceId: String, contentType: ContentType, fileName: String) async {
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw DownloadError.invalidResponse
            }
            
            // Save file to local storage
            let fileURL = getLocalFileURL(for: fileName)
            try data.write(to: fileURL)
            
            // Update download task progress
            await MainActor.run {
                if var downloadTask = activeDownloads[resourceId] {
                    downloadTask.completedFiles += 1
                    downloadTask.progress = Double(downloadTask.completedFiles) / Double(downloadTask.totalFiles)
                    downloadTask.downloadedFiles[contentType] = fileURL
                    activeDownloads[resourceId] = downloadTask
                }
            }
            
            // Save download record to database
            // try await DataManager.shared.saveDownload(
            //     resourceId: resourceId,
            //     contentType: contentType.rawValue,
            //     fileName: fileName,
            //     filePath: fileURL.path,
            //     fileSize: Int64(data.count)
            // )
            print("📦 Would save download record for \(fileName)")
            
        } catch {
            print("Failed to download \(contentType.rawValue) for resource \(resourceId): \(error)")
            
            await MainActor.run {
                if var downloadTask = activeDownloads[resourceId] {
                    downloadTask.errors.append("Failed to download \(contentType.rawValue)")
                    activeDownloads[resourceId] = downloadTask
                }
            }
        }
    }
    
    private func completeDownload(resourceId: String) {
        activeDownloads.removeValue(forKey: resourceId)
        completedDownloads.insert(resourceId)
        saveCompletedDownloads()
        
        // Show completion notification
                    // NotificationManager.shared.scheduleProgressReminder(for: resourceId)
            print("🔔 Would schedule progress reminder for \(resourceId)")
    }
    
    // MARK: - Download Management
    
    func cancelDownload(resourceId: String) {
        activeDownloads.removeValue(forKey: resourceId)
        
        // Clean up partial files
        Task {
            await cleanupPartialDownload(resourceId: resourceId)
        }
    }
    
    private func cleanupPartialDownload(resourceId: String) async {
        // let downloads = await DataManager.shared.fetchDownloads(for: resourceId)
        // Temporarily disabled cleanup
        print("🧹 Would cleanup downloads for \(resourceId)")
    }
    
    func deleteDownloadedResource(_ resourceId: String) {
        Task {
            await deleteDownloadedResourceFiles(resourceId)
        }
    }
    
    private func deleteDownloadedResourceFiles(_ resourceId: String) async {
        await cleanupPartialDownload(resourceId: resourceId)
        completedDownloads.remove(resourceId)
        saveCompletedDownloads()
    }
    
    // MARK: - File Management
    
    func getLocalFileURL(for fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent("Downloads").appendingPathComponent(fileName)
    }
    
    func getLocalVideoURL(for resourceId: String) -> URL? {
        let videoURL = getLocalFileURL(for: "\(resourceId)_video.mp4")
        return fileManager.fileExists(atPath: videoURL.path) ? videoURL : nil
    }
    
    func getLocalAudioURL(for resourceId: String) -> URL? {
        let audioURL = getLocalFileURL(for: "\(resourceId)_audio.mp3")
        return fileManager.fileExists(atPath: audioURL.path) ? audioURL : nil
    }
    
    func getLocalThumbnailURL(for resourceId: String) -> URL? {
        let thumbnailURL = getLocalFileURL(for: "\(resourceId)_thumbnail.jpg")
        return fileManager.fileExists(atPath: thumbnailURL.path) ? thumbnailURL : nil
    }
    
    func isResourceDownloaded(_ resourceId: String) -> Bool {
        return completedDownloads.contains(resourceId)
    }
    
    func getDownloadProgress(for resourceId: String) -> Double {
        return activeDownloads[resourceId]?.progress ?? 0.0
    }
    
    // MARK: - Storage Management
    
    func getStorageInfo() -> StorageInfo {
        var totalSize: Int64 = 0
        var fileCount = 0
        
        let downloadsDir = documentsDirectory.appendingPathComponent("Downloads")
        
        if let enumerator = fileManager.enumerator(at: downloadsDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                    fileCount += 1
                }
            }
        }
        
        return StorageInfo(totalSize: totalSize, fileCount: fileCount)
    }
    
    func clearAllDownloads() {
        Task {
            await clearAllDownloadedFiles()
        }
    }
    
    private func clearAllDownloadedFiles() async {
        let downloadsDir = documentsDirectory.appendingPathComponent("Downloads")
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: downloadsDir, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear downloads: \(error)")
        }
        
        await MainActor.run {
            completedDownloads.removeAll()
            activeDownloads.removeAll()
        }
        
        saveCompletedDownloads()
    }
    
    // MARK: - Persistence
    
    private func loadCompletedDownloads() {
        if let data = UserDefaults.standard.data(forKey: "completedDownloads"),
           let downloads = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedDownloads = downloads
        }
    }
    
    private func saveCompletedDownloads() {
        if let data = try? JSONEncoder().encode(completedDownloads) {
            UserDefaults.standard.set(data, forKey: "completedDownloads")
        }
    }
    
    // MARK: - Helper Methods
    
    private func countDownloadableFiles(_ resource: LearningResource) -> Int {
        var count = 0
        if resource.contentURL != nil { count += 1 }
        if resource.thumbnailURL != nil { count += 1 }
        return max(count, 1) // At least 1 to avoid division by zero
    }
}

// MARK: - Supporting Types

struct DownloadTask {
    let id: String
    let resourceTitle: String
    let totalFiles: Int
    var completedFiles: Int = 0
    var progress: Double = 0.0
    var downloadedFiles: [ContentType: URL] = [:]
    var errors: [String] = []
    let startTime = Date()
}

enum ContentType: String, CaseIterable {
    case video = "video"
    case audio = "audio"
    case thumbnail = "thumbnail"
}

enum DownloadError: Error {
    case invalidURL
    case invalidResponse
    case fileWriteError
    case networkError(String)
}

struct StorageInfo {
    let totalSize: Int64
    let fileCount: Int
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
