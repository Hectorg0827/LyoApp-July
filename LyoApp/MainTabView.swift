


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
    @State private var showingPost = false
    @State private var tabBarOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            mainTabContent
                .padding(.bottom, 16)
            customTabBarView
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingPost) {
            PostView()
                .environmentObject(appState)
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            selectedTab = newTab
        }
    }

    // ...existing code...

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
                    VStack {
                        Spacer()
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            // AI Assistant Icon
                            ZStack {
                                Circle()
                                    .fill(DesignTokens.Colors.primaryGradient)
                                    .frame(width: 100, height: 100)
                                    .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 0)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            Text("Lyo AI Assistant")
                                .font(DesignTokens.Typography.title2)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Text("Tap to start learning with AI")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("Start Conversation") {
                                withAnimation(DesignTokens.Animations.bouncy) {
                                    showAIChat = true
                                }
                            }
                            .font(DesignTokens.Typography.buttonLabel)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignTokens.Spacing.xl)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .background(DesignTokens.Colors.primaryGradient)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        Spacer()
                    }
                }
            case .post:
                // Show post creation sheet instead of direct view
                EmptyView()
                    .onAppear {
                        showingPost = true
                    }
            case .more:
                MoreTabView()
                    .environmentObject(appState)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
    }

    // MARK: - Custom Tab Bar
    private var customTabBarView: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            ForEach(MainTab.allCases, id: \ .self) { tab in
                if tab == .ai {
                    FuturisticAIButton(isSelected: selectedTab == .ai) {
                        handleTabSelection(.ai)
                    }
                    .padding(.bottom, 4)
                } else {
                    FuturisticTabButton(tab: tab, isSelected: selectedTab == tab, showLabel: false, iconSize: 28) {
                        handleTabSelection(tab)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, DesignTokens.Spacing.xl * 1.5)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                        .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(color: DesignTokens.Colors.primary.opacity(0.15), radius: 16, x: 0, y: 4)
        )
        .padding(.bottom, 16)
    }

    // MARK: - Tab Selection Handler
    private func handleTabSelection(_ tab: MainTab) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        withAnimation(DesignTokens.Animations.quick) {
            selectedTab = tab
            appState.selectedTab = tab
            showAIChat = false
        }
        // Handle specific tab behaviors
        switch tab {
        case .post:
            showingPost = true
        case .ai:
            showAIChat = true
        default:
            break
        }
    }
}
struct FuturisticTabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let showLabel: Bool
    let iconSize: CGFloat
    let action: () -> Void

    @State private var isPressed = false
    @State private var badgeCount = 0
    @State private var rotateAnimation = false
    @State private var pulseAnimation = false
    @State private var glowAnimation = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background glow
                if isSelected {
                    Circle()
                        .fill(DesignTokens.Colors.primary.opacity(0.2))
                        .frame(width: iconSize + 10, height: iconSize + 10)
                        .blur(radius: 4)
                }
                // Special styling for Post tab
                if tab == .post {
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
                        .frame(width: iconSize, height: iconSize)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? DesignTokens.Colors.glassHighlight : DesignTokens.Colors.glassBorder,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                } else {
                    Circle()
                        .fill(isSelected ? DesignTokens.Colors.primary.opacity(0.1) : Color.clear)
                        .frame(width: iconSize, height: iconSize)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                }
                // Icon with badge
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: iconSize, weight: tab == .post ? .bold : .medium))
                        .foregroundColor(
                            tab == .post ? 
                            (isSelected ? .white : DesignTokens.Colors.primary) : 
                            (isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                        )
                    if badgeCount > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.error)
                                        .frame(width: 16, height: 16)
                                    Text("\(badgeCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                // Label (optional)
                if showLabel {
                    Text("Lyo")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onAppear {
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
                                    
                                    // AI notification badge
                                    VStack {
                                        HStack {
                                            Spacer()
                                            
                                            if isSelected {
                                                ZStack {
                                                    Circle()
                                                        .fill(DesignTokens.Colors.neonGreen)
                                                        .frame(width: 12, height: 12)
                                                        .shadow(color: DesignTokens.Colors.neonGreen.opacity(0.6), radius: 4, x: 0, y: 0)
                                                    
                                                    Circle()
                                                        .fill(DesignTokens.Colors.neonGreen)
                                                        .frame(width: 8, height: 8)
                                                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        }
                                        Spacer()
                                    }
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


