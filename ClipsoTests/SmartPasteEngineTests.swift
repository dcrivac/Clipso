import XCTest
@testable import Clipso

final class SmartPasteEngineTests: XCTestCase {

    var engine: SmartPasteEngine!

    override func setUp() {
        super.setUp()
        engine = SmartPasteEngine.shared
    }

    // MARK: - Chat App Transformations

    func testTransformCodeForSlack() {
        let code = "function test() {\n  return true;\n}"

        let transformed = engine.transform(content: code, targetApp: "Slack", category: .code)

        // Should wrap code in markdown code blocks
        XCTAssertTrue(transformed.contains("```"), "Code should be wrapped in markdown code blocks for Slack")
        XCTAssertTrue(transformed.contains(code), "Original code should be present")
    }

    func testTransformCodeForDiscord() {
        let code = "print('Hello World')"

        let transformed = engine.transform(content: code, targetApp: "Discord", category: .code)

        // Should wrap code in markdown code blocks
        XCTAssertTrue(transformed.contains("```"), "Code should be wrapped in markdown code blocks for Discord")
        XCTAssertTrue(transformed.contains(code), "Original code should be present")
    }

    func testTransformTextForChat() {
        let text = "Regular text message"

        let transformed = engine.transform(content: text, targetApp: "Slack", category: .text)

        // Regular text should pass through unchanged
        XCTAssertEqual(transformed, text, "Regular text should not be transformed for chat apps")
    }

    // MARK: - IDE Transformations

    func testTransformLinkForXcode() {
        let link = "https://github.com/dcrivac/Clipso"

        let transformed = engine.transform(content: link, targetApp: "Xcode", category: .link)

        // Should wrap link in comment
        XCTAssertTrue(transformed.contains("//"), "Link should be wrapped in comment for Xcode")
        XCTAssertTrue(transformed.contains(link), "Original link should be present")
    }

    func testTransformLinkForVSCode() {
        let link = "https://example.com/api"

        let transformed = engine.transform(content: link, targetApp: "Code", category: .link)

        // Should wrap link in comment
        XCTAssertTrue(transformed.contains("//"), "Link should be wrapped in comment for VS Code")
        XCTAssertTrue(transformed.contains(link), "Original link should be present")
    }

    func testTransformCodeForIDE() {
        let code = "const x = 42;"

        let transformed = engine.transform(content: code, targetApp: "Xcode", category: .code)

        // Code should pass through unchanged for IDE
        XCTAssertEqual(transformed, code, "Code should not be transformed for IDE")
    }

    // MARK: - Email Transformations

    func testTransformCodeForMail() {
        let code = "function example() { }"

        let transformed = engine.transform(content: code, targetApp: "Mail", category: .code)

        // Should wrap in code block
        XCTAssertTrue(transformed.contains("```"), "Code should be wrapped in code block for Mail")
        XCTAssertTrue(transformed.contains(code), "Original code should be present")
    }

    func testTransformLinkForMail() {
        let link = "https://clipso.app"

        let transformed = engine.transform(content: link, targetApp: "Mail", category: .link)

        // Should format as markdown link
        XCTAssertTrue(transformed.contains("[") && transformed.contains("]"), "Link should be formatted as markdown for Mail")
        XCTAssertTrue(transformed.contains(link), "Original link should be present")
    }

    // MARK: - Documentation Transformations

    func testTransformCodeForNotion() {
        let code = "SELECT * FROM users;"

        let transformed = engine.transform(content: code, targetApp: "Notion", category: .code)

        // Should wrap in code block
        XCTAssertTrue(transformed.contains("```"), "Code should be wrapped in code block for Notion")
        XCTAssertTrue(transformed.contains(code), "Original code should be present")
    }

    func testTransformCodeForObsidian() {
        let code = "import Foundation"

        let transformed = engine.transform(content: code, targetApp: "Obsidian", category: .code)

        // Should wrap in code block
        XCTAssertTrue(transformed.contains("```"), "Code should be wrapped in code block for Obsidian")
        XCTAssertTrue(transformed.contains(code), "Original code should be present")
    }

    // MARK: - Terminal Transformations

