import Foundation
import SwiftUI
import OSLog
import Combine
#if canImport(NukeUI)
import NukeUI
#endif

// MARK: - Performance Manager
@MainActor
final class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "Performance")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Image Caching
    private let imageCache = NSCache<NSString, UIImage>()
    private let imageCacheQueue = DispatchQueue(label: "com.lyo.app.imageCache", qos: .utility)
    
    // MARK: - Memory Management
    @Published var memoryPressure: MemoryPressureLevel = .normal
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    enum MemoryPressureLevel {
        case normal
        case warning
        case critical
        
        var description: String {
            switch self {
            case .normal: return "Normal"
            case .warning: return "Warning"
            case .critical: return "Critical"
            }
        }
    }
    
    // MARK: - Network Optimization
    private var pendingRequests: [String: Task<Void, Never>] = [:]
    private let requestDebouncer = RequestDebouncer()
    
    init() {
        setupImageCache()
        setupMemoryPressureMonitoring()
        logger.info("🚀 PerformanceManager initialized")
    }
    
    // MARK: - Image Caching System
    
    private func setupImageCache() {
        imageCache.countLimit = 100 // Limit cached images
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Clear cache on memory pressure
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearImageCache()
            }
            .store(in: &cancellables)
    }
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Rough memory cost
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func clearImageCache() {
        imageCacheQueue.async { [weak self] in
            self?.imageCache.removeAllObjects()
            Task { @MainActor in
                self?.logger.info("🗑️ Image cache cleared due to memory pressure")
            }
        }
    }
    
    // MARK: - Memory Pressure Monitoring
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical, .normal],
            queue: DispatchQueue.global(qos: .utility)
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            guard let self = self,
                  let source = self.memoryPressureSource else { return }
            
            let event = source.mask
            Task { @MainActor in
                if event.contains(.critical) {
                    self.memoryPressure = .critical
                    self.handleCriticalMemoryPressure()
                } else if event.contains(.warning) {
                    self.memoryPressure = .warning
                    self.handleMemoryWarning()
                } else if event.contains(.normal) {
                    self.memoryPressure = .normal
                }
                
                self.logger.info("💾 Memory pressure: \(self.memoryPressure.description)")
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    private func handleMemoryWarning() {
        // Clear non-essential caches
        clearImageCache()
        
        // Notify other managers to reduce memory usage
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
        
        logger.warning("⚠️ Memory warning - clearing caches")
    }
    
    private func handleCriticalMemoryPressure() {
        // Aggressive memory cleanup
        clearImageCache()
        URLCache.shared.removeAllCachedResponses()
        
        // Force garbage collection
        autoreleasepool {
            // This block helps with memory cleanup
        }
        
        logger.error("🚨 Critical memory pressure - aggressive cleanup")
    }
    
    // MARK: - Network Request Optimization
    
    func optimizedRequest<T>(
        id: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        // Cancel existing request with same ID
        pendingRequests[id]?.cancel()
        
        let task = Task { @MainActor in
            defer { pendingRequests.removeValue(forKey: id) }
            
            do {
                let result = try await operation()
                logger.info("✅ Optimized request completed: \(id)")
                return result
            } catch {
                logger.error("❌ Optimized request failed: \(id) - \(error)")
                throw error
            }
        }
        
        pendingRequests[id] = Task { await _ = try? await task.value }
        
        return try await task.value
    }
    
    func debouncedRequest<T>(
        id: String,
        delay: TimeInterval = 0.3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await requestDebouncer.debounce(id: id, delay: delay, operation: operation)
    }
    
    // MARK: - Background Processing
    
    func performBackgroundTask<T>(
        priority: TaskPriority = .utility,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withTaskGroup(of: T.self) { group in
            group.addTask(priority: priority) {
                try await operation()
            }
            
            return try await group.next()!
        }
    }
    
    // MARK: - Batch Operations
    
    func batchProcess<T, R>(
        items: [T],
        batchSize: Int = 10,
        operation: @escaping ([T]) async throws -> [R]
    ) async throws -> [R] {
        var results: [R] = []
        
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let endIndex = min(i + batchSize, items.count)
            let batch = Array(items[i..<endIndex])
            
            let batchResults = try await operation(batch)
            results.append(contentsOf: batchResults)
            
            // Small delay to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        return results
    }
    
    deinit {
        memoryPressureSource?.cancel()
    }
}

// MARK: - Request Debouncer
private actor RequestDebouncer {
    private var tasks: [String: Task<Any, Error>] = [:]
    
    func debounce<T>(
        id: String,
        delay: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        // Cancel existing task
        tasks[id]?.cancel()
        
        // Create new debounced task
        let task = Task<Any, Error> {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return try await operation()
        }
        
        tasks[id] = task
        
        do {
            let result = try await task.value
            tasks.removeValue(forKey: id)
            return result as! T
        } catch {
            tasks.removeValue(forKey: id)
            throw error
        }
    }
}

// MARK: - Optimized AsyncImage
struct OptimizedAsyncImage: View {
    let url: URL?
    let placeholder: Image
    
    var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
            } else if state.error != nil {
                placeholder
                    .foregroundColor(.gray)
                    .overlay(Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red))
            } else {
                placeholder
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Background Sync Service
@MainActor
final class BackgroundSyncService: ObservableObject {
    static let shared = BackgroundSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "BackgroundSync")
    private let performanceManager = PerformanceManager.shared
    private var syncTimer: Timer?
    
    init() {
        setupBackgroundSync()
    }
    
    private func setupBackgroundSync() {
        // Setup periodic sync every 5 minutes when app is active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSync()
            }
        }
        
        // Sync on app becoming active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performSync()
                }
            }
            .store(in: &cancellables)
    }
    
    func performSync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        logger.info("🔄 Starting background sync")
        
        do {
            // Batch sync operations for efficiency
            async let healthCheck = APIClient.shared.checkConnection()
            async let userProfile = try? APIClient.shared.getCurrentUser()
            
            let (isConnected, _) = await (try? healthCheck ?? false, userProfile)
            
            if isConnected {
                lastSyncDate = Date()
                logger.info("✅ Background sync completed successfully")
            } else {
                logger.warning("⚠️ Background sync failed - no connection")
            }
            
        } catch {
            logger.error("❌ Background sync error: \(error)")
        }
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let memoryWarning = Notification.Name("memoryWarning")
    static let backgroundSyncCompleted = Notification.Name("backgroundSyncCompleted")
}

// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    @ObservedObject var performanceManager = PerformanceManager.shared
    @ObservedObject var backgroundSync = BackgroundSyncService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Memory Status
            HStack {
                Circle()
                    .fill(performanceManager.memoryPressure == .normal ? .green : 
                          performanceManager.memoryPressure == .warning ? .orange : .red)
                    .frame(width: 8, height: 8)
                
                Text("Memory: \(performanceManager.memoryPressure.description)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Background Sync Status
            HStack {
                if backgroundSync.isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Text(backgroundSync.isSyncing ? "Syncing..." : "Sync Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastSync = backgroundSync.lastSyncDate {
                    Text("• \(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}