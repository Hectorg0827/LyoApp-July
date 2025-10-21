import SwiftUI

/// Example-type ALO renderer with code display
struct ExampleCard: View {
    let alo: ALO
    let onComplete: () -> Void
    let onNeedHelp: () -> Void

    @State private var codeCopied = false

    private var exampleContent: ExampleContent? {
        alo.exampleContent
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header

                // Description Card
                if let content = exampleContent {
                    descriptionCard(content: content)

                    // Code Block
                    if let code = content.code {
                        codeBlock(code: code, language: content.language ?? "swift")
                    }
                }

                // Complete Button
                completeButton

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
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
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Example Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Example")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("See It In Action")
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

    // MARK: - Description Card

    private func descriptionCard(content: ExampleContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)

                Text("DESCRIPTION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()
            }

            Text(content.markdown)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.purple.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Code Block

    private func codeBlock(code: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.purple.opacity(0.8))

                Text(language.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()

                // Copy Button
                Button(action: {
                    copyCode(code)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14))
                        Text(codeCopied ? "Copied!" : "Copy")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(codeCopied ? .green : .purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(codeCopied ? Color.green.opacity(0.15) : Color.purple.opacity(0.15))
                    )
                }
                .accessibilityLabel(codeCopied ? "Code copied" : "Copy code")
            }

            // Code Content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(Color(red: 0.8, green: 0.9, blue: 1.0))
                    .padding(16)
            }
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onComplete()
        }) {
            HStack(spacing: 12) {
                Text("Got It")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.purple.opacity(0.3), radius: 15, y: 8)
        }
        .accessibilityLabel("Mark example as understood and continue")
    }

    // MARK: - Actions

    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        codeCopied = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            codeCopied = false
        }
    }
}

// MARK: - Preview

#Preview {
    let mockALO = ALO(
        id: UUID(),
        loId: UUID(),
        aloType: .example,
        estTimeSec: 120,
        content: [
            "markdown": AnyCodable("## Perfect Centering with Flexbox\n\nThe classic \"how do I center a div\" problem, solved elegantly:"),
            "code": AnyCodable("""
.container {
  display: flex;
  justify-content: center; /* Center horizontally */
  align-items: center;     /* Center vertically */
  height: 100vh;
}

.box {
  width: 200px;
  height: 200px;
  background: #3498db;
  color: white;
}
"""),
            "language": AnyCodable("css"),
            "asset_urls": AnyCodable([])
        ],
        assessmentSpec: nil,
        difficulty: 0,
        tags: ["flexbox", "centering"],
        createdAt: Date(),
        updatedAt: Date()
    )

    return ExampleCard(
        alo: mockALO,
        onComplete: {
            print("Example completed")
        },
        onNeedHelp: {
            print("Help requested")
        }
    )
}
