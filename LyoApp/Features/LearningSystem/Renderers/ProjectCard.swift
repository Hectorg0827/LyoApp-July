import SwiftUI

/// Project-type ALO renderer with acceptance tests checklist
struct ProjectCard: View {
    let alo: ALO
    let onSubmit: ([String: Bool]) -> Void
    let onNeedHelp: () -> Void

    @State private var checklist: [String: Bool] = [:]
    @State private var showResources = false

    private var projectContent: ProjectContent? {
        alo.projectContent
    }

    private var allTestsPassed: Bool {
        guard let content = projectContent else { return false }
        return content.acceptanceTests.allSatisfy { checklist[$0] == true }
    }

    private var progressPercent: Int {
        guard let content = projectContent else { return 0 }
        let total = content.acceptanceTests.count
        let completed = content.acceptanceTests.filter { checklist[$0] == true }.count
        return total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header

                // Brief Card
                if let content = projectContent {
                    briefCard(content: content)

                    // Progress Indicator
                    progressIndicator

                    // Acceptance Tests Checklist
                    checklistSection(content: content)

                    // Resources
                    if let resources = content.resources, !resources.isEmpty {
                        resourcesSection(resources: resources)
                    }

                    // Submit Button
                    submitButton
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
            initializeChecklist()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Project Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "hammer.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Project")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("Build Something Real")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Time Estimate
            VStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(alo.estTimeSec / 60)min")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Brief Card

    private func briefCard(content: ProjectContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)

                Text("PROJECT BRIEF")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()
            }

            Text(content.brief)
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
                                colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.red.opacity(0.1), radius: 20, y: 10)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(progressPercent)% Complete")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if let content = projectContent {
                    Text("\(checklist.values.filter { $0 }.count) / \(content.acceptanceTests.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progressPercent) / 100, height: 8)
                        .cornerRadius(4)
                        .animation(.easeOut(duration: 0.3), value: progressPercent)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Checklist Section

    private func checklistSection(content: ProjectContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)

                Text("ACCEPTANCE TESTS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(Array(content.acceptanceTests.enumerated()), id: \.offset) { index, test in
                    checklistItem(test: test, index: index + 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func checklistItem(test: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                checklist[test]?.toggle()

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(checklist[test] == true ? Color.green : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if checklist[test] == true {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Test Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test \(index)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))

                    Text(test)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(checklist[test] == true ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(checklist[test] == true ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Test \(index): \(test)")
        .accessibilityValue(checklist[test] == true ? "Passed" : "Not passed")
        .accessibilityAddTraits(checklist[test] == true ? [.isSelected] : [])
    }

    // MARK: - Resources Section

    private func resourcesSection(resources: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text("HELPFUL RESOURCES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(resources, id: \.self) { resource in
                    if let url = URL(string: resource) {
                        Link(destination: url) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)

                                Text(url.host ?? resource)
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: {
            submitProject()
        }) {
            HStack(spacing: 12) {
                if allTestsPassed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Submit Project")
                        .font(.system(size: 17, weight: .semibold))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete All Tests First")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: allTestsPassed
                        ? [Color.green, Color.green.opacity(0.8)]
                        : [Color.gray, Color.gray.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: allTestsPassed ? Color.green.opacity(0.3) : Color.clear, radius: 15, y: 8)
        }
        .disabled(!allTestsPassed)
        .opacity(allTestsPassed ? 1.0 : 0.5)
        .accessibilityLabel(allTestsPassed ? "Submit project" : "Complete all acceptance tests to submit")
    }

    // MARK: - Actions

    private func initializeChecklist() {
        guard let content = projectContent else { return }
        for test in content.acceptanceTests {
            checklist[test] = false
        }
    }

    private func submitProject() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onSubmit(checklist)
    }
}

// MARK: - Preview

#Preview {
    let mockALO = ALO(
        id: UUID(),
        loId: UUID(),
        aloType: .project,
        estTimeSec: 900,
        content: [
            "brief": AnyCodable("""
# Project: Responsive Dashboard Layout

Build a dashboard that adapts seamlessly from mobile to desktop.

## Requirements

1. **Mobile (< 768px)**:
   - Single column layout
   - Header at top
   - Sidebar stacks above main content
   - Footer at bottom

2. **Desktop (≥ 768px)**:
   - Header spans full width
   - Sidebar on the left (250px fixed width)
   - Main content fills remaining space
   - Footer spans full width
"""),
            "acceptance_tests": AnyCodable([
                "Mobile layout is single column (flex-direction: column)",
                "Desktop uses flex-direction: row for sidebar + main",
                "Media query exists at 768px",
                "Sidebar has fixed width on desktop",
                "Main content uses flex: 1"
            ]),
            "rubric": AnyCodable([
                "mobile_layout": "Vertical stacking on small screens",
                "desktop_layout": "Sidebar + main content on large screens",
                "media_query": "Proper breakpoint implementation"
            ]),
            "resources": AnyCodable([
                "https://css-tricks.com/snippets/css/a-guide-to-flexbox/",
                "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout"
            ])
        ],
        assessmentSpec: nil,
        difficulty: 2,
        tags: ["flexbox", "responsive", "project"],
        createdAt: Date(),
        updatedAt: Date()
    )

    return ProjectCard(
        alo: mockALO,
        onSubmit: { checklist in
            print("Project submitted with checklist: \(checklist)")
        },
        onNeedHelp: {
            print("Help requested")
        }
    )
}
