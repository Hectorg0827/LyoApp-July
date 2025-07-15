import SwiftUI
import Foundation
import Combine

// MARK: - Performance Optimization Infrastructure

/// Comprehensive performance optimization system for LyoApp
/// Provides memory-efficient image loading, caching, and resource management
struct PerformanceOptimizer {
    
    // MARK: - Memory Management
    struct MemoryManager {
        static let shared = MemoryManager()
        
        private init() {}
        
        /// Monitor memory usage and trigger cleanup when needed
        func monitorMemoryUsage() {
            let memoryInfo = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            
            let result = withUnsafeMutablePointer(to: &memoryInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_,
                             task_flavor_t(MACH_TASK_BASIC_INFO),
                             $0,
                             &count)
                }
            }
            
            if result == KERN_SUCCESS {
                let memoryUsage = memoryInfo.resident_size
                let memoryLimit: UInt64 = 500 * 1024 * 1024 // 500MB threshold
                
                if memoryUsage > memoryLimit {
                    triggerMemoryCleanup()
                }
            }
        }
        
        private func triggerMemoryCleanup() {
            // Trigger image cache cleanup
            AsyncImageLoader.shared.clearCache()
            
            // Post notification for ViewModels to cleanup
            NotificationCenter.default.post(name: .memoryWarning, object: nil)
        }
    }
    
    // MARK: - Performance Metrics
    struct PerformanceMetrics {
        static let shared = PerformanceMetrics()
        
        private var startTimes: [String: CFTimeInterval] = [:]
        
        func startTimer(for operation: String) {
            startTimes[operation] = CACurrentMediaTime()
        }
        
        func endTimer(for operation: String) -> TimeInterval? {
            guard let startTime = startTimes[operation] else { return nil }
            let endTime = CACurrentMediaTime()
            let duration = endTime - startTime
            
            startTimes.removeValue(forKey: operation)
            
            #if DEBUG
            print("⚡ Performance: \(operation) took \(duration * 1000)ms")
            #endif
            
            return duration
        }
    }
}

// MARK: - Async Image Loading with Caching

/// High-performance async image loader with memory and disk caching
@MainActor
class AsyncImageLoader: ObservableObject {
    static let shared = AsyncImageLoader()
    
    @Published private(set) var loadingStates: [String: LoadingState] = [:]
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache = DiskImageCache()
    private var downloadTasks: [String: Task<UIImage?, Error>] = [:]
    
    enum LoadingState {
        case idle
        case loading
        case loaded(UIImage)
        case failed(Error)
    }
    
    private init() {
        setupCache()
        setupMemoryWarningObserver()
    }
    
    private func setupCache() {
        memoryCache.countLimit = 100 // Maximum 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: .memoryWarning,
            object: nil,
            queue: .main
        ) { _ in
            self.clearCache()
        }
    }
    
    func loadImage(from url: String) async -> UIImage? {
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: url as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await diskCache.image(for: url) {
            memoryCache.setObject(diskImage, forKey: url as NSString)
            return diskImage
        }
        
        // Download image
        return await downloadImage(from: url)
    }
    
    @MainActor
    func loadImageWithState(from url: String) {
        guard loadingStates[url] != .loading else { return }
        
        // Cancel existing task if any
        downloadTasks[url]?.cancel()
        
        loadingStates[url] = .loading
        
        let task = Task {
            do {
                if let image = await loadImage(from: url) {
                    loadingStates[url] = .loaded(image)
                    return image
                } else {
                    loadingStates[url] = .failed(URLError(.badURL))
                    return nil
                }
            } catch {
                loadingStates[url] = .failed(error)
                return nil
            }
        }
        
        downloadTasks[url] = task
    }
    
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            PerformanceOptimizer.PerformanceMetrics.shared.startTimer(for: "image_download_\(urlString)")
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            PerformanceOptimizer.PerformanceMetrics.shared.endTimer(for: "image_download_\(urlString)")
            
            guard let image = UIImage(data: data) else { return nil }
            
            // Cache the image
            memoryCache.setObject(image, forKey: urlString as NSString)
            await diskCache.store(image: image, for: urlString)
            
            return image
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        Task {
            await diskCache.clearCache()
        }
        loadingStates.removeAll()
        
        // Cancel all download tasks
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
    }
    
    func getLoadingState(for url: String) -> LoadingState {
        return loadingStates[url] ?? .idle
    }
}

// MARK: - Disk Image Cache

actor DiskImageCache {
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    
    init() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func image(for url: String) -> UIImage? {
        let fileName = url.md5Hash + ".jpg"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    func store(image: UIImage, for url: String) {
        let fileName = url.md5Hash + ".jpg"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        try? data.write(to: fileURL)
        
        // Check cache size and cleanup if needed
        Task {
            await cleanupCacheIfNeeded()
        }
    }
    
    func clearCache() {
        let fileURLs = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        
        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func cleanupCacheIfNeeded() {
        let fileManager = FileManager.default
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }
        
        // Calculate total cache size
        let totalSize = fileURLs.compactMap { url -> Int? in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        }.reduce(0, +)
        
        if totalSize > maxCacheSize {
            // Sort files by modification date (oldest first)
            let sortedFiles = fileURLs.compactMap { url -> (URL, Date)? in
                guard let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                    return nil
                }
                return (url, date)
            }.sorted { $0.1 < $1.1 }
            
            // Remove oldest files until under limit
            var currentSize = totalSize
            for (fileURL, _) in sortedFiles {
                if currentSize <= maxCacheSize / 2 { break } // Remove until 50% of limit
                
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    try? fileManager.removeItem(at: fileURL)
                    currentSize -= fileSize
                }
            }
        }
    }
}

