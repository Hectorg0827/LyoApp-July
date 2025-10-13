//
//  FacialFeatureViews.swift
//  LyoApp
//
//  Detailed facial feature customization panels
//  Child-friendly with visual presets
//  Created: October 10, 2025
//

import SwiftUI

// MARK: - Face Shape Selector

struct FaceShapeSelector: View {
    @Binding var selectedShape: FaceShape
    
    let shapes: [FaceShape] = FaceShape.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Face Shape", systemImage: "face.smiling")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(shapes, id: \.self) { shape in
                    FaceShapeCard(
                        shape: shape,
                        isSelected: selectedShape == shape
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedShape = shape
                        }
                    }
                }
            }
        }
    }
}

struct FaceShapeCard: View {
    let shape: FaceShape
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.secondarySystemBackground))
                        .frame(height: 80)
                    
                    shapeIcon
                        .font(.system(size: 40))
                        .foregroundStyle(isSelected ? .blue : .primary)
                }
                
                Text(shape.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var shapeIcon: some View {
        switch shape {
        case .round:
            Circle()
                .strokeBorder(lineWidth: 3)
                .frame(width: 40, height: 40)
        case .oval:
            Ellipse()
                .strokeBorder(lineWidth: 3)
                .frame(width: 35, height: 45)
        case .square:
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(lineWidth: 3)
                .frame(width: 40, height: 40)
        case .heart:
            Image(systemName: "heart")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
        case .long:
            Capsule()
                .strokeBorder(lineWidth: 3)
                .frame(width: 30, height: 50)
        case .diamond:
            Image(systemName: "diamond")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
        }
    }
}

// MARK: - Eye Customization

struct EyeCustomizationPanel: View {
    @Binding var eyeShape: EyeShape
    @Binding var eyeColor: Color
    @Binding var eyeSize: Double
    @Binding var eyeSpacing: Double
    @Binding var hasEyelashes: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Eye Shape
            VStack(alignment: .leading, spacing: 12) {
                Label("Eye Shape", systemImage: "eye.fill")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                    ForEach(EyeShape.allCases, id: \.self) { shape in
                        EyeShapeButton(
                            shape: shape,
                            isSelected: eyeShape == shape
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                eyeShape = shape
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Eye Color
            VStack(alignment: .leading, spacing: 12) {
                Label("Eye Color", systemImage: "paintpalette.fill")
                    .font(.headline)
                
                ColorPaletteGrid(selectedColor: $eyeColor, colors: [
                    .blue, .green, .brown, Color(red: 0.3, green: 0.15, blue: 0.05),
                    .gray, Color(red: 0.6, green: 0.4, blue: 0.2), .cyan, .purple
                ])
            }
            
            Divider()
            
            // Eye Size
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Eye Size", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(eyeSize * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $eyeSize, in: 0.7...1.3, step: 0.1)
                    .tint(.blue)
            }
            
            Divider()
            
            // Eye Spacing
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Eye Spacing", systemImage: "arrow.left.and.right")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(eyeSpacing * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $eyeSpacing, in: 0.8...1.2, step: 0.1)
                    .tint(.blue)
            }
            
            Divider()
            
            // Eyelashes Toggle
            Toggle(isOn: $hasEyelashes) {
                Label("Eyelashes", systemImage: "sparkles")
                    .font(.headline)
            }
            .tint(.blue)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct EyeShapeButton: View {
    let shape: EyeShape
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 60)
                    
                    eyeShapeIcon
                        .font(.system(size: 30))
                        .foregroundStyle(isSelected ? .blue : .primary)
                }
                
                Text(shape.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var eyeShapeIcon: some View {
        // Simple representations of eye shapes
        switch shape {
        case .almond:
            Ellipse()
                .strokeBorder(lineWidth: 2)
                .frame(width: 35, height: 18)
        case .round:
            Circle()
                .strokeBorder(lineWidth: 2)
                .frame(width: 22, height: 22)
        case .hooded:
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                path.addCurve(to: CGPoint(x: 30, y: 10), control1: CGPoint(x: 10, y: 0), control2: CGPoint(x: 20, y: 0))
                path.addLine(to: CGPoint(x: 30, y: 15))
                path.addCurve(to: CGPoint(x: 0, y: 15), control1: CGPoint(x: 20, y: 20), control2: CGPoint(x: 10, y: 20))
                path.closeSubpath()
            }
            .stroke(lineWidth: 2)
            .frame(width: 30, height: 20)
        case .upturned:
            Path { path in
                path.move(to: CGPoint(x: 0, y: 12))
                path.addQuadCurve(to: CGPoint(x: 30, y: 8), control: CGPoint(x: 15, y: 0))
            }
            .stroke(lineWidth: 2)
            .frame(width: 30, height: 15)
        case .downturned:
            Path { path in
                path.move(to: CGPoint(x: 0, y: 8))
                path.addQuadCurve(to: CGPoint(x: 30, y: 12), control: CGPoint(x: 15, y: 20))
            }
            .stroke(lineWidth: 2)
            .frame(width: 30, height: 20)
        case .monolid:
            Rectangle()
                .frame(width: 32, height: 6)
        }
    }
}

// MARK: - Nose Customization

