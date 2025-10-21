import SwiftUI

struct DynamicClassroomView: View {
    @StateObject var manager = DynamicClassroomManager.shared
    @State private var showQuiz = false
    @State private var currentAnswerText = ""
    @State private var selectedQuestion: ContextualQuestion?
    
    let course: Course
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background - Environment-specific
            environmentBackground
            
            VStack(spacing: 0) {
                // Header with environment info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(manager.currentEnvironment?.location ?? "Loading...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(manager.currentEnvironment?.timeperiod ?? "")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Avatar introduction
                    if let tutor = manager.tutorPersonality {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Your Guide")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(tutor.role)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.4))
                
                // Main classroom content
                ScrollView {
                    VStack(spacing: 20) {
                        // Course title
                        Text(course.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                        
                        // Environment description
                        if let environment = manager.currentEnvironment {
                            EnvironmentCard(environment: environment)
                                .padding()
                        }
                        
                        // Teaching content
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📚 Today's Immersive Lesson")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("You are now in \(manager.currentEnvironment?.location ?? "a dynamic classroom"). Your AI guide will teach you in context of this unique environment. Every interaction and quiz question is tailored to this setting.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                        .padding()
                        
                        // Start learning button
                        Button(action: { showQuiz = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Interactive Lesson")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding()
                        
                        Spacer(minLength: 20)
                    }
                }
                
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()
            }
            
            // Loading overlay
            if manager.isGenerating {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    
                    VStack(spacing: 8) {
                        Text("Generating Your Classroom")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Creating a unique \(manager.currentEnvironment?.setting ?? "classroom") experience...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.6))
            }
            
            // Error overlay
            if let error = manager.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Classroom Generation Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { dismiss() }) {
                        Text("Go Back")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.6))
            }
        }
        .sheet(isPresented: $showQuiz) {
            DynamicQuizView(
                quiz: manager.contextualQuiz,
                manager: manager,
                environment: manager.currentEnvironment
            )
        }
        .onAppear {
            Task {
                await manager.generateClassroomForCourse(course)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private var environmentBackground: some View {
        let setting = manager.currentEnvironment?.setting ?? ""
        
        switch setting {
        case "maya_ceremonial_center":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.4, blue: 0.2),
                    Color(red: 0.8, green: 0.7, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
        case "mars_habitation_base":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.8, green: 0.3, blue: 0.1),
                    Color(red: 0.9, green: 0.5, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
        case "modern_chemistry_lab":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.5),
                    Color(red: 0.3, green: 0.4, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        
        case "amazon_rainforest":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.1),
                    Color(red: 0.3, green: 0.6, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
        case "renaissance_studio":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.7, green: 0.6, blue: 0.4),
                    Color(red: 0.9, green: 0.8, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
        default:
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Environment Card

struct EnvironmentCard: View {
    let environment: ClassroomEnvironment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(environment.location)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(environment.timeperiod)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Cultural elements
            if let elements = environment.culturalElements, !elements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 Environment Elements")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(elements.prefix(5), id: \.self) { element in
                            Badge(text: element)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .border(Color.white.opacity(0.3), width: 1)
    }
}

// MARK: - Dynamic Quiz View

struct DynamicQuizView: View {
    let quiz: ContextualQuiz?
    let manager: DynamicClassroomManager
    let environment: ClassroomEnvironment?
    
    @State private var currentQuestionIndex = 0
    @State private var userAnswer = ""
    @State private var showFeedback = false
    @State private var feedback: QuizGradingResponse?
    @State private var totalScore = 0
    @Environment(\.dismiss) var dismiss
    
    var currentQuestion: ContextualQuestion? {
        guard let quiz = quiz, currentQuestionIndex < quiz.questions.count else {
            return nil
        }
        return quiz.questions[currentQuestionIndex]
    }
    
    var progressPercent: Double {
        guard let quiz = quiz, quiz.questions.count > 0 else { return 0 }
        return Double(currentQuestionIndex) / Double(quiz.questions.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Question counter and progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Question \(currentQuestionIndex + 1) of \(quiz?.questions.count ?? 0)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("Score: \(totalScore) points")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: progressPercent)
                            .tint(.blue)
                    }
                    .padding()
                    
                    if let question = currentQuestion {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Environment context reminder
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text("In \(environment?.location ?? "the classroom")...")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                Divider()
                                
                                // Question context
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Context")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                    
                                    Text(question.context)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                
                                Divider()
                                
                                // Question text
                                Text(question.questionText)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                // Answer input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Answer")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                    
                                    TextEditor(text: $userAnswer)
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .border(Color.gray.opacity(0.3), width: 1)
                                }
                                
                                // Time limit indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                    Text("\(question.timeLimit) seconds per question")
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                                
                                Spacer()
                            }
                            .padding()
                        }
                        
                        // Answer button
                        Button(action: submitAnswer) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submit Answer")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userAnswer.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(userAnswer.isEmpty)
                        .padding()
                        
                        // Feedback
                        if showFeedback {
                            FeedbackCard(feedback: feedback)
                                .padding()
                        }
                    } else {
                        // Quiz complete
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            VStack(spacing: 8) {
                                Text("Lesson Complete!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Final Score: \(totalScore) points")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("You've successfully completed the interactive lesson in \(environment?.location ?? "this immersive environment").")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                            
                            Button(action: { dismiss() }) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Return to Classroom")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Interactive Quiz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func submitAnswer() {
        Task {
            if let question = currentQuestion {
                await manager.submitQuizAnswer(questionId: question.id, answer: userAnswer)
                
                // Simulate scoring
                let score = calculateScore(answer: userAnswer)
                totalScore += score
                
                // Show feedback briefly
                showFeedback = true
                
                // Move to next question
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    currentQuestionIndex += 1
                    userAnswer = ""
                    showFeedback = false
                }
            }
        }
    }
    
    private func calculateScore(answer: String) -> Int {
        let baseScore = answer.count > 20 ? 80 : (answer.count > 10 ? 60 : 40)
        return min(baseScore, 100)
    }
}

// MARK: - Feedback Card

struct FeedbackCard: View {
    var feedback: QuizGradingResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Great Answer!")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Contextual Feedback")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Your answer demonstrates good understanding of the concept within this environment.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .border(Color.green.opacity(0.3), width: 1)
    }
}

// MARK: - Helper Views

struct Badge: View {
    let text: String
    
    var body: some View {
        Text(text.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(16)
    }
}

struct FlowLayout: View {
    let spacing: CGFloat
    let children: [AnyView]
    
    init<C: Collection>(spacing: CGFloat = 8, @ViewBuilder content: () -> C) where C.Element: View {
        self.spacing = spacing
        self.children = content().map { AnyView($0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<children.count, id: \.self) { index in
                HStack(spacing: spacing) {
                    children[index]
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    DynamicClassroomView(
        course: Course(
            id: UUID(),
            title: "Ancient Civilizations - Maya",
            subject: "history",
            topic: "maya",
            description: "Learn about the Maya civilization",
            instructor: "Dr. History",
            duration: 45,
            level: "intermediate"
        )
    )
}
