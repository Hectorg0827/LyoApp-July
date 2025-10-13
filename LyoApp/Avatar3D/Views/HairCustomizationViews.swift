//
//  HairCustomizationViews.swift
//  LyoApp
//
//  Comprehensive hair styling system
//  15+ styles, color picker, highlights, facial hair
//  Created: October 10, 2025
//

import SwiftUI

// MARK: - Main Hair Customization View

struct HairCustomizationView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Hair Style Grid
            HairStyleGrid(selectedStyle: $avatar.hair.style)
            
            // Hair Color Picker
            if avatar.hair.style != .bald {
                HairColorPicker(
                    color: Binding(
                        get: { avatar.hair.color.color },
                        set: { newColor in
                            // Find the closest HairColor to the selected Color
                            avatar.hair.color = HairColor.allCases.min(by: { color1, color2 in
                                colorDistance(color1.color, newColor) < colorDistance(color2.color, newColor)
                            }) ?? .brown
                        }
                    ),
                    hasHighlights: $avatar.hair.hasHighlights,
                    highlightColor: Binding(
                        get: { (avatar.hair.highlightColor ?? .blonde).color },
                        set: { newColor in
                            avatar.hair.highlightColor = HairColor.allCases.min(by: { color1, color2 in
                                colorDistance(color1.color, newColor) < colorDistance(color2.color, newColor)
                            }) ?? .blonde
                        }
                    )
                )
            }
            
            // Facial Hair (for appropriate genders and species)
            if shouldShowFacialHair {
                FacialHairSelector(
                    facialHairStyle: $avatar.hair.facialHair,
                    facialHairColor: Binding(
                        get: { (avatar.hair.facialHairColor ?? avatar.hair.color).color },
                        set: { newColor in
                            avatar.hair.facialHairColor = HairColor.allCases.min(by: { color1, color2 in
                                colorDistance(color1.color, newColor) < colorDistance(color2.color, newColor)
                            }) ?? avatar.hair.color
                        }
                    )
                )
            }
        }
    }
    
    private var shouldShowFacialHair: Bool {
        // Show facial hair for humans with masculine or neutral gender
        avatar.species == .human && (avatar.gender == .male || avatar.gender == .neutral)
    }
}

// MARK: - Hair Style Grid

