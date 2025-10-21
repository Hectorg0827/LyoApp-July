import SwiftUI
import Combine

/// Coordinates the course builder wizard flow
@MainActor
class CourseBuilderCoordinator: ObservableObject {
    // MARK: - Published Properties

    // Current step in the wizard
    @Published var currentStep: BuilderStep = .topic

    // User inputs
    @Published var topic: String = ""
    @Published var learningGoal: String = ""
    @Published var selectedLevel: LearningLevel = .beginner
    @Published var selectedStyle: LearningStyle = .examplesFirst
    @Published var selectedPace: Pedagogy.LearningPace = .moderate
    @Published var minutesPerDay: Int = 30
    @Published var daysPerWeek: Int = 5
    @Published var preferVideo: Bool = true
    @Published var preferText: Bool = true
    @Published var preferInteractive: Bool = true
    @Published var selectedTimeOfDay: Schedule.TimeOfDay = .evening
    @Published var reminderEnabled: Bool = true

    // Generation state
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Double = 0.0
    @Published var generationStatus: String = ""
    @Published var generatedCourse: ClassroomCourse?
    @Published var generationError: String?

    // Navigation
    @Published var shouldDismiss: Bool = false
    @Published var shouldLaunchClassroom: Bool = false

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case .topic:
            return !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .preferences:
            return true // All preferences have defaults
        case .generating:
            return generatedCourse != nil
        case .preview:
            return generatedCourse != nil
        }
    }

    var progressPercentage: Double {
        switch currentStep {
        case .topic: return 0.25
        case .preferences: return 0.50
        case .generating: return 0.75
        case .preview: return 1.0
        }
    }

    // MARK: - Builder Steps

    enum BuilderStep {
        case topic          // Step 1: What do you want to learn?
        case preferences    // Step 2: How do you want to learn?
        case generating     // Step 3: AI generates the course
        case preview        // Step 4: Review the syllabus
    }

    // MARK: - Navigation Methods

    func nextStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            switch currentStep {
            case .topic:
                currentStep = .preferences
                HapticManager.shared.light()

            case .preferences:
                currentStep = .generating
                Task {
                    await generateCourse()
                }

            case .generating:
                if generatedCourse != nil {
                    currentStep = .preview
                    HapticManager.shared.success()
                }

            case .preview:
                // Launch classroom
                shouldLaunchClassroom = true
                HapticManager.shared.success()
            }
        }
    }

    func previousStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            switch currentStep {
            case .topic:
                shouldDismiss = true

            case .preferences:
                currentStep = .topic

            case .generating:
                // Can't go back during generation
                break

            case .preview:
                currentStep = .preferences
            }

            HapticManager.shared.light()
        }
    }

    func cancel() {
        HapticManager.shared.light()
        shouldDismiss = true
    }

    func reset() {
        topic = ""
        learningGoal = ""
        selectedLevel = .beginner
        selectedStyle = .examplesFirst
        selectedPace = .moderate
        minutesPerDay = 30
        daysPerWeek = 5
        preferVideo = true
        preferText = true
        preferInteractive = true
        selectedTimeOfDay = .evening
        reminderEnabled = true

        isGenerating = false
        generationProgress = 0.0
        generationStatus = ""
        generatedCourse = nil
        generationError = nil

        currentStep = .topic
    }

    // MARK: - Course Generation

    func generateCourse() async {
        guard !topic.isEmpty else { return }

        isGenerating = true
        generationError = nil
        generationProgress = 0.0

        // Simulate progressive updates
        await updateGenerationStatus("Analyzing your learning goals...", progress: 0.1)

        do {
            // Build pedagogy from user preferences
            let pedagogy = Pedagogy(
                style: selectedStyle,
                preferVideo: preferVideo,
                preferText: preferText,
                preferInteractive: preferInteractive,
                pace: selectedPace
            )

            // Build schedule
            let schedule = Schedule(
                minutesPerDay: minutesPerDay,
                daysPerWeek: daysPerWeek,
                startDate: Date(),
                reminderEnabled: reminderEnabled,
                preferredTimeOfDay: selectedTimeOfDay
            )

            await updateGenerationStatus("Designing your course structure...", progress: 0.3)

            // Define learning outcomes
            let outcomes = generateLearningOutcomes()

            await updateGenerationStatus("Creating engaging lessons...", progress: 0.5)

            // Call backend API to generate course
            let course = try await ClassroomAPIService.shared.generateCourse(
                topic: topic,
                level: selectedLevel,
                outcomes: outcomes,
                pedagogy: pedagogy
            )

            await updateGenerationStatus("Curating learning resources...", progress: 0.7)

            // Wait a moment for effect
            try await Task.sleep(nanoseconds: 500_000_000)

            await updateGenerationStatus("Finalizing your personalized course...", progress: 0.9)

            // Add schedule to course
            var finalCourse = course
            finalCourse.schedule = schedule

            await updateGenerationStatus("Course ready!", progress: 1.0)

            generatedCourse = finalCourse

            // Small delay before moving to preview
            try await Task.sleep(nanoseconds: 800_000_000)

            withAnimation {
                currentStep = .preview
            }

            print("✅ [CourseBuilder] Course generated successfully: \(course.title)")

        } catch {
            print("❌ [CourseBuilder] Generation failed: \(error.localizedDescription)")

            await updateGenerationStatus("", progress: 0.0)
            generationError = "Failed to generate course: \(error.localizedDescription). Please check your connection and try again."
            
            // DO NOT create mock course - fail properly
            print("⚠️ [CourseBuilder] No fallback - user must retry with real backend")
        }

        isGenerating = false
    }

    private func updateGenerationStatus(_ status: String, progress: Double) async {
        await MainActor.run {
            withAnimation {
                self.generationStatus = status
                self.generationProgress = progress
            }
        }

        // Small delay between updates
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    private func generateLearningOutcomes() -> [String] {
        // Generate context-aware outcomes based on level and topic
        switch selectedLevel {
        case .beginner:
            return [
                "Understand the fundamentals of \(topic)",
                "Build confidence with hands-on practice",
                "Create your first \(topic) project"
            ]

        case .intermediate:
            return [
                "Master advanced \(topic) concepts",
                "Apply best practices and patterns",
                "Build production-ready projects"
            ]

        case .advanced:
            return [
                "Deep dive into \(topic) internals",
                "Optimize and architect complex systems",
                "Mentor others and lead projects"
            ]

        case .expert:
            return [
                "Push the boundaries of \(topic)",
                "Contribute to the ecosystem",
                "Innovate and create new solutions"
            ]
        }
    }

    // REMOVED: createMockCourse() - No fallback, fail properly with error message

    // MARK: - Quick Setup Methods

    func setupQuickCourse(topic: String, level: LearningLevel = .beginner) {
        self.topic = topic
        self.selectedLevel = level
        self.currentStep = .preferences
    }

    func applyQuickPreferences(_ preset: PreferencesPreset) {
        switch preset {
        case .focused:
            selectedPace = .fast
            minutesPerDay = 60
            daysPerWeek = 7
            preferVideo = true
            preferText = false
            preferInteractive = true

        case .balanced:
            selectedPace = .moderate
            minutesPerDay = 30
            daysPerWeek = 5
            preferVideo = true
            preferText = true
            preferInteractive = true

        case .relaxed:
            selectedPace = .slow
            minutesPerDay = 15
            daysPerWeek = 3
            preferVideo = true
            preferText = true
            preferInteractive = false
        }
    }

    enum PreferencesPreset {
        case focused    // Fast pace, daily, intensive
        case balanced   // Moderate pace, weekdays
        case relaxed    // Slow pace, few days/week
    }
}
