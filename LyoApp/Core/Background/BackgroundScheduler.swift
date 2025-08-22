import BackgroundTasks
import Foundation

/// Background task scheduler for finishing long-running course generation
class BackgroundScheduler {
    
    static let shared = BackgroundScheduler()
    
    // Background task identifiers
    private let appRefreshTaskId = "com.lyo.app.refresh"
    private let processingTaskId = "com.lyo.app.processing"
    
    private let apiClient: APIClient
    private let taskOrchestrator: TaskOrchestrator
    private let coreDataStack: CoreDataStack
    
    // Track running tasks
    @Published var runningTasks: Set<String> = []
    
    init(apiClient: APIClient? = nil, taskOrchestrator: TaskOrchestrator? = nil) {
        let authManager = AuthManager()
        self.apiClient = apiClient ?? APIClient(environment: .current, authManager: authManager)
        self.taskOrchestrator = taskOrchestrator ?? TaskOrchestrator(apiClient: self.apiClient)
        self.coreDataStack = CoreDataStack.shared
        
        registerBackgroundTasks()
    }
    
    // MARK: - Background Task Registration
    
    private func registerBackgroundTasks() {
        // Register app refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: appRefreshTaskId, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register processing task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskId, using: nil) { task in
            self.handleProcessingTask(task: task as! BGProcessingTask)
        }
        
        print("✅ Background tasks registered")
    }
    
    // MARK: - Task Scheduling
    
    /// Schedule background refresh when a course generation is running
    func scheduleBackgroundCompletion(for taskId: String) {
        runningTasks.insert(taskId)
        
        // Schedule app refresh task for 15-30 minutes
        let request = BGAppRefreshTaskRequest(identifier: appRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Background task scheduled for course generation: \(taskId)")
        } catch {
            print("❌ Failed to schedule background task: \(error)")
        }
    }
    
    /// Schedule processing task for immediate execution when app backgrounds
    func scheduleProcessingTask(for taskId: String) {
        let request = BGProcessingTaskRequest(identifier: processingTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5) // 5 seconds
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Processing task scheduled for: \(taskId)")
        } catch {
            print("❌ Failed to schedule processing task: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("🔄 Handling app refresh background task")
        
        // Schedule the next refresh
        scheduleNextAppRefresh()
        
        // Create operation for checking running tasks
        let operation = BackgroundTaskOperation(
            runningTasks: Array(runningTasks),
            apiClient: apiClient,
            coreDataStack: coreDataStack
        )
        
        // Set expiration handler
        task.expirationHandler = {
            print("⏰ App refresh task expired")
            operation.cancel()
        }
        
        // Complete task when operation finishes
        operation.completionBlock = {
            let success = !operation.isCancelled
            print("✅ App refresh completed: \(success)")
            task.setTaskCompleted(success: success)
        }
        
        // Start the operation
        OperationQueue().addOperation(operation)
    }
    
    private func handleProcessingTask(task: BGProcessingTask) {
        print("⚙️ Handling processing background task")
        
        // Create operation for intensive task processing
        let operation = BackgroundTaskOperation(
            runningTasks: Array(runningTasks),
            apiClient: apiClient,
            coreDataStack: coreDataStack,
            isProcessingTask: true
        )
        
        // Set expiration handler
        task.expirationHandler = {
            print("⏰ Processing task expired")
            operation.cancel()
        }
        
        // Complete task when operation finishes
        operation.completionBlock = {
            let success = !operation.isCancelled
            print("✅ Processing task completed: \(success)")
            
            // Remove completed tasks from tracking
            if success {
                self.runningTasks.removeAll()
            }
            
            task.setTaskCompleted(success: success)
        }
        
        // Start the operation
        OperationQueue().addOperation(operation)
    }
    
    private func scheduleNextAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("❌ Failed to schedule next app refresh: \(error)")
        }
    }
    
    // MARK: - Task Status Management
    
    /// Mark a task as completed (remove from tracking)
    func taskCompleted(_ taskId: String) {
        runningTasks.remove(taskId)
        print("✅ Task completed and removed from tracking: \(taskId)")
    }
    
    /// Check if any tasks are running in background
    var hasRunningTasks: Bool {
        return !runningTasks.isEmpty
    }
}

