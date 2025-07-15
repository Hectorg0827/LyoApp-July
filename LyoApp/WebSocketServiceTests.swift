
import XCTest
@testable import LyoApp

class WebSocketServiceTests: XCTestCase {

    var webSocketService: WebSocketService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        webSocketService = WebSocketService()
    }

    override func tearDownWithError() throws {
        webSocketService = nil
        try super.tearDownWithError()
    }

    func testConnectAndDisconnect() {
        let expectation = XCTestExpectation(description: "WebSocket connects and disconnects")

        // Connect
        webSocketService.connect(userId: "testUser")

        // Disconnect after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.webSocketService.disconnect()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
