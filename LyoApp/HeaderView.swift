// MARK: - Minimal DrawerContentView Stub (Fixes missing symbol error)
struct DrawerContentView: View {
    @Binding var showingStoryViewer: Bool
    @Binding var selectedStory: Story?
    var onInteraction: () -> Void
    @State private var showAISearch = false
    @State private var showMessenger = false
    @State private var showLibrary = false
    var body: some View {
        VStack(spacing: 0) {
            // Icons aligned right, no text, less intrusive
            HStack(spacing: 24) {
                Button(action: {
                    showAISearch = true
                    onInteraction()
                }) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.neonBlue)
                        .padding(12)
                        .background(DesignTokens.Colors.glassOverlay.opacity(0.3))
                        .clipShape(Circle())
                }
                Button(action: {
                    showMessenger = true
                    onInteraction()
                }) {
                    Image(systemName: "message.fill")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.neonPurple)
                        .padding(12)
                        .background(DesignTokens.Colors.glassOverlay.opacity(0.3))
                        .clipShape(Circle())
                }
                Button(action: {
                    showLibrary = true
                    onInteraction()
                }) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.neonPink)
                        .padding(12)
                        .background(DesignTokens.Colors.glassOverlay.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
            .padding(.top, 8)

            // Story strip under icons
            StoryStrip()
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Colors.glassBg)
                .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showAISearch) { AISearchView() }
        .sheet(isPresented: $showMessenger) { MessengerView() }
        .sheet(isPresented: $showLibrary) { LibraryView() }
    }
}
import SwiftUI
// MARK: - Add Story Circle (Top-level, before StoryStrip)
struct AddStoryCircle: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [DesignTokens.Colors.neonBlue, DesignTokens.Colors.neonPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 70, height: 70)
                    Circle()
                        .fill(DesignTokens.Colors.glassBg)
                        .frame(width: 60, height: 60)
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.neonBlue)
                }
                Text("Add Story")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
    }
}
// MARK: - Lyo Button
struct LyoButton: View {
    @Binding var showingStoryDrawer: Bool
    @State private var glowAnimation = false
    @State private var showingAIAvatar = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button {
            // Toggle between story drawer and AI Avatar
            if showingStoryDrawer {
                showingStoryDrawer = false
            } else {
                // Launch AI Avatar
                appState.presentAvatar()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(LinearGradient(
                        colors: [DesignTokens.Colors.glassBg.opacity(0.7), DesignTokens.Colors.neonBlue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 56)
                    .shadow(color: glowAnimation ? DesignTokens.Colors.neonPink.opacity(0.3) : .clear, radius: 18)
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.neonBlue)
                        .opacity(0.8)
                        .shadow(color: DesignTokens.Colors.neonPink.opacity(0.5), radius: 2)
                    Text("Lyo")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
        .onLongPressGesture {
            // Long press to show story drawer
            showingStoryDrawer.toggle()
        }
    }
}

struct DrawerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(height: 44)
            .background(configuration.isPressed ? DesignTokens.Colors.glassOverlay : DesignTokens.Colors.glassBg.opacity(0.5))
            .clipShape(Capsule())
    }
}

struct HeaderView: View {
    @Binding var showingStoryDrawer: Bool
    @State private var showingStoryViewer = false
    @State private var selectedStory: Story?
    @State private var autoCloseTimer: Timer?

    var body: some View {
        ZStack(alignment: .top) {
            // Drawer Content (appears when open, below button)
            if showingStoryDrawer {
                HStack {
                    DrawerContentView(
                        showingStoryViewer: $showingStoryViewer,
                        selectedStory: $selectedStory,
                        onInteraction: startOrResetTimer
                    )
                    Spacer()
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
                .animation(DesignTokens.Animations.smooth, value: showingStoryDrawer)
            }
            // App Drawer Button (always on top and clickable)
            HStack {
                Spacer()
                LyoButton(showingStoryDrawer: $showingStoryDrawer)
                    .offset(x: showingStoryDrawer ? -UIScreen.main.bounds.width + 140 : 0)
                    .animation(DesignTokens.Animations.smooth, value: showingStoryDrawer)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .zIndex(1)
        }
        .fullScreenCover(isPresented: $showingStoryViewer) {
            if let story = selectedStory {
                StoryViewer(story: story, isPresented: $showingStoryViewer)
            }
        }
        .onChange(of: showingStoryDrawer) { oldValue, newValue in
            if newValue {
                startOrResetTimer()
            } else {
                invalidateTimer()
            }
        }
    }
    private func startOrResetTimer() {
        invalidateTimer()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            withAnimation(DesignTokens.Animations.smooth) {
                showingStoryDrawer = false
            }
        }
    }
    private func invalidateTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }
}

import SwiftUI

// MARK: - Story Strip Component
struct StoryStrip: View {
    @State private var stories = Story.sampleStories
    @State private var showingStoryViewer = false
    @State private var selectedStory: Story?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Add Story Circle (first item)
                AddStoryCircle {
                    // Action for add story (e.g., open camera or picker)
                }
                // Endless stories
                ForEach(stories) { story in
                    StoryCircle(story: story) {
                        selectedStory = story
                        showingStoryViewer = true
                    }
                }
            }
        }
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .fullScreenCover(isPresented: $showingStoryViewer) {
            if let story = selectedStory {
                StoryViewer(story: story, isPresented: $showingStoryViewer)
            }
        }
    }

// MARK: - Add Story Circle
}

#Preview {
    HeaderView(showingStoryDrawer: .constant(false))
        .background(DesignTokens.Colors.primaryBg)
}
