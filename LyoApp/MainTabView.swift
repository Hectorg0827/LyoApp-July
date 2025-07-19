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
            AIFullChatViewWithCompletion(onComplete: { topic in
                // Handle the topic completion
                appState.setCurrentTopic(topic)
            })
                .environmentObject(appState)
        case .post:
            EmptyView()
                .onAppear {
                    showingPost = true
                }
        case .more:
            MoreTabView()
                .environmentObject(appState)
        }
    }

    // MARK: - Custom Tab Bar
    @ViewBuilder
    private var customTabBarView: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                FuturisticTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    showLabel: true,
                    iconSize: 18,
                    action: { handleTabSelection(tab) }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60) // Ensure proper height
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
        .padding(.horizontal, 16)
    }

    // MARK: - Tab Selection Handler
    private func handleTabSelection(_ tab: MainTab) {
        print("🎯 handleTabSelection called for: \(tab.rawValue)")
        print("🎯 Current selectedTab: \(selectedTab.rawValue)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        withAnimation(DesignTokens.Animations.quick) {
            selectedTab = tab
            appState.selectedTab = tab
        }
        
        print("🎯 After selection - selectedTab: \(selectedTab.rawValue)")
        print("🎯 After selection - appState.selectedTab: \(appState.selectedTab.rawValue)")
        
        if tab == .post {
            showingPost = true
        }
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
    
    var body: some View {
        Button(action: {
            print("🔘 Tab button tapped: \(tab.rawValue)")
            action()
        }) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    // Standard tab button for all tabs
                    standardTabButton
                }
                
                if showLabel {
                    Text(tab.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
                glowAnimation = true
            }
        }
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