//
//  VoiceSelectionViews.swift
//  LyoApp
//
//  Voice selection and customization system
//  Voice library, pitch/speed controls, audio preview
//  Created: October 10, 2025
//

import SwiftUI
import AVFoundation

// MARK: - Voice Types

struct VoiceOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let pitchDefault: Float
    let speedDefault: Float
    let tone: VoiceTone
    
    static func == (lhs: VoiceOption, rhs: VoiceOption) -> Bool {
        lhs.id == rhs.id
    }
}

enum VoiceTone: String {
    case friendly = "Friendly"
    case energetic = "Energetic"
    case calm = "Calm"
    case wise = "Wise"
    case playful = "Playful"
    case professional = "Professional"
    case cheerful = "Cheerful"
    case mysterious = "Mysterious"
    case confident = "Confident"
    case gentle = "Gentle"
    case robotic = "Robotic"
    case magical = "Magical"
}

// MARK: - Main Voice Selection View

struct VoiceSelectionView: View {
    @ObservedObject var avatar: Avatar3DModel
    @State private var selectedVoice: VoiceOption?
    @State private var isPlaying = false
    @State private var showAdvancedControls = false
    
    let voiceOptions: [VoiceOption] = [
        VoiceOption(name: "Alex", description: "Warm and friendly", icon: "person.wave.2.fill", pitchDefault: 1.0, speedDefault: 1.0, tone: .friendly),
        VoiceOption(name: "Riley", description: "Energetic and fun", icon: "bolt.fill", pitchDefault: 1.1, speedDefault: 1.2, tone: .energetic),
        VoiceOption(name: "Morgan", description: "Calm and soothing", icon: "leaf.fill", pitchDefault: 0.9, speedDefault: 0.9, tone: .calm),
        VoiceOption(name: "Sage", description: "Wise and thoughtful", icon: "book.fill", pitchDefault: 0.85, speedDefault: 0.85, tone: .wise),
        VoiceOption(name: "Casey", description: "Playful and silly", icon: "face.smiling.fill", pitchDefault: 1.2, speedDefault: 1.1, tone: .playful),
        VoiceOption(name: "Jordan", description: "Professional and clear", icon: "briefcase.fill", pitchDefault: 1.0, speedDefault: 1.0, tone: .professional),
        VoiceOption(name: "Sunny", description: "Cheerful and bright", icon: "sun.max.fill", pitchDefault: 1.15, speedDefault: 1.05, tone: .cheerful),
        VoiceOption(name: "Nova", description: "Mysterious and cool", icon: "moon.stars.fill", pitchDefault: 0.95, speedDefault: 0.95, tone: .mysterious),
        VoiceOption(name: "Phoenix", description: "Confident and bold", icon: "flame.fill", pitchDefault: 1.05, speedDefault: 1.0, tone: .confident),
        VoiceOption(name: "River", description: "Gentle and flowing", icon: "water.waves", pitchDefault: 0.92, speedDefault: 0.88, tone: .gentle),
        VoiceOption(name: "Pixel", description: "Robotic and digital", icon: "cpu.fill", pitchDefault: 1.3, speedDefault: 1.0, tone: .robotic),
        VoiceOption(name: "Luna", description: "Magical and dreamy", icon: "sparkles", pitchDefault: 1.1, speedDefault: 0.95, tone: .magical)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Voice Library
            VoiceLibraryGrid(
                voices: voiceOptions,
                selectedVoice: $selectedVoice,
                currentVoiceId: avatar.voiceId
            )
            
            // Voice Preview Player
            if let voice = selectedVoice {
                VoicePreviewPlayer(
                    voice: voice,
                    isPlaying: $isPlaying,
                    pitch: $avatar.voicePitch,
                    speed: $avatar.voiceSpeed
                )
            }
            
            // Voice Controls
            VoiceControlsPanel(
                pitch: $avatar.voicePitch,
                speed: $avatar.voiceSpeed,
                showAdvanced: $showAdvancedControls
            )
        }
        .onAppear {
            // Set initial selected voice
            let voiceId = avatar.voiceId // voiceId is non-optional String
            if let voice = voiceOptions.first(where: { $0.name == voiceId }) {
                selectedVoice = voice
            } else {
                selectedVoice = voiceOptions[0]
                avatar.voiceId = voiceOptions[0].name
            }
        }
        .onChange(of: selectedVoice) { _, newVoice in
            if let voice = newVoice {
                avatar.voiceId = voice.name
                avatar.voicePitch = voice.pitchDefault
                avatar.voiceSpeed = voice.speedDefault
            }
        }
    }
}