struct HairStyleGrid: View {
    @Binding var selectedStyle: HairStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hair Style", systemImage: "scissors")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 12) {
                ForEach(HairStyle.allCases, id: \.self) { style in
                    HairStyleCard(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedStyle = style
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

struct HairStyleCard: View {
    let style: HairStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 85)
                    
                    VStack(spacing: 4) {
                        styleIcon
                            .font(.system(size: 36))
                            .foregroundStyle(isSelected ? .purple : .primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }
                }
                
                Text(style.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .purple : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var styleIcon: some View {
        switch style {
        case .short:
            Image(systemName: "person.fill")
        case .medium:
            Image(systemName: "person.fill.turn.right")
        case .long:
            Image(systemName: "figure.stand")
        case .curly:
            Image(systemName: "lasso.and.sparkles")
        case .wavy:
            Image(systemName: "water.waves")
        case .straight:
            Image(systemName: "arrow.down")
        case .buzz:
            Image(systemName: "person.crop.circle")
        case .bald:
            Image(systemName: "circle.fill")
        case .ponytail:
            Image(systemName: "figure.walk")
        case .bun:
            Image(systemName: "circle.circle")
        case .braids:
            Image(systemName: "line.3.horizontal")
        case .dreadlocks:
            Image(systemName: "line.3.horizontal.decrease")
        case .mohawk:
            Image(systemName: "triangle.fill")
        case .afro:
            Image(systemName: "circle.hexagongrid.fill")
        case .pixie:
            Image(systemName: "sparkles")
        case .crew:
            Image(systemName: "person.crop.circle.badge")
        case .undercut:
            Image(systemName: "person.crop.square")
        case .bob:
            Image(systemName: "person.fill.checkmark")
        case .shortCurly:
            Image(systemName: "lasso.sparkles")
        case .shoulder:
            Image(systemName: "person.fill.turn.down")
        case .lob:
            Image(systemName: "person.fill.questionmark")
        case .shag:
            Image(systemName: "sparkles.square")
        case .layers:
            Image(systemName: "square.3.layers.3d.down.right")
        }
    }
}

// MARK: - Hair Color Picker

struct HairColorPicker: View {
    @Binding var color: Color
    @Binding var hasHighlights: Bool
    @Binding var highlightColor: Color
    
    let naturalHairColors: [Color] = [
        // Blacks
        Color(red: 0.1, green: 0.1, blue: 0.1),
        Color(red: 0.15, green: 0.1, blue: 0.05),
        // Browns
        Color(red: 0.3, green: 0.2, blue: 0.1),
        Color(red: 0.4, green: 0.25, blue: 0.15),
        Color(red: 0.5, green: 0.35, blue: 0.2),
        Color(red: 0.6, green: 0.4, blue: 0.25),
        // Blondes
        Color(red: 0.8, green: 0.7, blue: 0.4),
        Color(red: 0.9, green: 0.8, blue: 0.5),
        Color(red: 0.95, green: 0.85, blue: 0.6),
        // Reds
        Color(red: 0.6, green: 0.2, blue: 0.1),
        Color(red: 0.7, green: 0.3, blue: 0.15),
        Color(red: 0.8, green: 0.35, blue: 0.2),
        // Grays/White
        Color(red: 0.5, green: 0.5, blue: 0.5),
        Color(red: 0.7, green: 0.7, blue: 0.7),
        Color(red: 0.9, green: 0.9, blue: 0.9),
        Color.white
    ]
    
    let funHairColors: [Color] = [
        .blue, .cyan, .green, .mint,
        .purple, .pink, .red, .orange,
        .yellow, .indigo, .teal, Color(red: 0.5, green: 0, blue: 0.5)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Main Hair Color
            VStack(alignment: .leading, spacing: 12) {
                Label("Hair Color", systemImage: "paintbrush.fill")
                    .font(.headline)
                
                Text("Natural Colors")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                    ForEach(Array(naturalHairColors.enumerated()), id: \.offset) { _, hairColor in
                        ColorButton(
                            color: hairColor,
                            isSelected: color.hexString == hairColor.hexString
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                color = hairColor
                            }
                        }
                    }
                }
                
                Text("Fun Colors")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                    ForEach(Array(funHairColors.enumerated()), id: \.offset) { _, hairColor in
                        ColorButton(
                            color: hairColor,
                            isSelected: color.hexString == hairColor.hexString
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                color = hairColor
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Highlights Toggle
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $hasHighlights) {
                    Label("Add Highlights", systemImage: "sparkles")
                        .font(.headline)
                }
                .tint(.purple)
                
                if hasHighlights {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Highlight Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                            ForEach(Array(naturalHairColors.enumerated()), id: \.offset) { _, hairColor in
                                ColorButton(
                                    color: hairColor,
                                    isSelected: highlightColor.hexString == hairColor.hexString
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        highlightColor = hairColor
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.3), value: hasHighlights)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Facial Hair Selector

struct FacialHairSelector: View {
    @Binding var facialHairStyle: FacialHairStyle
    @Binding var facialHairColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Facial Hair Style
            VStack(alignment: .leading, spacing: 12) {
                Label("Facial Hair", systemImage: "face.dashed")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 75))], spacing: 12) {
                    ForEach(FacialHairStyle.allCases, id: \.self) { style in
                        FacialHairCard(
                            style: style,
                            isSelected: facialHairStyle == style
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                facialHairStyle = style
                            }
                        }
                    }
                }
            }
            
            // Facial Hair Color (only if not "None")
            if facialHairStyle != .none {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Facial Hair Color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(naturalHairColorOptions, id: \.self) { hairColor in
                            ColorButton(
                                color: hairColor,
                                isSelected: facialHairColor.hexString == hairColor.hexString
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    facialHairColor = hairColor
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .animation(.spring(response: 0.3), value: facialHairStyle)
    }
    
    private var naturalHairColorOptions: [Color] {
        [
            Color(red: 0.1, green: 0.1, blue: 0.1),
            Color(red: 0.3, green: 0.2, blue: 0.1),
            Color(red: 0.4, green: 0.25, blue: 0.15),
            Color(red: 0.5, green: 0.35, blue: 0.2),
            Color(red: 0.6, green: 0.4, blue: 0.25),
            Color(red: 0.6, green: 0.2, blue: 0.1),
            Color(red: 0.5, green: 0.5, blue: 0.5),
            Color.white
        ]
    }
}

struct FacialHairCard: View {
    let style: FacialHairStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.brown.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 75)
                    
                    VStack(spacing: 4) {
                        styleIcon
                            .font(.system(size: 32))
                            .foregroundStyle(isSelected ? .brown : .primary)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.brown)
                        }
                    }
                }
                
                Text(style.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .brown : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var styleIcon: some View {
        switch style {
        case .none:
            Image(systemName: "xmark.circle")
        case .stubble:
            Image(systemName: "circlebadge.fill")
        case .goatee:
            Path { path in
                path.move(to: CGPoint(x: 15, y: 5))
                path.addLine(to: CGPoint(x: 12, y: 15))
                path.addLine(to: CGPoint(x: 18, y: 15))
                path.closeSubpath()
            }
            .stroke(lineWidth: 2)
            .frame(width: 30, height: 20)
        case .beard:
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 28, height: 20)
        case .fullBeard:
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 30, height: 24)
        case .vandyke, .chinstrap:
            Image(systemName: "person.crop.circle.badge")
        case .mustache:
            Path { path in
                path.move(to: CGPoint(x: 5, y: 10))
                path.addQuadCurve(to: CGPoint(x: 15, y: 8), control: CGPoint(x: 10, y: 5))
                path.addQuadCurve(to: CGPoint(x: 25, y: 10), control: CGPoint(x: 20, y: 5))
            }
            .stroke(lineWidth: 3)
            .frame(width: 30, height: 15)
        case .soulPatch:
            Capsule()
                .frame(width: 8, height: 12)
        }
    }
}

