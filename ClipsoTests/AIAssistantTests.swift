import XCTest
@testable import Clipso

final class AIClipboardAssistantTests: XCTestCase {

    var assistant: AIClipboardAssistant!

    override func setUp() {
        super.setUp()
        assistant = AIClipboardAssistant.shared
    }

    // MARK: - Summarize Tests

    func testSummarizeShortText() {
        let shortText = "This is a short sentence."

        let summary = assistant.summarize(shortText, maxSentences: 3)

        XCTAssertFalse(summary.isEmpty, "Summary should not be empty")
        XCTAssertEqual(summary, shortText, "Short text should return as-is")
    }

    func testSummarizeLongText() {
        let longText = """
        The clipboard manager is an essential tool for productivity. It allows users to store multiple clipboard items. \
        Each item can be searched and retrieved later. The AI features include semantic search and context detection. \
        Users can also encrypt sensitive clipboard data. OCR functionality extracts text from images. \
        Smart paste transforms content based on the target application. Project tagging helps organize clipboard history.
        """

        let summary = assistant.summarize(longText, maxSentences: 3)

        XCTAssertFalse(summary.isEmpty, "Summary should not be empty")
        // Summary should be shorter than or equal to original
        XCTAssertLessThanOrEqual(summary.count, longText.count, "Summary should not be longer than original")
    }

    func testSummarizeEmptyText() {
        let emptyText = ""

        let summary = assistant.summarize(emptyText)

        XCTAssertEqual(summary, "", "Empty text should return empty summary")
    }

    func testSummarizeWithDifferentMaxSentences() {
        let text = """
        First sentence. Second sentence. Third sentence. Fourth sentence. Fifth sentence.
        """

        let summary1 = assistant.summarize(text, maxSentences: 1)
        let summary2 = assistant.summarize(text, maxSentences: 2)
        let summary3 = assistant.summarize(text, maxSentences: 5)

        XCTAssertFalse(summary1.isEmpty)
        XCTAssertFalse(summary2.isEmpty)
        XCTAssertFalse(summary3.isEmpty)

        // More sentences should result in longer summary (generally)
        XCTAssertLessThanOrEqual(summary1.count, summary2.count)
    }

    // MARK: - Extract Action Items Tests

    func testExtractActionItemsFromToDo() {
        let text = """
        Meeting notes:
        - TODO: Review the pull request
        - Need to update the documentation
        - [ ] Fix the bug in clipboard monitor
        - Remember to send email to client
        """

        let actionItems = assistant.extractActionItems(text)

        XCTAssertFalse(actionItems.isEmpty, "Should extract action items")
        XCTAssertTrue(actionItems.count >= 2, "Should find at least 2 action items")

        // Check that action items contain expected keywords
        let combined = actionItems.joined(separator: " ").lowercased()
        XCTAssertTrue(combined.contains("review") || combined.contains("update") || combined.contains("fix") || combined.contains("send"))
    }

    func testExtractActionItemsNoItems() {
        let text = """
        This is a simple paragraph with no action items.
        Just some regular text discussing various topics.
        """

        let actionItems = assistant.extractActionItems(text)

        // Should return empty array when no action items found
        XCTAssertTrue(actionItems.isEmpty, "Should not find action items in regular text")
    }

    func testExtractActionItemsWithVariousFormats() {
        let text = """
        - TODO: First task
        - [ ] Second task
        - Need to complete third task
        - Remember to do fourth task
        - Fix: Fifth task
        """

        let actionItems = assistant.extractActionItems(text)

        XCTAssertFalse(actionItems.isEmpty, "Should extract action items")
        // Should find most or all of the action items
        XCTAssertGreaterThanOrEqual(actionItems.count, 3, "Should find at least 3 action items")
    }

    func testExtractActionItemsEmptyText() {
        let emptyText = ""

        let actionItems = assistant.extractActionItems(emptyText)

        XCTAssertTrue(actionItems.isEmpty, "Empty text should return no action items")
    }

    // MARK: - Fix Grammar Tests

    func testFixGrammarBasic() {
        let text = "this is a test sentence"

        let fixed = assistant.fixGrammar(text)

        XCTAssertFalse(fixed.isEmpty, "Fixed text should not be empty")
        // Should capitalize first letter
        XCTAssertTrue(fixed.first?.isUppercase ?? false, "First letter should be capitalized")
    }

    func testFixGrammarEmptyText() {
        let emptyText = ""

        let fixed = assistant.fixGrammar(emptyText)

        XCTAssertEqual(fixed, "", "Empty text should return empty string")
    }

    func testFixGrammarAlreadyCorrect() {
        let correctText = "This is a properly formatted sentence."

        let fixed = assistant.fixGrammar(correctText)

        XCTAssertFalse(fixed.isEmpty, "Fixed text should not be empty")
        // Should preserve correct formatting
        XCTAssertTrue(fixed.first?.isUppercase ?? false)
    }

    func testFixGrammarMultipleSentences() {
        let text = "first sentence. second sentence. third sentence."

        let fixed = assistant.fixGrammar(text)

        XCTAssertFalse(fixed.isEmpty, "Fixed text should not be empty")
        // First letter should be capitalized
        XCTAssertTrue(fixed.first?.isUppercase ?? false)
    }

    func testFixGrammarPreservesContent() {
        let text = "hello world this is a test"

        let fixed = assistant.fixGrammar(text)

        // Should not remove words or significantly change content
        XCTAssertTrue(fixed.lowercased().contains("hello"))
        XCTAssertTrue(fixed.lowercased().contains("world"))
        XCTAssertTrue(fixed.lowercased().contains("test"))
    }

    // MARK: - Integration Tests

    func testAllFunctionsWithSameText() {
        let text = """
        Project update: We need to review the codebase. TODO: Fix the encryption bug. \
        The semantic search is working well. Remember to update documentation.
        """

        // All functions should work without crashing
        let summary = assistant.summarize(text)
        let actionItems = assistant.extractActionItems(text)
        let fixed = assistant.fixGrammar(text)

        XCTAssertFalse(summary.isEmpty, "Summary should work")
        XCTAssertFalse(actionItems.isEmpty, "Should find action items")
        XCTAssertFalse(fixed.isEmpty, "Grammar fix should work")
    }
}
