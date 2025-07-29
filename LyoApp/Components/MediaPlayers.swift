import SwiftUI
import AVKit
import AVFoundation

// MARK: - Enhanced Video Player with Controls
struct VideoPlayerView: View {
    let videoURL: URL
    let title: String
    let onProgressUpdate: ((Double, TimeInterval) -> Void)?
    let onCompletion: (() -> Void)?
    
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            // Video Player
            VideoPlayer(player: playerManager.player)
                .onAppear {
                    playerManager.setup(url: videoURL)
                    playerManager.onProgressUpdate = onProgressUpdate
                    playerManager.onCompletion = onCompletion
                }
                .onDisappear {
                    playerManager.cleanup()
                }
                .onTapGesture {
                    toggleControls()
                }
            
            // Custom Controls Overlay
            if showControls {
                VStack {
                    // Top Controls
                    HStack {
                        Button(action: {
                            // Back button
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Text(title)
                            .foregroundColor(.white)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Menu {
                            Button("Download") {
                                // Trigger download
                            }
                            Button("Share") {
                                // Share functionality
                            }
                            Button("Report") {
                                // Report functionality
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                        }
                    }
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.7), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                    
                    // Bottom Controls
                    VStack(spacing: 16) {
                        // Progress Bar
                        VideoProgressView(
                            progress: playerManager.progress,
                            duration: playerManager.duration,
                            onSeek: { time in
                                playerManager.seek(to: time)
                            }
                        )
                        
                        // Play Controls
                        HStack(spacing: 30) {
                            Button(action: {
                                playerManager.rewind()
                            }) {
                                Image(systemName: "gobackward.15")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            
                            Button(action: {
                                playerManager.togglePlayback()
                            }) {
                                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            }
                            
                            Button(action: {
                                playerManager.fastForward()
                            }) {
                                Image(systemName: "goforward.15")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }
                        
                        // Time Display
                        HStack {
                            Text(formatTime(playerManager.currentTime))
                                .foregroundColor(.white)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(formatTime(playerManager.duration))
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            resetControlsTimer()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Video Progress View
struct VideoProgressView: View {
    let progress: Double
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Progress track
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * (isDragging ? dragValue : progress), height: 4)
                
                // Drag handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .offset(x: geometry.size.width * (isDragging ? dragValue : progress) - 8)
            }
        }
        .frame(height: 16)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newValue = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                    dragValue = newValue
                }
                .onEnded { value in
                    let newValue = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                    let seekTime = newValue * duration
                    onSeek(seekTime)
                    isDragging = false
                }
        )
    }
}

// MARK: - Video Player Manager
class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer = AVPlayer()
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    var onProgressUpdate: ((Double, TimeInterval) -> Void)?
    var onCompletion: (() -> Void)?
    
    private var timeObserver: Any?
    private var progressTimer: Timer?
    
    func setup(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        
        // Get duration
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.duration = playerItem.duration.seconds
                }
            }
            .store(in: &cancellables)
        
        // Progress tracking
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.updateProgress(time: time)
        }
        
        // Completion notification
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handleCompletion()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateProgress(time: CMTime) {
        currentTime = time.seconds
        if duration > 0 {
            progress = currentTime / duration
            onProgressUpdate?(progress, currentTime)
        }
    }
    
    private func handleCompletion() {
        onCompletion?()
        progress = 1.0
    }
    
    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    func rewind() {
        let newTime = max(0, currentTime - 15)
        seek(to: newTime)
    }
    
    func fastForward() {
        let newTime = min(duration, currentTime + 15)
        seek(to: newTime)
    }
    
    func cleanup() {
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        progressTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Audio Player View
struct AudioPlayerView: View {
    let audioURL: URL
    let title: String
    let artist: String?
    let albumArt: URL?
    let onProgressUpdate: ((Double, TimeInterval) -> Void)?
    let onCompletion: (() -> Void)?
    
    @StateObject private var audioManager = AudioPlayerManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // Album Art
            AsyncImage(url: albumArt) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.cardBackground)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(DesignTokens.textSecondary)
                            .font(.system(size: 50))
                    )
            }
            .frame(width: 250, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Track Info
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let artist = artist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                AudioProgressView(
                    progress: audioManager.progress,
                    duration: audioManager.duration,
                    onSeek: { time in
                        audioManager.seek(to: time)
                    }
                )
                
                HStack {
                    Text(formatTime(audioManager.currentTime))
                        .font(.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                    
                    Spacer()
                    
                    Text(formatTime(audioManager.duration))
                        .font(.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                }
            }
            .padding(.horizontal)
            
            // Controls
            HStack(spacing: 40) {
                Button(action: {
                    audioManager.rewind()
                }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(DesignTokens.textPrimary)
                }
                
                Button(action: {
                    audioManager.togglePlayback()
                }) {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.accent)
                }
                
                Button(action: {
                    audioManager.fastForward()
                }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundColor(DesignTokens.textPrimary)
                }
            }
        }
        .padding()
        .onAppear {
            audioManager.setup(url: audioURL)
            audioManager.onProgressUpdate = onProgressUpdate
            audioManager.onCompletion = onCompletion
        }
        .onDisappear {
            audioManager.cleanup()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Progress View
struct AudioProgressView: View {
    let progress: Double
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(DesignTokens.textSecondary.opacity(0.3))
                    .frame(height: 6)
                
                // Progress track
                Capsule()
                    .fill(DesignTokens.accent)
                    .frame(width: geometry.size.width * (isDragging ? dragValue : progress), height: 6)
                
                // Drag handle
                Circle()
                    .fill(DesignTokens.accent)
                    .frame(width: 20, height: 20)
                    .offset(x: geometry.size.width * (isDragging ? dragValue : progress) - 10)
            }
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let newValue = max(0, min(1, value.location.x / geometry.size.width))
                    dragValue = newValue
                }
                .onEnded { value in
                    let newValue = max(0, min(1, value.location.x / geometry.size.width))
                    let seekTime = newValue * duration
                    onSeek(seekTime)
                    isDragging = false
                }
        )
    }
}

// MARK: - Audio Player Manager
class AudioPlayerManager: ObservableObject {
    @Published var player: AVPlayer = AVPlayer()
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    var onProgressUpdate: ((Double, TimeInterval) -> Void)?
    var onCompletion: (() -> Void)?
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    func setup(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        
        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Get duration
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.duration = playerItem.duration.seconds
                }
            }
            .store(in: &cancellables)
        
        // Progress tracking
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.updateProgress(time: time)
        }
        
        // Completion notification
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handleCompletion()
        }
    }
    
    private func updateProgress(time: CMTime) {
        currentTime = time.seconds
        if duration > 0 {
            progress = currentTime / duration
            onProgressUpdate?(progress, currentTime)
        }
    }
    
    private func handleCompletion() {
        onCompletion?()
        progress = 1.0
        isPlaying = false
    }
    
    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    func rewind() {
        let newTime = max(0, currentTime - 15)
        seek(to: newTime)
    }
    
    func fastForward() {
        let newTime = min(duration, currentTime + 15)
        seek(to: newTime)
    }
    
    func cleanup() {
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
        isPlaying = false
    }
}
