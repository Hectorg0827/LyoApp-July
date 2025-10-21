import SwiftUI

/// Quiz-type ALO renderer with beautiful UI and smooth animations
struct QuizCard: View {
    let alo: ALO
    let onAnswer: (Bool) -> Void
    let onNeedHelp: () -> Void

    @State private var selectedIndex: Int? = nil
    @State private var showExplanation = false
    @State private var isCorrect = false
    @State private var hasAnswered = false

    private var quizContent: QuizContent? {
        alo.quizContent
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header

                // Question Card
                if let content = quizContent {
                    questionCard(content: content)

                    // Choices
                    choicesSection(content: content)

                    // Explanation (after answer)
                    if showExplanation && hasAnswered {
                        explanationCard(content: content)
                    }

                    // Submit Button
                    if !hasAnswered {
                        submitButton
                    }
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
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Quiz Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Quiz")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Test Your Understanding")
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

    // MARK: - Question Card

    private func questionCard(content: QuizContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)

                Text("QUESTION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()
            }

            Text(content.question)
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(.white)
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
                                colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.green.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Choices

    private func choicesSection(content: QuizContent) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(content.choices.enumerated()), id: \.offset) { index, choice in
                choiceButton(choice: choice, index: index, content: content)
            }
        }
    }

    private func choiceButton(choice: String, index: Int, content: QuizContent) -> some View {
        Button(action: {
            guard !hasAnswered else { return }
            selectedIndex = index
        }) {
            HStack(spacing: 16) {
                // Letter Badge
                ZStack {
                    Circle()
                        .fill(choiceBackgroundColor(index: index, content: content))
                        .frame(width: 40, height: 40)

                    Text(String(UnicodeScalar(65 + index)!)) // A, B, C, D
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(choiceTextColor(index: index, content: content))
                }

                // Choice Text
                Text(choice)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(choiceTextColor(index: index, content: content))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Selection Indicator
                if selectedIndex == index {
                    Image(systemName: hasAnswered ? checkmarkIcon(index: index, content: content) : "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(choiceIndicatorColor(index: index, content: content))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(choiceFillColor(index: index, content: content))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(choiceBorderColor(index: index, content: content), lineWidth: 2)
                    )
            )
        }
        .disabled(hasAnswered)
        .scaleEffect(selectedIndex == index && !hasAnswered ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
        .accessibilityLabel("Choice \(String(UnicodeScalar(65 + index)!)): \(choice)")
        .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
    }

    // MARK: - Choice Styling

    private func choiceBackgroundColor(index: Int, content: QuizContent) -> Color {
        if !hasAnswered {
            return selectedIndex == index ? Color.blue : Color.white.opacity(0.1)
        } else {
            if index == content.answerIndex {
                return Color.green
            } else if selectedIndex == index {
                return Color.red
            } else {
                return Color.white.opacity(0.1)
            }
        }
    }

    private func choiceTextColor(index: Int, content: QuizContent) -> Color {
        if !hasAnswered {
            return selectedIndex == index ? .white : .white.opacity(0.9)
        } else {
            return .white
        }
    }

    private func choiceFillColor(index: Int, content: QuizContent) -> Color {
        if !hasAnswered {
            return selectedIndex == index ? Color.blue.opacity(0.15) : Color.white.opacity(0.05)
        } else {
            if index == content.answerIndex {
                return Color.green.opacity(0.15)
            } else if selectedIndex == index {
                return Color.red.opacity(0.15)
            } else {
                return Color.white.opacity(0.05)
            }
        }
    }

    private func choiceBorderColor(index: Int, content: QuizContent) -> Color {
        if !hasAnswered {
            return selectedIndex == index ? Color.blue : Color.white.opacity(0.2)
        } else {
            if index == content.answerIndex {
                return Color.green
            } else if selectedIndex == index {
                return Color.red
            } else {
                return Color.white.opacity(0.2)
            }
        }
    }

    private func choiceIndicatorColor(index: Int, content: QuizContent) -> Color {
        if !hasAnswered {
            return .blue
        } else {
            return index == content.answerIndex ? .green : .red
        }
    }

    private func checkmarkIcon(index: Int, content: QuizContent) -> String {
        index == content.answerIndex ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    // MARK: - Explanation Card

    private func explanationCard(content: QuizContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isCorrect ? .green : .blue)

                Text(isCorrect ? "CORRECT!" : "EXPLANATION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
            }

            if let explanation = content.explanation {
                Text(explanation)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isCorrect ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: {
            submitAnswer()
        }) {
            HStack(spacing: 12) {
                Text("Submit Answer")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: selectedIndex != nil ? [Color.green, Color.green.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: selectedIndex != nil ? Color.green.opacity(0.3) : Color.clear, radius: 15, y: 8)
        }
        .disabled(selectedIndex == nil)
        .opacity(selectedIndex != nil ? 1.0 : 0.5)
        .accessibilityLabel("Submit answer")
        .accessibilityHint(selectedIndex != nil ? "Submit your selected answer" : "Please select an answer first")
    }

    // MARK: - Actions

    private func submitAnswer() {
        guard let selectedIndex = selectedIndex,
              let content = quizContent else { return }

        hasAnswered = true
        isCorrect = (selectedIndex == content.answerIndex)
        showExplanation = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(isCorrect ? .success : .error)

        // Delay callback to show visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onAnswer(isCorrect)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockALO = ALO(
        id: UUID(),
        loId: UUID(),
        aloType: .quiz,
        estTimeSec: 90,
        content: [
            "question": AnyCodable("Which property controls the direction of flex items in a flex container?"),
            "choices": AnyCodable(["flex-flow", "flex-direction", "flex-align", "flex-order"]),
            "answer_index": AnyCodable(1),
            "explanation": AnyCodable("`flex-direction` sets the main axis direction: row (horizontal) or column (vertical).")
        ],
        assessmentSpec: nil,
        difficulty: 0,
        tags: ["flexbox", "quiz"],
        createdAt: Date(),
        updatedAt: Date()
    )

    return QuizCard(
        alo: mockALO,
        onAnswer: { correct in
            print("Answer submitted: \(correct)")
        },
        onNeedHelp: {
            print("Help requested")
        }
    )
}
