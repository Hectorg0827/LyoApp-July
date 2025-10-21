import SwiftUI
import AVFoundation
import AVKit
import Photos

// MARK: - Video Creation Manager

@MainActor
class VideoCreationManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedDuration: TimeInterval = 0
    @Published var recordedVideoURL: URL?
    @Published var captureSession: AVCaptureSession?
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var currentCamera: AVCaptureDevice.Position = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var errorMessage: String?
    @Published var isProcessing = false
    
    private var movieOutput: AVCaptureMovieFileOutput?
    private var recordingTimer: Timer?
    private let maxRecordingDuration: TimeInterval = 60.0 // 60 seconds max
    
    override init() {
        super.init()
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() async throws {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        // Request camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                throw CameraError.permissionDenied
            }
        } else if status != .authorized {
            throw CameraError.permissionDenied
        }
        
        // Get camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera) else {
            throw CameraError.noCameraAvailable
        }
        
        // Add video input
        let videoInput = try AVCaptureDeviceInput(device: camera)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            throw CameraError.cannotAddInput
        }
        
        // Request microphone permission
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard granted else {
                throw CameraError.microphonePermissionDenied
            }
        } else if audioStatus != .authorized {
            throw CameraError.microphonePermissionDenied
        }
        
        // Add audio input
        if let microphone = AVCaptureDevice.default(for: .audio) {
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
        }
        
        // Configure movie output
        let output = AVCaptureMovieFileOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            movieOutput = output
            
            // Configure video stabilization
            if let connection = output.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        } else {
            throw CameraError.cannotAddOutput
        }
        
        await MainActor.run {
            self.captureSession = session
        }
        
        // Start session on background thread
        Task.detached { [weak self] in
            session.startRunning()
            
            // Create preview layer
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            
            await MainActor.run {
                self?.previewLayer = preview
            }
        }
    }
    
    // MARK: - Recording Controls
    
    func startRecording() {
        guard let movieOutput = movieOutput, !isRecording else { return }
        
        // Generate temporary file URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "video_\(Date().timeIntervalSince1970).mov"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // Start recording
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
        recordedDuration = 0
        
        // Start timer for duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.recordedDuration += 0.1
                
                // Auto-stop at max duration
                if self.recordedDuration >= self.maxRecordingDuration {
                    self.stopRecording()
                }
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func stopRecording() {
        guard let movieOutput = movieOutput, isRecording else { return }
        
        movieOutput.stopRecording()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Camera Controls
    
    func flipCamera() async throws {
        guard let session = captureSession else { return }
        
        session.beginConfiguration()
        
        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // Switch camera position
        currentCamera = currentCamera == .back ? .front : .back
        
        // Add new camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera) else {
            session.commitConfiguration()
            throw CameraError.noCameraAvailable
        }
        
        let videoInput = try AVCaptureDeviceInput(device: camera)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Re-add audio
        if let microphone = AVCaptureDevice.default(for: .audio) {
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
        }
        
        session.commitConfiguration()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func toggleFlash() async throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera) else {
            return
        }
        
        if device.hasFlash {
            try device.lockForConfiguration()
            flashMode = flashMode == .off ? .on : .off
            device.flashMode = flashMode
            device.unlockForConfiguration()
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Save to Camera Roll
    
    func saveToCameraRoll(url: URL) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard newStatus == .authorized else {
                throw CameraError.photoLibraryPermissionDenied
            }
        } else if status != .authorized {
            throw CameraError.photoLibraryPermissionDenied
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoCreationManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.recordedVideoURL = outputFileURL
            }
        }
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case permissionDenied
    case microphonePermissionDenied
    case photoLibraryPermissionDenied
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied. Please enable in Settings."
        case .microphonePermissionDenied:
            return "Microphone permission denied. Please enable in Settings."
        case .photoLibraryPermissionDenied:
            return "Photo Library permission denied. Please enable in Settings."
        case .noCameraAvailable:
            return "No camera available on this device."
        case .cannotAddInput:
            return "Cannot add camera input."
        case .cannotAddOutput:
            return "Cannot add video output."
        }
    }
}

// MARK: - Video Creation Flow View

