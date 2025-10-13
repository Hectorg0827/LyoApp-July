//
//  AvatarAnimationSystem.swift
//  LyoApp
//
//  Avatar animation and expression system
//  Facial expressions, idle animations, lip-sync
//  Created: October 10, 2025
//

import SwiftUI
import SceneKit
import AVFoundation

// MARK: - Facial Expressions

enum FacialExpression: String, CaseIterable, Identifiable {
    case neutral = "Neutral"
    case happy = "Happy"
    case sad = "Sad"
    case excited = "Excited"
    case angry = "Angry"
    case surprised = "Surprised"
    case thinking = "Thinking"
    case worried = "Worried"
    case playful = "Playful"
    case sleepy = "Sleepy"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .neutral: return "face.dashed"
        case .happy: return "face.smiling"
        case .sad: return "face.frowning"
        case .excited: return "star.circle.fill"
        case .angry: return "exclamationmark.triangle.fill"
        case .surprised: return "exclamationmark.circle.fill"
        case .thinking: return "brain.head.profile"
        case .worried: return "cloud.fill"
        case .playful: return "face.winking"
        case .sleepy: return "moon.zzz.fill"
        }
    }
    
    var description: String {
        switch self {
        case .neutral: return "Calm and relaxed"
        case .happy: return "Big smile!"
        case .sad: return "Feeling down"
        case .excited: return "Super energetic!"
        case .angry: return "Not happy"
        case .surprised: return "Wow!"
        case .thinking: return "Deep in thought"
        case .worried: return "A bit nervous"
        case .playful: return "Fun and silly"
        case .sleepy: return "Need some rest"
        }
    }
    
    var color: Color {
        switch self {
        case .neutral: return .gray
        case .happy: return .yellow
        case .sad: return .blue
        case .excited: return .orange
        case .angry: return .red
        case .surprised: return .purple
        case .thinking: return .indigo
        case .worried: return .mint
        case .playful: return .pink
        case .sleepy: return Color(red: 0.4, green: 0.3, blue: 0.6)
        }
    }
}

// MARK: - Blend Shape Targets

struct BlendShapeWeights {
    var eyeBlinkLeft: Float = 0.0
    var eyeBlinkRight: Float = 0.0
    var eyeWideLeft: Float = 0.0
    var eyeWideRight: Float = 0.0
    var browInnerUp: Float = 0.0
    var browDown: Float = 0.0
    var mouthSmileLeft: Float = 0.0
    var mouthSmileRight: Float = 0.0
    var mouthFrownLeft: Float = 0.0
    var mouthFrownRight: Float = 0.0
    var mouthOpen: Float = 0.0
    var mouthPucker: Float = 0.0
    var cheekPuff: Float = 0.0
    
    static func forExpression(_ expression: FacialExpression) -> BlendShapeWeights {
        var weights = BlendShapeWeights()
        
        switch expression {
        case .neutral:
            // All defaults (0.0)
            break
            
        case .happy:
            weights.mouthSmileLeft = 0.8
            weights.mouthSmileRight = 0.8
            weights.eyeBlinkLeft = 0.2
            weights.eyeBlinkRight = 0.2
            weights.browInnerUp = 0.3
            
        case .sad:
            weights.mouthFrownLeft = 0.7
            weights.mouthFrownRight = 0.7
            weights.browDown = 0.5
            weights.eyeBlinkLeft = 0.3
            weights.eyeBlinkRight = 0.3
            
        case .excited:
            weights.mouthSmileLeft = 1.0
            weights.mouthSmileRight = 1.0
            weights.mouthOpen = 0.5
            weights.eyeWideLeft = 0.8
            weights.eyeWideRight = 0.8
            weights.browInnerUp = 0.8
            
        case .angry:
            weights.browDown = 0.9
            weights.mouthFrownLeft = 0.4
            weights.mouthFrownRight = 0.4
            
        case .surprised:
            weights.eyeWideLeft = 1.0
            weights.eyeWideRight = 1.0
            weights.browInnerUp = 1.0
            weights.mouthOpen = 0.7
            
        case .thinking:
            weights.browDown = 0.3
            weights.mouthPucker = 0.2
            weights.eyeBlinkLeft = 0.1
            
        case .worried:
            weights.browInnerUp = 0.7
            weights.browDown = 0.3
            weights.mouthFrownLeft = 0.3
            weights.mouthFrownRight = 0.3
            
        case .playful:
            weights.mouthSmileLeft = 0.6
            weights.mouthSmileRight = 0.3
            weights.eyeBlinkRight = 0.5
            weights.cheekPuff = 0.2
            
        case .sleepy:
            weights.eyeBlinkLeft = 0.7
            weights.eyeBlinkRight = 0.7
            weights.mouthOpen = 0.2
            weights.browDown = 0.4
        }
        
        return weights
    }
}

// MARK: - Animation Controller

class AvatarAnimationController: ObservableObject {
    @Published var currentExpression: FacialExpression = .neutral
    @Published var isIdleAnimationEnabled: Bool = true
    @Published var isLipSyncEnabled: Bool = false
    
