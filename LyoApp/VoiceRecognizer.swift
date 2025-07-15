import Foundation
import Speech
import SwiftUI

/// Simple speech recognizer for "Hey Lyo" or "Hi Lio" hotword detection and dictation.
class VoiceRecognizer: ObservableObject {
    @Published var isListening = false
    @Published var transcript: String = ""
    @Published var hotwordDetected = false
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
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
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    private func startSession() {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
            guard let result = result else { return }
            let text = result.bestTranscription.formattedString
            DispatchQueue.main.async {
                self.transcript = text
                if text.lowercased().contains("hey lyo") || text.lowercased().contains("hi lio") {
                    self.hotwordDetected = true
                }
            }
        }
    }
}
