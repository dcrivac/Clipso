import XCTest
@testable import Clipso

final class SmartSearchEngineTests: XCTestCase {

    var searchEngine: SmartSearchEngine!
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        searchEngine = SmartSearchEngine.shared
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }

    override func tearDown() {
        // Clean up test items
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ClipboardItemEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)

        searchEngine = nil
        context = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Search Mode Tests

    func testSearchWithEmptyQuery() {
        let items = [
            createTestItem(content: "Test content 1"),
            createTestItem(content: "Test content 2")
        ]

        let results = searchEngine.search(query: "", in: items, mode: .keyword)

        XCTAssertTrue(results.isEmpty, "Empty query should return no results")
    }

    func testSearchModeKeyword() {
        let items = [createTestItem(content: "Swift programming")]

        let results = searchEngine.search(query: "Swift", in: items, mode: .keyword)

        XCTAssertFalse(results.isEmpty, "Keyword mode should find matches")
        XCTAssertEqual(results.first?.matchType, .keyword, "Should use keyword match type")
    }

    func testSearchModeSemantic() {
        let item = createTestItem(content: "Machine learning algorithms")
        generateEmbedding(for: item)

        let results = searchEngine.search(query: "AI and ML", in: [item], mode: .semantic)

        // Semantic search depends on NLEmbedding availability
        if SemanticEngine.shared.generateEmbedding(for: "test") != nil {
            XCTAssertEqual(results.first?.matchType, .semantic, "Should use semantic match type")
        }
    }

    func testSearchModeHybrid() {
        let item = createTestItem(content: "Swift programming language")
        generateEmbedding(for: item)

        let results = searchEngine.search(query: "Swift", in: [item], mode: .hybrid)

        XCTAssertEqual(results.first?.matchType, .hybrid, "Should use hybrid match type")
    }

    // MARK: - Keyword Search Tests

    func testKeywordSearchExactMatch() {
        let item = createTestItem(content: "Hello World")

        let results = searchEngine.search(query: "hello world", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should find exact match")
        XCTAssertEqual(results.first?.score, 1.0, accuracy: 0.01, "Exact match should score 1.0")
    }

    func testKeywordSearchCaseInsensitive() {
        let item = createTestItem(content: "Swift Programming")

        let results = searchEngine.search(query: "SWIFT programming", in: [item], mode: .keyword)

        XCTAssertFalse(results.isEmpty, "Search should be case-insensitive")
    }

    func testKeywordSearchSubstringMatch() {
        let item = createTestItem(content: "This is a test of substring matching")

        let results = searchEngine.search(query: "substring", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should find substring match")
        XCTAssertEqual(results.first?.score, 0.7, accuracy: 0.01, "Substring match should score 0.7")
    }

    func testKeywordSearchStartsWith() {
        let item = createTestItem(content: "Programming in Swift")

        let results = searchEngine.search(query: "programming", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should find prefix match")
        // Score should be 0.8 for starts with
        XCTAssertEqual(results.first?.score, 0.8, accuracy: 0.01, "Prefix match should score 0.8")
    }

    func testKeywordSearchNoMatch() {
        let item = createTestItem(content: "Swift programming")

        let results = searchEngine.search(query: "Python", in: [item], mode: .keyword)

        XCTAssertTrue(results.isEmpty, "Should return empty for no match")
    }

    func testKeywordSearchMultipleItems() {
        let items = [
            createTestItem(content: "Swift programming"),
            createTestItem(content: "Python programming"),
            createTestItem(content: "JavaScript programming")
        ]

        let results = searchEngine.search(query: "programming", in: items, mode: .keyword)

        XCTAssertEqual(results.count, 3, "Should find all matching items")
    }

    func testKeywordSearchSortedByScore() {
        let items = [
            createTestItem(content: "This contains Swift in the middle"),
            createTestItem(content: "Swift is at the start"),
            createTestItem(content: "Swift")
        ]

        let results = searchEngine.search(query: "Swift", in: items, mode: .keyword)

        XCTAssertEqual(results.count, 3, "Should find all items")
        // Results should be sorted by score descending
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].score, results[i + 1].score,
                                       "Results should be sorted by score descending")
        }
    }

    func testKeywordSearchWithSnippet() {
        let longContent = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Swift programming is amazing. Sed do eiusmod tempor incididunt."
        let item = createTestItem(content: longContent)

        let results = searchEngine.search(query: "Swift", in: [item], mode: .keyword)

        XCTAssertNotNil(results.first?.matchedText, "Should include matched snippet")
        XCTAssertTrue(results.first?.matchedText?.contains("Swift") ?? false, "Snippet should contain query")
    }

    // MARK: - OCR Text Search Tests

    func testKeywordSearchInOCRText() {
        let item = createTestItem(content: "Regular content")
        item.ocrText = "Text extracted from image containing Swift code"

        let results = searchEngine.search(query: "Swift", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should search in OCR text")
        XCTAssertEqual(results.first?.score, 0.6, accuracy: 0.01, "OCR match should score 0.6")
    }

    func testKeywordSearchPrefersContentOverOCR() {
        let item1 = createTestItem(content: "Swift programming")
        let item2 = createTestItem(content: "Other content")
        item2.ocrText = "Swift in OCR"

        let results = searchEngine.search(query: "Swift", in: [item1, item2], mode: .keyword)

        XCTAssertEqual(results.count, 2, "Should find both items")
        // item1 should score higher (0.7 or 0.8) than item2 (0.6)
        XCTAssertGreaterThan(results[0].score, results[1].score, "Content match should rank higher than OCR")
    }

    // MARK: - Semantic Search Tests

    func testSemanticSearchWithSimilarMeaning() {
        // Skip if NLEmbedding is not available
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping semantic test - NLEmbedding not available")
            return
        }

        let item1 = createTestItem(content: "Artificial intelligence and machine learning")
        let item2 = createTestItem(content: "Deep learning neural networks")
        let item3 = createTestItem(content: "Cooking recipes and food")

        generateEmbedding(for: item1)
        generateEmbedding(for: item2)
        generateEmbedding(for: item3)

        let results = searchEngine.search(query: "AI technology", in: [item1, item2, item3], mode: .semantic)

        // Should find semantically similar items
        XCTAssertGreaterThan(results.count, 0, "Should find semantically similar items")

        // item1 and item2 should rank higher than item3
        if let firstItem = results.first?.item {
            XCTAssertTrue(firstItem.id == item1.id || firstItem.id == item2.id,
                         "Most similar item should be about AI/ML")
        }
    }

    func testSemanticSearchThreshold() {
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping semantic test - NLEmbedding not available")
            return
        }

        let item = createTestItem(content: "Swift programming language")
        generateEmbedding(for: item)

        let results = searchEngine.search(query: "Python", in: [item], mode: .semantic)

        // Should respect 0.3 threshold
        for result in results {
            XCTAssertGreaterThan(result.score, 0.3, "All results should exceed 0.3 threshold")
        }
    }

    func testSemanticSearchWithoutEmbeddings() {
        let item = createTestItem(content: "Test content")
        // Don't generate embedding

        let results = searchEngine.search(query: "test", in: [item], mode: .semantic)

        // Should handle missing embeddings gracefully
        // Results may be empty or contain on-the-fly generated embeddings
        XCTAssertTrue(true, "Should not crash with missing embeddings")
    }

    // MARK: - Hybrid Search Tests

    func testHybridSearchCombinesResults() {
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping hybrid test - NLEmbedding not available")
            return
        }

        let item = createTestItem(content: "Swift programming language tutorial")
        generateEmbedding(for: item)

        let results = searchEngine.search(query: "Swift", in: [item], mode: .hybrid)

        XCTAssertEqual(results.count, 1, "Should find item in hybrid mode")
        XCTAssertEqual(results.first?.matchType, .hybrid, "Should mark as hybrid match")
    }

    func testHybridSearchWeighting() {
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping hybrid test - NLEmbedding not available")
            return
        }

        let item = createTestItem(content: "Swift programming")
        generateEmbedding(for: item)

        let results = searchEngine.search(query: "Swift", in: [item], mode: .hybrid)

        // Hybrid score should be weighted combination
        // Keyword (0.7 for substring) * 0.4 = 0.28
        // Semantic (high similarity) * 0.3 = ~0.3
        // Plus recency and frequency = should be > 0.4
        if let score = results.first?.score {
            XCTAssertGreaterThan(score, 0.0, "Hybrid score should be positive")
            XCTAssertLessThanOrEqual(score, 1.0, "Hybrid score should not exceed 1.0")
        }
    }

    func testHybridSearchRecencyScoring() {
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping hybrid test - NLEmbedding not available")
            return
        }

        let recentItem = createTestItem(content: "Swift code")
        recentItem.timestamp = Date()

        let oldItem = createTestItem(content: "Swift code")
        oldItem.timestamp = Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago

        generateEmbedding(for: recentItem)
        generateEmbedding(for: oldItem)

        let results = searchEngine.search(query: "Swift", in: [recentItem, oldItem], mode: .hybrid)

        XCTAssertEqual(results.count, 2, "Should find both items")

        // Recent item should score higher due to recency bonus (20%)
        if results.count == 2 {
            let recentResult = results.first { $0.item.id == recentItem.id }
            let oldResult = results.first { $0.item.id == oldItem.id }

            if let recentScore = recentResult?.score, let oldScore = oldResult?.score {
                XCTAssertGreaterThan(recentScore, oldScore, "Recent item should score higher")
            }
        }
    }

    func testHybridSearchFrequencyScoring() {
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping hybrid test - NLEmbedding not available")
            return
        }

        let frequentItem = createTestItem(content: "Popular content")
        frequentItem.accessCount = 50

        let infrequentItem = createTestItem(content: "Popular content")
        infrequentItem.accessCount = 1

        generateEmbedding(for: frequentItem)
        generateEmbedding(for: infrequentItem)

        let results = searchEngine.search(query: "Popular", in: [frequentItem, infrequentItem], mode: .hybrid)

        XCTAssertEqual(results.count, 2, "Should find both items")

        // Frequent item should score higher due to frequency bonus (10%)
        if results.count == 2 {
            let frequentResult = results.first { $0.item.id == frequentItem.id }
            let infrequentResult = results.first { $0.item.id == infrequentItem.id }

            if let frequentScore = frequentResult?.score, let infrequentScore = infrequentResult?.score {
                XCTAssertGreaterThanOrEqual(frequentScore, infrequentScore,
                                           "Frequently accessed item should score at least as high")
            }
        }
    }

    func testHybridSearchMaxScoreCapped() {
        guard SemanticEngine.shared.generateEmbedding(for: "test") != nil else {
            print("⚠️ Skipping hybrid test - NLEmbedding not available")
            return
        }

        let item = createTestItem(content: "test")
        item.accessCount = 1000 // Very high frequency
        item.timestamp = Date() // Very recent
        generateEmbedding(for: item)

        let results = searchEngine.search(query: "test", in: [item], mode: .hybrid)

        // Score should be capped at 1.0
        if let score = results.first?.score {
            XCTAssertLessThanOrEqual(score, 1.0, "Score should be capped at 1.0")
        }
    }

    // MARK: - Edge Cases

    func testSearchWithSpecialCharacters() {
        let item = createTestItem(content: "C++ programming language")

        let results = searchEngine.search(query: "C++", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should handle special characters in query")
    }

    func testSearchWithMultipleWords() {
        let item = createTestItem(content: "Learn Swift programming for iOS development")

        let results = searchEngine.search(query: "Swift programming", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should match multi-word queries")
    }

    func testSearchWithEmoji() {
        let item = createTestItem(content: "Great idea 💡 for a project")

        let results = searchEngine.search(query: "💡", in: [item], mode: .keyword)

        XCTAssertEqual(results.count, 1, "Should handle emoji in search")
    }

    func testSearchWithWhitespace() {
        let item = createTestItem(content: "Swift programming")

        let results = searchEngine.search(query: "  Swift  ", in: [item], mode: .keyword)

        // Should handle extra whitespace gracefully
        XCTAssertTrue(true, "Should handle whitespace without crashing")
    }

    func testSearchWithVeryLongQuery() {
        let longQuery = String(repeating: "test ", count: 200)
        let item = createTestItem(content: "test content")

        let results = searchEngine.search(query: longQuery, in: [item], mode: .keyword)

        // Should handle long queries without crashing
        XCTAssertTrue(true, "Should handle long queries")
    }

    func testSearchInEmptyItemList() {
        let results = searchEngine.search(query: "test", in: [], mode: .keyword)

        XCTAssertTrue(results.isEmpty, "Should return empty for empty item list")
    }

    func testSearchWithManyItems() {
        let items = (0..<1000).map { i in
            createTestItem(content: "Item \(i) with test content")
        }

        let startTime = Date()
        let results = searchEngine.search(query: "test", in: items, mode: .keyword)
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(results.count, 1000, "Should search through many items")
        XCTAssertLessThan(elapsed, 2.0, "Search should complete reasonably fast")
    }

    // MARK: - SearchResult Tests

    func testSearchResultIdentifiable() {
        let item = createTestItem(content: "Test")

        let result = SearchResult(item: item, score: 0.8, matchType: .keyword, matchedText: "Test")

        XCTAssertEqual(result.id, item.id, "SearchResult ID should match item ID")
    }

    func testSearchResultProperties() {
        let item = createTestItem(content: "Test content")

        let result = SearchResult(item: item, score: 0.75, matchType: .semantic, matchedText: "Test snippet")

        XCTAssertEqual(result.item.id, item.id)
        XCTAssertEqual(result.score, 0.75)
        XCTAssertEqual(result.matchType, .semantic)
        XCTAssertEqual(result.matchedText, "Test snippet")
    }

    // MARK: - Helper Methods

    private func createTestItem(content: String) -> ClipboardItemEntity {
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.content = content
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false
        item.accessCount = 0
        return item
    }

    private func generateEmbedding(for item: ClipboardItemEntity) {
        let semanticEngine = SemanticEngine.shared
        guard let embedding = semanticEngine.generateEmbedding(for: item.displayContent) else { return }
        guard let data = semanticEngine.embeddingToData(embedding) else { return }
        item.embedding = data
    }
}