struct NoseCustomizationPanel: View {
    @Binding var noseType: NoseType
    @Binding var noseSize: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Nose Type
            VStack(alignment: .leading, spacing: 12) {
                Label("Nose Type", systemImage: "nose.fill")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                    ForEach(NoseType.allCases, id: \.self) { type in
                        NoseTypeButton(
                            type: type,
                            isSelected: noseType == type
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                noseType = type
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Nose Size
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Nose Size", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(noseSize * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $noseSize, in: 0.7...1.3, step: 0.1)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct NoseTypeButton: View {
    let type: NoseType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 60)
                    
                    noseIcon
                        .foregroundStyle(isSelected ? .blue : .primary)
                }
                
                Text(type.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var noseIcon: some View {
        // Simple nose representations
        switch type {
        case .small:
            Image(systemName: "triangle.fill")
                .font(.system(size: 20))
                .rotationEffect(.degrees(180))
        case .medium:
            Image(systemName: "triangle.fill")
                .font(.system(size: 26))
                .rotationEffect(.degrees(180))
        case .large:
            Image(systemName: "triangle.fill")
                .font(.system(size: 32))
                .rotationEffect(.degrees(180))
        case .button:
            Circle()
                .frame(width: 20, height: 20)
        case .roman:
            Path { path in
                path.move(to: CGPoint(x: 15, y: 0))
                path.addLine(to: CGPoint(x: 12, y: 20))
                path.addLine(to: CGPoint(x: 18, y: 20))
                path.closeSubpath()
            }
            .frame(width: 30, height: 25)
        case .snub:
            Capsule()
                .frame(width: 28, height: 12)
        }
    }
}

// MARK: - Mouth Customization

struct MouthCustomizationPanel: View {
    @Binding var mouthShape: MouthShape
    @Binding var lipColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Mouth Shape
            VStack(alignment: .leading, spacing: 12) {
                Label("Mouth Shape", systemImage: "mouth.fill")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                    ForEach(MouthShape.allCases, id: \.self) { shape in
                        MouthShapeButton(
                            shape: shape,
                            isSelected: mouthShape == shape
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                mouthShape = shape
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Lip Color
            VStack(alignment: .leading, spacing: 12) {
                Label("Lip Color", systemImage: "paintpalette.fill")
                    .font(.headline)
                
                ColorPaletteGrid(selectedColor: $lipColor, colors: [
                    Color(red: 0.9, green: 0.5, blue: 0.5),
                    Color(red: 0.8, green: 0.3, blue: 0.3),
                    Color(red: 0.7, green: 0.2, blue: 0.3),
                    Color(red: 0.95, green: 0.6, blue: 0.6),
                    Color(red: 0.85, green: 0.45, blue: 0.5),
                    Color(red: 0.75, green: 0.35, blue: 0.4),
                    Color(red: 0.9, green: 0.55, blue: 0.45),
                    Color(red: 0.8, green: 0.4, blue: 0.35)
                ])
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct MouthShapeButton: View {
    let shape: MouthShape
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .frame(height: 60)
                    
                    mouthIcon
                        .foregroundStyle(isSelected ? .blue : .primary)
                }
                
                Text(shape.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var mouthIcon: some View {
        switch shape {
        case .small:
            Capsule()
                .frame(width: 20, height: 6)
        case .medium:
            Capsule()
                .frame(width: 28, height: 8)
        case .wide:
            Capsule()
                .frame(width: 36, height: 8)
        case .full:
            Capsule()
                .frame(width: 30, height: 12)
        case .thin:
            Capsule()
                .frame(width: 28, height: 4)
        case .cupid:
            Image(systemName: "heart.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 12)
        }
    }
}

// MARK: - Additional Features

struct AdditionalFeaturesPanel: View {
    @Binding var earSize: Double
    @Binding var cheekbones: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Ear Size
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Ear Size", systemImage: "ear.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(earSize * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $earSize, in: 0.7...1.3, step: 0.1)
                    .tint(.blue)
            }
            
            Divider()
            
            // Cheekbone Prominence
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Cheekbones", systemImage: "faceid")
                        .font(.headline)
                    Spacer()
                    Text(cheekbones < 0.9 ? "Soft" : cheekbones > 1.1 ? "Prominent" : "Normal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $cheekbones, in: 0.7...1.3, step: 0.1)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Reusable Color Palette

struct ColorPaletteGrid: View {
    @Binding var selectedColor: Color
    let colors: [Color]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                ColorButton(
                    color: color,
                    isSelected: selectedColor.hexString == color.hexString
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedColor = color
                    }
                }
            }
        }
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.white : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            FaceShapeSelector(selectedShape: .constant(.oval))
            
            EyeCustomizationPanel(
                eyeShape: .constant(.almond),
                eyeColor: .constant(.blue),
                eyeSize: .constant(1.0),
                eyeSpacing: .constant(1.0),
                hasEyelashes: .constant(true)
            )
            
            NoseCustomizationPanel(
                noseType: .constant(.medium),
                noseSize: .constant(1.0)
            )
            
            MouthCustomizationPanel(
                mouthShape: .constant(.medium),
                lipColor: .constant(Color(red: 0.8, green: 0.3, blue: 0.3))
            )
            
            AdditionalFeaturesPanel(
                earSize: .constant(1.0),
                cheekbones: .constant(1.0)
            )
        }
        .padding()
    }
}
