import Foundation
import Speech
import SwiftUI
import AVFoundation

/// Enhanced speech recognizer for Avatar Companion with real-time streaming and context awareness
class VoiceRecognizer: ObservableObject {
    @Published var isListening = false
    @Published var transcript: String = ""
    @Published var hotwordDetected = false
    @Published var isStreamingActive = false
    @Published var lastError: Error?
    
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // Avatar Companion integration
    private weak var voiceActivationService: VoiceActivationService?
    private weak var webSocketService: LyoWebSocketService?
    private var audioStreamingTimer: Timer?
    
    func startListening() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else { return }
            DispatchQueue.main.async {
                self.isListening = true
                self.transcript = ""
                self.hotwordDetected = false
                self.startSession()
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        request?.endAudio()
        recognitionTask?.cancel()
        audioStreamingTimer?.invalidate()
        audioStreamingTimer = nil
        
        DispatchQueue.main.async {
            self.isListening = false
            self.isStreamingActive = false
        }
    }
    
    private func startSession() {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        
        // Enhanced audio processing with real-time streaming
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)
            
            // Stream audio data to WebSocket for real-time processing
            self?.streamAudioData(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isStreamingActive = true
        } catch {
            Task { @MainActor in
                self.handleError(error)
            }
            return
        }
        
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    self?.handleError(error)
                    return
                }
                
                guard let result = result else { return }
                let text = result.bestTranscription.formattedString
                
                self?.transcript = text
                self?.processTranscript(text)
            }
        }
    }
    
    // MARK: - Avatar Companion Integration
    
    func configure(voiceActivationService: VoiceActivationService, webSocketService: LyoWebSocketService) {
        self.voiceActivationService = voiceActivationService
        self.webSocketService = webSocketService
    }
    
    @MainActor
    private func processTranscript(_ text: String) {
        // Check for hotword detection
        if text.lowercased().contains("hey lyo") || text.lowercased().contains("hi lio") {
            hotwordDetected = true
        }
        
        // Process voice input through the activation service
        voiceActivationService?.processVoiceInput(text)
    }
    
    private func streamAudioData(_ buffer: AVAudioPCMBuffer) {
        guard isStreamingActive,
              let webSocketService = webSocketService else { return }
        
        // Convert audio buffer to Data for WebSocket streaming
        if let audioData = buffer.audioBufferData() {
            Task { @MainActor in
                webSocketService.sendAudioStream(audioData)
            }
        }
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        lastError = error
        voiceActivationService?.handleVoiceError(error)
        
        // Reset state on error
        isListening = false
        isStreamingActive = false
        
        print("🎤 VoiceRecognizer error: \(error)")
    }
    
    // MARK: - Enhanced Features
    
    func startContinuousListening() {
        // Start continuous listening for ambient voice detection
        startListening()
        
        // Set up periodic audio streaming
        audioStreamingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Timer helps maintain continuous streaming
        }
    }
    
    func pauseListening() {
        audioEngine.pause()
        isStreamingActive = false
    }
    
    func resumeListening() {
        do {
            try audioEngine.start()
            isStreamingActive = true
        } catch {
            Task { @MainActor in
                self.handleError(error)
            }
        }
    }
}

// MARK: - Audio Buffer Extensions

extension AVAudioPCMBuffer {
    func audioBufferData() -> Data? {
        let audioBuffer = audioBufferList.pointee.mBuffers
        let data = Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
        return data
    }
}
