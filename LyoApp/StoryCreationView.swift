import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Story Creation Flow with Camera/Text Editor

struct StoryCreationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = StoryCameraManager()
    @StateObject private var storyCreationManager = StoryCreationManager()
    
    @State private var creationType: StoryCreationType = .camera
    @State private var showingPreview = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showTextEditor = false
    
    var onStoryCreated: ((StoryContent) -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showingPreview {
                // Preview before posting
                StoryPreviewView(
                    segments: storyCreationManager.segments,
                    onPost: {
                        Task {
                            await postStory()
                        }
                    },
                    onCancel: {
                        showingPreview = false
                    }
                )
            } else {
                // Creation Mode
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                    
                    Spacer()
                    
                    // Content Area based on type
                    contentArea
                    
                    Spacer()
                    
                    // Bottom Controls
                    bottomControls
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            cameraManager.checkPermissions()
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text("Create Story")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showingPreview = true }) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(storyCreationManager.canProceed ? .white : .gray)
            }
            .disabled(!storyCreationManager.canProceed)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Content Area
    @ViewBuilder
    private var contentArea: some View {
        switch creationType {
        case .camera:
            cameraView
        case .photo:
            photoPickerView
        case .text:
            textEditorView
        }
    }
    
    private var cameraView: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Camera Controls Overlay
            VStack {
                Spacer()
                
                HStack(spacing: 40) {
                    // Flash Toggle
                    Button(action: { cameraManager.toggleFlash() }) {
                        Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    // Capture Button
                    Button(action: { capturePhoto() }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    
                    // Flip Camera
                    Button(action: { cameraManager.flipCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var photoPickerView: some View {
        VStack {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Select Photo from Library")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        storyCreationManager.addPhotoSegment(image: uiImage)
                    }
                }
            }
        }
    }
    
    private var textEditorView: some View {
        StoryTextEditorView(manager: storyCreationManager)
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 30) {
            // Camera Mode
            CreationTypeButton(
                icon: "camera.fill",
                label: "Camera",
                isSelected: creationType == .camera
            ) {
                creationType = .camera
            }
            
            // Photo Library
            CreationTypeButton(
                icon: "photo.fill",
                label: "Photo",
                isSelected: creationType == .photo
            ) {
                creationType = .photo
            }
            
            // Text Story
            CreationTypeButton(
                icon: "textformat.size",
                label: "Text",
                isSelected: creationType == .text
            ) {
                creationType = .text
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    private func capturePhoto() {
        cameraManager.capturePhoto { image in
            if let image = image {
                storyCreationManager.addPhotoSegment(image: image)
            }
        }
    }
    
    private func postStory() async {
        do {
            if let story = try await storyCreationManager.createAndUploadStory() {
                await MainActor.run {
                    onStoryCreated?(story)
                    dismiss()
                }
            }
        } catch {
            print("Error posting story: \(error)")
        }
    }
}

// MARK: - Story Creation Type
enum StoryCreationType {
    case camera
    case photo
    case text
}

// MARK: - Creation Type Button
struct CreationTypeButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .black : .white)
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// MARK: - Story Text Editor View
struct StoryTextEditorView: View {
    @ObservedObject var manager: StoryCreationManager
    @State private var text: String = ""
    @State private var selectedBackgroundColor: String = "#6C5CE7"
    @State private var selectedTextColor: String = "#FFFFFF"
    
    let backgroundColors = [
        "#6C5CE7", "#A29BFE", "#FD79A8", "#FDCB6E", "#00B894",
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8",
        "#FF1493", "#FF69B4", "#FFB6C1", "#DDA0DD", "#9370DB"
    ]
    
    var body: some View {
        ZStack {
            // Background Color
            Color(hex: selectedBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Text Input
                TextEditor(text: $text)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: selectedTextColor))
                    .multilineTextAlignment(.center)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: 300)
                    .padding(.horizontal, 40)
                    .onChange(of: text) { newText in
                        manager.updateTextSegment(
                            text: newText,
                            backgroundColor: selectedBackgroundColor,
                            textColor: selectedTextColor
                        )
                    }
                
                // Color Pickers
                VStack(spacing: 20) {
                    // Background Colors
                    Text("Background Color")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(backgroundColors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedBackgroundColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedBackgroundColor = color
                                        manager.updateTextSegment(
                                            text: text,
                                            backgroundColor: color,
                                            textColor: selectedTextColor
                                        )
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Text Color Toggle
                    HStack(spacing: 20) {
                        Text("Text Color:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: {
                            selectedTextColor = "#FFFFFF"
                            manager.updateTextSegment(
                                text: text,
                                backgroundColor: selectedBackgroundColor,
                                textColor: "#FFFFFF"
                            )
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedTextColor == "#FFFFFF" ? 3 : 0)
                                )
                        }
                        
                        Button(action: {
                            selectedTextColor = "#000000"
                            manager.updateTextSegment(
                                text: text,
                                backgroundColor: selectedBackgroundColor,
                                textColor: "#000000"
                            )
                        }) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedTextColor == "#000000" ? 3 : 0)
                                )
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Story Preview View
struct StoryPreviewView: View {
    let segments: [StorySegment]
    let onPost: () -> Void
    let onCancel: () -> Void
    
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            // Preview Content
            if !segments.isEmpty {
                let segment = segments[currentIndex]
                
                Color(hex: segment.backgroundColor)
                    .ignoresSafeArea()
                
                VStack {
                    // Segment Preview
                    if segment.type == .text, let text = segment.text {
                        Text(text)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: segment.textColor ?? "#FFFFFF"))
                            .multilineTextAlignment(.center)
                            .padding(40)
                    } else if segment.type == .photo, let url = segment.mediaURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
            }
            
            // Controls
            VStack {
                // Top Bar
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Preview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onPost) {
                        Text("Post")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FF1493"), Color(hex: "#FF69B4")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Segment Navigation
                if segments.count > 1 {
                    HStack(spacing: 10) {
                        ForEach(0..<segments.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    currentIndex = index
                                }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Story Creation Manager
@MainActor
class StoryCreationManager: ObservableObject {
    @Published var segments: [StorySegment] = []
    @Published var isUploading = false
    
    private let apiService = StoriesAPIService.shared
    
    var canProceed: Bool {
        !segments.isEmpty
    }
    
    func addPhotoSegment(image: UIImage) {
        // Save image temporarily and create segment
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Create temporary URL
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            
            try? imageData.write(to: tempURL)
            
            let segment = StorySegment(
                type: .photo,
                mediaURL: tempURL,
                backgroundColor: "#000000",
                duration: 5.0
            )
            
            segments.append(segment)
        }
    }
    
    func updateTextSegment(text: String, backgroundColor: String, textColor: String) {
        // Remove existing text segment and add new one
        segments.removeAll { $0.type == .text }
        
        if !text.isEmpty {
            let segment = StorySegment(
                type: .text,
                backgroundColor: backgroundColor,
                duration: 5.0,
                text: text,
                textColor: textColor
            )
            
            segments.append(segment)
        }
    }
    
    func createAndUploadStory() async throws -> StoryContent? {
        guard !segments.isEmpty else { return nil }
        
        isUploading = true
        defer { isUploading = false }
        
        // Upload to backend
        let story = try await apiService.createStory(segments: segments)
        return story
    }
}

// MARK: - Camera Manager
@MainActor
class StoryCameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isFlashOn = false
    @Published var permissionGranted = false
    
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var captureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.permissionGranted = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        default:
            permissionGranted = false
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Setup camera input
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    currentDevice = device
                }
            } catch {
                print("Error setting up camera: \(error)")
            }
        }
        
        // Setup photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        Task {
            session.startRunning()
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func flipCamera() {
        session.beginConfiguration()
        
        // Remove current input
        if let input = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(input)
        }
        
        // Add opposite camera
        let newPosition: AVCaptureDevice.Position = currentDevice?.position == .back ? .front : .back
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    currentDevice = device
                }
            } catch {
                print("Error flipping camera: \(error)")
            }
        }
        
        session.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Photo Capture Delegate
extension StoryCameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                captureCompletion?(nil)
            }
            return
        }
        
        Task { @MainActor in
            captureCompletion?(image)
        }
    }
}
