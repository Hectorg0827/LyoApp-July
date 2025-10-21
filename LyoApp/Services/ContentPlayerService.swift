import Foundation
import AVFoundation
import AVKit
import SwiftUI
import Combine
import WebKit
import MediaPlayer
import UIKit
import PDFKit

// MARK: - Content Player Service

@MainActor
class ContentPlayerService: NSObject, ObservableObject {
    static let shared = ContentPlayerService()
    
    @Published var currentContent: LearningResource?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0
    @Published var volume: Float = 1.0
    @Published var playbackRate: Float = 1.0
    @Published var isBuffering: Bool = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVPlayer?
    private var videoPlayer: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
    }
    
    // MARK: - Content Loading
    
    func loadContent(_ resource: LearningResource) async {
        print("🎬 Loading content: \(resource.title)")
        
        currentContent = resource
        playbackState = .loading
        isBuffering = true
        errorMessage = nil
        
        do {
            // Use unified computed contentURL (fall back to original url string fields)
            guard let contentURL = resource.contentURL else { throw ContentPlayerError.invalidURL }
            
            // Check if content is downloaded locally
            if let localPath = await getLocalContentPath(for: resource.id) {
                let localURL = URL(fileURLWithPath: localPath)
                try await setupPlayer(with: localURL, for: .video) // Simplified content type
            } else {
                try await setupPlayer(with: contentURL, for: .video) // Simplified content type
            }
            
            isBuffering = false
            playbackState = .paused
            
            // Track content access
            await trackContentAccess(resource)
            
        } catch {
            await handlePlaybackError(error)
        }
    }
    
    private func setupPlayer(with url: URL, for contentType: ContentType) async throws {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        switch contentType {
        case .video:
            videoPlayer = AVPlayer(playerItem: playerItem)
            audioPlayer = nil
        case .audio:
            audioPlayer = AVPlayer(playerItem: playerItem)
            videoPlayer = nil
        case .thumbnail:
            throw ContentPlayerError.unsupportedContentType
        }
        
        let player = videoPlayer ?? audioPlayer
        setupPlayerObservers(player)
        
        // Load duration
        do {
            let duration = try await asset.load(.duration)
            self.duration = CMTimeGetSeconds(duration)
        } catch {
            print("⚠️ Failed to load duration: \(error)")
        }
    }
    
    // MARK: - Playback Controls
    
    func play() {
        guard let player = currentPlayer else { return }
        
        player.play()
        playbackState = .playing
        
        // Update now playing info
        updateNowPlayingInfo()
        
        print("▶️ Started playback")
    }
    
    func pause() {
        guard let player = currentPlayer else { return }
        
        player.pause()
        playbackState = .paused
        
        print("⏸️ Paused playback")
    }
    
    func stop() {
        guard let player = currentPlayer else { return }
        
        player.pause()
        seek(to: 0)
        playbackState = .stopped
        
        // Save progress
        if let content = currentContent {
            Task {
                await saveProgress(for: content, time: currentTime)
            }
        }
        
        print("⏹️ Stopped playback")
    }
    
    func seek(to time: TimeInterval) {
        guard let player = currentPlayer else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime) { [weak self] completed in
            if completed {
                DispatchQueue.main.async {
                    self?.currentTime = time
                    self?.updatePlaybackProgress()
                }
            }
        }
    }
    
    func skip(forward: Bool, interval: TimeInterval = 15) {
        let newTime = forward ? currentTime + interval : currentTime - interval
        let clampedTime = max(0, min(newTime, duration))
        seek(to: clampedTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        guard let player = currentPlayer else { return }
        
        player.rate = rate
        playbackRate = rate
        
        if playbackState == .playing {
            player.play()
        }
    }
    
    func setVolume(_ volume: Float) {
        guard let player = currentPlayer else { return }
        
        player.volume = volume
        self.volume = volume
    }
    
    // MARK: - Player Observers
    
    private func setupPlayerObservers(_ player: AVPlayer?) {
        guard let player = player else { return }
        
        // Remove existing observer
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
                self?.updatePlaybackProgress()
            }
        }
        
        // Observe player status
        player.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.playbackState = .paused
                    self?.isBuffering = false
                case .failed:
                    Task {
                        await self?.handlePlaybackError(player.error ?? ContentPlayerError.playbackFailed)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe playback completion
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                self?.playbackState = .completed
                self?.onPlaybackCompleted()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Audio Session
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Remote Controls
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skip(forward: true)
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skip(forward: false)
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let content = currentContent else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = content.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = content.category ?? "LyoApp"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        
        // Add artwork if available
        if let thumbnailURL = content.thumbnailURL {
            Task {
                if let imageData = try? Data(contentsOf: thumbnailURL),
                   let image = UIImage(data: imageData) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    // MARK: - Helper Methods
    
    private var currentPlayer: AVPlayer? {
        return videoPlayer ?? audioPlayer
    }
    
    private func updatePlaybackProgress() {
        guard duration > 0 else { return }
        playbackProgress = currentTime / duration
    }
    
    private func onPlaybackCompleted() {
        guard let content = currentContent else { return }
        
        Task {
            // Mark as completed
            await saveProgress(for: content, time: duration, completed: true)
            
            // Generate completion insights
            let _ = await GemmaService.shared.generatePersonalizedInsights(learningHistory: [content])
            print("🎓 Completed content: \(content.title)")
        }
    }
    
    private func getLocalContentPath(for resourceId: String) async -> String? {
        do {
            let dataService = LearningDataService.shared
            if let resource = try await dataService.fetchLearningResource(id: resourceId) {
                return resource.url // Simplified: treat primary url string as source
            }
        } catch { /* ignore */ }
        return nil
    }
    
    private func saveProgress(for content: LearningResource, time: TimeInterval, completed: Bool = false) async {
        do {
            let progress = completed ? 100.0 : (time / duration) * 100.0
            let dataService = LearningDataService.shared
            // Using placeholder user ID - replace with actual user ID
            try await dataService.updateProgress(resourceId: content.id, userId: "current_user", progress: progress)
        } catch {
            print("⚠️ Failed to save progress: \(error)")
        }
    }
    
    private func trackContentAccess(_ content: LearningResource) async {
        // Track analytics
        print("📊 Tracked content access: \(content.title)")
    }
    
    private func handlePlaybackError(_ error: Error) async {
        playbackState = .error
        isBuffering = false
        errorMessage = error.localizedDescription
        print("❌ Playback error: \(error)")
    }
    
    deinit {
        // Clean up time observer - this is safe to do from deinit
        if let timeObserver = timeObserver {
            // Use whichever player is available
            if let videoPlayer = videoPlayer {
                videoPlayer.removeTimeObserver(timeObserver)
            } else if let audioPlayer = audioPlayer {
                audioPlayer.removeTimeObserver(timeObserver)
            }
        }
    }
}

// MARK: - PDF Viewer Service

@MainActor
class PDFViewerService: ObservableObject {
    @Published var currentPDF: LearningResource?
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadPDF(_ resource: LearningResource) async {
        print("📄 Loading PDF: \(resource.title)")
        
        currentPDF = resource
        isLoading = true
        errorMessage = nil
        
        // Implementation would load PDF using PDFKit
        // This is a placeholder
        
        currentPage = 1
        totalPages = 10 // Placeholder
        isLoading = false
    }
    
    func navigateToPage(_ page: Int) {
        guard page > 0 && page <= totalPages else { return }
        currentPage = page
    }
    
    func nextPage() {
        navigateToPage(currentPage + 1)
    }
    
    func previousPage() {
        navigateToPage(currentPage - 1)
    }
}

// MARK: - Content Player States

enum PlaybackState {
    case stopped
    case loading
    case paused
    case playing
    case completed
    case error
}

enum ContentPlayerError: LocalizedError {
    case invalidURL
    case unsupportedContentType
    case playbackFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid content URL"
        case .unsupportedContentType:
            return "Unsupported content type"
        case .playbackFailed:
            return "Playback failed"
        case .networkError:
            return "Network connection error"
        }
    }
}

