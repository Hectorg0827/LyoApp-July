import SwiftUI

/// Slide-in drawer displaying curated content resources
struct ContentCardDrawer: View {
    let cards: [ContentCard]
    let onCardSelected: (ContentCard) -> Void
    let onClose: () -> Void

    @State private var animateIn: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Dim overlay - tap to close
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    closeDrawer()
                }

            // Drawer content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Learning Resources")
                            .font(DesignTokens.Typography.titleLarge)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text("\(cards.count) curated for you")
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }

                    Spacer()

                    Button(action: closeDrawer) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .padding()
                .background(DesignTokens.Colors.backgroundSecondary)

                Divider()
                    .background(DesignTokens.Colors.textTertiary.opacity(0.3))

                // Card list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cards) { card in
                            ContentCardRow(card: card)
                                .onTapGesture {
                                    onCardSelected(card)
                                    HapticManager.shared.light()
                                }
                        }
                    }
                    .padding()
                }
                .background(DesignTokens.Colors.backgroundPrimary)
            }
            .frame(width: min(UIScreen.main.bounds.width * 0.85, 400))
            .background(DesignTokens.Colors.backgroundPrimary)
            .offset(x: animateIn ? 0 : 400)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }

    private func closeDrawer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            animateIn = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onClose()
        }

        HapticManager.shared.light()
    }
}

/// Individual content card row in the drawer
struct ContentCardRow: View {
    let card: ContentCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            if let thumbnailURL = card.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
                .frame(height: 180)
                .clipped()
                .cornerRadius(12)
            } else {
                thumbnailPlaceholder
                    .frame(height: 180)
                    .cornerRadius(12)
            }

            // Content info
            VStack(alignment: .leading, spacing: 8) {
                // Type badge
                HStack(spacing: 8) {
                    Label(card.kind.rawValue.capitalized, systemImage: card.kind.iconName)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(card.kind.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(card.kind.color.opacity(0.15))
                        )

                    Text("\(card.estMinutes) min")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.backgroundTertiary)
                        )

                    Spacer()

                    // Relevance score
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(DesignTokens.Colors.neonYellow)

                        Text(String(format: "%.0f%%", card.relevanceScore * 100))
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }

                // Title
                Text(card.title)
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                // Source
                Text(card.source)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                // Summary
                Text(card.summary)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
                    .lineLimit(3)

                // Tags
                if !card.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(card.tags.prefix(5), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(DesignTokens.Typography.labelSmall)
                                    .foregroundColor(DesignTokens.Colors.brand)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(DesignTokens.Colors.brand.opacity(0.1))
                                    )
                            }
                        }
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Label("Save", systemImage: card.isSaved ? "bookmark.fill" : "bookmark")
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }

                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }

                    Spacer()

                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Text("View")
                                .font(DesignTokens.Typography.labelLarge)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.brand)
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [card.kind.color.opacity(0.3), card.kind.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: card.kind.iconName)
                .font(.system(size: 48))
                .foregroundColor(card.kind.color)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ContentCardDrawer(
            cards: ContentCard.mockCards,
            onCardSelected: { card in
                print("Selected: \(card.title)")
            },
            onClose: {
                print("Drawer closed")
            }
        )
    }
}
