//
//  Avatar3DCreatorView.swift
//  LyoApp
//
//  Main 3D Avatar Creator with Step-by-Step Flow
//  Child and adult-friendly interface
//  Created: October 10, 2025
//

import SwiftUI

// MARK: - Creation Steps

enum AvatarCreationStep: Int, CaseIterable {
    case species = 0
    case gender = 1
    case face = 2
    case hair = 3
    case clothing = 4
    case accessories = 5
    case voice = 6
    case name = 7
    
    var title: String {
        switch self {
        case .species: return "Choose Your Type"
        case .gender: return "Choose Your Style"
        case .face: return "Design Your Face"
        case .hair: return "Pick Your Hair"
        case .clothing: return "Choose Your Outfit"
        case .accessories: return "Add Accessories"
        case .voice: return "Pick Your Voice"
        case .name: return "Name Your Avatar"
        }
    }
    
    var subtitle: String {
        switch self {
        case .species: return "What do you want to be?"
        case .gender: return "Express yourself"
        case .face: return "Make it unique"
        case .hair: return "Style it up"
        case .clothing: return "Dress to impress"
        case .accessories: return "Final touches"
        case .voice: return "How do you sound?"
        case .name: return "Give it a name"
        }
    }
    
    var icon: String {
        switch self {
        case .species: return "star.circle.fill"
        case .gender: return "person.fill"
        case .face: return "face.smiling"
        case .hair: return "scissors"
        case .clothing: return "tshirt.fill"
        case .accessories: return "eyeglasses"
        case .voice: return "waveform"
        case .name: return "textformat.abc"
        }
    }
}

// MARK: - Main Creator View

struct Avatar3DCreatorView: View {
    @StateObject private var avatar = Avatar3DModel()
    @State private var currentStep: AvatarCreationStep = .species
    @State private var showPreview = true
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var avatarStore: AvatarStore
    
    var onComplete: ((Avatar3DModel) -> Void)?
    var autoSave: Bool = true  // Automatically save to AvatarStore on completion
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.15),
                    Color.pink.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Progress Bar
                progressBar
                
                // 3D Preview (collapsible)
                if showPreview {
                    Avatar3DPreviewCard(avatar: avatar, height: 250)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content Area
                ScrollView {
                    VStack(spacing: 20) {
                        stepContent
                            .padding()
                    }
                }
                
                // Navigation Buttons
                navigationButtons
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
        .animation(.spring(response: 0.3), value: showPreview)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text(currentStep.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(currentStep.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { withAnimation { showPreview.toggle() } }) {
                Image(systemName: showPreview ? "eye.slash.fill" : "eye.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(AvatarCreationStep.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .species:
            SpeciesSelectionView(avatar: avatar)
        case .gender:
            GenderSelectionView(avatar: avatar)
        case .face:
            FaceCustomizationView(avatar: avatar)
        case .hair:
            VStack(spacing: 20) {
                // Quick presets first
                HairPresetView(avatar: avatar)
                // Then full customization
                HairCustomizationView(avatar: avatar)
            }
        case .clothing:
            ClothingSelectionView(avatar: avatar)
        case .accessories:
            AccessorySelectionView(avatar: avatar)
        case .voice:
            VoiceSelectionView(avatar: avatar)
        case .name:
            NameInputView(avatar: avatar)
        }
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep.rawValue > 0 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.bordered)
            }
            
            Button(action: nextStep) {
                HStack {
                    Text(currentStep == .name ? "Create Avatar" : "Continue")
                    Image(systemName: currentStep == .name ? "checkmark" : "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func previousStep() {
        guard currentStep.rawValue > 0 else { return }
        currentStep = AvatarCreationStep(rawValue: currentStep.rawValue - 1) ?? .species
    }
    
    private func nextStep() {
        if currentStep == .name {
            completeAvatarCreation()
        } else if let next = AvatarCreationStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }
    
    private func completeAvatarCreation() {
        isSaving = true
        
        // Auto-save if enabled
        if autoSave {
            avatarStore.save3DAvatar(avatar)
        }
        
        // Call completion handler
        onComplete?(avatar)
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Species Selection

struct SpeciesSelectionView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(AvatarSpecies.allCases, id: \.self) { species in
                SpeciesCard(
                    species: species,
                    isSelected: avatar.species == species
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        avatar.species = species
                    }
                }
            }
        }
    }
}

struct SpeciesCard: View {
    let species: AvatarSpecies
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: species.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(species.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(species.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gender Selection

struct GenderSelectionView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(AvatarGender.allCases, id: \.self) { gender in
                GenderCard(
                    gender: gender,
                    isSelected: avatar.gender == gender
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        avatar.gender = gender
                    }
                }
            }
        }
    }
}

struct GenderCard: View {
    let gender: AvatarGender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: gender.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? .purple : .primary)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(gender.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(gender.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Face Customization (Full Implementation)

struct FaceCustomizationView: View {
    @ObservedObject var avatar: Avatar3DModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Face Shape
            FaceShapeSelector(selectedShape: $avatar.facialFeatures.faceShape)
            
            // Eyes
            EyeCustomizationPanel(
                eyeShape: $avatar.facialFeatures.eyeShape,
                eyeColor: Binding(
                    get: { avatar.facialFeatures.resolvedEyeColor },
                    set: { newColor in
                        avatar.facialFeatures.applyEyeColor(newColor)
                    }
                ),
                eyeSize: $avatar.facialFeatures.eyeSize,
                eyeSpacing: $avatar.facialFeatures.eyeSpacing,
                hasEyelashes: $avatar.facialFeatures.hasEyelashes
            )
            
            // Nose
            NoseCustomizationPanel(
                noseType: $avatar.facialFeatures.noseType,
                noseSize: $avatar.facialFeatures.noseSize
            )
            
            // Mouth
            MouthCustomizationPanel(
                mouthShape: $avatar.facialFeatures.mouthShape,
                lipColor: $avatar.facialFeatures.lipColor
            )
            
            // Additional Features
            AdditionalFeaturesPanel(
                earSize: $avatar.facialFeatures.earSize,
                cheekbones: $avatar.facialFeatures.cheekboneProminence
            )
        }
    }
}

// Hair customization moved to HairCustomizationViews.swift
// Hair customization moved to HairCustomizationViews.swift
// Clothing and accessories moved to ClothingCustomizationViews.swift
// Voice selection moved to VoiceSelectionViews.swift
// All full implementations complete

struct NameInputView: View {
    @ObservedObject var avatar: Avatar3DModel
    @State private var name: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Give your avatar a name!")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Enter name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .onChange(of: name) { _, newValue in
                    avatar.name = newValue
                }
            
            if !name.isEmpty {
                Text("Hello, \(name)! 👋")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .animation(.spring(response: 0.3), value: name)
    }
}

// MARK: - Preview

#Preview {
    Avatar3DCreatorView()
}
