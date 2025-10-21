import SwiftUI

/// Exercise-type ALO renderer with code editor
struct ExerciseCard: View {
    let alo: ALO
    let onSubmit: (String, Bool) -> Void
    let onNeedHelp: () -> Void

    @State private var userCode: String = ""
    @State private var currentHintIndex = 0
    @State private var showHints = false
    @State private var isSubmitting = false

    private var exerciseContent: ExerciseContent? {
        alo.exerciseContent
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header

                // Prompt Card
                if let content = exerciseContent {
                    promptCard(content: content)

                    // Code Editor
                    codeEditor(content: content)

                    // Hints Section
                    if showHints {
                        hintsSection(content: content)
                    }

                    // Actions
                    actionsRow
                }

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
        .onAppear {
            if let starterCode = exerciseContent?.starterCode {
                userCode = starterCode
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Exercise Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Exercise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Practice Your Skills")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Difficulty Badge
            HStack(spacing: 4) {
                ForEach(0..<abs(alo.difficulty) + 1, id: \.self) { _ in
                    Circle()
                        .fill(alo.difficulty >= 0 ? Color.orange : Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
        }
    }

    // MARK: - Prompt Card

    private func promptCard(content: ExerciseContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                Text("TASK")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()
            }

            Text(content.prompt)
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
                                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.orange.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Code Editor

    private func codeEditor(content: ExerciseContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.orange.opacity(0.8))

                Text((content.language ?? "code").uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()

                Text("\(userCode.count) characters")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Editor
            TextEditor(text: $userCode)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(Color(red: 0.8, green: 0.9, blue: 1.0))
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Hints Section

    private func hintsSection(content: ExerciseContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)

                Text("HINT \(currentHintIndex + 1) OF \(content.hints?.count ?? 0)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()

                if let hints = content.hints, currentHintIndex < hints.count - 1 {
                    Button(action: {
                        currentHintIndex += 1
                        onNeedHelp()
                    }) {
                        Text("Next Hint")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                }
            }

            if let hints = content.hints, currentHintIndex < hints.count {
                Text(hints[currentHintIndex])
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions Row

    private var actionsRow: some View {
        HStack(spacing: 12) {
            // Hint Button
            if !showHints {
                Button(action: {
                    withAnimation {
                        showHints = true
                        onNeedHelp()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                        Text("Hint")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.yellow)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                }
                .accessibilityLabel("Get a hint")
            }

            // Submit Button
            Button(action: {
                submitCode()
            }) {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Submit")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.orange.opacity(0.3), radius: 15, y: 8)
            }
            .disabled(isSubmitting || userCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(userCode.isEmpty ? 0.5 : 1.0)
            .accessibilityLabel("Submit code for review")
        }
    }

    // MARK: - Actions

    private func submitCode() {
        isSubmitting = true

        // Simulate basic validation (in production, send to backend)
        let passed = !userCode.isEmpty && userCode.count > 20

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(passed ? .success : .warning)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            onSubmit(userCode, passed)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockALO = ALO(
        id: UUID(),
        loId: UUID(),
        aloType: .exercise,
        estTimeSec: 300,
        content: [
            "prompt": AnyCodable("Create a flex container with 3 items arranged horizontally with equal spacing.\n\n**Requirements:**\n- Use `display: flex`\n- Distribute items with space between them\n- Align items to the center vertically"),
            "starter_code": AnyCodable("""
.container {
  /* Add your Flexbox properties here */
  height: 200px;
  border: 2px solid #ccc;
}

.item {
  width: 100px;
  height: 100px;
  background: #e74c3c;
}
"""),
            "language": AnyCodable("css"),
            "hints": AnyCodable([
                "Start with display: flex",
                "Use justify-content for horizontal spacing",
                "Use align-items for vertical alignment"
            ])
        ],
        assessmentSpec: [
            "checks": AnyCodable([
                ["property": "display", "value": "flex"],
                ["property": "justify-content", "value": "space-between"],
                ["property": "align-items", "value": "center"]
            ])
        ],
        difficulty: 0,
        tags: ["flexbox", "exercise"],
        createdAt: Date(),
        updatedAt: Date()
    )

    return ExerciseCard(
        alo: mockALO,
        onSubmit: { code, passed in
            print("Code submitted: \(passed)")
        },
        onNeedHelp: {
            print("Help requested")
        }
    )
}
