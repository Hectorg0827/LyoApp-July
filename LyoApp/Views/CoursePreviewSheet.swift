import SwiftUI

// MARK: - Course Preview Sheet
/// Beautiful preview shown before launching Unity classroom
/// Displays course details, environment info, and XP rewards
struct CoursePreviewSheet: View {
    let resource: LearningResource
    let generatedCourse: GeneratedCourse?
    @Binding var isPresented: Bool
    let onLaunch: () -> Void
    
    @State private var isExpanded = false
    @State private var selectedTab = 0
    @StateObject private var classroomManager = DynamicClassroomManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "0A0E27"),
                        Color(hex: "1A1F3A"),
                        Color(hex: "2A3F5A")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with environment preview
                        EnvironmentPreviewCard(
                            environmentName: environmentName,
                            courseName: resource.title
                        )
                        .padding(.top, 8)
                        
                        // Tab selector
                        Picker("Info", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Lessons").tag(1)
                            Text("Rewards").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Tab content
                        TabView(selection: $selectedTab) {
                            // Overview Tab
                            OverviewTab(
                                resource: resource,
                                generatedCourse: generatedCourse,
                                environment: classroomManager.currentEnvironment
                            )
                            .tag(0)
                            
                            // Lessons Tab
                            LessonsTab(
                                lessons: generatedCourse?.lessons ?? [],
                                duration: resource.estimatedDuration ?? "Unknown"
                            )
                            .tag(1)
                            
                            // Rewards Tab
                            RewardsTab(
                                totalXP: generatedCourse?.calculatedTotalXP ?? 0,
                                difficulty: resource.difficultyLevel?.rawValue ?? "beginner"
                            )
                            .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 400)
                        
                        // Launch button
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isPresented = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onLaunch()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Enter Classroom")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Course Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var environmentName: String {
        if let env = classroomManager.currentEnvironment?.setting {
            return env
        } else if let course = generatedCourse {
            return course.inferredUnityScene
        } else {
            return resource.inferUnityEnvironment()
        }
    }
}

// MARK: - Environment Preview Card
struct EnvironmentPreviewCard: View {
    let environmentName: String
    let courseName: String
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image (placeholder with gradient)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: environmentGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay(
                    Image(systemName: environmentIcon)
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            // Overlay info
            VStack(alignment: .leading, spacing: 4) {
                Text(environmentDisplayName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                
                Text(courseName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    private var environmentDisplayName: String {
        switch environmentName.lowercased() {
        case let name where name.contains("maya"):
            return "Maya Ceremonial Center"
        case let name where name.contains("egypt"):
            return "Egyptian Temple"
        case let name where name.contains("mars"):
            return "Mars Exploration Base"
        case let name where name.contains("chemistry"):
            return "Advanced Chemistry Lab"
        case let name where name.contains("math"):
            return "Mathematics Studio"
        case let name where name.contains("rome"):
            return "Roman Forum"
        case let name where name.contains("greece"):
            return "Greek Agora"
        default:
            return "Modern Classroom"
        }
    }
    
    private var environmentIcon: String {
        switch environmentName.lowercased() {
        case let name where name.contains("maya"):
            return "building.columns.fill"
        case let name where name.contains("egypt"):
            return "pyramid.fill"
        case let name where name.contains("mars"):
            return "moon.stars.fill"
        case let name where name.contains("chemistry"):
            return "flask.fill"
        case let name where name.contains("math"):
            return "function"
        default:
            return "book.fill"
        }
    }
    
    private var environmentGradient: [Color] {
        switch environmentName.lowercased() {
        case let name where name.contains("maya"):
            return [Color(hex: "1B5E20"), Color(hex: "4CAF50")]
        case let name where name.contains("egypt"):
            return [Color(hex: "FF6F00"), Color(hex: "FFD54F")]
        case let name where name.contains("mars"):
            return [Color(hex: "D32F2F"), Color(hex: "F57C00")]
        case let name where name.contains("chemistry"):
            return [Color(hex: "1565C0"), Color(hex: "42A5F5")]
        case let name where name.contains("math"):
            return [Color(hex: "6A1B9A"), Color(hex: "AB47BC")]
        default:
            return [Color(hex: "424242"), Color(hex: "757575")]
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let resource: LearningResource
    let generatedCourse: GeneratedCourse?
    let environment: ClassroomEnvironment?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            Text(resource.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // Stats
            HStack(spacing: 20) {
                StatBadge(
                    icon: "clock.fill",
                    label: "Duration",
                    value: resource.estimatedDuration ?? "Unknown"
                )
                
                StatBadge(
                    icon: "chart.bar.fill",
                    label: "Level",
                    value: resource.difficultyLevel?.rawValue.capitalized ?? "Beginner"
                )
                
                if let lessonCount = generatedCourse?.lessonCount {
                    StatBadge(
                        icon: "list.bullet",
                        label: "Lessons",
                        value: "\(lessonCount)"
                    )
                }
            }
            
            Divider()
            
            // Environment details
            if let env = environment {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment Details")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DetailRow(label: "Setting", value: env.setting)
                    DetailRow(label: "Location", value: env.location)
                    DetailRow(label: "Time Period", value: env.timeperiod)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Lessons Tab
struct LessonsTab: View {
    let lessons: [LessonOutline]
    let duration: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if lessons.isEmpty {
                    Text("Lesson details will be generated")
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                        .padding()
                } else {
                    ForEach(Array(lessons.enumerated()), id: \.offset) { index, lesson in
                        LessonRow(
                            number: index + 1,
                            title: lesson.title,
                            duration: lesson.duration ?? 0
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct LessonRow: View {
    let number: Int
    let title: String
    let duration: Int
    
    var body: some View {
        HStack {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.blue.opacity(0.3)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Text("\(duration) min")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Rewards Tab
struct RewardsTab: View {
    let totalXP: Int
    let difficulty: String
    
    var body: some View {
        VStack(spacing: 24) {
            // XP Display
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("\(totalXP) XP")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Total Experience Points")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            
            // Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Rewards Breakdown")
                    .font(.headline)
                    .foregroundColor(.white)
                
                RewardRow(icon: "book.fill", label: "Course Completion", value: "+\(Int(Double(totalXP) * 0.6))")
                RewardRow(icon: "trophy.fill", label: "Difficulty Bonus", value: difficultyBonus)
                RewardRow(icon: "checkmark.seal.fill", label: "Perfect Score Bonus", value: "+\(Int(Double(totalXP) * 0.2))")
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private var difficultyBonus: String {
        switch difficulty.lowercased() {
        case "beginner": return "+0%"
        case "intermediate": return "+50%"
        case "advanced": return "+100%"
        default: return "+0%"
        }
    }
}

struct RewardRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Helper Views
struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    CoursePreviewSheet(
        resource: LearningResource.sampleResources().first!,
        generatedCourse: nil,
        isPresented: .constant(true),
        onLaunch: {}
    )
}
#endif
