import XCTest
@testable import LyoApp

final class PaginatorTests: XCTestCase {
    
    // Mock item for testing
    struct TestItem: Identifiable {
        let id: String
    }
    
    func testPaginatorInitialization() {
        let paginator = Paginator<TestItem> { cursor in
            return ([], nil)
        }
        
        XCTAssertTrue(paginator.items.isEmpty)
        XCTAssertFalse(paginator.hasMore)
        XCTAssertFalse(paginator.isLoading)
    }
    
    func testLoadInitialPage() async throws {
        let expectation = XCTestExpectation(description: "Load initial page")
        
        let paginator = Paginator<TestItem> { cursor in
            XCTAssertNil(cursor) // First call should have nil cursor
            expectation.fulfill()
            return ([TestItem(id: "1"), TestItem(id: "2")], "next-cursor")
        }
        
        try await paginator.loadInitialPage()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(paginator.items.count, 2)
        XCTAssertEqual(paginator.items[0].id, "1")
        XCTAssertEqual(paginator.items[1].id, "2")
        XCTAssertTrue(paginator.hasMore)
    }
    
    func testLoadMoreWithCursor() async throws {
        let expectation1 = XCTestExpectation(description: "Load initial")
        let expectation2 = XCTestExpectation(description: "Load more")
        var callCount = 0
        
        let paginator = Paginator<TestItem> { cursor in
            callCount += 1
            if callCount == 1 {
                XCTAssertNil(cursor)
                expectation1.fulfill()
                return ([TestItem(id: "1")], "cursor-1")
            } else {
                XCTAssertEqual(cursor, "cursor-1")
                expectation2.fulfill()
                return ([TestItem(id: "2")], nil) // No more pages
            }
        }
        
        // Load initial page
        try await paginator.loadInitialPage()
        await fulfillment(of: [expectation1], timeout: 1.0)
        
        // Load more (should trigger when near end)
        try await paginator.loadMoreIfNeeded(currentIndex: 0)
        await fulfillment(of: [expectation2], timeout: 1.0)
        
        XCTAssertEqual(paginator.items.count, 2)
        XCTAssertFalse(paginator.hasMore) // No next cursor
    }
    
    func testDeduplication() async throws {
        let paginator = Paginator<TestItem> { cursor in
            if cursor == nil {
                return ([TestItem(id: "1"), TestItem(id: "2")], "next")
            } else {
                // Return duplicate item
                return ([TestItem(id: "2"), TestItem(id: "3")], nil)
            }
        }
        
        try await paginator.loadInitialPage()
        try await paginator.loadMoreIfNeeded(currentIndex: 1)
        
        XCTAssertEqual(paginator.items.count, 3) // Should have deduped id "2"
        XCTAssertEqual(Set(paginator.items.map { $0.id }), Set(["1", "2", "3"]))
    }
    
    func testNoLoadWhenNotNearEnd() async throws {
        var fetchCallCount = 0
        
        let paginator = Paginator<TestItem> { cursor in
            fetchCallCount += 1
            return (Array(0..<20).map { TestItem(id: "\($0)") }, "next")
        }
        
        try await paginator.loadInitialPage()
        XCTAssertEqual(fetchCallCount, 1)
        
        // Try to load more when at beginning (should not trigger)
        try await paginator.loadMoreIfNeeded(currentIndex: 0)
        XCTAssertEqual(fetchCallCount, 1) // Should not have called fetch again
        
        // Try when near end (should trigger)
        try await paginator.loadMoreIfNeeded(currentIndex: 17)
        XCTAssertEqual(fetchCallCount, 2) // Should have called fetch
    }
    
    func testReset() async throws {
        let paginator = Paginator<TestItem> { cursor in
            return ([TestItem(id: "1")], "next")
        }
        
        try await paginator.loadInitialPage()
        XCTAssertEqual(paginator.items.count, 1)
        XCTAssertTrue(paginator.hasMore)
        
        paginator.reset()
        XCTAssertTrue(paginator.items.isEmpty)
        XCTAssertFalse(paginator.hasMore)
        XCTAssertFalse(paginator.isLoading)
    }
}