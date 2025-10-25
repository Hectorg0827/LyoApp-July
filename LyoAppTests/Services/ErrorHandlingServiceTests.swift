import XCTest
@testable import LyoApp

@MainActor
final class ErrorHandlingServiceTests: XCTestCase {
    
    var sut: ErrorHandlingService!
    
    override func setUp() async throws {
        sut = ErrorHandlingService.shared
        sut.currentError = nil
        sut.errorHistory.removeAll()
    }
    
    override func tearDown() async throws {
        sut.currentError = nil
        sut.errorHistory.removeAll()
        sut = nil
    }
    
    // MARK: - Basic Error Display Tests
    
    func testShowError_SetsCurrentError() {
        // Given
        let error = UserFacingError.networkUnavailable
        
        // When
        sut.show(error, autoDismiss: false)
        
        // Then
        XCTAssertNotNil(sut.currentError)
        XCTAssertEqual(sut.currentError?.error.title, "No Internet Connection")
    }
    
    func testShowError_AddsToHistory() {
        // Given
        let error = UserFacingError.serverError
        
        // When
        sut.show(error, autoDismiss: false)
        
        // Then
        XCTAssertEqual(sut.errorHistory.count, 1)
        XCTAssertEqual(sut.errorHistory.first?.error.title, "Server Error")
    }
    
    func testDismiss_ClearsCurrentError() {
        // Given
        sut.show(.networkUnavailable, autoDismiss: false)
        XCTAssertNotNil(sut.currentError)
        
        // When
        sut.dismiss()
        
        // Then
        XCTAssertNil(sut.currentError)
    }
    
    // MARK: - Auto-Dismiss Tests
    
    func testShowError_AutoDismissesAfter5Seconds() async {
        // Given
        let error = UserFacingError.aiServiceUnavailable
        
        // When
        sut.show(error, autoDismiss: true)
        XCTAssertNotNil(sut.currentError)
        
        // Wait for auto-dismiss (5 seconds + buffer)
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        
        // Then
        XCTAssertNil(sut.currentError, "Error should auto-dismiss after 5 seconds")
    }
    
    // MARK: - Error History Tests
    
    func testErrorHistory_LimitsTo10Errors() {
        // Given & When
        for i in 1...15 {
            sut.show(.unknown("Error \(i)"), autoDismiss: false)
        }
        
        // Then
        XCTAssertEqual(sut.errorHistory.count, 10, "History should be limited to 10 errors")
    }
    
    // MARK: - API Error Conversion Tests
    
    func testShowAPIError_NetworkError_ConvertsCorrectly() {
        // Given
        let apiError = APIError.networkError(NSError(domain: "test", code: -1))
        
        // When
        sut.show(apiError, autoDismiss: false)
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "No Internet Connection")
    }
    
    func testShowAPIError_Unauthorized_ConvertsCorrectly() {
        // Given
        let apiError = APIError.unauthorized
        
        // When
        sut.show(apiError, autoDismiss: false)
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "Authentication Failed")
    }
    
    func testShowAPIError_ServerError_ConvertsCorrectly() {
        // Given
        let apiError = APIError.serverError(500, "Internal server error")
        
        // When
        sut.show(apiError, autoDismiss: false)
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "Server Error")
    }
    
    // MARK: - Convenience Methods Tests
    
    func testShowNetworkError_DisplaysCorrectError() {
        // When
        sut.showNetworkError()
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "No Internet Connection")
        XCTAssertEqual(sut.currentError?.error.icon, "wifi.slash")
    }
    
    func testShowAuthError_DisplaysCorrectErrorWithoutAutoDismiss() {
        // When
        sut.showAuthError()
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "Authentication Failed")
        XCTAssertEqual(sut.currentError?.error.icon, "lock.shield")
    }
    
    func testShowServerError_DisplaysCorrectError() {
        // When
        sut.showServerError()
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "Server Error")
    }
    
    func testShowAIError_DisplaysCorrectError() {
        // When
        sut.showAIError()
        
        // Then
        XCTAssertEqual(sut.currentError?.error.title, "AI Service Unavailable")
        XCTAssertEqual(sut.currentError?.error.icon, "brain.head.profile")
    }
}
