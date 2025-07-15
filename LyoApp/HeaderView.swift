
import SwiftUI

// MARK: - Story Strip Component
struct StoryStrip: View {
    @State private var stories = Story.sampleStories
    @State private var showingStoryViewer = false
    @State private var selectedStory: Story?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(stories) { story in
                    StoryCircle(story: story) {
                        selectedStory = story
                        showingStoryViewer = true
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
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
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.sm)
        .fullScreenCover(isPresented: $showingStoryViewer) {
            if let story = selectedStory {
                StoryViewer(story: story, isPresented: $showingStoryViewer)
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var showingStoryDrawer: Bool
    @State private var glowAnimation = false
    @State private var showAISearch = false
    @State private var showMessenger = false
    @State private var showLibrary = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                // Lyo Button (centered, replaces 'Stories')
                Button {
                    withAnimation(DesignTokens.Animations.bouncy) {
                        showingStoryDrawer.toggle()
                    }
                } label: {
                    ZStack {
                        // Outer glow ring
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        DesignTokens.Colors.neonBlue.opacity(glowAnimation ? 0.4 : 0.2),
                                        DesignTokens.Colors.neonPurple.opacity(glowAnimation ? 0.3 : 0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 110, height: 50)
                            .blur(radius: glowAnimation ? 8 : 4)
                        // Main container with holographic effect
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignTokens.Colors.glassBg.opacity(0.8),
                                        DesignTokens.Colors.glassOverlay.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 44)
                            .overlay(
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundColor(DesignTokens.Colors.neonBlue)
                                    Text("Lyo")
                                        .font(DesignTokens.Typography.buttonLabel)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                }
                            )
                            .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.18), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.top, 8)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glowAnimation.toggle()
                    }
                }
                Spacer()
                // Search Icon (AI-powered)
                Button(action: {
                    showAISearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background(DesignTokens.Colors.glassBg)
                        .clipShape(Circle())
                }
                // Message Icon (Instagram-like)
                Button(action: {
                    showMessenger = true
                }) {
                    Image(systemName: "message.fill")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background(DesignTokens.Colors.glassBg)
                        .clipShape(Circle())
                }
                // Library Icon (Netflix-style)
                Button(action: {
                    showLibrary = true
                }) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background(DesignTokens.Colors.glassBg)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            // Show the actual StoryStrip (story circles) only when drawer is open
            if showingStoryDrawer {
                StoryStrip()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(DesignTokens.Animations.smooth, value: showingStoryDrawer)
            }
        }
        // AI Search Sheet
        .sheet(isPresented: $showAISearch) {
            AISearchView()
        }
        // Messenger Modal
        .sheet(isPresented: $showMessenger) {
            MessengerView()
        }
        // Library Modal
        .sheet(isPresented: $showLibrary) {
            LibraryView()
        }
    }
}


// MARK: - Preview
#Preview {
    HeaderView(showingStoryDrawer: .constant(false))
        .background(DesignTokens.Colors.primaryBg)
}

struct StoryCard: View {
    let story: Story
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    // Story ring
                    Circle()
                        .strokeBorder(
                            story.isViewed ? 
                            LinearGradient(
                                colors: [DesignTokens.Colors.textSecondary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [DesignTokens.Colors.neonPink, DesignTokens.Colors.neonBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 70, height: 70)
                    
                    // Profile image
                    AsyncImage(url: URL(string: story.author.profileImageURL ?? "https://picsum.photos/60/60")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(DesignTokens.Colors.glassBg)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                }
                
                Text(story.author.username)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Preview
#Preview {
    HeaderView(showingStoryDrawer: .constant(false))
        .background(DesignTokens.Colors.primaryBg)
}
