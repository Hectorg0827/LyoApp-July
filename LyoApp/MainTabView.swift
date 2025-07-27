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
    @State private var showingPost = false
    @State private var tabBarOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            mainTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
                .padding(.bottom, 80)
            
            // Custom Tab Bar - Always positioned at bottom
            customTabBarView
                .zIndex(1) // Ensure tab bar stays above content
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingPost) {
            PostView()
                .environmentObject(appState)
        }
        .onChange(of: showingPost) { _, isShowing in
            // When post modal is dismissed, ensure proper layout restoration
            if !isShowing {
                // Reset any layout-affecting state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Force layout refresh if needed
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tabBarOffset = 0 // Reset any potential offset
                    }
                }
            }
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            // Only update selectedTab if it's not the Post tab
            if newTab != .post {
                selectedTab = newTab
            }
        }
        .overlay(
            // Floating companion overlay
            Group {
                if appState.showFloatingCompanion {
                    FloatingActionButton()
                        .environmentObject(appState)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: appState.showFloatingCompanion)
                }
            }
        )
        .fullScreenCover(isPresented: $appState.isAvatarPresented) {
            AIAvatarView()
                .environmentObject(appState)
        }
    }

    // MARK: - Main Tab Content
    @ViewBuilder
    private var mainTabContent: some View {
        switch selectedTab {
        case .home:
            HomeFeedView()
                .environmentObject(appState)
        case .discover:
            DiscoverView()
                .environmentObject(appState)
        case .ai:
            LearnTabView()
                .environmentObject(appState)
        case .post:
            // Post is handled as modal only, show the previously selected tab content
            // This prevents layout issues when Post tab is "selected"
            HomeFeedView()
                .environmentObject(appState)
        case .more:
            MoreTabView()
                .environmentObject(appState)
        }
    }

    // MARK: - Custom Tab Bar
    @ViewBuilder
    private var customTabBarView: some View {
        VStack {
            Spacer() // Push the tab bar to the bottom
            
            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.rawValue) { tab in
                    FuturisticTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab && tab != .post, // Post tab never shows as selected
                        showLabel: true,
                        iconSize: 18,
                        action: { handleTabSelection(tab) }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70) // Fixed height for better stability
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl + 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl + 4, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignTokens.Colors.glassBorder.opacity(0.8),
                                        DesignTokens.Colors.primary.opacity(0.3),
                                        DesignTokens.Colors.glassBorder.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: DesignTokens.Colors.primary.opacity(0.2), radius: 20, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
            .offset(y: tabBarOffset) // Apply any offset for animations
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Tab Selection Handler
    private func handleTabSelection(_ tab: MainTab) {
        print("🎯 handleTabSelection called for: \(tab.rawValue)")
        print("🎯 Current selectedTab: \(selectedTab.rawValue)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if tab == .post {
            // Show post modal without changing the selected tab
            showingPost = true
        } else {
            // Update tab selection for non-post tabs
            withAnimation(DesignTokens.Animations.quick) {
                selectedTab = tab
                appState.selectedTab = tab
            }
        }
        
        print("🎯 After selection - selectedTab: \(selectedTab.rawValue)")
        print("🎯 After selection - appState.selectedTab: \(appState.selectedTab.rawValue)")
    }
}

// MARK: - Futuristic Tab Button
struct FuturisticTabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let showLabel: Bool
    let iconSize: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var pulseAnimation = false
    @State private var glowAnimation = false
    
    // Special styling for the center learning tab
    private var isCenterLearningTab: Bool {
        return tab == .ai
    }
    
    private var enhancedIconSize: CGFloat {
        return isCenterLearningTab ? iconSize + 6 : iconSize
    }
    
    var body: some View {
        Button(action: {
            print("🔘 Tab button tapped: \(tab.rawValue)")
            action()
        }) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    if isCenterLearningTab {
                        // Enhanced center learning tab
                        centerLearningTabButton
                    } else {
                        // Standard tab button for other tabs
                        standardTabButton
                    }
                }
                
                if showLabel {
                    Text(tab.rawValue)
                        .font(.system(size: isCenterLearningTab ? 10 : 9, weight: .semibold))
                        .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(tab.accessibleName)
        .accessibilityHint(tab.accessibilityDescription)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(tab.accessibilityIdentifier)
        .onAppear {
            if isCenterLearningTab {
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                    glowAnimation = true
                }
            }
        }
    }
    
    private var centerLearningTabButton: some View {
        ZStack {
            // Glow background for center tab
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.primary.opacity(0.3),
                            DesignTokens.Colors.primary.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: enhancedIconSize + 8
                    )
                )
                .frame(width: enhancedIconSize + 16, height: enhancedIconSize + 16)
                .scaleEffect(glowAnimation ? 1.2 : 1.0)
                .opacity(isSelected ? 1.0 : 0.6)
            
            // Main icon container
            ZStack {
                if isSelected {
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .frame(width: enhancedIconSize + 8, height: enhancedIconSize + 8)
                } else {
                    Circle()
                        .fill(DesignTokens.Colors.glassBg)
                        .frame(width: enhancedIconSize + 8, height: enhancedIconSize + 8)
                }
                
                Circle()
                    .strokeBorder(
                        isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
                    .frame(width: enhancedIconSize + 8, height: enhancedIconSize + 8)
            }
            .shadow(
                color: isSelected ? DesignTokens.Colors.primary.opacity(0.4) : .clear,
                radius: 8,
                x: 0,
                y: 2
            )
            
            // Learning icon
            Image(systemName: tab.icon)
                .font(.system(size: enhancedIconSize, weight: .bold))
                .foregroundColor(isSelected ? .white : DesignTokens.Colors.primary)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
    
    private var standardTabButton: some View {
        Image(systemName: tab.icon)
            .font(.system(size: iconSize, weight: .medium))
            .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

#Preview {
    MainTabView(appState: AppState())
}