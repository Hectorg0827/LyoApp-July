import SwiftUI

struct CourseProgressDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var courseManager = CourseProgressManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let course = courseManager.currentCourse {
                        // Course Header
                        CourseHeaderSection(
                            course: course,
                            overallProgress: courseManager.overallProgress
                        )
                        
                        // Progress Overview
                        ProgressOverviewSection(
                            progress: courseManager.overallProgress,
                            milestones: courseManager.milestones
                        )
                        
                        // Course Modules
                        CourseModulesSection(course: course)
                        
                        // Achievement Section
                        if courseManager.overallProgress >= 1.0 {
                            CompletionBadgeSection()
                        }
                        
                        // Action Buttons
                        ActionButtonsSection(course: course)
                    } else {
                        CourseProgressEmptyStateView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Course Progress")
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
}

struct CourseHeaderSection: View {
    let course: ClassroomCourse
    let overallProgress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text(course.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack {
                        Label(course.scope, systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Label("\(course.estimatedDuration / 60)h", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Label("AI Generated", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                Spacer()
                
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: overallProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(overallProgress * 100))%")
                            .font(.caption.weight(.bold))
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ProgressOverviewSection: View {
    let progress: Double
    let milestones: [ProgressMilestone]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.headline.weight(.semibold))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(milestones) { milestone in
                    MilestoneCard(milestone: milestone)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MilestoneCard: View {
    let milestone: ProgressMilestone
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(milestone.isCompleted ? .green : .gray)
            
            Text(milestone.title)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
            
            if let unlockedAt = milestone.unlockedAt {
                Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(milestone.isCompleted ? .green.opacity(0.1) : .gray.opacity(0.05))
        )
    }
}

struct CourseModulesSection: View {
    let course: ClassroomCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Modules")
                .font(.headline.weight(.semibold))
            
            ForEach(0..<course.modules.count, id: \.self) { index in
                CourseModuleRow(module: course.modules[index], moduleIndex: index)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CourseModuleRow: View {
    let module: CourseModule
    let moduleIndex: Int
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Module Number
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 32, height: 32)
                    
                    Text("\(moduleIndex + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(module.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(module.lessons.count) lessons")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingDetails.toggle()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(showingDetails ? 90 : 0))
                    }
                }
            }
            
                        
            // Module Details
            if showingDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    Text("Lessons")
                        .font(.subheadline.weight(.semibold))
                    
                    ForEach(module.lessons, id: \.id) { lesson in
                        HStack {
                            Image(systemName: "book")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text(lesson.title)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(lesson.estimatedDuration)m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Label("\(module.estimatedDuration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        // CourseModule doesn't have difficulty property
                        // Text(module.difficulty)
                        //     .font(.caption)
                        //     .padding(.horizontal, 8)
                        //     .padding(.vertical, 4)
                        //     .background(
                        //         Capsule()
                        //             .fill(.blue.opacity(0.2))
                        //     )
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.spring(response: 0.4), value: showingDetails)
    }
}

struct CompletionBadgeSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 Course Completed!")
                .font(.title2.weight(.bold))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Achievement Level:")
                        .font(.body.weight(.medium))
                    
                    Spacer()
                    
                    HStack {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 12, height: 12)
                        
                        Text("Excellence")
                            .font(.body.weight(.semibold))
                    }
                }
                
                HStack {
                    Text("Completed:")
                        .font(.body.weight(.medium))
                    
                    Spacer()
                    
                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                        .font(.body.weight(.semibold))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ActionButtonsSection: View {
    let course: ClassroomCourse
    @StateObject private var courseManager = CourseProgressManager.shared
    @State private var showingShareSheet = false
    @State private var showingDuplicateAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Course")
                }
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
            }
            
            HStack(spacing: 12) {
                Button {
                    showingDuplicateAlert = true
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate")
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    Task {
                        await courseManager.removeFromLibrary(course)
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove")
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .alert("Duplicate Course", isPresented: $showingDuplicateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Duplicate") {
                let duplicated = courseManager.duplicateCourse(course)
                Task {
                    await courseManager.saveToLibrary(duplicated)
                }
            }
        } message: {
            Text("This will create a copy of the course that you can restart from the beginning.")
        }
        .sheet(isPresented: $showingShareSheet) {
            // Simple share interface
            VStack(spacing: 20) {
                Text("Share Course")
                    .font(.title2.weight(.bold))
                
                Text("Share this course with your friends and colleagues!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Copy Link") {
                    // Placeholder for share functionality
                    showingShareSheet = false
                }
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                
                Button("Cancel", role: .cancel) {
                    showingShareSheet = false
                }
            }
            .padding(24)
        }
    }
}

struct CourseProgressEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Active Course")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text("Start a conversation with Lyo to begin a new learning journey!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    CourseProgressDetailView()
}