import Foundation
import SwiftUI

// MARK: - Content Item View Data
struct ContentItemViewData: Identifiable {
    let id: String
    let type: String
    let title: String
    let url: URL?
    let duration: TimeInterval?
    
    init(from item: ContentItemDTO) {
        self.id = item.id
        self.type = item.type
        self.title = item.title
        self.url = URL(string: item.sourceUrl ?? "")
        self.duration = TimeInterval(item.durationSec ?? 0)
    }
    
    init(from entity: ContentItemEntity) {
        self.id = entity.id ?? UUID().uuidString
        self.type = entity.type ?? "unknown"
        self.title = entity.title ?? "Untitled"
        self.url = URL(string: entity.url ?? "")
        self.duration = entity.duration > 0 ? entity.duration : nil
    }
    
    // Convenience initializer for testing
    init(id: String, type: String, title: String, url: URL?, duration: TimeInterval?) {
        self.id = id
        self.type = type
        self.title = title
        self.url = url
        self.duration = duration
    }
}

// MARK: - Course Snapshot
struct CourseSnapshot {
    enum Status {
        case generating
        case ready
        case error(String)
    }
    
    let status: Status
    let items: [ContentItemEntity]
}

// MARK: - Course Repository Protocol
protocol CourseRepository {
    func observeCourse(id: String, onChange: @escaping (CourseSnapshot) -> Void) -> AnyObject
}

// MARK: - Core Data Course Repository
final class CoreDataCourseRepository: CourseRepository {
    private let coreDataManager = CoreDataManager.shared
    
    func observeCourse(id: String, onChange: @escaping (CourseSnapshot) -> Void) -> AnyObject {
        // Use NSTimer as a simple observer for now (in production, use NSFetchedResultsController)
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Fetch course and items from Core Data
            let courses = self.coreDataManager.fetchCourses()
            guard let courseEntity = courses.first(where: { $0.id == id }) else {
                let snapshot = CourseSnapshot(status: .error("Course not found"), items: [])
                onChange(snapshot)
                return
            }
            
            // Get associated content items (simplified - in real implementation would use relationships)
            let contentItems: [ContentItemEntity] = [] // Would fetch from relationships
            
            // Determine status based on course data
            let status: CourseSnapshot.Status
            if let errorField = courseEntity.value(forKey: "error") as? String, !errorField.isEmpty {
                status = .error(errorField)
            } else if let statusField = courseEntity.value(forKey: "status") as? String {
                switch statusField {
                case "generating":
                    status = .generating
                case "ready", "complete":
                    status = .ready
                default:
                    status = .generating
                }
            } else {
                status = .ready // Default to ready if no status field
            }
            
            let snapshot = CourseSnapshot(status: status, items: contentItems)
            onChange(snapshot)
        }
        
        return timer
    }
}

// MARK: - Course View Model
final class CourseViewModel: ObservableObject {
    enum State {
        case generating
        case ready
        case partial
        case error(String)
    }
    
    @Published private(set) var state: State = .generating
    @Published private(set) var items: [ContentItemViewData] = []
    
    private let courseId: String
    private let orchestrator: TaskOrchestrator
    private let repo: CourseRepository
    private var observer: AnyObject?
    
    init(courseId: String, orchestrator: TaskOrchestrator, repo: CourseRepository) {
        self.courseId = courseId
        self.orchestrator = orchestrator
        self.repo = repo
    }
    
    func startObserving() {
        observer = repo.observeCourse(id: courseId) { [weak self] snapshot in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.items = snapshot.items.map(ContentItemViewData.init)
                
                switch snapshot.status {
                case .generating where !self.items.isEmpty:
                    self.state = .partial
                case .generating:
                    self.state = .generating
                case .ready:
                    self.state = .ready
                case .error(let msg):
                    self.state = .error(msg)
                }
            }
        }
    }
    
    func retry() {
        // Use orchestrator to retry course generation
        Task {
            do {
                // In a real implementation, this would call orchestrator.retryCourseGeneration
                // For now, just reset state
                await MainActor.run {
                    self.state = .generating
                }
                Analytics.log("course_generate_requested", ["course_id": courseId, "retry": true])
            } catch {
                await MainActor.run {
                    self.state = .error("Failed to retry: \(error.localizedDescription)")
                }
                Analytics.log("course_generate_error", ["course_id": courseId, "error": error.localizedDescription])
            }
        }
    }
    
    func open(_ item: ContentItemViewData) {
        Analytics.log("content_item_opened", ["id": item.id, "type": item.type])
    }
    
    deinit {
        if let observer = observer as? Timer {
            observer.invalidate()
        }
    }
}