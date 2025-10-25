//
//  HeaderView.swift
//  LyoApp
//
//  Futuristic AI drawer with animated Lyo button and glassmorphic interface
//

import SwiftUI
import Combine
#if canImport(NukeUI)
import NukeUI
#endif

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var userDataManager = UserDataManager.shared
    @State private var isDrawerExpanded = false
    @State private var buttonPosition: CGFloat = UIScreen.main.bounds.width - 70
    @State private var glowIntensity: Double = 0.3
    @State private var showIcons = false
    @State private var showStories = false
    @State private var stories: [Story] = []
    
    // Navigation states
    @State private var showSearchView = false
    @State private var showMessengerView = false
    @State private var showLibraryView = false
    @State private var showStoryCreation = false
    
    private let expandedButtonPosition: CGFloat = 70
    private let collapsedButtonPosition: CGFloat = UIScreen.main.bounds.width - 70
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Glassmorphic background for expanded drawer
                if isDrawerExpanded {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sheet)
                        .glassEffect(DesignTokens.Glass.baseLayer)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sheet)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.Colors.brand.opacity(glowIntensity),
                                            DesignTokens.Colors.accent.opacity(glowIntensity * 0.7),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .frame(height: 60)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .shadow(color: DesignTokens.Colors.brand.opacity(glowIntensity * 0.5), radius: 15, x: 0, y: 5)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
                
                HStack {
                    lyoAIButton
                        .position(x: buttonPosition, y: 30)
                    
                    Spacer()
                    
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
            .padding(.top, DesignTokens.Spacing.sm)
            
            if showStories {
                futuristicStoriesSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .onAppear(perform: loadStories)
        .sheet(isPresented: $showSearchView) { AISearchView() }
        .sheet(isPresented: $showMessengerView) { MessengerView() }
        .sheet(isPresented: $showLibraryView) { LibraryView() }
        .fullScreenCover(isPresented: $showStoryCreation) { StoryCreationView() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main header and stories")
    }
    
    // MARK: - Lyo AI Button
    private var lyoAIButton: some View {
        Button(action: handleDrawerToggle) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: DesignTokens.Colors.brand, location: 0.0),
                                .init(color: DesignTokens.Colors.accent, location: 0.7),
                                .init(color: .black.opacity(0.8), location: 1.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: DesignTokens.Colors.brand.opacity(glowIntensity), radius: 10)
                
                Text("Lyo")
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .shadow(color: .white, radius: 3)
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(.plain)
        .scaleEffect(isDrawerExpanded ? 0.9 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDrawerExpanded)
        .accessibilityLabel(isDrawerExpanded ? "Close quick actions" : "Open quick actions")
    }
    
    // MARK: - Action Icons Row
    private var actionIconsRow: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            actionIcon(systemName: "magnifyingglass", accessibilityLabel: "Search", action: {
                showSearchView = true
            })
            
            actionIcon(systemName: "message", accessibilityLabel: "Messenger", action: {
                showMessengerView = true
            })
            
            actionIcon(systemName: "books.vertical", accessibilityLabel: "Library", action: {
                showLibraryView = true
            })
        }
        .padding(.trailing, DesignTokens.Spacing.xl)
    }
    
    private func actionIcon(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            ZStack {
                Circle()
                    .glassEffect(DesignTokens.Glass.interactiveLayer)
                    .frame(width: 40, height: 40)
                
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.brand)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(0.8)
        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: showIcons)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Futuristic Stories Section
    private var futuristicStoriesSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Stories")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    HapticManager.shared.light()
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.accent)
                .accessibilityLabel("See all stories")
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    addStoryCircle
                    
                    ForEach(stories, id: \.id) { story in
                        StoryCircle(story: story) {
                            print("Story tapped: \(story.author.username)")
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    // MARK: - Add Story Circle
    private var addStoryCircle: some View {
        Button(action: {
            HapticManager.shared.medium()
            showStoryCreation = true
        }) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .stroke(
                            DesignTokens.Colors.neonGradient,
                            style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                        )
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .glassEffect(DesignTokens.Glass.interactiveLayer)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(DesignTokens.Colors.brand)
                        )
                        .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 8)
                }
                
                Text("Your Story")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add to your story")
    }
    
    // MARK: - Animation & Data Methods
    private func handleDrawerToggle() {
        HapticManager.shared.medium()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            isDrawerExpanded.toggle()
            buttonPosition = isDrawerExpanded ? expandedButtonPosition : collapsedButtonPosition
            glowIntensity = isDrawerExpanded ? 0.8 : 0.3
        }
        
        if isDrawerExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showIcons = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { showStories = true }
            }
        } else {
            showIcons = false
            showStories = false
        }
    }
    
    private func loadStories() {
        stories = userDataManager.getUserStories()
    }
}

