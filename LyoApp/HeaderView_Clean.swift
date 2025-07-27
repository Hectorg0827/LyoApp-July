import SwiftUI

// MARK: - Premium Liquid Glass Story Strip Drawer
struct StoryStripDrawer: View {
    @Binding var showingStoryViewer: Bool
    @Binding var selectedStory: Story?
    @Binding var isOpen: Bool
    var onInteraction: () -> Void
    @State private var borderAnimation: CGFloat = 0
    @State private var glowAnimation: Bool = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Premium Add Story Circle (when drawer is open)
            if isOpen {
                PremiumAddStoryCircle {
                    onInteraction()
                    HapticManager.shared.medium()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.interpolatingSpring(stiffness: 300, damping: 25).delay(0.1)),
                    removal: .scale(scale: 1.2).combined(with: .opacity).animation(.interpolatingSpring(stiffness: 200, damping: 20))
                ))
            }
            
            // Horizontal Story Scroll with premium effects
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // TODO: Replace with real user stories from UserDataManager
                    ForEach([], id: \.id) { story in
                        // EmptyView() - story view implementation would go here
                    }
                        PremiumStoryCircle(story: story) {
                            selectedStory = story
                            showingStoryViewer = true
                            onInteraction()
                            HapticManager.shared.light()
                        }
                        .scaleEffect(calculateScaleForStory(story))
                    }
                }
                .padding(.horizontal, isOpen ? 16 : 8)
                .background(
                    GeometryReader { proxy in
                        Color.clear.onAppear {
                            scrollOffset = proxy.frame(in: .global).minX
                        }
                    }
                )
            }
            .scrollTargetBehavior(.paging)
        }
        .padding(.vertical, 24)
        .background(
            // Premium Liquid Glass Background with Infinite Scroll Illusion
            GeometryReader { geometry in
                ZStack {
                    // Base liquid glass layer
                    RoundedRectangle(cornerRadius: 20)
                        .fill(DesignTokens.Glass.baseLayer.background)
                        .frame(width: geometry.size.width + 300) // Extended for endless effect
                        .offset(x: -150)
                        .blur(radius: 0.5)
                    
                    // Content layer with animated gradients
                    RoundedRectangle(cornerRadius: 20)
                        .fill(DesignTokens.Glass.contentLayer.background)
                        .frame(width: geometry.size.width + 300)
                        .offset(x: -150)
                        .overlay(
                            // Animated gradient border
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            DesignTokens.Colors.brand.opacity(0.6),
                                            DesignTokens.Colors.accent.opacity(0.8),
                                            DesignTokens.Colors.brand.opacity(0.4),
                                            DesignTokens.Colors.accent.opacity(0.6)
                                        ],
                                        center: .center,
                                        startAngle: .degrees(borderAnimation),
                                        endAngle: .degrees(borderAnimation + 360)
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: geometry.size.width + 300)
                                .offset(x: -150)
                                .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: borderAnimation)
                        )
                    
                    // Frosted overlay for depth
                    RoundedRectangle(cornerRadius: 20)
                        .fill(DesignTokens.Glass.frostedLayer.background)
                        .frame(width: geometry.size.width + 300)
                        .offset(x: -150)
                        .blur(radius: 0.3)
                        .opacity(glowAnimation ? 0.8 : 0.6)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: glowAnimation)
                }
            }
        )
        .shadow(color: DesignTokens.Colors.brand.opacity(0.15), radius: 12, x: 0, y: 6)
        .shadow(color: DesignTokens.Colors.accent.opacity(0.1), radius: 24, x: 0, y: 12)
        .onAppear {
            startPremiumAnimations()
        }
    }
    
    private func startPremiumAnimations() {
        borderAnimation = 360
        glowAnimation = true
    }
    
    private func calculateScaleForStory(_ story: Story) -> CGFloat {
        // Dynamic scaling based on scroll position for premium effect
        return 1.0 + sin(scrollOffset * 0.01) * 0.05
    }
    
    // MARK: - Sample Data Removed
    // All mock stories moved to UserDataManager for real data management
    // generateMockStories() function removed - use UserDataManager.shared.getUserStories()
}