// MARK: - Optimized Image View

struct OptimizedAsyncImageView: View {
    let url: String
    let placeholder: AnyView
    let contentMode: ContentMode
    
    @StateObject private var loader = AsyncImageLoader.shared
    @State private var image: UIImage?
    
    init(
        url: String,
        contentMode: ContentMode = .fit,
        @ViewBuilder placeholder: () -> some View = { ProgressView() }
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            image = await loader.loadImage(from: url)
        }
    }
}

// MARK: - Optimized Post Thumbnail
struct OptimizedPostThumbnail: View {
    let post: Post
    @State private var image: UIImage?
    @State private var isLoading = true
    
    private let imageLoader = AsyncImageLoader.shared
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        .redacted(reason: .placeholder)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                }
            }
            .cornerRadius(8)
            .task {
                await loadImage()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Post by \(post.author.fullName)")
        .accessibilityAddTraits(.isImage)
        .accessibilityAddTraits(.isButton)
    }
    
    private func loadImage() async {
        guard let imageURL = post.imageURL,
              let url = URL(string: imageURL) else {
            isLoading = false
            return
        }
        
        let loadedImage = await imageLoader.loadImage(from: url)
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - Loading View Component
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading content")
    }
}

// MARK: - Lazy Loading Components

/// Lazy loading container that only renders content when visible
struct LazyRenderView<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    
    @State private var isVisible = false
    @State private var hasRendered = false
    
    init(threshold: CGFloat = 0.0, @ViewBuilder content: () -> Content) {
        self.threshold = threshold
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if hasRendered {
                content
            } else {
                Color.clear
                    .onAppear {
                        if !hasRendered {
                            hasRendered = true
                        }
                    }
            }
        }
        .onAppear {
            if !hasRendered {
                // Delay rendering for better performance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasRendered = true
                }
            }
        }
    }
}

/// Efficient list row that handles lazy loading and memory management
struct LazyListRow<Content: View>: View {
    let content: Content
    let onAppear: (() -> Void)?
    let onDisappear: (() -> Void)?
    
    @State private var isVisible = false
    
    init(
        onAppear: (() -> Void)? = nil,
        onDisappear: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onAppear = onAppear
        self.onDisappear = onDisappear
    }
    
    var body: some View {
        content
            .onAppear {
                isVisible = true
                onAppear?()
            }
            .onDisappear {
                isVisible = false
                onDisappear?()
            }
    }
}

// MARK: - Extensions

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

extension Notification.Name {
    static let memoryWarning = Notification.Name("MemoryWarning")
}

// MARK: - View Model Optimization Protocol

protocol OptimizedViewModel: ObservableObject {
    func cleanup()
    func preload()
    func handleMemoryWarning()
}

extension OptimizedViewModel {
    func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: .memoryWarning,
            object: nil,
            queue: .main
        ) { _ in
            self.handleMemoryWarning()
        }
    }
}

// MARK: - Background Task Manager

@MainActor
class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    private var backgroundTasks: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    func schedule<T>(
        id: String,
        priority: TaskPriority = .medium,
        operation: @escaping () async -> T
    ) {
        // Cancel existing task with same ID
        backgroundTasks[id]?.cancel()
        
        let task = Task(priority: priority) {
            _ = await operation()
            backgroundTasks.removeValue(forKey: id)
        }
        
        backgroundTasks[id] = task
    }
    
    func cancelTask(id: String) {
        backgroundTasks[id]?.cancel()
        backgroundTasks.removeValue(forKey: id)
    }
    
    func cancelAllTasks() {
        backgroundTasks.values.forEach { $0.cancel() }
        backgroundTasks.removeAll()
    }
}

// MARK: - Optimized Message Bubble
struct OptimizedMessageBubble: View {
    let message: AIMessage
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.xs) {
            if message.role == .assistant {
                // AI Avatar
                Circle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .accessibilityHidden(true)
            } else {
                Spacer()
            }
            
            // Message Content
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: DesignTokens.Spacing.xs) {
                Text(message.content)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(message.role == .user ? DesignTokens.Colors.primary : DesignTokens.Colors.secondaryBackground)
                    )
                    .foregroundColor(message.role == .user ? .white : DesignTokens.Colors.label)
                    .font(DesignTokens.Typography.body)
                
                Text(message.timestamp, style: .time)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.tertiaryLabel)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .user {
                // User Avatar
                Circle()
                    .fill(DesignTokens.Colors.gray200)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.gray600)
                    }
                    .accessibilityHidden(true)
            } else {
                Spacer()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.role == .user ? "You" : "AI"): \(message.content)")
        .accessibilityAddTraits(.isStaticText)
    }
}
