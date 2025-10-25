import Foundation
import SwiftUI
import Combine

// MARK: - Course Progress Manager (Canonical)
/// Manages course progress using canonical ClassroomCourse and CourseProgress models from ClassroomModels.swift
@MainActor
class CourseProgressManager: ObservableObject {
    static let shared = CourseProgressManager()
    
    // Current active course
    @Published var currentCourse: ClassroomCourse?
    @Published var currentProgress: CourseProgress?
    
    // Overall progress (0.0 to 1.0)
    @Published var overallProgress: Double = 0.0
    
    // Milestones from current progress
    @Published var milestones: [ProgressMilestone] = []
    
    // Saved and completed courses
    @Published var completedCourses: [ClassroomCourse] = []
    @Published var savedCourses: [ClassroomCourse] = []
    
    private var progressUpdateTimer: Timer?
    
    var hasActiveCourse: Bool {
        return currentCourse != nil
    }
    
    private init() {
        loadSavedCourses()
        startProgressTracking()
    }
    
    // MARK: - Course Management
    
    func startCourse(_ course: ClassroomCourse) async {
        currentCourse = course
        
        // Create or load progress for this course
        if let existingProgress = loadProgress(for: course.id) {
            currentProgress = existingProgress
        } else {
            currentProgress = CourseProgress(
                courseId: course.id,
                overallProgress: 0.0
            )
        }
        
        updateFromProgress()
        saveProgress()
    }
    
    func createCourseFromAction(_ action: ImmersiveQuickAction) async {
        guard action.type == .generateCourse else { return }
        
        // Create a mock course from the action
        let course = ClassroomCourse(
            title: "AI-Generated: \(action.title)",
            description: action.description,
            scope: "Comprehensive introduction to \(action.title)",
            level: .intermediate,
            outcomes: ["Understand core concepts", "Apply practical skills", "Build real projects"],
            modules: generateModules(for: action.title),
            estimatedDuration: 240 // 4 hours
        )
        
        currentCourse = course
        
        // Create initial progress
        currentProgress = CourseProgress(
            courseId: course.id,
            overallProgress: 0.0
        )
        
        updateFromProgress()
        
        // Auto-save to library
        await saveToLibrary(course)
    }
    
    func updateProgress(for courseId: UUID, with interaction: String) async {
        guard let course = currentCourse, 
              var progress = currentProgress,
              course.id == courseId else { return }
        
        // Increment progress by small amount
        let increment = 0.05 // 5% per interaction
        progress.overallProgress = min(progress.overallProgress + increment, 1.0)
        
        currentProgress = progress
        updateFromProgress()
        
        // Check if completed
        if progress.overallProgress >= 1.0 {
            await completeCourse(course)
        }
        
        saveProgress()
    }
    
    private func completeCourse(_ course: ClassroomCourse) async {
        // Move to completed courses
        if !completedCourses.contains(where: { $0.id == course.id }) {
            completedCourses.append(course)
        }
        
        // Save to library
        await saveToLibrary(course)
        
        // Clear current course
        currentCourse = nil
        currentProgress = nil
        overallProgress = 0.0
        milestones.removeAll()
    }
    
    // MARK: - Library Management
    
    func saveToLibrary(_ course: ClassroomCourse) async {
        // Add to saved courses if not already present
        if !savedCourses.contains(where: { $0.id == course.id }) {
            savedCourses.append(course)
        } else {
            // Update existing course
            if let index = savedCourses.firstIndex(where: { $0.id == course.id }) {
                savedCourses[index] = course
            }
        }
        
        saveCourses()
    }
    
    func removeFromLibrary(_ course: ClassroomCourse) async {
        savedCourses.removeAll { $0.id == course.id }
        completedCourses.removeAll { $0.id == course.id }
        saveCourses()
    }
    
    func duplicateCourse(_ course: ClassroomCourse) -> ClassroomCourse {
        var duplicated = course
        duplicated.id = UUID()
        duplicated.title = "\(course.title) (Copy)"
        duplicated.createdAt = Date()
        
        // Reset module progress
        duplicated.modules = course.modules.map { module in
            var newModule = module
            newModule.id = UUID()
            newModule.progress = 0.0
            newModule.isUnlocked = module.moduleNumber == 1
            return newModule
        }
        
        return duplicated
    }
    
    // MARK: - Course Sharing (Stub Implementation)
    
    func shareCourse(_ course: ClassroomCourse, with users: [String]) async -> ShareResult {
        // Generate a mock share link
        let shareLink = "https://lyo.app/courses/\(course.id.uuidString)"
        return .success(shareLink: shareLink)
    }
    
    func generatePublicShareLink(_ course: ClassroomCourse) async -> String? {
        // Generate a mock public link
        return "https://lyo.app/public/courses/\(course.id.uuidString)"
    }
    
    // MARK: - Progress Calculations
    
    private func updateFromProgress() {
        guard let progress = currentProgress else {
            overallProgress = 0.0
            milestones = []
            return
        }
        
        overallProgress = progress.overallProgress
        milestones = progress.milestones
    }
    
    private func generateMilestones(moduleCount: Int) -> [ProgressMilestone] {
        let milestonePoints = [0.25, 0.5, 0.75, 1.0]
        return milestonePoints.map { percentage in
            ProgressMilestone(
                title: "\(Int(percentage * 100))% Complete",
                progressPercentage: percentage,
                isCompleted: false
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateModules(for topic: String) -> [CourseModule] {
        let moduleTemplates = [
            ("Introduction to \(topic)", "Get started with the fundamentals"),
            ("Core Concepts", "Understand the key principles"),
            ("Practical Applications", "Apply what you've learned")
        ]
        
        return moduleTemplates.enumerated().map { item in
            let (index, (title, description)) = item
            return CourseModule(
                moduleNumber: index + 1,
                title: title,
                description: description,
                lessons: [],
                estimatedDuration: 60,
                isUnlocked: index == 0
            )
        }
    }
    
    // MARK: - Storage Management
    
    private func loadSavedCourses() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savedCourses"),
           let courses = try? JSONDecoder().decode([ClassroomCourse].self, from: data) {
            savedCourses = courses
            completedCourses = courses.filter { course in
                // A course is "completed" if we have progress >= 1.0 for it
                if let progress = loadProgress(for: course.id) {
                    return progress.overallProgress >= 1.0
                }
                return false
            }
        }
    }
    
    private func saveCourses() {
        if let data = try? JSONEncoder().encode(savedCourses) {
            UserDefaults.standard.set(data, forKey: "savedCourses")
        }
    }
    
    private func loadProgress(for courseId: UUID) -> CourseProgress? {
        guard let data = UserDefaults.standard.data(forKey: "progress_\(courseId.uuidString)"),
              let progress = try? JSONDecoder().decode(CourseProgress.self, from: data) else {
            return nil
        }
        return progress
    }
    
    private func saveProgress() {
        guard let progress = currentProgress else { return }
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: "progress_\(progress.courseId.uuidString)")
        }
    }
    
    // MARK: - Progress Tracking
    
    private func startProgressTracking() {
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                if var progress = self.currentProgress {
                    progress.totalTimeSpent += 60 // Add 1 minute
                    self.currentProgress = progress
                    self.saveProgress()
                }
            }
        }
    }
    
    deinit {
        progressUpdateTimer?.invalidate()
    }
}

// MARK: - Supporting Types

enum ShareResult {
    case success(shareLink: String)
    case failure(error: String)
}