// MARK: - Premium Morphing Lyo Button with Liquid Glass
struct PremiumMorphingLyoButton: View {
    @Binding var isDrawerOpen: Bool
    let action: () -> Void
    @State private var morphAnimation: Bool = false
    @State private var glowPulse: Bool = false
    @State private var rotationEffect: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: {
            withAnimation(DesignTokens.Animations.fluid) {
                morphAnimation.toggle()
                scaleEffect = 0.9
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignTokens.Animations.snappy) {
                    scaleEffect = 1.0
                }
                action()
            }
            
            HapticManager.shared.medium()
        }) {
            ZStack {
                // Liquid glass base with morphing effect
                RoundedRectangle(cornerRadius: isDrawerOpen ? 28 : 20)
                    .fill(DesignTokens.Glass.interactiveLayer.background)
                    .frame(
                        width: isDrawerOpen ? 56 : 80,
                        height: isDrawerOpen ? 56 : 48
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isDrawerOpen ? 28 : 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        DesignTokens.Colors.brand.opacity(0.4),
                                        DesignTokens.Colors.accent.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: DesignTokens.Colors.brand.opacity(glowPulse ? 0.4 : 0.2), radius: glowPulse ? 12 : 8, x: 0, y: 4)
                    .animation(DesignTokens.Animations.fluid, value: isDrawerOpen)
                
                // Content that morphs between states
                if isDrawerOpen {
                    // Close X icon
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.brand)
                        .rotationEffect(.degrees(rotationEffect))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.interpolatingSpring(stiffness: 400, damping: 25).delay(0.1)),
                            removal: .scale.combined(with: .opacity).animation(.interpolatingSpring(stiffness: 300, damping: 20))
                        ))
                } else {
                    // Sparkles and Lyo text
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.brand)
                            .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text("Lyo")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .shadow(color: DesignTokens.Colors.brand.opacity(0.2), radius: 1, x: 0, y: 0.5)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.interpolatingSpring(stiffness: 400, damping: 25).delay(0.1)),
                        removal: .scale.combined(with: .opacity).animation(.interpolatingSpring(stiffness: 300, damping: 20))
                    ))
                }
                
                // Ambient glow effect
                RoundedRectangle(cornerRadius: isDrawerOpen ? 28 : 20)
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignTokens.Colors.brand.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(
                        width: isDrawerOpen ? 56 : 80,
                        height: isDrawerOpen ? 56 : 48
                    )
                    .opacity(glowPulse ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scaleEffect)
        .onAppear {
            glowPulse = true
            
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationEffect = 360
            }
        }
        .onLongPressGesture {
            // Long press to launch AI Avatar
            appState.presentAvatar()
            HapticManager.shared.success()
        }
    }
}

// MARK: - Premium Action Icon with Liquid Glass
struct PremiumActionIcon: View {
    let iconName: String
    let color: Color
    let action: () -> Void
    @State private var hoverScale: CGFloat = 1.0
    @State private var isPressed: Bool = false
    @State private var glowEffect: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(DesignTokens.Animations.buttonPress) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignTokens.Animations.snappy) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(DesignTokens.Glass.interactiveLayer.background)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                color.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: color.opacity(0.2), radius: 6, x: 0, y: 3)
                
                // Icon with premium styling
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 1, x: 0, y: 0.5)
                
                // Glow effect on hover
                if glowEffect {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                        .animation(.easeInOut(duration: 0.3), value: glowEffect)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(hoverScale)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onHover { hovering in
            withAnimation(DesignTokens.Animations.gentle) {
                hoverScale = hovering ? 1.05 : 1.0
                glowEffect = hovering
            }
        }
    }
}

// MARK: - Premium Header View with Liquid Glass and Morphing Effects
struct HeaderView: View {
    @Binding var showingStoryDrawer: Bool
    @State private var showingStoryViewer = false
    @State private var selectedStory: Story?
    @State private var autoCloseTimer: Timer?
    @State private var drawerOffset: CGFloat = 0
    @State private var currentTime = Date()
    @State private var appScaleEffect: CGFloat = 1.0
    @State private var appRoundedCorners: CGFloat = 0
    
    // Professional functionality states
    @State private var showingProfessionalSearch = false
    @State private var showingProfessionalMessenger = false
    @State private var showingProfessionalLibrary = false
    
