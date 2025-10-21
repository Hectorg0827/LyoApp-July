import SwiftUI
// import MarkdownUI // TEMPORARY: Commented until Xcode resolves packages properly

/// Explain-type ALO renderer with rich markdown support
struct ExplainCard: View {
    let alo: ALO
    let onComplete: () -> Void
    let onNeedHelp: () -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var hasScrolledToBottom = false
    @State private var showCompleteButton = false

    private var explainContent: ExplainContent? {
        alo.explainContent
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Content Card
                    if let content = explainContent {
                        contentCard(content: content)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .background(GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    checkScrollProgress()
                }
            }
            .coordinateSpace(name: "scroll")
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.05, blue: 0.13),
                        Color(red: 0.05, green: 0.08, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            // Complete Button
            if showCompleteButton || hasScrolledToBottom {
                completeButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Explain Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "book.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Explanation")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Learn the Concept")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Help Button
            Button(action: onNeedHelp) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
            }
            .accessibilityLabel("Request help")
        }
    }

    // MARK: - Content Card

    private func contentCard(content: ExplainContent) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // TEMPORARY: Using Text until MarkdownUI package resolves
            Text(content.markdown)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)

            // Assets (if any)
            if let assetUrls = content.assetUrls, !assetUrls.isEmpty {
                assetsSection(urls: assetUrls)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.blue.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Assets Section

    private func assetsSection(urls: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESOURCES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1.5)

            ForEach(urls, id: \.self) { url in
                Link(destination: URL(string: url)!) {
                    HStack(spacing: 12) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        Text(url)
                            .font(.system(size: 15))
                            .foregroundColor(.blue)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundColor(.blue.opacity(0.6))
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onComplete()
        }) {
            HStack(spacing: 12) {
                Text("I Understand")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 15, y: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Mark as understood and continue")
    }

    // MARK: - Scroll Tracking

    private func checkScrollProgress() {
        // Show button after scrolling 60% or reaching bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCompleteButton = true
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Custom Markdown Theme

extension Theme {
    static let lyoDark = Theme()
        .text {
            ForegroundColor(.white.opacity(0.9))
            FontSize(17)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(16)
            ForegroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
        }
        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 8) {
                configuration.label
                    .relativePadding(.bottom, length: .em(0.3))
                    .relativeLineSpacing(.em(0.125))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(28)
                    }
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 2)
            }
        }
        .heading2 { configuration in
            configuration.label
                .relativePadding(.top, length: .em(0.5))
                .relativePadding(.bottom, length: .em(0.3))
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(24)
                }
        }
}

// MARK: - Preview

#Preview {
    let mockALO = ALO(
        id: UUID(),
        loId: UUID(),
        aloType: .explain,
        estTimeSec: 180,
        content: [
            "markdown": AnyCodable("""
# Understanding the CSS Box Model

Every element in web design is a **rectangular box**. The CSS box model describes how space is calculated around each element.

## The Four Layers

1. **Content** – Your text, images, or other media
2. **Padding** – Clear space around the content, inside the border
3. **Border** – A line around the padding (can be invisible)
4. **Margin** – Space outside the border, separating from other elements

## Key Insight

When you set `width: 300px`, you're often setting the **content** width. Padding and border are *added* on top.

## Example

```css
.box {
  width: 200px;
  padding: 20px;
  border: 2px solid black;
  margin: 10px;
}
/* Total width = 200 + 20×2 + 2×2 = 244px */
```

This foundational knowledge is critical for controlling layout precisely!
"""),
            "asset_urls": AnyCodable([])
        ],
        assessmentSpec: nil,
        difficulty: -1,
        tags: ["css", "box-model"],
        createdAt: Date(),
        updatedAt: Date()
    )

    return ExplainCard(
        alo: mockALO,
        onComplete: {
            print("Explanation completed")
        },
        onNeedHelp: {
            print("Help requested")
        }
    )
}
