import SwiftUI
import UIKit

// MARK: - Unity Classroom Container
/// SwiftUI wrapper for Unity's UIView that embeds the 3D classroom
/// Integrates with DynamicClassroomManager for environment-aware loading
struct UnityClassroomContainerView: UIViewRepresentable {
    let resource: LearningResource
    @Binding var isPresented: Bool
    @StateObject private var classroomManager = DynamicClassroomManager.shared
    @State private var isLoading = true
    
    func makeUIView(context: Context) -> UIView {
        print("🎮 [Unity] Creating Unity view for course: \(resource.title)")
        
        // Get Unity's root view
        let unityView = UnityManager.shared.getUnityView()
        
        // Send course data to Unity on creation
        sendCourseDataToUnity()
        
        return unityView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Unity view is persistent, no updates needed
        // Only reload if resource changes (handled by dismissal/recreation)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func sendCourseDataToUnity() {
        // Get environment from DynamicClassroomManager if available
        let environment = classroomManager.currentEnvironment?.setting ?? resource.inferUnityEnvironment()
        
        // Prepare JSON payload for Unity with enhanced data
        guard let jsonPayload = resource.toUnityJSON(
            environmentOverride: environment,
            tutorPersonality: classroomManager.tutorPersonality?.role
        ) else {
            print("❌ [Unity] Failed to serialize course data")
            return
        }
        
        print("📤 [Unity] Sending course data to Unity:")
        print("   Environment: \(environment)")
        print("   JSON: \(jsonPayload)")
        
        // Send to Unity's ClassroomController
        UnityManager.shared.sendMessage(
            to: "ClassroomController",
            methodName: "LoadCourse",
            message: jsonPayload
        )
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        var parent: UnityClassroomContainerView
        
        init(_ parent: UnityClassroomContainerView) {
            self.parent = parent
        }
    }
}

// MARK: - Unity Classroom Overlay
/// Full-screen overlay that presents the Unity classroom with controls
struct UnityClassroomOverlay: View {
    let resource: LearningResource
    @Binding var isPresented: Bool
    @State private var showControls = true
    @State private var progress: Double = 0.0
    @State private var isLoading = true
    @State private var showPreview = true
    @StateObject private var classroomManager = DynamicClassroomManager.shared
    @StateObject private var analytics = UnityAnalyticsService.shared
    
    var body: some View {
        ZStack {
            if showPreview {
                // Course Preview Sheet
                CoursePreviewSheet(
                    resource: resource,
                    generatedCourse: nil, // TODO: Pass actual GeneratedCourse if available
                    isPresented: $showPreview,
                    onLaunch: {
                        isLoading = true
                        
                        // Track session start
                        analytics.startClassroomSession(
                            courseId: resource.id ?? "unknown",
                            courseName: resource.title,
                            environment: environmentName,
                            difficulty: resource.difficultyLevel?.rawValue ?? "beginner"
                        )
                    }
                )
            } else if isLoading {
                // Loading screen
                UnityLoadingView(
                    environmentName: environmentName,
                    courseName: resource.title,
                    isLoading: $isLoading
                )
            } else {
                // Unity View
                UnityClassroomContainerView(
                    resource: resource,
                    isPresented: $isPresented
                )
                .edgesIgnoringSafeArea(.all)
            
            // Overlay Controls
            if showControls {
                VStack {
                    // Top Bar
                    HStack {
                        Button(action: { exitClassroom() }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Exit")
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        Text(resource.title)
                            .font(.headline)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        Button(action: { showControls.toggle() }) {
                            Image(systemName: "chevron.up.circle.fill")
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Progress Bar
                    VStack {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .padding(.horizontal)
                        
                        Text("\(Int(progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                }
            } else {
                // Hidden controls indicator
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showControls.toggle() }) {
                            Image(systemName: "chevron.down.circle.fill")
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            print("🎓 [Classroom] Unity classroom opened for: \(resource.title)")
            // Start progress tracking
            simulateProgress()
        }
        .onDisappear {
            print("👋 [Classroom] Unity classroom closed")
        }
    }
    
    private var environmentName: String {
        if let env = classroomManager.currentEnvironment?.setting {
            return env
        } else {
            return resource.inferUnityEnvironment()
        }
    }
    
    private func exitClassroom() {
        // Track session end
        UnityAnalyticsService.shared.endClassroomSession(
            completed: progress >= 0.95,
            finalProgress: progress,
            xpEarned: Int(progress * 1000)
        )
        
        isPresented = false
        LearningDataManager.shared.closeDynamicClassroom()
    }
    
    private func simulateProgress() {
        // TODO: Replace with real progress from Unity
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - LearningResource Extension for Unity JSON
extension LearningResource {
    /// Converts learning resource to JSON for Unity consumption
    /// - Parameters:
    ///   - environmentOverride: Optional environment name from DynamicClassroomManager
    ///   - tutorPersonality: Optional tutor role for personalized experience
    func toUnityJSON(environmentOverride: String? = nil, tutorPersonality: String? = nil) -> String? {
        let dict: [String: Any] = [
            "courseId": id ?? "unknown",
            "title": title,
            "description": description,
            "difficulty": difficultyLevel?.rawValue ?? "beginner",
            "estimatedDuration": estimatedDuration ?? "30 min",
            "category": category ?? "General",
            "tags": tags,
            "environment": environmentOverride ?? inferUnityEnvironment(),
            "tutorRole": tutorPersonality ?? "guide",
            "provider": provider ?? "Lyo Academy",
            "rating": rating ?? 0.0,
            "enrolledCount": enrolledCount ?? 0
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
    
    /// Infers the appropriate Unity environment based on course category
    private func inferUnityEnvironment() -> String {
        let categoryLower = (category ?? "").lowercased()
        let titleLower = title.lowercased()
        
        // Match to Unity scene names
        if categoryLower.contains("history") || titleLower.contains("maya") || titleLower.contains("civilization") {
            return "MayaCivilization"
        } else if categoryLower.contains("space") || titleLower.contains("mars") {
            return "MarsExploration"
        } else if categoryLower.contains("science") || categoryLower.contains("chemistry") {
            return "ChemistryLab"
        } else if categoryLower.contains("math") {
            return "MathematicsStudio"
        } else {
            return "DefaultClassroom"
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    UnityClassroomOverlay(
        resource: LearningResource.sampleResources().first!,
        isPresented: .constant(true)
    )
}
#endif