    private let drawerHeight: CGFloat = 100
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top status bar with premium clock
            HStack {
                // Left side content - App Drawer Button (moves to left when open)
                // When closed: empty space
                // When open: App Drawer button transforms to X and sits on left
                PremiumMorphingLyoButton(isDrawerOpen: $showingStoryDrawer) {
                    toggleDrawer()
                }
                .offset(x: showingStoryDrawer ? 0 : UIScreen.main.bounds.width - 120) // Move to right when closed
                .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: showingStoryDrawer)
                
                // Center content with real-time clock (only when drawer is CLOSED)
                HStack {
                    Spacer()
                    
                    if !showingStoryDrawer {
                        // Premium status indicator with real-time clock
                        HStack(spacing: 8) {
                            // Live indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .shadow(color: Color.green.opacity(0.5), radius: 2, x: 0, y: 1)
                                Text("Live")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            
                            // Real-time clock
                            Text(currentTime, style: .time)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DesignTokens.Glass.contentLayer.background)
                                .cornerRadius(8)
                                .shadow(color: DesignTokens.Colors.brand.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.interpolatingSpring(stiffness: 400, damping: 30).delay(0.1)),
                            removal: .scale.combined(with: .opacity).animation(.interpolatingSpring(stiffness: 300, damping: 25))
                        ))
                    }
                    
                    Spacer()
                }
                
                // Right side content - Icons (only when drawer is OPEN)
                if showingStoryDrawer {
                    // Premium Action Icons with liquid glass (shown when drawer is open on RIGHT side)
                    HStack(spacing: 16) {
                        PremiumActionIcon(iconName: "magnifyingglass", color: DesignTokens.Colors.brand) {
                            showingProfessionalSearch = true
                            HapticManager.shared.medium()
                        }
                        
                        PremiumActionIcon(iconName: "message", color: DesignTokens.Colors.accent) {
                            showingProfessionalMessenger = true
                            HapticManager.shared.medium()
                        }
                        
                        PremiumActionIcon(iconName: "books.vertical", color: DesignTokens.Colors.brand.opacity(0.8)) {
                            showingProfessionalLibrary = true
                            HapticManager.shared.medium()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity).animation(.interpolatingSpring(stiffness: 300, damping: 25).delay(0.2)),
                        removal: .move(edge: .trailing).combined(with: .opacity).animation(.interpolatingSpring(stiffness: 200, damping: 20))
                    ))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, 8)
            .zIndex(2)
            
            // Premium Story Strip Drawer
            if showingStoryDrawer {
                StoryStripDrawer(
                    showingStoryViewer: $showingStoryViewer,
                    selectedStory: $selectedStory,
                    isOpen: $showingStoryDrawer,
                    onInteraction: startOrResetTimer
                )
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).animation(.interpolatingSpring(stiffness: 300, damping: 25).delay(0.1)),
                    removal: .move(edge: .top).combined(with: .opacity).animation(.interpolatingSpring(stiffness: 250, damping: 20))
                ))
                .zIndex(1)
            }
        }
        .scaleEffect(appScaleEffect)
        .cornerRadius(appRoundedCorners)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onChange(of: showingStoryDrawer) { _, isOpen in
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 25)) {
                appScaleEffect = isOpen ? 0.96 : 1.0
                appRoundedCorners = isOpen ? 16 : 0
            }
        }
        .onAppear {
            if showingStoryDrawer {
                startOrResetTimer()
            }
        }
    }
    
    private func toggleDrawer() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0.2)) {
            showingStoryDrawer.toggle()
        }
        
        if showingStoryDrawer {
            startOrResetTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startOrResetTimer() {
        stopTimer()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showingStoryDrawer = false
            }
            stopTimer()
        }
    }
    
    private func stopTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }
}

