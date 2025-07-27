//
//  FuturisticHeaderView.swift
//  LyoApp
//
//  Futuristic AI drawer header with animated Lyo button and glassmorphic interface
//

import SwiftUI
import Combine

struct FuturisticHeaderView: View {
    @State private var isDrawerExpanded = false
    @State private var buttonPosition: CGFloat = UIScreen.main.bounds.width - 70 // Start position (right side)
    @State private var glowIntensity: Double = 0.3
    @State private var quantumPhase: Double = 0
    @State private var consciousnessLevel: Double = 0.1
    @State private var showIcons = false
    @State private var showStories = false
    
    // Quantum animation timer
    @State private var quantumTimer: Timer?
    
    private let expandedButtonPosition: CGFloat = 70 // End position (left side)
    private let collapsedButtonPosition: CGFloat = UIScreen.main.bounds.width - 70
    
    var body: some View {
        VStack(spacing: 0) {
            // Main header strip
            ZStack {
                // Glassmorphic background strip (only visible when expanded)
                if isDrawerExpanded {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.blue.opacity(0.08),
                                    Color.purple.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.Colors.brand.opacity(glowIntensity),
                                            DesignTokens.Colors.accent.opacity(glowIntensity * 0.7),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .frame(height: 60)
                        .padding(.horizontal, 16)
                        .shadow(
                            color: DesignTokens.Colors.brand.opacity(glowIntensity * 0.5),
                            radius: 15,
                            x: 0,
                            y: 5
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
                
                HStack {
                    // Lyo AI Button
                    lyoAIButton
                        .position(x: buttonPosition, y: 30)
                    
                    Spacer()
                    
                    // Action icons (appear when drawer is expanded)
                    if showIcons {
                        actionIconsRow
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .frame(height: 60)
            }
            .padding(.top, 10)
            
            // Stories section (appears below when expanded)
            if showStories {
                futuristicStoriesSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            startQuantumAnimations()
        }
        .onDisappear {
            stopQuantumAnimations()
        }
    }
    
    // MARK: - Lyo AI Button
    private var lyoAIButton: some View {
        Button(action: {
            handleDrawerToggle()
        }) {
            ZStack {
                // Quantum rings
                ForEach(0..<6, id: \.self) { i in
                    let radius = 15.0 + Double(i) * 4.0
                    let rotation = quantumPhase + Double(i) * 60.0
                    let opacity = consciousnessLevel * (0.6 + sin((quantumPhase + Double(i) * 30.0) * 0.02) * 0.4)
                    
                    Circle()
                        .stroke(getQuantumColor(for: i), lineWidth: 1.5 - Double(i) * 0.2)
                        .frame(width: radius * 2, height: radius * 2)
                        .opacity(opacity)
                        .rotationEffect(.degrees(rotation))
                        .blur(radius: 0.8)
                        .shadow(color: getQuantumColor(for: i), radius: 3)
                }
                
                // Central core with Lyo text
                ZStack {
                    // Background sphere
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: DesignTokens.Colors.brand, location: 0.0),
                                    .init(color: DesignTokens.Colors.accent, location: 0.7),
                                    .init(color: Color.black.opacity(0.8), location: 1.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: DesignTokens.Colors.brand, radius: 10)
                    
                    // Lyo text
                    Text("Lyo")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.cyan.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white, radius: 3)
                }
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isDrawerExpanded ? 0.9 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDrawerExpanded)
    }
    
    // MARK: - Action Icons Row
    private var actionIconsRow: some View {
        HStack(spacing: 20) {
            // Search icon
            actionIcon(systemName: "magnifyingglass", action: {
                print("Search tapped")
                HapticManager.shared.light()
            })
            
            // Message icon
            actionIcon(systemName: "message", action: {
                print("Message tapped")
                HapticManager.shared.light()
            })
            
            // Library icon
            actionIcon(systemName: "books.vertical", action: {
                print("Library tapped")
                HapticManager.shared.light()
            })
        }
        .padding(.trailing, 30)
    }
    
    private func actionIcon(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                DesignTokens.Colors.brand.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.brand)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.8)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: showIcons)
    }
    
    // MARK: - Futuristic Stories Section
    private var futuristicStoriesSection: some View {
        VStack(spacing: 12) {
            // Stories label
            HStack {
                Text("Stories")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    HapticManager.shared.light()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.accent)
            }
            .padding(.horizontal, 20)
            
            // Horizontal stories scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Add story circle (first one)
                    addStoryCircle
                    
                    // User stories
                    // TODO: Replace with real user stories from UserDataManager
                    ForEach([], id: \.username) { story in
                        // EmptyView() - story view implementation would go here
                    }
                        FuturisticStoryCircle(story: story)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Add Story Circle
    private var addStoryCircle: some View {
        Button(action: {
            HapticManager.shared.medium()
            print("Add story tapped")
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Futuristic gradient ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.brand,
                                    DesignTokens.Colors.accent,
                                    Color.cyan
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(quantumPhase * 0.5))
                    
                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.blue.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignTokens.Colors.brand)
                        )
                        .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 8)
                }
                
                Text("Your Story")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Animation Methods
    private func handleDrawerToggle() {
        HapticManager.shared.medium()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            isDrawerExpanded.toggle()
            buttonPosition = isDrawerExpanded ? expandedButtonPosition : collapsedButtonPosition
            glowIntensity = isDrawerExpanded ? 0.8 : 0.3
            consciousnessLevel = isDrawerExpanded ? 0.8 : 0.1
        }
        
        // Delayed animations for sequential reveal
        if isDrawerExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showIcons = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showStories = true
                }
            }
        } else {
            showIcons = false
            showStories = false
        }
    }
    
    private func startQuantumAnimations() {
        quantumTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            quantumPhase = (quantumPhase + 2.0).truncatingRemainder(dividingBy: 360)
        }
    }
    
    private func stopQuantumAnimations() {
        quantumTimer?.invalidate()
        quantumTimer = nil
    }
    
    private func getQuantumColor(for index: Int) -> Color {
        let hue = (240.0 + Double(index) * 20) / 360 // Blue-purple spectrum
        return Color(hue: hue, saturation: 0.8, brightness: 0.7)
    }
}

// MARK: - Futuristic Story Circle
struct FuturisticStoryCircle: View {
    let story: MockStory
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.medium()
            print("Story tapped: \(story.username)")
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Holographic ring for new stories
                    if story.hasNewStory {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        DesignTokens.Colors.brand,
                                        DesignTokens.Colors.accent,
                                        Color.cyan,
                                        Color.purple,
                                        DesignTokens.Colors.brand
                                    ],
                                    center: .center
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: DesignTokens.Colors.brand.opacity(0.6), radius: 8)
                    }
                    
                    // Avatar container
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            // Avatar image or icon
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(DesignTokens.Colors.brand)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 5)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                
                // Username
                Text(story.username)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

// MARK: - Mock Data
struct MockStory: Identifiable {
    let id = UUID()
    let username: String
    let hasNewStory: Bool
    
    // MARK: - Sample Data Removed
    // All mock stories moved to UserDataManager for real data management
    // static let mockStories = [] // Use UserDataManager.shared.getUserStories()
}

// MARK: - Helper Extension (reuse from original HeaderView)
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}

// MARK: - Global Access (TODO: Remove when UserDataManager integration is complete)
let mockStories: [MockStory] = [] // Empty array until real data integration

#Preview {
    FuturisticHeaderView()
        .background(Color.black.ignoresSafeArea())
}
