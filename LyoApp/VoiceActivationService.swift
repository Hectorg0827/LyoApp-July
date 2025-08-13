import Foundation
import SwiftUI
import Combine

/// Global voice activation service for "Hey Lyo" hotword detection
@MainActor
class VoiceActivationService: ObservableObject {
    static let shared = VoiceActivationService()
    
    @Published var isLyoActivated = false
    @Published var isListening = false
    @Published var lastActivationTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 2.0 // Prevent rapid successive activations
    private weak var appState: AppState?
    private weak var webSocketService: LyoWebSocketService?
    
    init() {
        setupObservers()
    }
    
    // deinit removed to avoid main actor isolation issues
    
    private func setupObservers() {
        // Listen for app lifecycle changes
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.startListening()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopListening()
            }
            .store(in: &cancellables)
    }
    
    func startListening() {
        guard !isListening else { return }
        
        isListening = true
        print("🎤 Voice activation service started listening for 'Hey Lyo'")
        
        // In a real implementation, this would start the Speech framework
        // For now, we'll just simulate the service being active
    }
    
    func stopListening() {
        guard isListening else { return }
        
        isListening = false
        print("🎤 Voice activation service stopped listening")
    }
    
    func simulateActivation() {
        // Method to simulate "Hey Lyo" activation for testing
        handleLyoActivation()
    }
    
    private func handleLyoActivation() {
        let now = Date()
        
        // Debounce rapid activations
        if let lastActivation = lastActivationTime,
           now.timeIntervalSince(lastActivation) < debounceInterval {
            return
        }
        
        lastActivationTime = now
        isLyoActivated = true
        
        print("🎯 Hey Lyo detected! Activating AI assistant...")
        
        // Integrate with Avatar Companion system
        appState?.presentAvatar(with: "voice_activation")
        appState?.updateAvatarState(.listening)
        
        // Send activation event to WebSocket
        webSocketService?.sendContextualRequest(
            "Voice activation detected - user said 'Hey Lyo'",
            currentScreen: getCurrentScreen()
        )
        
        // Auto-reset after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLyoActivated = false
        }
    }
    
    func resetActivation() {
        isLyoActivated = false
    }
    
    // MARK: - Avatar Companion Integration
    
    func configure(appState: AppState, webSocketService: LyoWebSocketService) {
        self.appState = appState
        self.webSocketService = webSocketService
    }
    
    private func getCurrentScreen() -> String {
        guard let appState = appState else { return "unknown" }
        return appState.selectedTab.rawValue.lowercased()
    }
    
    // MARK: - Enhanced Voice Processing
    
    func processVoiceInput(_ transcript: String) {
        // Process continuous voice input for contextual awareness
        if transcript.lowercased().contains("hey lyo") || transcript.lowercased().contains("lyo") {
            handleLyoActivation()
        } else if !transcript.isEmpty {
            // Send contextual transcript to WebSocket
            webSocketService?.sendLiveTranscript(transcript)
        }
    }
    
    func handleVoiceError(_ error: Error) {
        print("🎤 Voice activation error: \(error)")
        appState?.handleError(error)
        isListening = false
    }
}