struct VideoCreationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = VideoCreationManager()
    @State private var showPreview = false
    @State private var showPostCreation = false
    @State private var showError = false
    
    var onVideoCreated: ((VideoPost) -> Void)?
    
    var body: some View {
        ZStack {
            if !showPreview && !showPostCreation {
                // Camera recording view
                CameraRecordingView(manager: manager) {
                    showPreview = true
                }
            } else if showPreview && !showPostCreation {
                // Video preview
                VideoPreviewView(
                    videoURL: manager.recordedVideoURL!,
                    onRetake: {
                        showPreview = false
                        manager.recordedVideoURL = nil
                    },
                    onNext: {
                        showPostCreation = true
                    }
                )
            } else if showPostCreation {
                // Post creation form
                PostCreationView(
                    videoURL: manager.recordedVideoURL!,
                    duration: manager.recordedDuration,
                    onPost: { videoPost in
                        onVideoCreated?(videoPost)
                        dismiss()
                    },
                    onCancel: {
                        showPostCreation = false
                    }
                )
            }
        }
        .onAppear {
            Task {
                do {
                    try await manager.setupCamera()
                } catch {
                    manager.errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
        .onDisappear {
            manager.cleanup()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(manager.errorMessage ?? "Unknown error")
        }
    }
}

// MARK: - Camera Recording View

struct CameraRecordingView: View {
    @ObservedObject var manager: VideoCreationManager
    @Environment(\.dismiss) private var dismiss
    let onRecordingComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera preview
            CameraPreviewView(previewLayer: manager.previewLayer)
                .ignoresSafeArea()
            
            VStack {
                // Top controls
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    if manager.currentCamera == .back {
                        Button(action: {
                            Task {
                                try? await manager.toggleFlash()
                            }
                        }) {
                            Image(systemName: manager.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(manager.flashMode == .on ? .yellow : .white)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Recording indicator and timer
                if manager.isRecording {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            
                            Text(formatDuration(manager.recordedDuration))
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: geometry.size.width * CGFloat(manager.recordedDuration / 60.0), height: 4)
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // Bottom controls
                HStack(spacing: 60) {
                    // Flip camera
                    Button(action: {
                        Task {
                            try? await manager.flipCamera()
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                    }
                    .disabled(manager.isRecording)
                    .opacity(manager.isRecording ? 0.3 : 1.0)
                    
                    // Record button
                    Button(action: {
                        if manager.isRecording {
                            manager.stopRecording()
                            // Wait a moment for file to be written, then show preview
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if manager.recordedVideoURL != nil {
                                    onRecordingComplete()
                                }
                            }
                        } else {
                            manager.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 6)
                                .frame(width: 80, height: 80)
                            
                            if manager.isRecording {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 32, height: 32)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 68, height: 68)
                            }
                        }
                    }
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 60, height: 60)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Camera Preview UIView Wrapper

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = previewLayer else { return }
        
        // Remove existing preview layers
        uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        previewLayer.frame = uiView.bounds
        uiView.layer.addSublayer(previewLayer)
    }
}

// MARK: - Video Preview View

struct VideoPreviewView: View {
    let videoURL: URL
    let onRetake: () -> Void
    let onNext: () -> Void
    
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                        
                        // Loop video
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player.currentItem,
                            queue: .main
                        ) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
            }
            
            VStack {
                Spacer()
                
                // Bottom buttons
                HStack(spacing: 20) {
                    Button(action: onRetake) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Retake")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                    
                    Button(action: onNext) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Post Creation View

struct PostCreationView: View {
    let videoURL: URL
    let duration: TimeInterval
    let onPost: (VideoPost) -> Void
    let onCancel: () -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var hashtagInput = ""
    @State private var hashtags: [String] = []
    @State private var soundName = "Original Sound"
    @State private var player: AVPlayer?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Video thumbnail preview
                        HStack(spacing: 16) {
                            if let player = player {
                                VideoPlayer(player: player)
                                    .frame(width: 100, height: 177)
                                    .cornerRadius(12)
                                    .onAppear {
                                        player.play()
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Duration: \(formatDuration(duration))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                
                                Text("Sound: \(soundName)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("Add a catchy title...", text: $title)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        
                        // Description field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        
                        // Hashtags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hashtags")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Add hashtag...", text: $hashtagInput)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                                
                                Button(action: addHashtag) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                .disabled(hashtagInput.isEmpty)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            
                            if !hashtags.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(hashtags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.blue)
                                            
                                            Button(action: { removeHashtag(tag) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Loading overlay
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Posting your video...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        postVideo()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
        }
    }
    
    private func addHashtag() {
        let cleaned = hashtagInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        if !cleaned.isEmpty && !hashtags.contains(cleaned) {
            hashtags.append(cleaned)
            hashtagInput = ""
        }
    }
    
    private func removeHashtag(_ tag: String) {
        hashtags.removeAll { $0 == tag }
    }
    
    private func postVideo() {
        isSaving = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create video post
            let currentUser = User(
                id: UUID(),
                username: "currentuser",
                displayName: "Current User",
                email: "user@example.com",
                profileImageURL: nil,
                bio: "Content creator",
                followerCount: 0,
                followingCount: 0,
                postCount: 0,
                isFollowing: false,
                joinDate: Date()
            )
            
            let videoPost = VideoPost(
                id: UUID(),
                creator: currentUser,
                videoURL: videoURL,
                thumbnailURL: nil,
                title: title,
                description: description.isEmpty ? nil : description,
                hashtags: hashtags,
                soundName: soundName,
                soundURL: nil,
                duration: duration,
                createdAt: Date(),
                viewCount: 0,
                engagement: VideoEngagement(likes: 0, comments: 0, shares: 0, saves: 0, isLiked: false),
                isSaved: false
            )
            
            isSaving = false
            onPost(videoPost)
        }
    }
}

// MARK: - Flow Layout for Hashtags

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            content()
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > geometry.size.width {
                        width = 0
                        height -= dimension.height + spacing
                    }
                    let result = width
                    if dimension.width == 0 {
                        width = 0
                    } else {
                        width -= dimension.width + spacing
                    }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if width == 0 {
                        height = 0
                    }
                    return result
                }
        }
    }
}

// MARK: - Helper Functions

private func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
}
