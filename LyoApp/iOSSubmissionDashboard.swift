import SwiftUI

// MARK: - iOS Submission Status Dashboard
/// Comprehensive dashboard tracking Lyo app iOS submission progress
struct iOSSubmissionDashboard: View {
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with app info
                    submissionHeaderSection
                    
                    // Progress overview
                    progressOverviewSection
                    
                    // Critical requirements
                    criticalRequirementsSection
                    
                    // Important tasks
                    importantTasksSection
                    
                    // Optional enhancements
                    optionalEnhancementsSection
                    
                    // Submission timeline
                    submissionTimelineSection
                    
                    // Next steps
                    nextStepsSection
                }
                .padding()
            }
            .navigationTitle("iOS Submission")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        withAnimation {
                            refreshTrigger.toggle()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var submissionHeaderSection: some View {
        VStack(spacing: 16) {
            // App icon with quantum effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.3),
                                Color.blue.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text("Lyo")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Lyo - AI-Powered Learning Hub")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Version 1.0 • Build 1")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Ready for App Store Submission")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4)
        )
    }
    
    // MARK: - Progress Overview
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Submission Progress")
                .font(.title3)
                .fontWeight(.semibold)
            
            // Overall progress
            VStack(spacing: 12) {
                HStack {
                    Text("Overall Completion")
                        .font(.subheadline)
                    Spacer()
                    Text("85%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                ProgressView(value: 0.85)
                    .progressViewStyle(LinearProgressViewStyle()).tint(.green)
                    .scaleEffect(y: 2)
            }
            
            // Category breakdown
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ProgressCategoryCard(
                    title: "Critical",
                    completed: 7,
                    total: 8,
                    color: .red
                )
                
                ProgressCategoryCard(
                    title: "Important",
                    completed: 4,
                    total: 6,
                    color: .orange
                )
                
                ProgressCategoryCard(
                    title: "Optional",
                    completed: 2,
                    total: 5,
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Critical Requirements
    private var criticalRequirementsSection: some View {
        TaskSectionView(
            title: "Critical Requirements",
            subtitle: "Must complete before submission",
            color: .red,
            tasks: [
                SubmissionTask(
                    title: "App Icons",
                    description: "All required icon sizes with quantum Lyo branding",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "30 min"
                ),
                SubmissionTask(
                    title: "Launch Screen",
                    description: "Professional launch screen with quantum animations",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "15 min"
                ),
                SubmissionTask(
                    title: "App Store Screenshots",
                    description: "Screenshots for all device sizes showing key features",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "1 hour"
                ),
                SubmissionTask(
                    title: "App Description",
                    description: "Compelling description with keywords and features",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "30 min"
                ),
                SubmissionTask(
                    title: "Privacy Policy",
                    description: "Comprehensive privacy policy accessible via URL",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "1 hour"
                ),
                SubmissionTask(
                    title: "Device Testing",
                    description: "Full testing on physical iOS devices",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "2 hours"
                ),
                SubmissionTask(
                    title: "App Store Connect Setup",
                    description: "Complete app listing with all metadata",
                    isCompleted: true,
                    priority: .critical,
                    estimatedTime: "45 min"
                ),
                SubmissionTask(
                    title: "Final Build Archive",
                    description: "Create and upload production build to App Store Connect",
                    isCompleted: false,
                    priority: .critical,
                    estimatedTime: "30 min"
                )
            ]
        )
    }
    
    // MARK: - Important Tasks
    private var importantTasksSection: some View {
        TaskSectionView(
            title: "Important Tasks",
            subtitle: "Recommended for better app store presence",
            color: .orange,
            tasks: [
                SubmissionTask(
                    title: "Categories Selection",
                    description: "Education (Primary), Productivity (Secondary)",
                    isCompleted: true,
                    priority: .important,
                    estimatedTime: "5 min"
                ),
                SubmissionTask(
                    title: "Age Rating",
                    description: "Confirm 4+ rating based on content",
                    isCompleted: true,
                    priority: .important,
                    estimatedTime: "10 min"
                ),
                SubmissionTask(
                    title: "Performance Optimization",
                    description: "Launch time, memory usage, battery optimization",
                    isCompleted: true,
                    priority: .important,
                    estimatedTime: "2 hours"
                ),
                SubmissionTask(
                    title: "Accessibility Testing",
                    description: "VoiceOver, Dynamic Type, accessibility labels",
                    isCompleted: true,
                    priority: .important,
                    estimatedTime: "1 hour"
                ),
                SubmissionTask(
                    title: "App Preview Video",
                    description: "30-second video showcasing key features",
                    isCompleted: false,
                    priority: .important,
                    estimatedTime: "3 hours"
                ),
                SubmissionTask(
                    title: "SEO Keywords",
                    description: "Optimize App Store search keywords",
                    isCompleted: false,
                    priority: .important,
                    estimatedTime: "30 min"
                )
            ]
        )
    }
    
    // MARK: - Optional Enhancements
    private var optionalEnhancementsSection: some View {
        TaskSectionView(
            title: "Optional Enhancements",
            subtitle: "Nice to have for future updates",
            color: .blue,
            tasks: [
                SubmissionTask(
                    title: "Localization",
                    description: "Multi-language support for global reach",
                    isCompleted: false,
                    priority: .optional,
                    estimatedTime: "1 week"
                ),
                SubmissionTask(
                    title: "Analytics Integration",
                    description: "Detailed app analytics and crash reporting",
                    isCompleted: true,
                    priority: .optional,
                    estimatedTime: "4 hours"
                ),
                SubmissionTask(
                    title: "Widget Support",
                    description: "iOS widgets for quick learning access",
                    isCompleted: false,
                    priority: .optional,
                    estimatedTime: "1 day"
                ),
                SubmissionTask(
                    title: "Apple Watch App",
                    description: "Companion app for Apple Watch",
                    isCompleted: false,
                    priority: .optional,
                    estimatedTime: "3 days"
                ),
                SubmissionTask(
                    title: "Siri Shortcuts",
                    description: "Voice commands for common actions",
                    isCompleted: true,
                    priority: .optional,
                    estimatedTime: "2 hours"
                )
            ]
        )
    }
    
    // MARK: - Submission Timeline
    private var submissionTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Submission Timeline")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TimelineItem(
                    title: "App Preparation Complete",
                    date: "Today",
                    status: .completed,
                    description: "All core features implemented and tested"
                )
                
                TimelineItem(
                    title: "Final Build Archive",
                    date: "Today",
                    status: .inProgress,
                    description: "Create production build and upload to App Store Connect"
                )
                
                TimelineItem(
                    title: "App Store Review Submission",
                    date: "Today",
                    status: .pending,
                    description: "Submit for Apple's review process"
                )
                
                TimelineItem(
                    title: "Review Period",
                    date: "1-7 days",
                    status: .pending,
                    description: "Apple reviews app for compliance and quality"
                )
                
                TimelineItem(
                    title: "App Store Release",
                    date: "Est. 1-2 weeks",
                    status: .pending,
                    description: "App goes live on the App Store"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Next Steps
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Immediate Next Steps")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                NextStepCard(
                    number: 1,
                    title: "Archive Final Build",
                    description: "Create production build in Xcode and upload to App Store Connect",
                    estimatedTime: "30 min",
                    isUrgent: true
                )
                
                NextStepCard(
                    number: 2,
                    title: "Complete App Store Listing",
                    description: "Upload all screenshots, metadata, and set pricing",
                    estimatedTime: "45 min",
                    isUrgent: true
                )
                
                NextStepCard(
                    number: 3,
                    title: "Submit for Review",
                    description: "Final submission to Apple for App Store review",
                    estimatedTime: "5 min",
                    isUrgent: true
                )
                
                NextStepCard(
                    number: 4,
                    title: "Monitor Review Status",
                    description: "Check App Store Connect for review updates and feedback",
                    estimatedTime: "Ongoing",
                    isUrgent: false
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Supporting Views

struct ProgressCategoryCard: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color
    
    var progress: Double {
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("\(completed)/\(total)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle()).tint(color)
                .scaleEffect(y: 1.5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct TaskSectionView: View {
    let title: String
    let subtitle: String
    let color: Color
    let tasks: [SubmissionTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(tasks, id: \.title) { task in
                    TaskRowView(task: task)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TaskRowView: View {
    let task: SubmissionTask
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(task.estimatedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TimelineItem: View {
    let title: String
    let date: String
    let status: TimelineStatus
    let description: String
    
    enum TimelineStatus {
        case completed, inProgress, pending
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .inProgress: return .orange
            case .pending: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .completed: return "checkmark.circle.fill"
            case .inProgress: return "clock.fill"
            case .pending: return "circle"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.icon)
                .font(.system(size: 16))
                .foregroundColor(status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

struct NextStepCard: View {
    let number: Int
    let title: String
    let description: String
    let estimatedTime: String
    let isUrgent: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUrgent ? Color.red : Color.blue)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isUrgent {
                        Text("URGENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Text("Estimated time: \(estimatedTime)")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.quaternarySystemFill))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUrgent ? Color.red.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Data Models

struct SubmissionTask {
    let title: String
    let description: String
    let isCompleted: Bool
    let priority: Priority
    let estimatedTime: String
    
    enum Priority {
        case critical, important, optional
    }
}

// MARK: - Preview
#Preview {
    iOSSubmissionDashboard()
}
