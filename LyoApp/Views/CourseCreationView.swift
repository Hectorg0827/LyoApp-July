import SwiftUI

struct CourseCreationView: View {
    @Environment(\.dismiss) private var dismiss
    let course: ClassroomCourse?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    if let course = course {
                        // Course Header
                        courseHeaderView(course: course)
                        
                        // Course Modules
                        courseModulesView(course: course)
                        
                        // Action Buttons
                        actionButtonsView(course: course)
                    } else {
                        Text("No course selected")
                            .font(DesignTokens.Typography.title2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Course Created!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func courseHeaderView(course: ClassroomCourse) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Success Icon
            HStack {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignTokens.Colors.success)
                Spacer()
            }
            
            // Course Title
            Text(course.title)
                .font(DesignTokens.Typography.hero)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Course Description
            Text(course.description)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            // Course Info
            HStack(spacing: DesignTokens.Spacing.lg) {
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text(formatDuration(course.estimatedDuration))
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Difficulty")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text(course.level.displayName)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Modules")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text("\(course.modules.count)")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
            .padding()
            .background(DesignTokens.Colors.glassBg)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }
    
    @ViewBuilder
    private func courseModulesView(course: ClassroomCourse) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Course Modules")
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            ForEach(0..<course.modules.count, id: \.self) { index in
                moduleCardView(module: course.modules[index], index: index + 1)
            }
        }
    }
    
    @ViewBuilder
    private func moduleCardView(module: CourseModule, index: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Module \(index)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignTokens.Colors.primary.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(formatDuration(module.estimatedDuration))
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Text(module.title)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(module.description)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineLimit(3)
            
            if !module.lessons.isEmpty {
                Text("\(module.lessons.count) lessons")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding()
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func actionButtonsView(course: ClassroomCourse) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Button("Start Learning Now") {
                // Navigate to course content or start first module
                dismiss()
            }
            .primaryButton()
            
            Button("Save for Later") {
                // Course is already saved to CourseManager
                dismiss()
            }
            .secondaryButton()
            
            Button("Customize Course") {
                // Allow user to modify modules, duration, etc.
            }
            .secondaryButton()
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let minutesPerWeek = 7 * 24 * 60
        let minutesPerDay = 24 * 60

        let weeks = minutes / minutesPerWeek
        let remainingAfterWeeks = minutes % minutesPerWeek
        let days = remainingAfterWeeks / minutesPerDay
        let remainingMinutes = remainingAfterWeeks % minutesPerDay
        let hours = remainingMinutes / 60

        if weeks > 0 {
            return days > 0 ? "\(weeks)w \(days)d" : "\(weeks) weeks"
        } else if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days) days"
        } else if hours > 0 {
            return remainingMinutes % 60 > 0 ? "\(hours)h \(remainingMinutes % 60)m" : "\(hours) hours"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    CourseCreationView(course: ClassroomCourse.mockCourse)
}