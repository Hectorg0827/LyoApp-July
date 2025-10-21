import SwiftUI
import AVKit

/// Video/content player for lesson chunks with AI-driven captions and whiteboard
struct LecturePlayerView: View {
    let chunk: LessonChunk?
    @Binding var playbackState: ClassroomViewState.PlaybackState
    let onChunkCompleted: () -> Void

    @State private var player: AVPlayer?
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var showingCaptions: Bool = true
    @State private var currentCaption: String = ""

    var body: some View {
        ZStack {
            // Background
            Color.black

            if let chunk = chunk {
                if let videoURL = chunk.videoURL {
                    // Video Player
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onAppear {
                            setupPlayer(url: videoURL)
                        }
                        .onChange(of: playbackState) { _, newState in
                            handlePlaybackStateChange(newState)
                        }
                } else {
                    // Fallback: Animated whiteboard with script content
                    animatedWhiteboardView
                }

                // Captions Overlay
                if showingCaptions, !currentCaption.isEmpty {
                    VStack {
                        Spacer()

                        Text(currentCaption)
                            .font(DesignTokens.Typography.bodyLarge)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.75))
                            )
                            .padding(.horizontal, 40)
                            .padding(.bottom, 100)
                    }
                }
            } else {
                // Loading state
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }

    // MARK: - Animated Whiteboard View
    private var animatedWhiteboardView: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.13),
                    Color(red: 0.05, green: 0.08, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 24) {
                // Title
                if let chunk = chunk {
                    Text(chunk.title)
                        .font(DesignTokens.Typography.displaySmall)
                        .foregroundColor(.white)
                        .textReadability()
                        .padding(.top, 60)
                }

                // Animated content
                if let scriptContent = chunk?.scriptContent {
                    ScrollView {
                        Text(scriptContent)
                            .font(DesignTokens.Typography.bodyLarge)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                    }
                    .frame(maxWidth: 800)
                }

                Spacer()
            }

            // Floating particles for visual interest
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.brand.opacity(0.3), DesignTokens.Colors.brand.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...60))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300)
                    )
                    .blur(radius: 10)
                    .opacity(0.4)
            }
        }
    }

    // MARK: - Player Setup

    private func setupPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Observe playback time
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            currentTime = time.seconds
            updateCaptions()
            checkCompletion()
        }

        // Get duration using modern async loading API
        Task {
            do {
                let assetDuration = try await playerItem.asset.load(.duration)
                let durationValue = assetDuration.seconds
                if durationValue.isFinite {
                    await MainActor.run {
                        self.duration = durationValue
                    }
                }
            } catch {
                print("⚠️ [Player] Failed to load duration: \(error.localizedDescription)")
            }
        }

        // Start playing if state is playing
        if playbackState == .playing {
            player?.play()
        }

        print("🎬 [Player] Setup complete for: \(url.lastPathComponent)")
    }

    private func handlePlaybackStateChange(_ newState: ClassroomViewState.PlaybackState) {
        switch newState {
        case .playing:
            player?.play()
            print("▶️ [Player] Playing")

        case .paused:
            player?.pause()
            print("⏸️ [Player] Paused")

        case .loading:
            player?.pause()
            print("⏳ [Player] Loading")

        case .completed:
            player?.pause()
            player?.seek(to: .zero)
            print("✅ [Player] Completed")
        }
    }

    private func updateCaptions() {
        guard let chunk = chunk, let scriptContent = chunk.scriptContent else { return }

        // Simple caption simulation - in production, use proper subtitle tracks
        // This would parse SRT/VTT files or use speech-to-text timestamps

        if currentTime < duration * 0.33 {
            currentCaption = scriptContent.components(separatedBy: ". ").first ?? ""
        } else if currentTime < duration * 0.66 {
            let sentences = scriptContent.components(separatedBy: ". ")
            currentCaption = sentences.count > 1 ? sentences[1] : ""
        } else {
            let sentences = scriptContent.components(separatedBy: ". ")
            currentCaption = sentences.count > 2 ? sentences[2] : ""
        }
    }

    private func checkCompletion() {
        guard let chunk = chunk else { return }

        // Check if chunk is completed (95% watched)
        if currentTime >= chunk.duration * 0.95 && playbackState == .playing {
            print("✅ [Player] Chunk completed")
            onChunkCompleted()
        }
    }
}

// MARK: - Avatar Overlay View

/// Floating AI avatar that appears during lessons
struct AvatarOverlayView: View {
    let mood: AvatarMood
    let isThinking: Bool
    let orientation: ClassroomViewState.ClassroomOrientation

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        VStack {
            if orientation == .horizontal {
                Spacer()
            }

            HStack {
                if orientation == .horizontal {
                    avatarView
                        .padding(.leading, 20)
                        .padding(.bottom, 120)

                    Spacer()
                } else {
                    Spacer()

                    avatarView
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                }
            }

            if orientation == .vertical {
                Spacer()
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            moodColor.opacity(0.4),
                            moodColor.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 15)
                .scaleEffect(scale)

            // Main avatar circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [moodColor, moodColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: moodColor.opacity(0.5), radius: 10)

            // Icon
            Image(systemName: moodIcon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotation))

            // Thinking indicator
            if isThinking {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var moodColor: Color {
        switch mood {
        case .neutral: return DesignTokens.Colors.primary
        case .friendly: return DesignTokens.Colors.brand
        case .excited: return DesignTokens.Colors.neonYellow
        case .supportive: return DesignTokens.Colors.success
        case .curious: return DesignTokens.Colors.neonOrange
        case .empathetic: return DesignTokens.Colors.neonPink
        case .thoughtful: return DesignTokens.Colors.neonPurple
        case .engaged: return DesignTokens.Colors.info
        case .thinking: return DesignTokens.Colors.neonBlue
        }
    }

    private var moodIcon: String {
        switch mood {
        case .neutral: return "circle.fill"
        case .friendly: return "sparkles"
        case .excited: return "star.fill"
        case .supportive: return "hand.thumbsup.fill"
        case .curious: return "questionmark.circle.fill"
        case .empathetic: return "heart.fill"
        case .thoughtful: return "brain.head.profile"
        case .engaged: return "eye.fill"
        case .thinking: return "lightbulb.fill"
        }
    }

    private func startAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            scale = 1.2
        }

        // Rotation for thinking state
        if isThinking {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview("Lecture Player") {
    LecturePlayerView(
        chunk: .mockChunk1,
        playbackState: .constant(.playing),
        onChunkCompleted: {}
    )
}

#Preview("Avatar Overlay") {
    ZStack {
        Color.black.ignoresSafeArea()

        AvatarOverlayView(
            mood: .friendly,
            isThinking: false,
            orientation: .horizontal
        )
    }
}
