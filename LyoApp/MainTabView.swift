


import SwiftUI
import Foundation

// UIKit-based blur view for SwiftUI
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}


struct MainTabView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: MainTab = .home
    @State private var showAIChat = false

    var body: some View {
        ZStack(alignment: .bottom) {
            mainTabContent
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - Main Tab Content
    @ViewBuilder
    private var mainTabContent: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeFeedView()
                    .environmentObject(appState)
            case .discover:
                DiscoverView()
                    .environmentObject(appState)
            case .ai:
                if showAIChat {
                    AIFullChatViewWithCompletion { topic in
                        showAIChat = false
                    }
                } else {
                    Color.clear
                }
            case .post:
                PostView()
                    .environmentObject(appState)
            case .more:
                ProfileView()
                    .environmentObject(appState)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
    }

    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            ForEach(MainTab.allCases, id: \..self) { tab in
                if tab == .ai {
                    FuturisticAIButton(isSelected: selectedTab == .ai) {
                        withAnimation(DesignTokens.Animations.quick) {
                            selectedTab = .ai
                            showAIChat = true
                        }
                    }
                    .padding(.bottom, 2)
                } else {
                    FuturisticTabButton(tab: tab, isSelected: selectedTab == tab) {
                        withAnimation(DesignTokens.Animations.quick) {
                            selectedTab = tab
                            showAIChat = false
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                        .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(color: DesignTokens.Colors.primary.opacity(0.15), radius: 16, x: 0, y: 4)
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Futuristic Tab Button
struct FuturisticTabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) { // Minimal spacing for compact layout
                ZStack {
                    // Background glow
                    if isSelected {
                        Circle()
                            .fill(DesignTokens.Colors.primary.opacity(0.2))
                            .frame(width: 30, height: 30)
                            .blur(radius: 4)
                    }
                    
                    // Special styling for Post tab
                    if tab == .post {
                        // Post button with gradient background
                        Circle()
                            .fill(
                                isSelected ? 
                                DesignTokens.Colors.primaryGradient : 
                                LinearGradient(
                                    colors: [DesignTokens.Colors.glassBg, DesignTokens.Colors.glassBg],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isSelected ? DesignTokens.Colors.glassHighlight : DesignTokens.Colors.glassBorder,
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                    } else {
                        // Regular button
                        Circle()
                            .fill(isSelected ? DesignTokens.Colors.primary.opacity(0.1) : Color.clear)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                    }
                    
                    // Icon
                    Image(systemName: tab.icon)
                        .font(.system(size: tab == .post ? 16 : 14, weight: tab == .post ? .bold : .medium))
                        .foregroundColor(
                            tab == .post ? 
                            (isSelected ? .white : DesignTokens.Colors.primary) : 
                            (isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                        )
                }
                
                // Label
                Text(tab.rawValue)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(DesignTokens.Animations.quick) {
                isPressed = isPressing
            }
        } perform: {
            action()
        }
    }
}

// MARK: - Futuristic AI Avatar Button
struct FuturisticAIButton: View {
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulseAnimation = false
    @State private var rotateAnimation = false
    @State private var glowAnimation = false
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    // Outer electric ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    DesignTokens.Colors.neonBlue,
                                    DesignTokens.Colors.neonPurple,
                                    DesignTokens.Colors.neonPink,
                                    DesignTokens.Colors.neonBlue
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: pulseAnimation ? 52 : 50, height: pulseAnimation ? 52 : 50)
                        .rotationEffect(.degrees(rotateAnimation ? 360 : 0))
                        .opacity(glowAnimation ? 1.0 : 0.6)
                    // Middle glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DesignTokens.Colors.primary.opacity(0.4),
                                    DesignTokens.Colors.secondary.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 45, height: 45)
                        .blur(radius: 8)
                    // Main AI button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.primary,
                                    DesignTokens.Colors.secondary,
                                    DesignTokens.Colors.tertiary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            ZStack {
                                // Inner glass highlight
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                DesignTokens.Colors.glassHighlight,
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                                // Lyo Learning Companion Icon
                                ZStack {
                                    // Add a subtle inner glow when selected
                                    if isSelected {
                                        Circle()
                                            .fill(DesignTokens.Colors.neonBlue.opacity(0.3))
                                            .frame(width: 20, height: 20)
                                            .blur(radius: 4)
                                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                    }
                                    Image(systemName: "lightbulb.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: DesignTokens.Colors.neonBlue, radius: 4)
                                        .scaleEffect(isSelected && pulseAnimation ? 1.05 : 1.0)
                                }
                            }
                        )
                        .shadow(
                            color: isSelected ? DesignTokens.Colors.primary.opacity(0.8) : DesignTokens.Colors.primary.opacity(0.4),
                            radius: isSelected ? 20 : 12,
                            x: 0,
                            y: 4
                        )
                }
                // Label
                Text("Lyo")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onAppear {
            // Start continuous animations
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotateAnimation = true
            }
            withAnimation(DesignTokens.Animations.pulse) {
                pulseAnimation = true
            }
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(DesignTokens.Animations.quick) {
                isPressed = isPressing
            }
        } perform: {
            action()
        }
    }
}