// MARK: - Premium Add Story Circle with Liquid Glass
struct PremiumAddStoryCircle: View {
    let action: () -> Void
    @State private var hoverScale: CGFloat = 1.0
    @State private var glowPulse: Bool = false
    @State private var borderRotation: Double = 0
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(DesignTokens.Animations.buttonPress) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignTokens.Animations.snappy) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Animated gradient border
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    DesignTokens.Colors.brand,
                                    DesignTokens.Colors.accent,
                                    DesignTokens.Colors.brand.opacity(0.6),
                                    DesignTokens.Colors.accent.opacity(0.8),
                                    DesignTokens.Colors.brand
                                ],
                                center: .center,
                                startAngle: .degrees(borderRotation),
                                endAngle: .degrees(borderRotation + 360)
                            ),
                            style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                        )
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(borderRotation))
                        .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: borderRotation)
                    
                    // Liquid glass background
                    Circle()
                        .fill(DesignTokens.Glass.interactiveLayer.background)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            DesignTokens.Colors.brand.opacity(0.1),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 34
                                    )
                                )
                                .opacity(glowPulse ? 1.0 : 0.6)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)
                        )
                    
                    // Plus icon with premium styling
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.brand)
                        .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 2, x: 0, y: 1)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                .scaleEffect(hoverScale)
                .shadow(color: DesignTokens.Colors.brand.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Text("Add Story")
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(DesignTokens.Animations.gentle) {
                hoverScale = hovering ? 1.05 : 1.0
            }
        }
        .onAppear {
            borderRotation = 360
            glowPulse = true
        }
        .frame(width: 80)
    }
}

// MARK: - Premium Story Circle with Advanced Effects
struct PremiumStoryCircle: View {
    let story: Story
    let action: () -> Void
    @State private var hoverScale: CGFloat = 1.0
    @State private var hoverGlow: Bool = false
    @State private var borderShimmer: Double = 0
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(DesignTokens.Animations.buttonPress) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignTokens.Animations.snappy) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Premium gradient border for unviewed stories
                    if !story.isViewed {
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [
                                        DesignTokens.Colors.brand,
                                        DesignTokens.Colors.accent.opacity(0.8),
                                        DesignTokens.Colors.brand.opacity(0.6),
                                        DesignTokens.Colors.accent,
                                        DesignTokens.Colors.brand
                                    ],
                                    center: .center,
                                    startAngle: .degrees(borderShimmer),
                                    endAngle: .degrees(borderShimmer + 360)
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 76, height: 76)
                            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: borderShimmer)
                            .shadow(color: DesignTokens.Colors.brand.opacity(0.4), radius: hoverGlow ? 8 : 4, x: 0, y: 2)
                    } else {
                        // Subtle border for viewed stories
                        Circle()
                            .strokeBorder(DesignTokens.Colors.textSecondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 76, height: 76)
                    }
                    
                    // Premium user avatar with liquid glass effect
                    AsyncImage(url: URL(string: story.author.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(DesignTokens.Glass.contentLayer.background)
                            .overlay(
                                Text(story.author.username.prefix(1).uppercased())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(DesignTokens.Colors.brand)
                            )
                    }
                    .frame(width: 68, height: 68)
                    .clipShape(Circle())
                    .overlay(
                        // Liquid glass overlay
                        Circle()
                            .fill(DesignTokens.Glass.frostedLayer.background.opacity(0.1))
                            .frame(width: 68, height: 68)
                            .opacity(hoverGlow ? 0.3 : 0.0)
                            .animation(.easeInOut(duration: 0.3), value: hoverGlow)
                    )
                    
                    // Premium notification badge for verified users
                    if story.author.isVerified {
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(DesignTokens.Colors.brand)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: DesignTokens.Colors.brand.opacity(0.4), radius: 4, x: 0, y: 2)
                                    .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                        .frame(width: 76, height: 76)
                    }
                }
                .scaleEffect(hoverScale)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .shadow(color: DesignTokens.Colors.brand.opacity(hoverGlow ? 0.3 : 0.1), radius: hoverGlow ? 12 : 6, x: 0, y: 4)
                
                Text(story.author.username)
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(DesignTokens.Animations.gentle) {
                hoverScale = hovering ? 1.08 : 1.0
                hoverGlow = hovering
            }
        }
        .onAppear {
            if !story.isViewed {
                borderShimmer = 360
            }
        }
        .frame(width: 80)
    }
}

#Preview {
    HeaderView(showingStoryDrawer: .constant(false))
        .background(DesignTokens.Colors.backgroundPrimary)
}
