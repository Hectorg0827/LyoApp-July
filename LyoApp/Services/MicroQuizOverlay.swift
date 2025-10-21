import SwiftUI

/// Interactive quiz overlay that appears between lesson chunks
struct MicroQuizOverlay: View {
    let quiz: MicroQuiz
    let onComplete: (Bool) -> Void

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswers: [UUID: Int] = [:]
    @State private var showingExplanation: Bool = false
    @State private var quizCompleted: Bool = false
    @State private var score: Double = 0.0
    @State private var animateIn: Bool = false

    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentQuestionIndex]
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }

    var body: some View {
        ZStack {
            // Backdrop blur
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal
                }

            if quizCompleted {
                completionView
            } else if let question = currentQuestion {
                quizQuestionView(question)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }

    // MARK: - Quiz Question View
    @ViewBuilder
    private func quizQuestionView(_ question: QuizQuestion) -> some View {
        VStack(spacing: 32) {
            // Avatar speaks the question
            AvatarSpeakingView()

            VStack(spacing: 24) {
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<quiz.questions.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentQuestionIndex ? DesignTokens.Colors.brand : Color.white.opacity(0.3))
                            .frame(width: 40, height: 4)
                    }
                }

                // Question card
                VStack(spacing: 20) {
                    // Question number
                    Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)

                    // Question text
                    Text(question.question)
                        .font(DesignTokens.Typography.titleLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // Answer options
                    VStack(spacing: 12) {
                        ForEach(Array(question.answers.enumerated()), id: \.offset) { index, answer in
                            AnswerButton(
                                answer: answer,
                                index: index,
                                isSelected: selectedAnswers[question.id] == index,
                                isCorrect: showingExplanation ? index == question.correctAnswerIndex : nil,
                                onSelect: {
                                    selectAnswer(index, for: question)
                                }
                            )
                        }
                    }
                    .padding(.top, 8)

                    // Explanation (if shown)
                    if showingExplanation {
                        explanationView(question)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Action button
                    if let selected = selectedAnswers[question.id] {
                        if showingExplanation {
                            // Next/Finish button
                            Button(action: handleNextQuestion) {
                                Text(isLastQuestion ? "Finish Quiz" : "Next Question")
                                    .font(DesignTokens.Typography.titleMedium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DesignTokens.Colors.brandGradient)
                                    )
                            }
                        } else {
                            // Submit button
                            Button(action: submitAnswer) {
                                Text("Submit Answer")
                                    .font(DesignTokens.Typography.titleMedium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DesignTokens.Colors.brand)
                                    )
                            }
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(DesignTokens.Colors.backgroundSecondary)
                        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                )
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding(.top, 60)
        .scaleEffect(animateIn ? 1.0 : 0.8)
        .opacity(animateIn ? 1.0 : 0.0)
    }

    // MARK: - Explanation View
    @ViewBuilder
    private func explanationView(_ question: QuizQuestion) -> some View {
        let isCorrect = selectedAnswers[question.id] == question.correctAnswerIndex

        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)

            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? "Correct!" : "Not quite right")
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)

                if !question.explanation.isEmpty {
                    Text(question.explanation)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? DesignTokens.Colors.success.opacity(0.1) : DesignTokens.Colors.error.opacity(0.1))
        )
    }

    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 32) {
            // Success animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                score >= quiz.passThreshold ? DesignTokens.Colors.success.opacity(0.3) : DesignTokens.Colors.warning.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: score >= quiz.passThreshold ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(score >= quiz.passThreshold ? DesignTokens.Colors.success : DesignTokens.Colors.warning)
            }

            VStack(spacing: 12) {
                Text(score >= quiz.passThreshold ? "Great Job!" : "Keep Practicing")
                    .font(DesignTokens.Typography.displaySmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text("You scored \(Int(score * 100))%")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                if score >= quiz.passThreshold {
                    Text("You've mastered this concept!")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                } else {
                    Text("Let's review the material and try again")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }

            Button(action: {
                HapticManager.shared.success()
                onComplete(score >= quiz.passThreshold)
            }) {
                Text("Continue Learning")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignTokens.Colors.brandGradient)
                    )
            }
            .padding(.horizontal, 40)
        }
        .scaleEffect(animateIn ? 1.0 : 0.8)
        .opacity(animateIn ? 1.0 : 0.0)
    }

    // MARK: - Methods

    private func selectAnswer(_ index: Int, for question: QuizQuestion) {
        guard !showingExplanation else { return }

        selectedAnswers[question.id] = index
        HapticManager.shared.light()
    }

    private func submitAnswer() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingExplanation = true
        }

        guard let question = currentQuestion,
              let selectedIndex = selectedAnswers[question.id] else { return }

        if selectedIndex == question.correctAnswerIndex {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }
    }

    private func handleNextQuestion() {
        showingExplanation = false

        if isLastQuestion {
            // Calculate final score
            calculateScore()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                quizCompleted = true
                animateIn = false
            }

            // Re-animate completion view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateIn = true
                }
            }
        } else {
            // Move to next question
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentQuestionIndex += 1
            }
        }

        HapticManager.shared.light()
    }

    private func calculateScore() {
        var correct = 0

        for question in quiz.questions {
            if let selectedIndex = selectedAnswers[question.id],
               selectedIndex == question.correctAnswerIndex {
                correct += 1
            }
        }

        score = Double(correct) / Double(quiz.questions.count)
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
    let answer: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Letter indicator
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 32, height: 32)

                    Text(letter)
                        .font(DesignTokens.Typography.labelLarge)
                        .foregroundColor(foregroundColor)
                }

                // Answer text
                Text(answer)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(foregroundColor)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Status indicator
                if let isCorrect = isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .disabled(isCorrect != nil)
    }

    private var letter: String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters[index]
    }

    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? DesignTokens.Colors.success.opacity(0.1) : DesignTokens.Colors.error.opacity(0.1)
        } else if isSelected {
            return DesignTokens.Colors.brand.opacity(0.2)
        } else {
            return DesignTokens.Colors.backgroundTertiary
        }
    }

    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error
        } else if isSelected {
            return DesignTokens.Colors.brand
        } else {
            return Color.clear
        }
    }

    private var foregroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error
        } else if isSelected {
            return DesignTokens.Colors.brand
        } else {
            return DesignTokens.Colors.textPrimary
        }
    }
}

// MARK: - Avatar Speaking View

struct AvatarSpeakingView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.Colors.brand.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scale)

            // Avatar
            Circle()
                .fill(DesignTokens.Colors.brandGradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )

            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.3
            }
        }
    }
}

#Preview("Quiz") {
    ZStack {
        Color.black.ignoresSafeArea()

        MicroQuizOverlay(
            quiz: .mockQuiz,
            onComplete: { passed in
                print("Quiz completed: \(passed)")
            }
        )
    }
}