    func testTransformForTerminal() {
        let text = "echo 'Hello World'"

        let transformed = engine.transform(content: text, targetApp: "Terminal", category: .text)

        // Terminal content should pass through unchanged
        XCTAssertEqual(transformed, text, "Content should not be transformed for Terminal")
    }

    func testTransformForITerm() {
        let command = "ls -la"

        let transformed = engine.transform(content: command, targetApp: "iTerm", category: .text)

        // iTerm content should pass through unchanged
        XCTAssertEqual(transformed, command, "Content should not be transformed for iTerm")
    }

    // MARK: - Default/Unknown App Behavior

    func testTransformForUnknownApp() {
        let content = "Some random content"

        let transformed = engine.transform(content: content, targetApp: "UnknownApp", category: .text)

        // Unknown apps should pass through unchanged
        XCTAssertEqual(transformed, content, "Content should not be transformed for unknown apps")
    }

    func testTransformEmptyContent() {
        let empty = ""

        let transformed = engine.transform(content: empty, targetApp: "Slack", category: .text)

        XCTAssertEqual(transformed, "", "Empty content should remain empty")
    }

    // MARK: - Language Detection Tests

    func testDetectJavaScriptLanguage() {
        let jsCode = "const x = () => { return 42; }"

        let language = engine.detectLanguage(jsCode)

        XCTAssertTrue(["javascript", "js"].contains(language.lowercased()), "Should detect JavaScript")
    }

    func testDetectPythonLanguage() {
        let pythonCode = "def hello():\n    print('Hello')"

        let language = engine.detectLanguage(pythonCode)

        XCTAssertTrue(["python", "py"].contains(language.lowercased()), "Should detect Python")
    }

    func testDetectSwiftLanguage() {
        let swiftCode = "func greet() -> String { return \"Hello\" }"

        let language = engine.detectLanguage(swiftCode)

        XCTAssertEqual(language.lowercased(), "swift", "Should detect Swift")
    }

    func testDetectSQLLanguage() {
        let sqlCode = "SELECT * FROM users WHERE id = 1"

        let language = engine.detectLanguage(sqlCode)

        XCTAssertEqual(language.lowercased(), "sql", "Should detect SQL")
    }

    func testDetectBashLanguage() {
        let bashCode = "#!/bin/bash\necho 'test'"

        let language = engine.detectLanguage(bashCode)

        XCTAssertTrue(["bash", "sh"].contains(language.lowercased()), "Should detect Bash")
    }

    // MARK: - Category-Based Transformations

    func testTransformEmailCategory() {
        let email = "test@example.com"

        let transformed = engine.transform(content: email, targetApp: "Mail", category: .email)

        XCTAssertTrue(transformed.contains(email), "Email should be preserved")
    }

    func testTransformPhoneCategory() {
        let phone = "+1-555-123-4567"

        let transformed = engine.transform(content: phone, targetApp: "Messages", category: .phone)

        XCTAssertTrue(transformed.contains(phone), "Phone number should be preserved")
    }

    func testTransformColorCategory() {
        let color = "#FF5733"

        let transformed = engine.transform(content: color, targetApp: "Xcode", category: .color)

        XCTAssertTrue(transformed.contains(color), "Color should be preserved")
    }

    // MARK: - Edge Cases

    func testTransformVeryLongCode() {
        let longCode = String(repeating: "function test() { }\n", count: 100)

        let transformed = engine.transform(content: longCode, targetApp: "Slack", category: .code)

        // Should still wrap in code blocks
        XCTAssertTrue(transformed.contains("```"), "Long code should still be wrapped")
        XCTAssertTrue(transformed.contains("function test"), "Content should be preserved")
    }

    func testTransformMultilineCode() {
        let multilineCode = """
        function calculate(a, b) {
            const sum = a + b;
            const product = a * b;
            return { sum, product };
        }
        """

        let transformed = engine.transform(content: multilineCode, targetApp: "Discord", category: .code)

        // Should preserve multiline structure
        XCTAssertTrue(transformed.contains("```"), "Multiline code should be wrapped")
        XCTAssertTrue(transformed.contains("function calculate"), "Content should be preserved")
        XCTAssertTrue(transformed.contains("return"), "All lines should be preserved")
    }
}
