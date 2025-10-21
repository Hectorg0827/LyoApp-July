import SwiftUI

/// Main Course Builder wizard - guides users through creating an AI-powered course
struct CourseBuilderView: View {
    @StateObject private var coordinator = CourseBuilderCoordinator()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.13),
                    Color(red: 0.05, green: 0.08, blue: 0.16),
                    Color(red: 0.08, green: 0.10, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressHeader

                // Current step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .navigationBarHidden(true)
        .onChange(of: coordinator.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $coordinator.shouldLaunchClassroom) {
            if let course = coordinator.generatedCourse {
                EnhancedAIClassroomView(
                    topic: course.title,
                    course: convertToLocalCourse(course), // ✅ Convert Course to CourseOutlineLocal
                    onExit: { coordinator.shouldLaunchClassroom = false }
                )
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Top bar with back/close
            HStack {
                Button(action: {
                    coordinator.previousStep()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .opacity(coordinator.currentStep == .generating ? 0 : 1)

                Spacer()

                Button(action: {
                    coordinator.cancel()
                }) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(12)
                }
                .opacity(coordinator.currentStep == .generating ? 0 : 1)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.brand, DesignTokens.Colors.neonBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * coordinator.progressPercentage, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)

            // Step indicator
            Text(stepTitle)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch coordinator.currentStep {
        case .topic:
            TopicGatheringView(coordinator: coordinator)

        case .preferences:
            CoursePreferencesView(coordinator: coordinator)

        case .generating:
            CourseGeneratingView(coordinator: coordinator)

        case .preview:
            SyllabusPreviewView(coordinator: coordinator)
        }
    }

    // MARK: - Helpers

    private var stepTitle: String {
        switch coordinator.currentStep {
        case .topic: return "Step 1 of 4: What do you want to learn?"
        case .preferences: return "Step 2 of 4: How do you want to learn?"
        case .generating: return "Step 3 of 4: Generating your course..."
        case .preview: return "Step 4 of 4: Review your course"
        }
    }
    
    /// Convert backend Course model to local CourseOutlineLocal format
    private func convertToLocalCourse(_ course: ClassroomCourse) -> CourseOutlineLocal {
        // Convert all modules and their lessons to bite-sized LessonOutlines
        var allLessons: [LessonOutline] = []
        
        for module in course.modules {
            for lesson in module.lessons {
                let lessonOutline = LessonOutline(
                    title: "📚 \(lesson.title)",
                    description: lesson.description,
                    contentType: .text, // Default to text content type
                    estimatedDuration: min(lesson.estimatedDuration, 10) // Use minutes directly, cap at 10 min
                )
                allLessons.append(lessonOutline)
            }
        }
        
        // If no lessons found, create a default one
        if allLessons.isEmpty {
            allLessons.append(LessonOutline(
                title: "🎯 Getting Started with \(course.title)",
                description: course.description,
                contentType: .text,
                estimatedDuration: 5
            ))
        }
        
        return CourseOutlineLocal(
            title: course.title,
            description: course.description,
            lessons: allLessons
        )
    }
}

#Preview {
    CourseBuilderView()
}
