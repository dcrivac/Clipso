import Foundation
import NaturalLanguage

// MARK: - AI Assistant
class AIClipboardAssistant {
    static let shared = AIClipboardAssistant()

    func summarize(_ text: String, maxSentences: Int = 3) -> String {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            sentences.append(String(text[range]))
            return true
        }

        guard sentences.count > maxSentences else { return text }

        let first = sentences.first!
        let middle = sentences[sentences.count / 2]
        let last = sentences.last!

        return [first, middle, last].joined(separator: " ")
    }

    func extractActionItems(_ text: String) -> [String] {
        let keywords = ["need to", "should", "must", "TODO", "FIXME"]
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var items: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if keywords.contains(where: { sentence.lowercased().contains($0.lowercased()) }) {
                items.append(sentence)
            }
            return true
        }

        return items
    }

    func fixGrammar(_ text: String) -> String {
        var fixed = text
        let sentences = text.components(separatedBy: ". ")
        fixed = sentences.map { sentence in
            guard !sentence.isEmpty else { return sentence }
            return sentence.prefix(1).uppercased() + sentence.dropFirst()
        }.joined(separator: ". ")

        fixed = fixed.replacingOccurrences(of: " i ", with: " I ")
        fixed = fixed.replacingOccurrences(of: "  ", with: " ")

        return fixed
    }
}
