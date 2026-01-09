import Foundation
import CoreData

// MARK: - Smart Search Engine
enum SearchMode {
    case keyword
    case semantic
    case hybrid
}

enum MatchType {
    case keyword
    case semantic
    case hybrid
}

struct SearchResult: Identifiable {
    let id: UUID
    let item: ClipboardItemEntity
    let score: Double
    let matchType: MatchType
    let matchedText: String?

    init(item: ClipboardItemEntity, score: Double, matchType: MatchType, matchedText: String? = nil) {
        self.id = item.id
        self.item = item
        self.score = score
        self.matchType = matchType
        self.matchedText = matchedText
    }
}

class SmartSearchEngine {
    static let shared = SmartSearchEngine()
    private let semanticEngine = SemanticEngine.shared

    func search(query: String,
               in items: [ClipboardItemEntity],
               mode: SearchMode = .hybrid) -> [SearchResult] {

        guard !query.isEmpty else { return [] }

        switch mode {
        case .keyword:
            return keywordSearch(query, items)
        case .semantic:
            return semanticSearch(query, items)
        case .hybrid:
            return hybridSearch(query, items)
        }
    }

    // MARK: - Keyword Search
    private func keywordSearch(_ query: String, _ items: [ClipboardItemEntity]) -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        var results: [SearchResult] = []

        for item in items {
            let content = item.displayContent.lowercased()
            let ocrText = (item.ocrText ?? "").lowercased()

            var score = 0.0
            var matchedText: String?

            // Exact match
            if content == lowercaseQuery || ocrText == lowercaseQuery {
                score = 1.0
                matchedText = String(item.displayContent.prefix(100))
            }
            // Content contains query
            else if content.contains(lowercaseQuery) {
                score = 0.7
                // Find matching snippet
                if let range = content.range(of: lowercaseQuery) {
                    let start = max(content.startIndex, content.index(range.lowerBound, offsetBy: -20, limitedBy: content.startIndex) ?? range.lowerBound)
                    let end = min(content.endIndex, content.index(range.upperBound, offsetBy: 20, limitedBy: content.endIndex) ?? range.upperBound)
                    matchedText = "..." + String(content[start..<end]) + "..."
                }
            }
            // OCR text contains query
            else if ocrText.contains(lowercaseQuery) {
                score = 0.6
                matchedText = "OCR: " + String(ocrText.prefix(100))
            }
            // Starts with query
            else if content.hasPrefix(lowercaseQuery) || ocrText.hasPrefix(lowercaseQuery) {
                score = 0.8
                matchedText = String(item.displayContent.prefix(100))
            }

            if score > 0 {
                results.append(SearchResult(
                    item: item,
                    score: score,
                    matchType: .keyword,
                    matchedText: matchedText
                ))
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    // MARK: - Semantic Search
    private func semanticSearch(_ query: String, _ items: [ClipboardItemEntity]) -> [SearchResult] {
        // Generate embedding for query
        guard let queryEmbedding = semanticEngine.generateEmbedding(for: query) else {
            print("⚠️ Failed to generate embedding for query")
            return []
        }

        var results: [SearchResult] = []

        for item in items {
            // Get or generate embedding for item
            guard let itemEmbedding = getItemEmbedding(item) else { continue }

            // Calculate similarity
            let similarity = semanticEngine.cosineSimilarity(queryEmbedding, itemEmbedding)

            if similarity > 0.3 { // Lower threshold for semantic search
                results.append(SearchResult(
                    item: item,
                    score: similarity,
                    matchType: .semantic,
                    matchedText: String(item.displayContent.prefix(100))
                ))
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    // MARK: - Hybrid Search
    private func hybridSearch(_ query: String, _ items: [ClipboardItemEntity]) -> [SearchResult] {
        let keywordResults = keywordSearch(query, items)
        let semanticResults = semanticSearch(query, items)

        return mergeAndRank(keyword: keywordResults, semantic: semanticResults, items: items)
    }

    private func mergeAndRank(keyword: [SearchResult], semantic: [SearchResult], items: [ClipboardItemEntity]) -> [SearchResult] {
        var combinedResults: [UUID: SearchResult] = [:]

        // Add keyword results with weighted score
        for result in keyword {
            let weightedScore = result.score * 0.4 // 40% weight
            combinedResults[result.id] = SearchResult(
                item: result.item,
                score: weightedScore,
                matchType: .hybrid,
                matchedText: result.matchedText
            )
        }

        // Add or merge semantic results
        for result in semantic {
            let weightedScore = result.score * 0.3 // 30% weight

            if var existing = combinedResults[result.id] {
                // Merge scores
                existing = SearchResult(
                    item: existing.item,
                    score: existing.score + weightedScore,
                    matchType: .hybrid,
                    matchedText: existing.matchedText ?? result.matchedText
                )
                combinedResults[result.id] = existing
            } else {
                combinedResults[result.id] = SearchResult(
                    item: result.item,
                    score: weightedScore,
                    matchType: .hybrid,
                    matchedText: result.matchedText
                )
            }
        }

        // Add recency and frequency scores
        var finalResults: [SearchResult] = []

        for (_, result) in combinedResults {
            var finalScore = result.score

            // Recency score (20%)
            let timestamp = result.item.timestamp
            let daysSince = Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
            let recencyScore = max(0, 0.2 * (1.0 / (1.0 + Double(daysSince))))
            finalScore += recencyScore

            // Frequency score (10%)
            let frequencyScore = min(0.1, Double(result.item.accessCount) / 100.0)
            finalScore += frequencyScore

            finalResults.append(SearchResult(
                item: result.item,
                score: min(1.0, finalScore),
                matchType: result.matchType,
                matchedText: result.matchedText
            ))
        }

        return finalResults.sorted { $0.score > $1.score }
    }

    // Helper to get embedding for an item
    private func getItemEmbedding(_ item: ClipboardItemEntity) -> [Double]? {
        // Check if embedding exists in Core Data
        if let embeddingData = item.embedding,
           let embedding = semanticEngine.dataToEmbedding(embeddingData) {
            return embedding
        }

        // Generate on-the-fly
        let text = item.displayContent
        guard !text.isEmpty else { return nil }
        return semanticEngine.generateEmbedding(for: text)
    }
}
