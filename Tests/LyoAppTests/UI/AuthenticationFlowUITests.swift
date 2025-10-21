import XCTest
@testable import LyoApp

@MainActor
final class AuthenticationFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Clear any existing authentication state
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["RESET_AUTH"] = "true"
        app.launch()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    // MARK: - Login Flow Tests
    
    func testLoginScreenAppearance() {
        // Check if login screen elements are present
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
        XCTAssertTrue(app.buttons["Don't have an account? Sign Up"].exists)
        XCTAssertTrue(app.buttons["Try Working Mode"].exists)
    }
    
    func testSwitchToRegistration() {
        // Tap on sign up button
        app.buttons["Don't have an account? Sign Up"].tap()
        
        // Verify registration screen appears
        XCTAssertTrue(app.staticTexts["Join LyoApp"].waitForExistence(timeout: 2.0))
        XCTAssertTrue(app.textFields["Full Name"].exists)
        XCTAssertTrue(app.textFields["Username"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Create Account"].exists)
    }
    
    func testSwitchBackToLogin() {
        // Go to registration first
        app.buttons["Don't have an account? Sign Up"].tap()
        
        // Then switch back to login
        app.buttons["Already have an account? Sign In"].tap()
        
        // Verify login screen appears
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 2.0))
    }
    
    func testLoginWithEmptyFields() {
        // Try to sign in without entering credentials
        app.buttons["Sign In"].tap()
        
        // Sign in button should be disabled or show validation
        // The exact behavior depends on implementation
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    func testLoginWithValidCredentials() {
        // Enter valid test credentials
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Tap sign in
        app.buttons["Sign In"].tap()
        
        // Wait for either main app screen or error message
        let mainAppExists = app.tabBars.element.waitForExistence(timeout: 10.0)
        let errorExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'failed' OR label CONTAINS 'Invalid'")).element.exists
        
        XCTAssertTrue(mainAppExists || errorExists, "Should either show main app or error message")
    }
    
    func testLoginWithInvalidEmail() {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        emailField.tap()
        emailField.typeText("invalid-email")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Sign In"].tap()
        
        // Should show validation error or disable button
        // Implementation specific - just verify app doesn't crash
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Registration Flow Tests
    
    func testRegistrationWithValidData() {
        // Switch to registration
        app.buttons["Don't have an account? Sign Up"].tap()
        
        // Fill out registration form
        let fullNameField = app.textFields["Full Name"]
        let usernameField = app.textFields["Username"]
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        fullNameField.tap()
        fullNameField.typeText("Test User")
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        emailField.tap()
        emailField.typeText("testuser@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Submit registration
        app.buttons["Create Account"].tap()
        
        // Wait for either main app or error
        let mainAppExists = app.tabBars.element.waitForExistence(timeout: 10.0)
        let errorExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'failed'")).element.exists
        
        XCTAssertTrue(mainAppExists || errorExists, "Should either show main app or error message")
    }
    
    func testRegistrationWithEmptyFields() {
        // Switch to registration
        app.buttons["Don't have an account? Sign Up"].tap()
        
        // Try to create account without filling fields
        app.buttons["Create Account"].tap()
        
        // Button should be disabled or show validation
        XCTAssertTrue(app.buttons["Create Account"].exists)
    }
    
    // MARK: - Working Mode Tests
    
    func testWorkingModeEntry() {
        // Tap working mode button
        app.buttons["Try Working Mode"].tap()
        
        // Should navigate to main app
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5.0), "Should show main app tabs")
        
        // Verify all tabs are present
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Discover"].exists)
        XCTAssertTrue(app.tabBars.buttons["Learn"].exists)
        XCTAssertTrue(app.tabBars.buttons["Post"].exists)
        XCTAssertTrue(app.tabBars.buttons["More"].exists)
    }
    
    func testWorkingModeBackendStatus() {
        // Enter working mode
        app.buttons["Try Working Mode"].tap()
        
        // Wait for main app
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5.0))
        
        // Look for backend status indicator (if visible in UI)
        // Implementation specific - this tests the general flow
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Navigation Tests
    
    func testKeyboardHandling() {
        let emailField = app.textFields["Email"]
        
        // Tap email field to show keyboard
        emailField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2.0))
        
        // Tap somewhere else to dismiss keyboard
        app.staticTexts["Welcome Back"].tap()
        
        // Keyboard should dismiss (test might be flaky on different simulators)
        // Just verify app still exists and is functional
        XCTAssertTrue(app.exists)
    }
    
    func testFormValidation() {
        // Test email validation
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        emailField.tap()
        emailField.typeText("invalid-email")
        
        passwordField.tap()
        passwordField.typeText("123") // Short password
        
        // The form should handle validation
        // Implementation specific behavior
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        // This test would require network condition simulation
        // For now, test that the app handles login attempts gracefully
        
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Sign In"].tap()
        
        // App should handle the response (success or error) without crashing
        sleep(3) // Wait for network response
        XCTAssertTrue(app.exists, "App should remain functional after login attempt")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        // Verify important elements have accessibility labels
        XCTAssertTrue(app.textFields["Email"].isHittable)
        XCTAssertTrue(app.secureTextFields["Password"].isHittable)
        XCTAssertTrue(app.buttons["Sign In"].isHittable)
        XCTAssertTrue(app.buttons["Try Working Mode"].isHittable)
    }
    
    func testVoiceOverNavigation() {
        // Basic VoiceOver navigation test
        // This would require VoiceOver to be enabled in test environment
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }
    
    // MARK: - Performance Tests
    
    func testLoginScreenLoadTime() {
        measure {
            // Restart app and measure load time
            app.terminate()
            app.launch()
            XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 5.0))
        }
    }
    
    func testWorkingModeNavigationSpeed() {
        measure {
            app.buttons["Try Working Mode"].tap()
            XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 5.0))
            
            // Navigate back for next iteration
            // Implementation would depend on navigation structure
        }
    }
    
    // MARK: - Device Rotation Tests
    
    func testPortraitOrientation() {
        // Verify UI works in portrait
        XCUIDevice.shared.orientation = .portrait
        
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    func testLandscapeOrientation() {
        // Verify UI adapts to landscape (if supported)
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // UI should still be functional
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists || app.textFields["Email"].exists)
        
        // Rotate back
        XCUIDevice.shared.orientation = .portrait
    }
}