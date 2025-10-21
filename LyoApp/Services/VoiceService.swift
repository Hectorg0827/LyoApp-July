import Foundation
import Speech
import AVFoundation
import Combine
import os.log

// MARK: - Voice Service
@MainActor
class VoiceService: NSObject, ObservableObject {
    static let shared = VoiceService()
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isRecognitionAvailable = false
    @Published var transcribedText = ""
    @Published var isSpeaking = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "com.lyo.app", category: "VoiceService")
    
    // MARK: - Callback Closures
    var onTranscriptionComplete: ((String) -> Void)?
    var onSpeechComplete: (() -> Void)?
    
    override init() {
        super.init()
        setupSpeechRecognition()
        setupTextToSpeech()
    }
    
    // MARK: - Setup Methods
    private func setupSpeechRecognition() {
        speechRecognizer?.delegate = self
        isRecognitionAvailable = speechRecognizer?.isAvailable ?? false
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    private func setupTextToSpeech() {
        synthesizer.delegate = self
    }
    
    // MARK: - Permission Methods
    func requestSpeechPermission() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    self.logger.info("🎤 Speech authorization status: \(status.rawValue)")
                    continuation.resume()
                }
            }
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.logger.info("🎤 Microphone permission: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Speech Recognition
    func startListening() async throws {
        guard !isListening else { return }
        
        // Check permissions
        if authorizationStatus != .authorized {
            await requestSpeechPermission()
        }
        
        guard authorizationStatus == .authorized else {
            throw VoiceError.speechNotAuthorized
        }
        
        let microphoneGranted = await requestMicrophonePermission()
        guard microphoneGranted else {
            throw VoiceError.microphoneNotAuthorized
        }
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        transcribedText = ""
        lastError = nil
        
        logger.info("🎤 Started listening for speech")
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self.logger.info("🎤 Final transcription: \(self.transcribedText)")
                        self.stopListening()
                        self.onTranscriptionComplete?(self.transcribedText)
                    }
                }
                
                if let error = error {
                    self.logger.error("❌ Speech recognition error: \(error.localizedDescription)")
                    self.lastError = error
                    self.stopListening()
                }
            }
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        
        logger.info("🎤 Stopped listening")
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Text to Speech
    func speak(_ text: String, voice: AVSpeechSynthesisVoice? = nil) {
        guard !text.isEmpty else { return }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.volume = 0.8
        utterance.pitchMultiplier = 1.0
        
        // Use a pleasant voice if available
        if let voice = voice ?? AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        isSpeaking = true
        logger.info("🔊 Starting to speak: \(text.prefix(50))...")
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            logger.info("🔊 Stopped speaking")
        }
    }
    
    // MARK: - Utility Methods
    func isAvailable() -> Bool {
        return isRecognitionAvailable && authorizationStatus == .authorized
    }
    
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension VoiceService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isRecognitionAvailable = available
        logger.info("🎤 Speech recognizer availability changed: \(available)")
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        logger.info("🔊 Speech synthesis started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        logger.info("🔊 Speech synthesis finished")
        onSpeechComplete?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        logger.info("🔊 Speech synthesis cancelled")
    }
}

// MARK: - Voice Errors
enum VoiceError: LocalizedError {
    case speechNotAuthorized
    case microphoneNotAuthorized
    case recognitionRequestFailed
    case audioEngineError
    
    var errorDescription: String? {
        switch self {
        case .speechNotAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .microphoneNotAuthorized:
            return "Microphone access not authorized. Please enable in Settings."
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request."
        case .audioEngineError:
            return "Audio engine error occurred."
        }
    }
}

// MARK: - Voice Button Component
import SwiftUI

struct VoiceButton: View {
    @StateObject private var voiceService = VoiceService.shared
    @State private var isPressed = false
    let onTranscription: (String) -> Void
    
    var body: some View {
        Button(action: {
            if voiceService.isListening {
                voiceService.stopListening()
            } else {
                startListening()
            }
        }) {
            Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(voiceService.isListening ? Color.red : Color.blue)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0) {
            // On press
            withAnimation {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }
        .onAppear {
            voiceService.onTranscriptionComplete = onTranscription
        }
    }
    
    private func startListening() {
        Task {
            do {
                try await voiceService.startListening()
            } catch {
                print("Failed to start listening: \(error)")
            }
        }
    }
}