import XCTest

/// UI Tests for the AI Course Creation flow
/// Tests the complete user journey from opening AI chat to course generation
final class AICourseCreationUITests: XCTestCase {
    
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
    
    // MARK: - AI Conversation Flow Tests
    
    func testAIConversationButton_ExistsInLearningHub() throws {
        // Given: App is launched and user navigates to Learning Hub
        let learningTab = app.tabBars.buttons["Learn"]
        XCTAssertTrue(learningTab.waitForExistence(timeout: 5))
        learningTab.tap()
        
        // When: Looking for AI conversation button
        let aiButton = app.buttons.matching(identifier: "ai_conversation_button").firstMatch
        
        // Then: Button should exist and be tappable
        XCTAssertTrue(aiButton.waitForExistence(timeout: 3))
        XCTAssertTrue(aiButton.isHittable)
    }
    
    func testAIConversation_OpensWhenButtonTapped() throws {
        // Given: User is on Learning Hub
        let learningTab = app.tabBars.buttons["Learn"]
        learningTab.tap()
        
        // When: User taps AI conversation button
        let aiButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'sparkles' OR label CONTAINS 'AI'")).firstMatch
        XCTAssertTrue(aiButton.waitForExistence(timeout: 5))
        aiButton.tap()
        
        // Then: AI conversation view should appear
        let conversationTitle = app.navigationBars["Lyo AI"]
        XCTAssertTrue(conversationTitle.waitForExistence(timeout: 3))
    }
    
    func testAIConversation_ShowsWelcomeMessage() throws {
        // Given: User opens AI conversation
        openAIConversation()
        
        // When: Conversation view loads
        // Then: Welcome message should be visible
        let welcomeMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'learning companion'")).firstMatch
        XCTAssertTrue(welcomeMessage.waitForExistence(timeout: 3))
    }
    
    func testAIConversation_CanTypeMessage() throws {
        // Given: User is in AI conversation
        openAIConversation()
        
        // When: User taps input field and types
        let inputField = app.textFields.firstMatch
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
        inputField.tap()
        inputField.typeText("What is Swift programming?")
        
        // Then: Text should appear in the field
        XCTAssertTrue(inputField.value as? String == "What is Swift programming?" || 
                     (inputField.value as? String)?.contains("Swift programming") == true)
    }
    
    func testAIConversation_SendButtonDisabledWhenEmpty() throws {
        // Given: User is in AI conversation with empty input
        openAIConversation()
        
        // When: Looking at send button
        let sendButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow' OR identifier CONTAINS 'send'")).firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        
        // Then: Send button should be disabled
        XCTAssertFalse(sendButton.isEnabled)
    }
    
    func testAIConversation_SendButtonEnabledWithText() throws {
        // Given: User types a message
        openAIConversation()
        let inputField = app.textFields.firstMatch
        inputField.tap()
        inputField.typeText("Hello")
        
        // When: Checking send button state
        let sendButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow' OR identifier CONTAINS 'send'")).firstMatch
        
        // Then: Send button should be enabled
        XCTAssertTrue(sendButton.waitForExistence(timeout: 2))
        XCTAssertTrue(sendButton.isEnabled)
    }
    
    func testAIConversation_DismissesWithDoneButton() throws {
        // Given: User is in AI conversation
        openAIConversation()
        
        // When: User taps Done button
        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()
        
        // Then: Should return to Learning Hub
        let learningHubTitle = app.staticTexts["Learning Hub"]
        XCTAssertTrue(learningHubTitle.waitForExistence(timeout: 3))
    }
    
    // MARK: - Performance Tests
    
    func testAIConversation_LoadsQuickly() throws {
        // Measure how quickly the AI conversation view appears
        measure(metrics: [XCTApplicationLaunchMetric(), XCTClockMetric()]) {
            app.launch()
            let learningTab = app.tabBars.buttons["Learn"]
            learningTab.tap()
            
            let aiButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'sparkles'")).firstMatch
            if aiButton.waitForExistence(timeout: 5) {
                aiButton.tap()
            }
            
            let conversationTitle = app.navigationBars["Lyo AI"]
            _ = conversationTitle.waitForExistence(timeout: 5)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openAIConversation() {
        let learningTab = app.tabBars.buttons["Learn"]
        if learningTab.exists {
            learningTab.tap()
        }
        
        // Try multiple ways to find the AI button
        var aiButton = app.buttons.matching(identifier: "ai_conversation_button").firstMatch
        if !aiButton.exists {
            aiButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'sparkles'")).firstMatch
        }
        if !aiButton.exists {
            aiButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'AI Chat'")).firstMatch
        }
        
        if aiButton.waitForExistence(timeout: 5) {
            aiButton.tap()
        }
    }
}