// MARK: - Hair Preset Styles

struct HairPresetView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    let presets: [(name: String, style: HairStyle, color: Color)] = [
        ("Classic Short", .short, Color(red: 0.3, green: 0.2, blue: 0.1)),
        ("Beach Waves", .wavy, Color(red: 0.8, green: 0.7, blue: 0.4)),
        ("Long & Straight", .long, Color(red: 0.1, green: 0.1, blue: 0.1)),
        ("Curly Bob", .curly, Color(red: 0.6, green: 0.4, blue: 0.25)),
        ("Elegant Bun", .bun, Color(red: 0.4, green: 0.25, blue: 0.15)),
        ("Cool Mohawk", .mohawk, Color.blue),
        ("Natural Afro", .afro, Color(red: 0.1, green: 0.1, blue: 0.1)),
        ("Braided Style", .braids, Color(red: 0.3, green: 0.2, blue: 0.1)),
        ("Pixie Cut", .pixie, Color(red: 0.7, green: 0.3, blue: 0.15)),
        ("Buzz Cut", .buzz, Color(red: 0.3, green: 0.2, blue: 0.1))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Styles", systemImage: "sparkles")
                .font(.headline)
            
            Text("Tap a preset to apply instantly")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(presets.enumerated()), id: \.offset) { _, preset in
                        HairPresetCard(
                            name: preset.name,
                            style: preset.style,
                            color: preset.color
                        ) {
                            withAnimation(.spring(response: 0.4)) {
                                avatar.hair.style = preset.style
                                // Convert Color back to HairColor enum
                                if let matchingColor = HairColor.allCases.first(where: { $0.color.description == preset.color.description }) {
                                    avatar.hair.color = matchingColor
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct HairPresetCard: View {
    let name: String
    let style: HairStyle
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.3))
                        .frame(width: 100, height: 80)
                    
                    VStack(spacing: 4) {
                        styleIcon
                            .font(.system(size: 32))
                            .foregroundStyle(.primary)
                        
                        Text(style.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 100)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var styleIcon: some View {
        switch style {
        case .short: Image(systemName: "person.fill")
        case .medium: Image(systemName: "person.fill.turn.right")
        case .long: Image(systemName: "figure.stand")
        case .curly: Image(systemName: "lasso.and.sparkles")
        case .wavy: Image(systemName: "water.waves")
        case .straight: Image(systemName: "arrow.down")
        case .buzz: Image(systemName: "person.crop.circle")
        case .bald: Image(systemName: "circle.fill")
        case .ponytail: Image(systemName: "figure.walk")
        case .bun: Image(systemName: "circle.circle")
        case .braids: Image(systemName: "line.3.horizontal")
        case .dreadlocks: Image(systemName: "line.3.horizontal.decrease")
        case .mohawk: Image(systemName: "triangle.fill")
        case .afro: Image(systemName: "circle.hexagongrid.fill")
        case .pixie: Image(systemName: "sparkles")
        case .crew: Image(systemName: "person.crop.circle.badge")
        case .undercut: Image(systemName: "person.crop.square")
        case .bob: Image(systemName: "person.fill.checkmark")
        case .shortCurly: Image(systemName: "lasso.sparkles")
        case .shoulder: Image(systemName: "person.fill.turn.down")
        case .lob: Image(systemName: "person.fill.questionmark")
        case .shag: Image(systemName: "sparkles")
        case .layers: Image(systemName: "square.3.layers.3d.down.right")
        }
    }
}

// MARK: - Helper Functions

/// Calculate distance between two colors (simple RGB distance)
private func colorDistance(_ color1: Color, _ color2: Color) -> CGFloat {
    // Extract RGB components (simplified - assumes colors can be converted)
    // In a real implementation, you'd extract actual RGB values
    // For now, we'll use a simple hash-based approach
    return CGFloat(abs(color1.description.hashValue - color2.description.hashValue))
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            let avatar = Avatar3DModel()
            
            HairPresetView(avatar: avatar)
            HairCustomizationView(avatar: avatar)
        }
        .padding()
    }
}