// MARK: - Background Task Operation
private class BackgroundTaskOperation: Operation {
    
    private let runningTasks: [String]
    private let apiClient: APIClient
    private let coreDataStack: CoreDataStack
    private let isProcessingTask: Bool
    
    init(runningTasks: [String], apiClient: APIClient, coreDataStack: CoreDataStack, isProcessingTask: Bool = false) {
        self.runningTasks = runningTasks
        self.apiClient = apiClient
        self.coreDataStack = coreDataStack
        self.isProcessingTask = isProcessingTask
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        print("🚀 Background operation started with \(runningTasks.count) tasks")
        
        let group = DispatchGroup()
        
        for taskId in runningTasks {
            guard !isCancelled else { break }
            
            group.enter()
            
            Task {
                defer { group.leave() }
                await self.checkTask(taskId)
            }
        }
        
        // Wait for all tasks to complete or timeout
        let timeout: DispatchTime = isProcessingTask ? .now() + 25 : .now() + 25 // 25 seconds
        let result = group.wait(timeout: timeout)
        
        if result == .timedOut {
            print("⏰ Background operation timed out")
        } else {
            print("✅ Background operation completed")
        }
    }
    
    private func checkTask(_ taskId: String) async {
        do {
            print("🔍 Checking task status: \(taskId)")
            
            let taskEvent: TaskEvent = try await apiClient.get("tasks/\(taskId)")
            
            if taskEvent.state == .done, let resultId = taskEvent.resultId {
                print("🎉 Task completed in background: \(taskId)")
                
                // Prefetch the completed course
                await prefetchCourse(resultId)
                
                // Send local notification
                await sendCompletionNotification(taskId: taskId, courseId: resultId)
                
            } else if taskEvent.state == .error {
                print("❌ Task failed in background: \(taskId)")
                await sendErrorNotification(taskId: taskId)
                
            } else {
                print("⏳ Task still running: \(taskId) (\(taskEvent.state))")
            }
            
        } catch {
            print("❌ Failed to check task status: \(error)")
        }
    }
    
    private func prefetchCourse(_ courseId: String) async {
        do {
            print("📚 Prefetching completed course: \(courseId)")
            
            let courseDTO: CourseDTO = try await apiClient.get("courses/\(courseId)")
            
            // Normalize and cache the course
            await MainActor.run {
                let normalizer = DataNormalizer(coreDataStack: coreDataStack)
                try? normalizer.normalizeCourse(courseDTO)
                print("✅ Course cached for offline access")
            }
            
        } catch {
            print("❌ Failed to prefetch course: \(error)")
        }
    }
    
    private func sendCompletionNotification(taskId: String, courseId: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Course Ready! 🎉"
        content.body = "Your personalized course has been generated and is ready to explore."
        content.sound = .default
        content.userInfo = ["course_id": courseId]
        
        let request = UNNotificationRequest(
            identifier: "course_completed_\(taskId)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📧 Completion notification sent")
        } catch {
            print("❌ Failed to send notification: \(error)")
        }
    }
    
    private func sendErrorNotification(taskId: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Course Generation Failed"
        content.body = "There was an issue generating your course. Please try again."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "course_failed_\(taskId)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📧 Error notification sent")
        } catch {
            print("❌ Failed to send error notification: \(error)")
        }
    }
}

// MARK: - App Lifecycle Integration
extension BackgroundScheduler {
    
    /// Call when app enters background with running tasks
    func handleAppDidEnterBackground() {
        if hasRunningTasks {
            print("📱 App backgrounded with \(runningTasks.count) running tasks")
            
            // Schedule immediate processing task
            for taskId in runningTasks {
                scheduleProcessingTask(for: taskId)
            }
        }
    }
    
    /// Call when app becomes active to check for completed tasks
    func handleAppDidBecomeActive() {
        print("📱 App became active, checking task status")
        
        // Check running tasks immediately
        Task {
            for taskId in Array(runningTasks) {
                do {
                    let taskEvent: TaskEvent = try await apiClient.get("tasks/\(taskId)")
                    
                    if taskEvent.isTerminal {
                        taskCompleted(taskId)
                    }
                } catch {
                    print("❌ Failed to check task on app active: \(error)")
                }
            }
        }
    }
}