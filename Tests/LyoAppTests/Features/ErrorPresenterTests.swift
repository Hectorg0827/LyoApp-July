import XCTest
@testable import LyoApp

final class ErrorPresenterTests: XCTestCase {
    
    func testUserMessageForProblemDetails() {
        // Test 401 Unauthorized
        let unauthorized = ProblemDetails.unauthorized()
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: unauthorized),
            "Session expired. Please sign in again."
        )
        
        // Test 403 Forbidden
        let forbidden = ProblemDetails.forbidden()
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: forbidden),
            "You don't have access to this."
        )
        
        // Test 404 Not Found
        let notFound = ProblemDetails.notFound()
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: notFound),
            "Not found."
        )
        
        // Test 422 with detail
        let validationError = ProblemDetails(title: "Validation Error", status: 422, detail: "Name is required")
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: validationError),
            "Name is required"
        )
        
        // Test 422 without detail
        let validationErrorNoDetail = ProblemDetails(title: "Validation Error", status: 422)
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: validationErrorNoDetail),
            "Please check your input."
        )
        
        // Test 429 Rate Limited
        let rateLimited = ProblemDetails.rateLimited()
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: rateLimited),
            "Things are busy. We'll retry automatically."
        )
        
        // Test 500 Server Error
        let serverError = ProblemDetails.internalServerError()
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: serverError),
            "Temporary server issue. Try again shortly."
        )
        
        // Test custom error code
        let customError = ProblemDetails(title: "Custom Error", status: 418, detail: "I'm a teapot")
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: customError),
            "I'm a teapot"
        )
    }
    
    func testUserMessageForURLError() {
        // Test network connection errors
        let notConnected = URLError(.notConnectedToInternet)
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: notConnected),
            "No internet connection. Please check your network."
        )
        
        let timeout = URLError(.timedOut)
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: timeout),
            "Request timed out. Please try again."
        )
        
        let connectionLost = URLError(.networkConnectionLost)
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: connectionLost),
            "Network connection lost. Please try again."
        )
        
        let cannotConnect = URLError(.cannotConnectToHost)
        XCTAssertEqual(
            ErrorPresenter.userMessage(for: cannotConnect),
            "Can't connect to server. Please try again later."
        )
    }
    
    func testRetrySuggestion() {
        // Test 429 Rate Limited
        let rateLimited = ProblemDetails.rateLimited()
        XCTAssertEqual(
            ErrorPresenter.retrySuggestion(for: rateLimited),
            "We'll retry automatically in a moment"
        )
        
        // Test 500 Server Error
        let serverError = ProblemDetails.internalServerError()
        XCTAssertEqual(
            ErrorPresenter.retrySuggestion(for: serverError),
            "Try again in a few seconds"
        )
        
        // Test timeout
        let timeout = ProblemDetails(title: "Timeout", status: 408)
        XCTAssertEqual(
            ErrorPresenter.retrySuggestion(for: timeout),
            "Try again now"
        )
        
        // Test non-retryable error
        let badRequest = ProblemDetails.invalidRequest()
        XCTAssertNil(ErrorPresenter.retrySuggestion(for: badRequest))
    }
    
    func testIsRetryable() {
        // Test retryable errors
        XCTAssertTrue(ErrorPresenter.isRetryable(ProblemDetails.rateLimited()))
        XCTAssertTrue(ErrorPresenter.isRetryable(ProblemDetails.internalServerError()))
        XCTAssertTrue(ErrorPresenter.isRetryable(ProblemDetails.unauthorized()))
        XCTAssertTrue(ErrorPresenter.isRetryable(ProblemDetails(title: "Timeout", status: 408)))
        
        // Test non-retryable errors
        XCTAssertFalse(ErrorPresenter.isRetryable(ProblemDetails.invalidRequest()))
        XCTAssertFalse(ErrorPresenter.isRetryable(ProblemDetails.forbidden()))
        XCTAssertFalse(ErrorPresenter.isRetryable(ProblemDetails.notFound()))
        
        // Test network errors
        XCTAssertTrue(ErrorPresenter.isRetryable(URLError(.timedOut)))
        XCTAssertTrue(ErrorPresenter.isRetryable(URLError(.notConnectedToInternet)))
        XCTAssertFalse(ErrorPresenter.isRetryable(URLError(.cancelled)))
    }
    
    func testRetryDelay() {
        // Test 429 with exponential backoff
        let rateLimited = ProblemDetails.rateLimited()
        XCTAssertEqual(ErrorPresenter.retryDelay(for: rateLimited, attempt: 1), 2.0)
        XCTAssertEqual(ErrorPresenter.retryDelay(for: rateLimited, attempt: 2), 4.0)
        XCTAssertEqual(ErrorPresenter.retryDelay(for: rateLimited, attempt: 3), 8.0)
        
        // Should cap at 30 seconds
        XCTAssertEqual(ErrorPresenter.retryDelay(for: rateLimited, attempt: 10), 30.0)
        
        // Test server errors with shorter backoff
        let serverError = ProblemDetails.internalServerError()
        XCTAssertEqual(ErrorPresenter.retryDelay(for: serverError, attempt: 1), 1.0)
        XCTAssertEqual(ErrorPresenter.retryDelay(for: serverError, attempt: 2), 1.5)
        
        // Test URL errors
        let timeout = URLError(.timedOut)
        XCTAssertEqual(ErrorPresenter.retryDelay(for: timeout), 2.0)
        
        let networkLost = URLError(.networkConnectionLost)
        XCTAssertEqual(ErrorPresenter.retryDelay(for: networkLost), 5.0)
    }
}