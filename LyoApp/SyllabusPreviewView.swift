import SwiftUI

/// Step 4: Preview the generated course syllabus before starting
struct SyllabusPreviewView: View {
    @ObservedObject var coordinator: CourseBuilderCoordinator

    @State private var animateIn: Bool = false
    @State private var expandedModules: Set<UUID> = []

    var course: Course? {
        coordinator.generatedCourse
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success celebration
                celebrationHeader

                // Course overview card
                if let course = course {
                    courseOverviewCard(course)

                    // Modules list
                    modulesSection(course)
                }

                // Start button
                startButton

                Spacer()
                    .frame(height: 20)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateIn = true
            }

            // Auto-expand first module
            if let firstModule = course?.modules.first {
                expandedModules.insert(firstModule.id)
            }
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            // Success icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignTokens.Colors.success.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIn ? 1.0 : 0.5)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignTokens.Colors.success)
                    .scaleEffect(animateIn ? 1.0 : 0.0)
                    .rotationEffect(.degrees(animateIn ? 0 : -180))
            }

            VStack(spacing: 8) {
                Text("Your Course is Ready!")
                    .font(DesignTokens.Typography.displaySmall)
                    .foregroundColor(.white)
                    .textReadability()
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : 20)

                Text("Personalized just for you")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : 20)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Course Overview Card

    private func courseOverviewCard(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(DesignTokens.Typography.headlineMedium)
                    .foregroundColor(.white)

                Text(course.description)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(.white.opacity(0.7))
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Quick stats
            HStack(spacing: 16) {
                StatPill(
                    icon: course.level.icon,
                    label: course.level.displayName,
                    color: DesignTokens.Colors.brand
                )

                StatPill(
                    icon: "clock.fill",
                    label: "\(course.estimatedDuration) min",
                    color: DesignTokens.Colors.info
                )

                StatPill(
                    icon: "book.fill",
                    label: "\(course.modules.count) modules",
                    color: DesignTokens.Colors.neonPurple
                )
            }

            // Learning outcomes
            if !course.outcomes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("What You'll Learn", systemImage: "target")
                        .font(DesignTokens.Typography.titleSmall)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(course.outcomes, id: \.self) { outcome in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignTokens.Colors.success)

                                Text(outcome)
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }

            // Schedule info
            VStack(alignment: .leading, spacing: 8) {
                Label("Your Schedule", systemImage: "calendar")
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    ScheduleChip(
                        icon: "clock",
                        text: "\(course.schedule.minutesPerDay) min/day"
                    )

                    ScheduleChip(
                        icon: "calendar",
                        text: "\(course.schedule.daysPerWeek) days/week"
                    )

                    ScheduleChip(
                        icon: "sun.max.fill",
                        text: course.schedule.preferredTimeOfDay.rawValue.capitalized
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.brand.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(animateIn ? 1.0 : 0.9)
        .opacity(animateIn ? 1.0 : 0.0)
    }

    // MARK: - Modules Section

    private func modulesSection(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Course Modules", systemImage: "list.bullet.rectangle.fill")
                .font(DesignTokens.Typography.titleLarge)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(course.modules) { module in
                    ModuleCard(
                        module: module,
                        isExpanded: expandedModules.contains(module.id),
                        onToggle: {
                            withAnimation {
                                if expandedModules.contains(module.id) {
                                    expandedModules.remove(module.id)
                                } else {
                                    expandedModules.insert(module.id)
                                }
                            }
                            HapticManager.shared.light()
                        }
                    )
                }
            }
        }
        .opacity(animateIn ? 1.0 : 0.0)
        .offset(y: animateIn ? 0 : 30)
    }

    // MARK: - Start Button

    private var startButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                HapticManager.shared.success()
                coordinator.nextStep()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)

                    Text("Start Learning")
                        .font(DesignTokens.Typography.titleMedium)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(DesignTokens.Colors.brandGradient)
                        .shadow(color: DesignTokens.Colors.brand.opacity(0.5), radius: 15, y: 8)
                )
            }

            Button(action: {
                coordinator.previousStep()
            }) {
                Text("Adjust Preferences")
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .opacity(animateIn ? 1.0 : 0.0)
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))

            Text(label)
                .font(DesignTokens.Typography.labelMedium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

struct ScheduleChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))

            Text(text)
                .font(DesignTokens.Typography.labelSmall)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ModuleCard: View {
    let module: CourseModule
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Module number
                    ZStack {
                        Circle()
                            .fill(module.isUnlocked ? DesignTokens.Colors.brand.opacity(0.2) : Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Text("\(module.moduleNumber)")
                            .font(DesignTokens.Typography.titleMedium.weight(.bold))
                            .foregroundColor(module.isUnlocked ? DesignTokens.Colors.brand : .white.opacity(0.5))
                    }

                    // Title and info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title)
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            Label("\(module.lessons.count) lessons", systemImage: "play.circle")
                                .font(DesignTokens.Typography.labelSmall)

                            Label("\(module.estimatedDuration) min", systemImage: "clock")
                                .font(DesignTokens.Typography.labelSmall)
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Lock or expand icon
                    Image(systemName: module.isUnlocked ? (isExpanded ? "chevron.up" : "chevron.down") : "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(16)
            }
            .disabled(!module.isUnlocked)

            // Expanded content (lessons)
            if isExpanded && module.isUnlocked && !module.lessons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(module.lessons) { lesson in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(DesignTokens.Colors.brand.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text(lesson.title)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Text("\(lesson.estimatedDuration) min")
                                .font(DesignTokens.Typography.labelSmall)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isExpanded ? DesignTokens.Colors.brand.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        SyllabusPreviewView(coordinator: {
            let c = CourseBuilderCoordinator()
            c.generatedCourse = .mockCourse
            return c
        }())
    }
}
