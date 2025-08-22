import XCTest
import Combine
@testable import LyoApp

final class CourseViewModelTests: XCTestCase {
    
    // Mock repository for testing
    class MockCourseRepository: CourseRepository {
        var snapshotHandler: ((CourseSnapshot) -> Void)?
        var currentSnapshot: CourseSnapshot = CourseSnapshot(status: .generating, items: [])
        
        func observeCourse(id: String, onChange: @escaping (CourseSnapshot) -> Void) -> AnyObject {
            self.snapshotHandler = onChange
            // Immediately send current snapshot
            onChange(currentSnapshot)
            
            // Return a mock timer-like object
            return NSObject()
        }
        
        func updateSnapshot(_ snapshot: CourseSnapshot) {
            currentSnapshot = snapshot
            snapshotHandler?(snapshot)
        }
    }
    
    // Mock orchestrator
    class MockTaskOrchestrator: TaskOrchestrator {
        init() {
            let authManager = AuthManager()
            let apiClient = APIClient(environment: .current, authManager: authManager)
            super.init(apiClient: apiClient)
        }
    }
    
    var mockRepository: MockCourseRepository!
    var orchestrator: MockTaskOrchestrator!
    var viewModel: CourseViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockCourseRepository()
        orchestrator = MockTaskOrchestrator()
        viewModel = CourseViewModel(
            courseId: "test-course",
            orchestrator: orchestrator,
            repo: mockRepository
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockRepository = nil
        orchestrator = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.state, .generating)
        XCTAssertTrue(viewModel.items.isEmpty)
    }
    
    func testStateTransitionFromGeneratingToReady() {
        let expectation = XCTestExpectation(description: "State changed to ready")
        
        viewModel.$state
            .dropFirst() // Skip initial value
            .sink { state in
                if case .ready = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.startObserving()
        
        // Create mock content items
        let contentItem = ContentItemEntity()
        contentItem.id = "item-1"
        contentItem.title = "Test Item"
        contentItem.type = "video"
        contentItem.url = "https://example.com/video.mp4"
        
        // Update repository to ready state with items
        let readySnapshot = CourseSnapshot(status: .ready, items: [contentItem])
        mockRepository.updateSnapshot(readySnapshot)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items[0].id, "item-1")
        XCTAssertEqual(viewModel.items[0].title, "Test Item")
        XCTAssertEqual(viewModel.items[0].type, "video")
    }
    
    func testStateTransitionToPartial() {
        let expectation = XCTestExpectation(description: "State changed to partial")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .partial = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.startObserving()
        
        // Create mock content items
        let contentItem = ContentItemEntity()
        contentItem.id = "item-1"
        contentItem.title = "Partial Item"
        
        // Update repository to generating state with items (partial)
        let partialSnapshot = CourseSnapshot(status: .generating, items: [contentItem])
        mockRepository.updateSnapshot(partialSnapshot)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.items.count, 1)
        if case .partial = viewModel.state {
            // Success
        } else {
            XCTFail("Expected partial state")
        }
    }
    
    func testStateTransitionToError() {
        let expectation = XCTestExpectation(description: "State changed to error")
        
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .error(let message) = state {
                    XCTAssertEqual(message, "Generation failed")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.startObserving()
        
        // Update repository to error state
        let errorSnapshot = CourseSnapshot(status: .error("Generation failed"), items: [])
        mockRepository.updateSnapshot(errorSnapshot)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRetryResetsToGenerating() {
        let expectation = XCTestExpectation(description: "State reset to generating")
        expectation.expectedFulfillmentCount = 2 // Initial + after retry
        
        viewModel.$state
            .sink { state in
                if case .generating = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.startObserving()
        
        // First, set to error state
        let errorSnapshot = CourseSnapshot(status: .error("Test error"), items: [])
        mockRepository.updateSnapshot(errorSnapshot)
        
        // Then retry
        viewModel.retry()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testOpenContentItem() {
        // This test verifies that analytics are tracked when opening an item
        let item = ContentItemViewData(
            id: "test-id",
            type: "video", 
            title: "Test Video",
            url: URL(string: "https://example.com/video.mp4"),
            duration: 120
        )
        
        // Open the item (this should trigger analytics)
        viewModel.open(item)
        
        // Note: In a real test, we'd verify analytics were called
        // For now, we just verify the method doesn't crash
    }
}