    private var blinkTimer: Timer?
    private var breatheTimer: Timer?
    private weak var avatarNode: SCNNode?
    
    init() {
        startIdleAnimations()
    }
    
    deinit {
        stopIdleAnimations()
    }
    
    // MARK: - Setup
    
    func attachToAvatar(_ node: SCNNode) {
        self.avatarNode = node
        applyExpression(currentExpression, animated: false)
    }
    
    // MARK: - Expression Control
    
    func setExpression(_ expression: FacialExpression, animated: Bool = true) {
        currentExpression = expression
        applyExpression(expression, animated: animated)
    }
    
    private func applyExpression(_ expression: FacialExpression, animated: Bool) {
        guard let avatarNode = avatarNode else { return }
        
        let weights = BlendShapeWeights.forExpression(expression)
        let duration: TimeInterval = animated ? 0.3 : 0.0
        
        // Apply blend shapes with animation
        applyBlendShapes(to: avatarNode, weights: weights, duration: duration)
    }
    
    private func applyBlendShapes(to node: SCNNode, weights: BlendShapeWeights, duration: TimeInterval) {
        // In a production app, these would map to actual morph targets
        // For now, we'll animate node transforms to simulate expressions
        
        // Simulate mouth movement
        if let mouthNode = node.childNode(withName: "mouth", recursively: true) {
            let mouthScale = 1.0 + (weights.mouthOpen * 0.3)
            let action = SCNAction.scale(to: CGFloat(mouthScale), duration: duration)
            action.timingMode = .easeInEaseOut
            mouthNode.runAction(action)
        }
        
        // Simulate eye movement
        if let leftEyeNode = node.childNode(withName: "leftEye", recursively: true) {
            let eyeScale = 1.0 - weights.eyeBlinkLeft
            let action = SCNAction.scale(to: CGFloat(eyeScale), duration: duration)
            action.timingMode = .easeInEaseOut
            leftEyeNode.runAction(action)
        }
        
        if let rightEyeNode = node.childNode(withName: "rightEye", recursively: true) {
            let eyeScale = 1.0 - weights.eyeBlinkRight
            let action = SCNAction.scale(to: CGFloat(eyeScale), duration: duration)
            action.timingMode = .easeInEaseOut
            rightEyeNode.runAction(action)
        }
    }
    
    // MARK: - Idle Animations
    
    func startIdleAnimations() {
        guard isIdleAnimationEnabled else { return }
        
        // Blinking animation (every 3-5 seconds)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...5), repeats: true) { [weak self] _ in
            self?.performBlink()
        }
        
        // Breathing animation (subtle continuous)
        breatheTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.performBreathing()
        }
    }
    
    func stopIdleAnimations() {
        blinkTimer?.invalidate()
        breatheTimer?.invalidate()
        blinkTimer = nil
        breatheTimer = nil
    }
    
    private func performBlink() {
        guard let avatarNode = avatarNode else { return }
        
        // Quick blink animation
        let blinkDown = SCNAction.scale(to: 0.1, duration: 0.1)
        let blinkUp = SCNAction.scale(to: 1.0, duration: 0.1)
        let blinkSequence = SCNAction.sequence([blinkDown, blinkUp])
        
        if let leftEyeNode = avatarNode.childNode(withName: "leftEye", recursively: true) {
            leftEyeNode.runAction(blinkSequence)
        }
        
        if let rightEyeNode = avatarNode.childNode(withName: "rightEye", recursively: true) {
            rightEyeNode.runAction(blinkSequence)
        }
        
        // Schedule next blink
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...5), repeats: false) { [weak self] _ in
            self?.performBlink()
        }
    }
    
    private func performBreathing() {
        guard let avatarNode = avatarNode, isIdleAnimationEnabled else { return }
        
        // Subtle breathing motion (body scale)
        let time = Date().timeIntervalSince1970
        let breathScale = 1.0 + (sin(time * 0.5) * 0.02) // ±2% scale
        
        if let bodyNode = avatarNode.childNode(withName: "body", recursively: true) {
            bodyNode.scale.y = Float(breathScale)
        }
    }
    
    // MARK: - Lip Sync
    
    func startLipSync(for utterance: AVSpeechUtterance) {
        isLipSyncEnabled = true
        
        // In production, use AVSpeechSynthesizerDelegate to sync with actual speech
        // For now, simulate with random mouth movements
        simulateLipSync(duration: Double(utterance.speechString.count) * 0.1)
    }
    
    func stopLipSync() {
        isLipSyncEnabled = false
        // Return mouth to neutral
        if let avatarNode = avatarNode {
            let neutralWeights = BlendShapeWeights.forExpression(.neutral)
            applyBlendShapes(to: avatarNode, weights: neutralWeights, duration: 0.2)
        }
    }
    
    private func simulateLipSync(duration: TimeInterval) {
        guard isLipSyncEnabled, let avatarNode = avatarNode else { return }
        
        // Simulate phoneme-based mouth movements
        let phonemeSequence = generatePhonemeSequence(duration: duration)
        
        var currentTime: TimeInterval = 0.0
        for (phoneme, phonemeDuration) in phonemeSequence {
            let delay = currentTime
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard self?.isLipSyncEnabled == true else { return }
                self?.applyPhoneme(phoneme, to: avatarNode, duration: phonemeDuration)
            }
            
            currentTime += phonemeDuration
        }
    }
    
    private func generatePhonemeSequence(duration: TimeInterval) -> [(Phoneme, TimeInterval)] {
        // Simplified phoneme generation
        // In production, use speech recognition or phoneme analysis
        let phonemes: [Phoneme] = [.aa, .eh, .ow, .m, .s, .t, .iy, .uh]
        let phonemeCount = Int(duration / 0.15)
        
        var sequence: [(Phoneme, TimeInterval)] = []
        for _ in 0..<phonemeCount {
            let phoneme = phonemes.randomElement() ?? .aa
            let duration = Double.random(in: 0.1...0.2)
            sequence.append((phoneme, duration))
        }
        
        return sequence
    }
    
    private func applyPhoneme(_ phoneme: Phoneme, to node: SCNNode, duration: TimeInterval) {
        let mouthShape = phoneme.mouthShape
        
        var weights = BlendShapeWeights()
        
        switch mouthShape {
        case .closed:
            weights.mouthOpen = 0.0
            
        case .neutral:
            weights.mouthOpen = 0.2
            
        case .open:
            weights.mouthOpen = 0.8
            
        case .lips:
            weights.mouthPucker = 0.6
            weights.mouthOpen = 0.0
            
        case .teeth:
            weights.mouthOpen = 0.4
            weights.mouthSmileLeft = 0.3
            weights.mouthSmileRight = 0.3
            
        case .rounded:
            weights.mouthPucker = 0.8
            weights.mouthOpen = 0.3
            
        case .tongue:
            weights.mouthOpen = 0.5
        }
        
        applyBlendShapes(to: node, weights: weights, duration: duration)
    }
}