// MARK: - Voice Library Grid

struct VoiceLibraryGrid: View {
    let voices: [VoiceOption]
    @Binding var selectedVoice: VoiceOption?
    let currentVoiceId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Voice Library", systemImage: "waveform")
                .font(.headline)
            
            Text("Choose a voice that fits your personality")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(voices) { voice in
                    VoiceCard(
                        voice: voice,
                        isSelected: selectedVoice?.id == voice.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedVoice = voice
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct VoiceCard: View {
    let voice: VoiceOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? toneColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 100)
                    
                    VStack(spacing: 6) {
                        Image(systemName: voice.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(isSelected ? toneColor : .primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(toneColor)
                        }
                    }
                }
                
                VStack(spacing: 2) {
                    Text(voice.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .bold : .semibold)
                        .foregroundStyle(isSelected ? toneColor : .primary)
                    
                    Text(voice.tone.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var toneColor: Color {
        switch voice.tone {
        case .friendly: return .blue
        case .energetic: return .orange
        case .calm: return .green
        case .wise: return .purple
        case .playful: return .pink
        case .professional: return .indigo
        case .cheerful: return .yellow
        case .mysterious: return Color(red: 0.4, green: 0.2, blue: 0.6)
        case .confident: return .red
        case .gentle: return .mint
        case .robotic: return .gray
        case .magical: return Color(red: 0.7, green: 0.3, blue: 0.9)
        }
    }
}

// MARK: - Voice Preview Player

struct VoicePreviewPlayer: View {
    let voice: VoiceOption
    @Binding var isPlaying: Bool
    @Binding var pitch: Float
    @Binding var speed: Float
    
    @State private var synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Voice Preview", systemImage: "play.circle.fill")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Voice info
                HStack {
                    Image(systemName: voice.icon)
                        .font(.title2)
                        .foregroundStyle(toneColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(voice.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(voice.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(toneColor.opacity(0.1))
                .cornerRadius(12)
                
                // Preview text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\"Hello! This is how I sound. I'm ready to help you learn and grow!\"")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Play button
                Button(action: playPreview) {
                    HStack {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        Text(isPlaying ? "Stop Preview" : "Play Preview")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(toneColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
                .disabled(isPlaying)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var toneColor: Color {
        switch voice.tone {
        case .friendly: return .blue
        case .energetic: return .orange
        case .calm: return .green
        case .wise: return .purple
        case .playful: return .pink
        case .professional: return .indigo
        case .cheerful: return .yellow
        case .mysterious: return Color(red: 0.4, green: 0.2, blue: 0.6)
        case .confident: return .red
        case .gentle: return .mint
        case .robotic: return .gray
        case .magical: return Color(red: 0.7, green: 0.3, blue: 0.9)
        }
    }
    
    private func playPreview() {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        let utterance = AVSpeechUtterance(string: "Hello! This is how I sound. I'm ready to help you learn and grow!")
        
        // Apply pitch and speed
        utterance.pitchMultiplier = pitch
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * speed
        
        // Select appropriate voice based on tone
        if let availableVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { voice in
            voice.language.starts(with: "en")
        }) {
            utterance.voice = availableVoice
        }
        
        synthesizer.speak(utterance)
        
        // Stop playing after utterance completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isPlaying = false
        }
    }
}

// MARK: - Voice Controls Panel

struct VoiceControlsPanel: View {
    @Binding var pitch: Float
    @Binding var speed: Float
    @Binding var showAdvanced: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with toggle
            HStack {
                Label("Voice Settings", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Button(action: { withAnimation { showAdvanced.toggle() } }) {
                    Text(showAdvanced ? "Hide" : "Show")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            if showAdvanced {
                VStack(spacing: 20) {
                    // Pitch Control
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Pitch", systemImage: "waveform.path.ecg")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(String(format: "%.1fx", pitch))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Text("Low")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Slider(value: $pitch, in: 0.5...2.0, step: 0.1)
                                .tint(.purple)
                            
                            Text("High")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Reset button
                        Button(action: { withAnimation { pitch = 1.0 } }) {
                            Text("Reset to Default")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Divider()
                    
                    // Speed Control
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Speed", systemImage: "speedometer")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(String(format: "%.1fx", speed))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Text("Slow")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Slider(value: $speed, in: 0.5...2.0, step: 0.1)
                                .tint(.orange)
                            
                            Text("Fast")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Reset button
                        Button(action: { withAnimation { speed = 1.0 } }) {
                            Text("Reset to Default")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Divider()
                    
                    // Voice characteristics info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice Characteristics")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pitch")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(pitchDescription)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Divider()
                                .frame(height: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Speed")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(speedDescription)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .animation(.spring(response: 0.3), value: showAdvanced)
    }
    
    private var pitchDescription: String {
        switch pitch {
        case 0.5..<0.8: return "Very Low"
        case 0.8..<0.95: return "Low"
        case 0.95..<1.05: return "Normal"
        case 1.05..<1.3: return "High"
        case 1.3...2.0: return "Very High"
        default: return "Normal"
        }
    }
    
    private var speedDescription: String {
        switch speed {
        case 0.5..<0.8: return "Very Slow"
        case 0.8..<0.95: return "Slow"
        case 0.95..<1.05: return "Normal"
        case 1.05..<1.3: return "Fast"
        case 1.3...2.0: return "Very Fast"
        default: return "Normal"
        }
    }
}

// MARK: - Phoneme Mapping Helper (for future lip-sync)

enum Phoneme: String, CaseIterable {
    case silence = "silence"
    case aa = "AA" // father
    case ae = "AE" // cat
    case ah = "AH" // cut
    case ao = "AO" // dog
    case aw = "AW" // how
    case ay = "AY" // hide
    case b = "B"   // be
    case ch = "CH" // cheese
    case d = "D"   // dee
    case dh = "DH" // thee
    case eh = "EH" // Ed
    case er = "ER" // hurt
    case ey = "EY" // ate
    case f = "F"   // fee
    case g = "G"   // green
    case hh = "HH" // he
    case ih = "IH" // it
    case iy = "IY" // eat
    case jh = "JH" // gee
    case k = "K"   // key
    case l = "L"   // lee
    case m = "M"   // me
    case n = "N"   // knee
    case ng = "NG" // ping
    case ow = "OW" // oat
    case oy = "OY" // toy
    case p = "P"   // pee
    case r = "R"   // read
    case s = "S"   // sea
    case sh = "SH" // she
    case t = "T"   // tea
    case th = "TH" // theta
    case uh = "UH" // hood
    case uw = "UW" // two
    case v = "V"   // vee
    case w = "W"   // we
    case y = "Y"   // yield
    case z = "Z"   // zee
    case zh = "ZH" // seizure
    
    var mouthShape: PhonemeShape {
        switch self {
        case .silence: return .closed
        case .aa, .ao, .aw, .ow: return .open
        case .b, .m, .p: return .lips
        case .f, .v: return .teeth
        case .ch, .sh, .jh, .zh: return .rounded
        case .th, .dh: return .tongue
        default: return .neutral
        }
    }
}

enum PhonemeShape {
    case closed   // Mouth closed
    case neutral  // Slight opening
    case open     // Wide open for vowels
    case lips     // Lips pressed (B, M, P)
    case teeth    // Teeth showing (F, V)
    case rounded  // Rounded lips (SH, CH)
    case tongue   // Tongue visible (TH)
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            let avatar = Avatar3DModel()
            
            VoiceSelectionView(avatar: avatar)
        }
        .padding()
    }
}
