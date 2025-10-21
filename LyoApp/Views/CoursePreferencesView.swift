import SwiftUI

/// Step 2: User selects learning preferences (style, pace, schedule)
struct CoursePreferencesView: View {
    @ObservedObject var coordinator: CourseBuilderCoordinator

    @State private var selectedPreset: CourseBuilderCoordinator.PreferencesPreset? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("How do you want to learn?")
                        .font(DesignTokens.Typography.displaySmall)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textReadability()
                        .padding(.top, 20)

                    Text("Customize your learning experience")
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Quick presets
                quickPresetsSection

                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal)

                // Detailed preferences
                VStack(spacing: 24) {
                    // Learning level
                    levelSection

                    // Learning style
                    styleSection

                    // Learning pace
                    paceSection

                    // Time commitment
                    timeCommitmentSection

                    // Content preferences
                    contentPreferencesSection

                    // Schedule
                    scheduleSection
                }
                .padding(.horizontal)

                // Continue button
                Button(action: {
                    coordinator.nextStep()
                }) {
                    HStack {
                        Text("Generate Course")
                            .font(DesignTokens.Typography.titleMedium)

                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignTokens.Colors.brandGradient)
                            .shadow(color: DesignTokens.Colors.brand.opacity(0.4), radius: 12)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Quick Presets

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)

            HStack(spacing: 12) {
                PresetCard(
                    icon: "bolt.fill",
                    title: "Focused",
                    subtitle: "60 min/day · Daily",
                    color: DesignTokens.Colors.neonOrange,
                    isSelected: selectedPreset == .focused
                ) {
                    selectPreset(.focused)
                }

                PresetCard(
                    icon: "checkmark.circle.fill",
                    title: "Balanced",
                    subtitle: "30 min/day · Weekdays",
                    color: DesignTokens.Colors.brand,
                    isSelected: selectedPreset == .balanced
                ) {
                    selectPreset(.balanced)
                }

                PresetCard(
                    icon: "leaf.fill",
                    title: "Relaxed",
                    subtitle: "15 min/day · 3x/week",
                    color: DesignTokens.Colors.success,
                    isSelected: selectedPreset == .relaxed
                ) {
                    selectPreset(.relaxed)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Level Section

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your Experience Level", systemImage: "star.fill")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach(LearningLevel.allCases, id: \.self) { level in
                    Button(action: {
                        withAnimation {
                            coordinator.selectedLevel = level
                        }
                        HapticManager.shared.light()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: level.icon)
                                .font(.title3)

                            Text(level.displayName)
                                .font(DesignTokens.Typography.labelSmall)
                        }
                        .foregroundColor(coordinator.selectedLevel == level ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(coordinator.selectedLevel == level ? DesignTokens.Colors.brand.opacity(0.3) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(coordinator.selectedLevel == level ? DesignTokens.Colors.brand : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Style Section

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Learning Style", systemImage: "brain.head.profile")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(.white)

            VStack(spacing: 8) {
                StyleOption(
                    title: "Examples First",
                    description: "Learn through practical examples",
                    isSelected: coordinator.selectedStyle == .examplesFirst
                ) {
                    coordinator.selectedStyle = .examplesFirst
                }

                StyleOption(
                    title: "Theory First",
                    description: "Understand concepts before practicing",
                    isSelected: coordinator.selectedStyle == .theoryFirst
                ) {
                    coordinator.selectedStyle = .theoryFirst
                }

                StyleOption(
                    title: "Project-Based",
                    description: "Build real projects as you learn",
                    isSelected: coordinator.selectedStyle == .projectsFirst
                ) {
                    coordinator.selectedStyle = .projectsFirst
                }

                StyleOption(
                    title: "Hybrid",
                    description: "Mix of theory, examples, and projects",
                    isSelected: coordinator.selectedStyle == .hybrid
                ) {
                    coordinator.selectedStyle = .hybrid
                }
            }
        }
    }

    // MARK: - Pace Section

    private var paceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Learning Pace", systemImage: "gauge.with.dots.needle.67percent")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(.white)

            HStack(spacing: 8) {
                ForEach([Pedagogy.LearningPace.slow, .moderate, .fast], id: \.self) { pace in
                    Button(action: {
                        withAnimation {
                            coordinator.selectedPace = pace
                        }
                        HapticManager.shared.light()
                    }) {
                        Text(pace.rawValue.capitalized)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(coordinator.selectedPace == pace ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(coordinator.selectedPace == pace ? DesignTokens.Colors.brand.opacity(0.3) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(coordinator.selectedPace == pace ? DesignTokens.Colors.brand : Color.clear, lineWidth: 2)
                                    )
                            )
                    }
                }
            }
        }
    }

    // MARK: - Time Commitment

    private var timeCommitmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Time Commitment", systemImage: "clock.fill")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(.white)

            // Minutes per day
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minutes per day")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("\(coordinator.minutesPerDay) min")
                        .font(DesignTokens.Typography.bodyMedium.weight(.semibold))
                        .foregroundColor(DesignTokens.Colors.brand)
                        .monospacedDigit()
                }

                Slider(value: Binding(
                    get: { Double(coordinator.minutesPerDay) },
                    set: { coordinator.minutesPerDay = Int($0) }
                ), in: 10...120, step: 5)
                .tint(DesignTokens.Colors.brand)
            }

            // Days per week
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Days per week")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("\(coordinator.daysPerWeek) days")
                        .font(DesignTokens.Typography.bodyMedium.weight(.semibold))
                        .foregroundColor(DesignTokens.Colors.brand)
                        .monospacedDigit()
                }

                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        Button(action: {
                            withAnimation {
                                coordinator.daysPerWeek = day
                            }
                            HapticManager.shared.light()
                        }) {
                            Text("\(day)")
                                .font(DesignTokens.Typography.bodyMedium.weight(.semibold))
                                .foregroundColor(coordinator.daysPerWeek == day ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(coordinator.daysPerWeek == day ? DesignTokens.Colors.brand : Color.white.opacity(0.05))
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Preferences

    private var contentPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Content Types", systemImage: "list.bullet.rectangle.fill")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ToggleOption(
                    icon: "play.rectangle.fill",
                    title: "Video Lessons",
                    isOn: $coordinator.preferVideo
                )

                ToggleOption(
                    icon: "doc.text.fill",
                    title: "Text & Articles",
                    isOn: $coordinator.preferText
                )

                ToggleOption(
                    icon: "hand.tap.fill",
                    title: "Interactive Exercises",
                    isOn: $coordinator.preferInteractive
                )
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Schedule", systemImage: "calendar")
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(.white)

            // Time of day
            HStack(spacing: 8) {
                ForEach([Schedule.TimeOfDay.morning, .afternoon, .evening, .night], id: \.self) { time in
                    Button(action: {
                        withAnimation {
                            coordinator.selectedTimeOfDay = time
                        }
                        HapticManager.shared.light()
                    }) {
                        Text(time.rawValue.capitalized)
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(coordinator.selectedTimeOfDay == time ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(coordinator.selectedTimeOfDay == time ? DesignTokens.Colors.brand.opacity(0.3) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(coordinator.selectedTimeOfDay == time ? DesignTokens.Colors.brand : Color.clear, lineWidth: 1.5)
                                    )
                            )
                    }
                }
            }

            // Reminder toggle
            ToggleOption(
                icon: "bell.fill",
                title: "Daily Reminders",
                isOn: $coordinator.reminderEnabled
            )
        }
    }

    // MARK: - Methods

    private func selectPreset(_ preset: CourseBuilderCoordinator.PreferencesPreset) {
        withAnimation {
            selectedPreset = preset
            coordinator.applyQuickPreferences(preset)
        }
        HapticManager.shared.medium()
    }
}

// MARK: - Supporting Views

struct PresetCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(DesignTokens.Typography.titleSmall)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.white.opacity(0.1), lineWidth: 2)
                    )
            )
        }
    }
}

struct StyleOption: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.light()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? DesignTokens.Colors.brand : .white.opacity(0.3))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyLarge)
                        .foregroundColor(.white)

                    Text(description)
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? DesignTokens.Colors.brand.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? DesignTokens.Colors.brand : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
}

struct ToggleOption: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isOn ? DesignTokens.Colors.brand : .white.opacity(0.5))
                .frame(width: 28)

            Text(title)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(DesignTokens.Colors.brand)
                .labelsHidden()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        CoursePreferencesView(coordinator: CourseBuilderCoordinator())
    }
}
