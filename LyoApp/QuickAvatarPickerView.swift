import SwiftUI

// MARK: - Avatar Preset Models

/// Preset avatar configuration that users can select
struct AvatarPreset: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let type: AvatarType
    let primaryColor: CodableColor
    let secondaryColor: CodableColor
    let personality: String
    let emoji: String
    
    init(id: UUID = UUID(), name: String, type: AvatarType, primaryColor: Color, secondaryColor: Color, personality: String, emoji: String) {
        self.id = id
        self.name = name
        self.type = type
        self.primaryColor = CodableColor(color: primaryColor)
        self.secondaryColor = CodableColor(color: secondaryColor)
        self.personality = personality
        self.emoji = emoji
    }
    
    var primary: Color {
        primaryColor.color
    }
    
    var secondary: Color {
        secondaryColor.color
    }
}

/// Avatar type options
enum AvatarType: String, Codable {
    case human
    case cat
    case dog
    case owl
    case fox
    case robot
    
    var icon: String {
        switch self {
        case .human: return "person.fill"
        case .cat: return "cat.fill"
        case .dog: return "dog.fill"
        case .owl: return "bird.fill"
        case .fox: return "hare.fill"
        case .robot: return "cpu.fill"
        }
    }
    
    var description: String {
        switch self {
        case .human: return "Classic human companion"
        case .cat: return "Curious and independent"
        case .dog: return "Loyal and enthusiastic"
        case .owl: return "Wise and thoughtful"
        case .fox: return "Clever and adaptive"
        case .robot: return "Logical and systematic"
        }
    }
}

/// Codable wrapper for Color
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        // Extract components (simplified)
        if let components = color.cgColor?.components, components.count >= 3 {
            self.red = components[0]
            self.green = components[1]
            self.blue = components[2]
            self.opacity = components.count > 3 ? components[3] : 1.0
        } else {
            self.red = 0.5
            self.green = 0.5
            self.blue = 0.5
            self.opacity = 1.0
        }
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Preset Avatar Library

extension AvatarPreset {
    static let presets: [AvatarPreset] = [
        .init(
            name: "Lyo",
            type: .human,
            primaryColor: .blue,
            secondaryColor: .cyan,
            personality: "Friendly and encouraging",
            emoji: "😊"
        ),
        .init(
            name: "Luna",
            type: .cat,
            primaryColor: .purple,
            secondaryColor: .pink,
            personality: "Curious and independent",
            emoji: "🐱"
        ),
        .init(
            name: "Max",
            type: .dog,
            primaryColor: .orange,
            secondaryColor: .yellow,
            personality: "Enthusiastic and loyal",
            emoji: "🐕"
        ),
        .init(
            name: "Sage",
            type: .owl,
            primaryColor: .indigo,
            secondaryColor: .teal,
            personality: "Wise and patient",
            emoji: "🦉"
        ),
        .init(
            name: "Nova",
            type: .fox,
            primaryColor: .red,
            secondaryColor: .orange,
            personality: "Clever and playful",
            emoji: "🦊"
        ),
        .init(
            name: "Atlas",
            type: .robot,
            primaryColor: .gray,
            secondaryColor: .blue,
            personality: "Logical and systematic",
            emoji: "🤖"
        )
    ]
    
    static var defaultPreset: AvatarPreset {
        presets[0] // Lyo
    }
}

// MARK: - Avatar Customization Manager

@MainActor
public class AvatarCustomizationManager: ObservableObject {
    @Published var selectedPreset: AvatarPreset
    @Published var customName: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let avatarKey = "userSelectedAvatar"
    private let nameKey = "userAvatarName"
    
    init() {
        // Load saved avatar or use default
        if let data = userDefaults.data(forKey: avatarKey),
           let saved = try? JSONDecoder().decode(AvatarPreset.self, from: data) {
            self.selectedPreset = saved
        } else {
            self.selectedPreset = AvatarPreset.defaultPreset
        }
        
        // Load saved name
        self.customName = userDefaults.string(forKey: nameKey) ?? ""
    }
    
    func selectPreset(_ preset: AvatarPreset) {
        selectedPreset = preset
        save()
    }
    
    func setName(_ name: String) {
        customName = name
        userDefaults.set(name, forKey: nameKey)
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(selectedPreset) {
            userDefaults.set(data, forKey: avatarKey)
        }
    }
    
    var displayName: String {
        customName.isEmpty ? selectedPreset.name : customName
    }
}

// MARK: - Quick Avatar Picker View

struct QuickAvatarPickerView: View {
    @StateObject private var manager = AvatarCustomizationManager()
    @State private var showingNameField = false
    @State private var tempName = ""
    
    let onComplete: (AvatarPreset, String) -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Meet Your Learning Companion")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Choose a companion to guide your learning journey")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal)
                
                Spacer()
                
                // Preview of selected avatar
                VStack(spacing: 16) {
                    // Large preview
                    AvatarPreviewView(preset: manager.selectedPreset, size: .large)
                        .transition(.scale.combined(with: .opacity))
                    
                    VStack(spacing: 8) {
                        Text(showingNameField ? tempName.isEmpty ? manager.selectedPreset.name : tempName : manager.selectedPreset.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(manager.selectedPreset.personality)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 20)
                
                // Avatar selection grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(AvatarPreset.presets) { preset in
                            AvatarSelectionCard(
                                preset: preset,
                                isSelected: preset.id == manager.selectedPreset.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        manager.selectPreset(preset)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 140)
                .padding(.bottom, 20)
                
                // Name customization
                if showingNameField {
                    VStack(spacing: 12) {
                        Text("Give your companion a name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("Enter name", text: $tempName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if !showingNameField {
                        Button {
                            withAnimation {
                                showingNameField = true
                                tempName = manager.selectedPreset.name
                            }
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Customize Name")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Button {
                        if showingNameField && !tempName.isEmpty {
                            manager.setName(tempName)
                        }
                        onComplete(manager.selectedPreset, manager.displayName)
                    } label: {
                        HStack {
                            Text(showingNameField ? "Start Learning" : "Continue with \(manager.selectedPreset.name)")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [manager.selectedPreset.primary, manager.selectedPreset.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: manager.selectedPreset.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        onSkip()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 10)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Avatar Selection Card

struct AvatarSelectionCard: View {
    let preset: AvatarPreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [preset.primary, preset.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                        )
                        .shadow(color: preset.primary.opacity(0.5), radius: isSelected ? 15 : 5)
                    
                    Text(preset.emoji)
                        .font(.system(size: 40))
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(preset.name)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.white)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Avatar Preview View

struct AvatarPreviewView: View {
    let preset: AvatarPreset
    let size: PreviewSize
    
    @State private var isAnimating = false
    
    enum PreviewSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 160
            }
        }
        
        var emojiSize: CGFloat {
            switch self {
            case .small: return 30
            case .medium: return 50
            case .large: return 80
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [preset.primary.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: size.dimension * 0.5,
                        endRadius: size.dimension * 1.5
                    )
                )
                .frame(width: size.dimension * 2, height: size.dimension * 2)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            
            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [preset.primary, preset.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Avatar emoji/icon
            Text(preset.emoji)
                .font(.system(size: size.emojiSize))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.45),
                Color(red: 0.3, green: 0.15, blue: 0.5),
                Color(red: 0.15, green: 0.25, blue: 0.6)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuickAvatarPickerView(
        onComplete: { preset, name in
            print("Selected: \(preset.name), Custom name: \(name)")
        },
        onSkip: {
            print("Skipped")
        }
    )
}
