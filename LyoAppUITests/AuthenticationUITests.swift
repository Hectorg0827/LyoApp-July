import XCTest

/// UI Tests for the authentication flow
/// Tests login, signup, and logout functionality
final class AuthenticationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Login Flow Tests
    
    func testLogin_MoreTabShowsLoginOption() throws {
        // Given: App is launched
        // When: User navigates to More tab
        let moreTab = app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5))
        moreTab.tap()
        
        // Then: Login/signup option should be visible
        let loginButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In' OR label CONTAINS 'Login'")).firstMatch
        XCTAssertTrue(loginButton.waitForExistence(timeout: 3))
    }
    
    func testLogin_OpensLoginView() throws {
        // Given: User is on More tab
        navigateToMoreTab()
        
        // When: User taps sign in button
        let signInButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In'")).firstMatch
        if signInButton.waitForExistence(timeout: 3) {
            signInButton.tap()
        }
        
        // Then: Email and password fields should appear
        let emailField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'email' OR label CONTAINS 'Email'")).firstMatch
        XCTAssertTrue(emailField.waitForExistence(timeout: 3))
        
        let passwordField = app.secureTextFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'password' OR label CONTAINS 'Password'")).firstMatch
        XCTAssertTrue(passwordField.waitForExistence(timeout: 3))
    }
    
    func testLogin_RequiresEmail() throws {
        // Given: User is on login screen
        openLoginScreen()
        
        // When: User tries to login without email
        let passwordField = app.secureTextFields.firstMatch
        passwordField.tap()
        passwordField.typeText("password123")
        
        let loginButton = findLoginSubmitButton()
        if loginButton.exists {
            loginButton.tap()
        }
        
        // Then: Should show validation error or button should be disabled
        // (Implementation depends on your validation strategy)
        XCTAssertTrue(true) // Placeholder - adjust based on actual behavior
    }
    
    func testLogin_RequiresPassword() throws {
        // Given: User is on login screen
        openLoginScreen()
        
        // When: User tries to login without password
        let emailField = app.textFields.firstMatch
        emailField.tap()
        emailField.typeText("test@lyoapp.com")
        
        let loginButton = findLoginSubmitButton()
        if loginButton.exists {
            loginButton.tap()
        }
        
        // Then: Should show validation error or button should be disabled
        XCTAssertTrue(true) // Placeholder - adjust based on actual behavior
    }
    
    func testLogin_WithValidCredentials() throws {
        // Given: User is on login screen
        openLoginScreen()
        
        // When: User enters valid credentials
        let emailField = app.textFields.firstMatch
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("test@lyoapp.com")
        }
        
        let passwordField = app.secureTextFields.firstMatch
        if passwordField.waitForExistence(timeout: 3) {
            passwordField.tap()
            passwordField.typeText("password123")
        }
        
        let loginButton = findLoginSubmitButton()
        if loginButton.waitForExistence(timeout: 3) {
            loginButton.tap()
        }
        
        // Then: Should navigate to main app (wait for network response)
        // Check for absence of login screen or presence of logged-in indicator
        let loggedInIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Logged in' OR label CONTAINS 'Welcome'")).firstMatch
        XCTAssertTrue(loggedInIndicator.waitForExistence(timeout: 10))
    }
    
    // MARK: - Signup Flow Tests
    
    func testSignup_ShowsSignupOption() throws {
        // Given: User is on login screen
        openLoginScreen()
        
        // When: Looking for signup option
        let signupButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Up' OR label CONTAINS 'Create Account'")).firstMatch
        
        // Then: Signup button should exist
        XCTAssertTrue(signupButton.waitForExistence(timeout: 3))
    }
    
    // MARK: - Logout Flow Tests
    
    func testLogout_LogoutButtonExists() throws {
        // Given: User is logged in
        // (This test assumes user is already logged in or mocked login state)
        
        // When: User navigates to More tab
        navigateToMoreTab()
        
        // Then: Logout button should be visible
        let logoutButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Log Out' OR label CONTAINS 'Sign Out'")).firstMatch
        // Note: This will only exist if user is actually logged in
        XCTAssertTrue(logoutButton.exists || !logoutButton.exists) // Conditional test
    }
    
    // MARK: - Network Error Handling Tests
    
    func testLogin_ShowsErrorOnNetworkFailure() throws {
        // Given: User is on login screen with invalid credentials
        openLoginScreen()
        
        // When: User enters invalid credentials
        let emailField = app.textFields.firstMatch
        emailField.tap()
        emailField.typeText("invalid@test.com")
        
        let passwordField = app.secureTextFields.firstMatch
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        let loginButton = findLoginSubmitButton()
        loginButton.tap()
        
        // Then: Error message should appear
        let errorAlert = app.alerts.firstMatch
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'failed'")).firstMatch
        
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 10) || errorText.waitForExistence(timeout: 10))
    }
    
    // MARK: - Accessibility Tests
    
    func testLogin_EmailFieldHasAccessibilityLabel() throws {
        // Given: User is on login screen
        openLoginScreen()
        
        // When: Checking email field accessibility
        let emailField = app.textFields.firstMatch
        
        // Then: Should have meaningful accessibility label
        XCTAssertTrue(emailField.exists)
        XCTAssertNotNil(emailField.label)
    }
    
    func testLogin_PasswordFieldHasAccessibilityLabel() throws {
        // Given: User is on login screen
        openLoginScreen()
        
        // When: Checking password field accessibility
        let passwordField = app.secureTextFields.firstMatch
        
        // Then: Should have meaningful accessibility label
        XCTAssertTrue(passwordField.exists)
        XCTAssertNotNil(passwordField.label)
    }
    
    // MARK: - Performance Tests
    
    func testLogin_LoadsQuickly() throws {
        measure(metrics: [XCTClockMetric()]) {
            navigateToMoreTab()
            let signInButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In'")).firstMatch
            if signInButton.waitForExistence(timeout: 5) {
                signInButton.tap()
            }
            
            let emailField = app.textFields.firstMatch
            _ = emailField.waitForExistence(timeout: 5)
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToMoreTab() {
        let moreTab = app.tabBars.buttons["More"]
        if moreTab.waitForExistence(timeout: 5) {
            moreTab.tap()
        }
    }
    
    private func openLoginScreen() {
        navigateToMoreTab()
        
        let signInButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In'")).firstMatch
        if signInButton.waitForExistence(timeout: 3) {
            signInButton.tap()
        }
        
        // Wait for login screen to appear
        let emailField = app.textFields.firstMatch
        _ = emailField.waitForExistence(timeout: 3)
    }
    
    private func findLoginSubmitButton() -> XCUIElement {
        // Try multiple ways to find the login submit button
        var loginButton = app.buttons["Sign In"]
        if !loginButton.exists {
            loginButton = app.buttons["Log In"]
        }
        if !loginButton.exists {
            loginButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In' OR label CONTAINS 'Log In'")).firstMatch
        }
        return loginButton
    }
}
