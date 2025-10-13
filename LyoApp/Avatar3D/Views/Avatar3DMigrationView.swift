//
//  Avatar3DMigrationView.swift
//  LyoApp
//
//  Migration flow from 2D emoji avatars to 3D customizable avatars
//  Created: October 10, 2025
//

import SwiftUI

// MARK: - Migration View

struct Avatar3DMigrationView: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @State private var showCreator = false
    @State private var isAnimating = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Title
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse, options: .repeating, value: isAnimating)
                    
                    Text("Upgrade Your Avatar!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create your own 3D avatar with full customization")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "person.crop.circle.fill", title: "Choose Your Look", description: "Human, animal, or robot")
                    FeatureRow(icon: "paintbrush.fill", title: "Customize Everything", description: "Face, hair, clothing, and accessories")
                    FeatureRow(icon: "waveform", title: "Pick Your Voice", description: "12 unique voice options with pitch control")
                    FeatureRow(icon: "face.smiling", title: "Expressive Animations", description: "10 facial expressions and idle animations")
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        showCreator = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Create My 3D Avatar")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .fullScreenCover(isPresented: $showCreator) {
            Avatar3DCreatorView { newAvatar in
                print("✅ [Migration] Created new 3D avatar: \(newAvatar.name)")
            }
            .environmentObject(avatarStore)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Auto-Migration Prompt

struct Avatar3DAutoMigrationPrompt: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @State private var showMigrationView = false
    
    var body: some View {
        Group {
            if avatarStore.hasCompletedSetup && !avatarStore.has3DAvatar() {
                // User has 2D avatar but no 3D avatar - show prompt
                EmptyView()
                    .onAppear {
                        // Show prompt after slight delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showMigrationView = true
                        }
                    }
                    .sheet(isPresented: $showMigrationView) {
                        Avatar3DMigrationView()
                            .environmentObject(avatarStore)
                    }
            }
        }
    }
}

// MARK: - Settings Row for Manual Migration

struct Avatar3DUpgradeButton: View {
    @EnvironmentObject var avatarStore: AvatarStore
    @State private var showMigrationView = false
    
    var body: some View {
        Button(action: {
            showMigrationView = true
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to 3D Avatar")
                        .font(.headline)
                    
                    Text("Create a fully customizable 3D avatar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showMigrationView) {
            Avatar3DCreatorView()
                .environmentObject(avatarStore)
        }
    }
}

// MARK: - Preview

#Preview {
    Avatar3DMigrationView()
        .environmentObject(AvatarStore())
}
