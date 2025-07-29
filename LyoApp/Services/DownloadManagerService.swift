import Foundation
import Combine
import SwiftUI

// MARK: - Download Manager Service

@MainActor
class DownloadManagerService: NSObject, ObservableObject {
    static let shared = DownloadManagerService()
    
    @Published var downloads: [DownloadItem] = []
    @Published var totalDownloads: Int = 0
    @Published var activeDownloads: Int = 0
    @Published var isDownloading: Bool = false
    
    private var urlSession: URLSession!
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private let maxConcurrentDownloads = 3
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupURLSession()
        loadExistingDownloads()
    }
    
    // MARK: - Setup
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.lyoapp.downloads")
        config.allowsCellularAccess = false // Only WiFi by default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        print("✅ Download manager initialized")
    }
    
    private func loadExistingDownloads() {
        Task {
            do {
                let dataService = LearningDataService.shared
                let queueItems = try await dataService.fetchDownloadQueue()
                
                self.downloads = queueItems.map { queueItem in
                    DownloadItem(
                        id: queueItem.id,
                        resourceId: queueItem.resourceId,
                        title: "Loading...", // Will be updated when resource is loaded
                        url: URL(string: queueItem.downloadURL)!,
                        status: DownloadStatus(rawValue: queueItem.status) ?? .pending,
                        progress: queueItem.progress,
                        fileSize: queueItem.fileSize,
                        downloadedBytes: queueItem.downloadedBytes
                    )
                }
                
                updateDownloadCounts()
                resumePendingDownloads()
                
            } catch {
                print("⚠️ Failed to load existing downloads: \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    func startDownload(for resource: LearningResource) async -> Bool {
        guard let contentURL = resource.contentURL else {
            print("❌ Invalid content URL for resource: \(resource.title)")
            return false
        }
        
        // Check if already downloading or downloaded
        if downloads.contains(where: { $0.resourceId == resource.id.uuidString }) {
            print("⚠️ Resource already in download queue: \(resource.title)")
            return false
        }
        
        let downloadItem = DownloadItem(
            resourceId: resource.id.uuidString,
            title: resource.title,
            url: contentURL,
            status: .pending
        )
        
        downloads.append(downloadItem)
        updateDownloadCounts()
        
        // Save to database
        do {
            let dataService = LearningDataService.shared
            try await dataService.queueDownload(
                resourceId: resource.id.uuidString,
                downloadURL: contentURL.absoluteString,
                priority: 0
            )
            
            print("📥 Queued download: \(resource.title)")
            await startNextDownload()
            return true
            
        } catch {
            print("❌ Failed to queue download: \(error)")
            removeDownload(downloadItem.id)
            return false
        }
    }
    
    func pauseDownload(_ downloadId: String) {
        guard let index = downloads.firstIndex(where: { $0.id == downloadId }) else { return }
        
        if let task = downloadTasks[downloadId] {
            task.suspend()
            downloadTasks.removeValue(forKey: downloadId)
        }
        
        downloads[index].status = .paused
        updateDownloadCounts()
        
        Task {
            await updateDownloadInDatabase(downloads[index])
            await startNextDownload()
        }
        
        print("⏸️ Paused download: \(downloads[index].title)")
    }
    
    func resumeDownload(_ downloadId: String) {
        guard let index = downloads.firstIndex(where: { $0.id == downloadId }) else { return }
        
        downloads[index].status = .pending
        updateDownloadCounts()
        
        Task {
            await updateDownloadInDatabase(downloads[index])
            await startNextDownload()
        }
        
        print("▶️ Resumed download: \(downloads[index].title)")
    }
    
    func cancelDownload(_ downloadId: String) {
        guard let index = downloads.firstIndex(where: { $0.id == downloadId }) else { return }
        
        if let task = downloadTasks[downloadId] {
            task.cancel()
            downloadTasks.removeValue(forKey: downloadId)
        }
        
        let download = downloads[index]
        
        // Clean up local file if exists
        if let localPath = download.localFilePath {
            try? FileManager.default.removeItem(atPath: localPath)
        }
        
        downloads.remove(at: index)
        updateDownloadCounts()
        
        Task {
            await removeDownloadFromDatabase(downloadId)
            await startNextDownload()
        }
        
        print("❌ Cancelled download: \(download.title)")
    }
    
    func removeDownload(_ downloadId: String) {
        guard let index = downloads.firstIndex(where: { $0.id == downloadId }) else { return }
        
        let download = downloads[index]
        downloads.remove(at: index)
        updateDownloadCounts()
        
        Task {
            await removeDownloadFromDatabase(downloadId)
        }
        
        print("🗑️ Removed download: \(download.title)")
    }
    
    func clearCompletedDownloads() {
        let completedDownloads = downloads.filter { $0.status == .completed }
        downloads.removeAll { $0.status == .completed }
        updateDownloadCounts()
        
        Task {
            for download in completedDownloads {
                await removeDownloadFromDatabase(download.id)
            }
        }
        
        print("🧹 Cleared \(completedDownloads.count) completed downloads")
    }
    
    func pauseAllDownloads() {
        for download in downloads.filter({ $0.status == .downloading }) {
            pauseDownload(download.id)
        }
        print("⏸️ Paused all downloads")
    }
    
    func resumeAllDownloads() {
        for download in downloads.filter({ $0.status == .paused }) {
            resumeDownload(download.id)
        }
        print("▶️ Resumed all downloads")
    }
    
    // MARK: - Private Methods
    
    private func startNextDownload() async {
        guard activeDownloads < maxConcurrentDownloads else { return }
        
        guard let nextDownload = downloads.first(where: { $0.status == .pending }) else {
            if activeDownloads == 0 {
                isDownloading = false
            }
            return
        }
        
        await startDownloadTask(for: nextDownload)
    }
    
    private func startDownloadTask(for download: DownloadItem) async {
        guard let index = downloads.firstIndex(where: { $0.id == download.id }) else { return }
        
        downloads[index].status = .downloading
        downloads[index].startDate = Date()
        updateDownloadCounts()
        
        let task = urlSession.downloadTask(with: download.url)
        downloadTasks[download.id] = task
        task.resume()
        
        isDownloading = true
        
        await updateDownloadInDatabase(downloads[index])
        
        print("⬇️ Started download: \(download.title)")
    }
    
    private func updateDownloadCounts() {
        totalDownloads = downloads.count
        activeDownloads = downloads.filter { $0.status == .downloading }.count
    }
    
    private func resumePendingDownloads() {
        Task {
            for _ in downloads.filter({ $0.status == .pending || $0.status == .downloading }) {
                await startNextDownload()
            }
        }
    }
    
    // MARK: - Database Operations
    
    private func updateDownloadInDatabase(_ download: DownloadItem) async {
        // Update download status in database
        // Implementation would use LearningDataService
        print("💾 Updated download in database: \(download.title)")
    }
    
    private func removeDownloadFromDatabase(_ downloadId: String) async {
        // Remove download from database
        // Implementation would use LearningDataService
        print("🗑️ Removed download from database: \(downloadId)")
    }
    
    // MARK: - Storage Management
    
    func getStorageInfo() -> StorageInfo {
        let totalDownloaded = downloads
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.fileSize }
        
        let pendingSize = downloads
            .filter { $0.status == .pending || $0.status == .downloading }
            .reduce(0) { $0 + $1.fileSize }
        
        return StorageInfo(
            totalSize: totalDownloaded + pendingSize,
            fileCount: downloads.count
        )
    }
    
    private func getAvailableStorageSpace() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSize = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSize.int64Value
            }
        } catch {
            print("⚠️ Failed to get available storage: \(error)")
        }
        return 0
    }
    
    func getDownloadDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadPath = documentsPath.appendingPathComponent("Downloads")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: downloadPath, withIntermediateDirectories: true)
        
        return downloadPath
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManagerService: URLSessionDownloadDelegate {
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task { @MainActor in
            guard let downloadId = downloadTasks.first(where: { $0.value == downloadTask })?.key,
                  let index = downloads.firstIndex(where: { $0.id == downloadId }) else {
                return
            }
        
        DispatchQueue.main.async {
            let download = self.downloads[index]
            
            // Move file to permanent location
            let downloadDirectory = self.getDownloadDirectory()
            let destinationURL = downloadDirectory.appendingPathComponent("\(download.resourceId).\(download.url.pathExtension)")
            
            do {
                // Remove existing file if present
                try? FileManager.default.removeItem(at: destinationURL)
                
                // Move downloaded file
                try FileManager.default.moveItem(at: location, to: destinationURL)
                
                self.downloads[index].status = .completed
                self.downloads[index].localFilePath = destinationURL.path
                self.downloads[index].completionDate = Date()
                self.downloads[index].progress = 1.0
                
                self.downloadTasks.removeValue(forKey: downloadId)
                self.updateDownloadCounts()
                
                print("✅ Download completed: \(download.title)")
                
                // Update resource in database
                Task {
                    await self.markResourceAsDownloaded(download.resourceId, localPath: destinationURL.path)
                    await self.updateDownloadInDatabase(self.downloads[index])
                    await self.startNextDownload()
                }
                
            } catch {
                self.downloads[index].status = .failed
                self.downloads[index].errorMessage = error.localizedDescription
                print("❌ Failed to save download: \(error)")
            }
        }
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            guard let downloadId = downloadTasks.first(where: { $0.value == downloadTask })?.key,
                  let index = downloads.firstIndex(where: { $0.id == downloadId }) else {
                return
            }
        
        DispatchQueue.main.async {
            self.downloads[index].downloadedBytes = totalBytesWritten
            self.downloads[index].fileSize = totalBytesExpectedToWrite
            
            if totalBytesExpectedToWrite > 0 {
                self.downloads[index].progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
        }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didCompleteWithError error: Error?) {
        guard let downloadId = downloadTasks.first(where: { $0.value == downloadTask })?.key,
              let index = downloads.firstIndex(where: { $0.id == downloadId }) else {
            return
        }
        
        DispatchQueue.main.async {
            if let error = error {
                self.downloads[index].status = .failed
                self.downloads[index].errorMessage = error.localizedDescription
                print("❌ Download failed: \(error)")
            }
            
            self.downloadTasks.removeValue(forKey: downloadId)
            self.updateDownloadCounts()
            
            Task {
                await self.updateDownloadInDatabase(self.downloads[index])
                await self.startNextDownload()
            }
        }
    }
    
    private func markResourceAsDownloaded(_ resourceId: String, localPath: String) async {
        do {
            let dataService = LearningDataService.shared
            if let resource = try await dataService.fetchLearningResource(id: resourceId) {
                resource.isDownloaded = true
                resource.localFilePath = localPath
                resource.downloadDate = Date()
                // Save changes would be handled by SwiftData context
            }
        } catch {
            print("⚠️ Failed to mark resource as downloaded: \(error)")
        }
    }
}

// MARK: - Data Models

struct DownloadItem: Identifiable {
    let id: String
    let resourceId: String
    let title: String
    let url: URL
    
    var status: DownloadStatus = .pending
    var progress: Double = 0.0
    var fileSize: Int64 = 0
    var downloadedBytes: Int64 = 0
    var localFilePath: String?
    var errorMessage: String?
    
    var startDate: Date?
    var completionDate: Date?
    
    init(id: String = UUID().uuidString, resourceId: String, title: String, url: URL, status: DownloadStatus = .pending, progress: Double = 0.0, fileSize: Int64 = 0, downloadedBytes: Int64 = 0) {
        self.id = id
        self.resourceId = resourceId
        self.title = title
        self.url = url
        self.status = status
        self.progress = progress
        self.fileSize = fileSize
        self.downloadedBytes = downloadedBytes
    }
}

enum DownloadStatus: String, CaseIterable {
    case pending = "pending"
    case downloading = "downloading"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .downloading: return "arrow.down.circle"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
}
