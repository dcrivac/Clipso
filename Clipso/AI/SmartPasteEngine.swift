import Foundation

// MARK: - Smart Paste Engine
class SmartPasteEngine {
    static let shared = SmartPasteEngine()

    func transform(content: String, targetApp: String, category: ClipboardCategory) -> String {
        switch targetApp.lowercased() {
        case let app where app.contains("slack") || app.contains("discord"):
            return transformForChat(content, category: category)
        case let app where app.contains("xcode") || app.contains("code"):
            return transformForIDE(content, category: category)
        case let app where app.contains("terminal") || app.contains("iterm"):
            return transformForTerminal(content)
        case let app where app.contains("notion") || app.contains("obsidian"):
            return transformForMarkdown(content, category: category)
        default:
            return content
        }
    }

    private func transformForChat(_ content: String, category: ClipboardCategory) -> String {
        if category == .code {
            let language = detectLanguage(content)
            return "```\(language)\n\(content)\n```"
        }
        return content
    }

    private func transformForIDE(_ content: String, category: ClipboardCategory) -> String {
        if category == .code {
            return formatCode(content)
        }
        return content
    }

    private func transformForTerminal(_ content: String) -> String {
        let specialChars = CharacterSet(charactersIn: "$`\"\\!")
        if content.rangeOfCharacter(from: specialChars) != nil {
            return "'\(content)'"
        }
        return content
    }

    private func transformForMarkdown(_ content: String, category: ClipboardCategory) -> String {
        if category == .code {
            let language = detectLanguage(content)
            return "```\(language)\n\(content)\n```"
        } else if category == .link {
            return "[\(content)](\(content))"
        }
        return content
    }

    private func formatCode(_ code: String) -> String {
        let lines = code.components(separatedBy: .newlines)
        var indentLevel = 0
        var formatted: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.contains("}") || trimmed.contains("]") {
                indentLevel = max(0, indentLevel - 1)
            }

            let indent = String(repeating: "    ", count: indentLevel)
            formatted.append(indent + trimmed)

            if trimmed.contains("{") || trimmed.contains("[") {
                indentLevel += 1
            }
        }

        return formatted.joined(separator: "\n")
    }

    private func detectLanguage(_ code: String) -> String {
        if code.contains("func ") || code.contains("var ") || code.contains("let ") {
            return "swift"
        } else if code.contains("function ") || code.contains("const ") || code.contains("=>") {
            return "javascript"
        } else if code.contains("def ") {
            return "python"
        }
        return ""
    }
}