// MARK: - Expression Test View

struct ExpressionTestView: View {
    @ObservedObject var animationController: AvatarAnimationController
    @ObservedObject var avatar: Avatar3DModel
    
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        VStack(spacing: 20) {
            // Expression selector
            VStack(alignment: .leading, spacing: 12) {
                Label("Test Expressions", systemImage: "face.smiling")
                    .font(.headline)
                
                Text("Tap an expression to see your avatar animate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(FacialExpression.allCases) { expression in
                        ExpressionButton(
                            expression: expression,
                            isSelected: animationController.currentExpression == expression
                        ) {
                            withAnimation {
                                animationController.setExpression(expression, animated: true)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            
            // Animation controls
            VStack(alignment: .leading, spacing: 16) {
                Label("Animation Settings", systemImage: "gearshape.fill")
                    .font(.headline)
                
                Toggle(isOn: $animationController.isIdleAnimationEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Idle Animations")
                            .font(.subheadline)
                        Text("Blinking and breathing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: animationController.isIdleAnimationEnabled) { _, isEnabled in
                    if isEnabled {
                        animationController.startIdleAnimations()
                    } else {
                        animationController.stopIdleAnimations()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

struct ExpressionButton: View {
    let expression: FacialExpression
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? expression.color.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 80)
                    
                    VStack(spacing: 4) {
                        Image(systemName: expression.icon)
                            .font(.system(size: 30))
                            .foregroundStyle(isSelected ? expression.color : .primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(expression.color)
                        }
                    }
                }
                
                Text(expression.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? expression.color : .primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lip Sync Demo View

struct LipSyncDemoView: View {
    @ObservedObject var animationController: AvatarAnimationController
    @ObservedObject var avatar: Avatar3DModel
    @State private var isPlaying = false
    
    private let synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Lip Sync Demo", systemImage: "waveform.and.mic")
                .font(.headline)
            
            Text("Watch your avatar's mouth move as they speak!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                // Sample phrases
                ForEach(samplePhrases, id: \.self) { phrase in
                    Button(action: { playPhrase(phrase) }) {
                        HStack {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            Text(phrase)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    .disabled(isPlaying)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private let samplePhrases = [
        "Hello! Nice to meet you!",
        "I'm excited to learn with you!",
        "Let's explore something new today!",
        "You're doing a great job!"
    ]
    
    private func playPhrase(_ phrase: String) {
        isPlaying = true
        
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = avatar.voiceSpeed * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = avatar.voicePitch
        
        animationController.startLipSync(for: utterance)
        synthesizer.speak(utterance)
        
        // Stop after duration
        let duration = Double(phrase.count) * 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            animationController.stopLipSync()
            isPlaying = false
        }
    }
}

// MARK: - Combined Animation View

struct AvatarAnimationView: View {
    @ObservedObject var avatar: Avatar3DModel
    @StateObject private var animationController = AvatarAnimationController()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Expression test
                ExpressionTestView(
                    animationController: animationController,
                    avatar: avatar
                )
                
                // Lip sync demo
                LipSyncDemoView(
                    animationController: animationController,
                    avatar: avatar
                )
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    AvatarAnimationView(avatar: Avatar3DModel())
}