// Local content type for the player (distinct from LearningResource.ContentType)
enum ContentType {
    case video
    case audio
    case thumbnail
}

// MARK: - Content Player Views

// Renamed to avoid collisions with any other VideoPlayerView types
struct LyoVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

struct AudioPlayerControlsView: View {
    @StateObject private var playerService = ContentPlayerService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress bar
            HStack {
                Text(formatTime(playerService.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { playerService.playbackProgress },
                    set: { progress in
                        playerService.seek(to: progress * playerService.duration)
                    }
                ))
                
                Text(formatTime(playerService.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Control buttons
            HStack(spacing: 30) {
                Button(action: { playerService.skip(forward: false) }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                
                Button(action: {
                    if playerService.playbackState == .playing {
                        playerService.pause()
                    } else {
                        playerService.play()
                    }
                }) {
                    Image(systemName: playerService.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.largeTitle)
                }
                
                Button(action: { playerService.skip(forward: true) }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
            }
            
            // Playback rate
            HStack {
                Text("Speed:")
                    .font(.caption)
                
                Menu("\(playerService.playbackRate, specifier: "%.1f")x") {
                    ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                        Button("\(rate, specifier: "%.2f")x") {
                            playerService.setPlaybackRate(Float(rate))
                        }
                    }
                }
                .font(.caption)
            }
        }
        .padding()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PDFViewerView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update if needed
    }
}

// Intentionally no global typealias for `VideoPlayerView` to avoid duplicate declarations.