// MARK: - Futuristic Story Circle
struct FuturisticStoryCircle: View {
    let story: Story
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.medium()
            print("Story tapped: \(story.author.username)")
        }) {
            ZStack {
                Circle()
                    .strokeBorder(DesignTokens.Colors.cosmicGradient, lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .blur(radius: 0.5)
                
                // Image with NukeUI if available, otherwise AsyncImage
                #if canImport(NukeUI)
                LazyImage(url: URL(string: story.mediaURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(DesignTokens.Colors.subtleGradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(story.author.username.prefix(1).uppercased()))
                                    .font(DesignTokens.Typography.titleLarge)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            )
                    }
                }
                #else
                AsyncImage(url: URL(string: story.mediaURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(DesignTokens.Colors.subtleGradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(story.author.username.prefix(1).uppercased()))
                                    .font(DesignTokens.Typography.titleLarge)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            )
                    }
                }
                #endif
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.2), .clear],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .blendMode(.overlay)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(story.author.username)'s story")
    }
}

// MARK: - Helper Extension
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { isPressing in
            if isPressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}

// Simple Story Creation View
struct StoryCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStoryType: StoryType = .photo
    
    enum StoryType: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case photo = "Photo"
        case video = "Video"
        case text = "Text"
        case ai = "AI Art"
        case poll = "Poll"
        case quiz = "Quiz"
        
        var icon: String {
            switch self {
            case .photo: "camera.fill"
            case .video: "video.fill"
            case .text: "text.alignleft"
            case .ai: "wand.and.stars"
            case .poll: "chart.bar.fill"
            case .quiz: "questionmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.Colors.cosmicGradient.ignoresSafeArea()
                
                VStack(spacing: DesignTokens.Spacing.lg) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.lg) {
                        ForEach(StoryType.allCases) { type in
                            storyTypeButton(type)
                        }
                    }
                    .padding(.horizontal)
                    
                    contentView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DesignTokens.Radius.xl)
                        .padding()
                    
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        Button("Cancel") { dismiss() }
                            .buttonStyle(GhostButtonStyle())
                        
                        Button("Share Story") { dismiss() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    @ViewBuilder
    private func storyTypeButton(_ type: StoryType) -> some View {
        Button(action: { selectedStoryType = type }) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: type.icon)
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(selectedStoryType == type ? DesignTokens.Colors.textInverse : DesignTokens.Colors.textPrimary)
                
                Text(type.rawValue)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(selectedStoryType == type ? DesignTokens.Colors.textInverse : DesignTokens.Colors.textPrimary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(selectedStoryType == type ? DesignTokens.Colors.brand : .white.opacity(0.2))
            )
        }
        .accessibilityLabel(type.rawValue)
        .accessibilityHint("Select \(type.rawValue) story type")
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        switch selectedStoryType {
        case .photo: PhotosPickerView()
        case .video: VideoCreationView()
        case .text: TextStoryView()
        case .ai: AIArtView()
        case .poll: PollCreationView()
        case .quiz: QuizCreationView()
        }
    }
}

// MARK: - Reusable Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.brand)
            .cornerRadius(DesignTokens.Radius.button)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignTokens.Animations.buttonPress, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.brand)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .stroke(DesignTokens.Colors.brand, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(DesignTokens.Animations.quick, value: configuration.isPressed)
    }
}

// Supporting Views
struct PhotosPickerView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("Tap to select photo")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(DesignTokens.Typography.headline)
        }
    }
}

struct VideoCreationView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "video.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("Record or select video")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(DesignTokens.Typography.headline)
        }
    }
}

struct TextStoryView: View {
    @State private var storyText: String = ""
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $storyText)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .background(.clear)
                .font(DesignTokens.Typography.titleLarge)
                .padding()
            
            if storyText.isEmpty {
                Text("What's on your mind?")
                    .foregroundColor(DesignTokens.Colors.textTertiary)
                    .font(DesignTokens.Typography.headline)
                    .padding()
                    .padding(.top, 8) // Align with TextEditor
            }
        }
    }
}

struct AIArtView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("Generate AI artwork")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(DesignTokens.Typography.headline)
        }
    }
}

struct PollCreationView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("Create a poll")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(DesignTokens.Typography.headline)
        }
    }
}

struct QuizCreationView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("Create a quiz")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(DesignTokens.Typography.headline)
        }
    }
}

#Preview {
    HeaderView()
        .environmentObject(AppState())
        .background(Color.black.ignoresSafeArea())
}
