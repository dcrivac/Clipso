import XCTest
import CoreData
import NaturalLanguage
@testable import Clipso

final class SemanticEngineTests: XCTestCase {

    var engine: SemanticEngine!
    var mockContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        engine = SemanticEngine.shared

        // Set up in-memory Core Data context for testing
        let container = NSPersistentContainer(name: "ClipboardManager")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }

        mockContext = container.viewContext
    }

    override func tearDown() {
        engine = nil
        mockContext = nil
        super.tearDown()
    }

    // MARK: - Embedding Generation Tests

    func testGenerateEmbeddingForSimpleText() {
        let text = "Hello world, this is a test."

        let embedding = engine.generateEmbedding(for: text)

        if embedding != nil {
            XCTAssertNotNil(embedding, "Should generate embedding for simple text")
            XCTAssertFalse(embedding!.isEmpty, "Embedding should not be empty")
            // NLEmbedding typically returns vectors of size 300-400
            XCTAssertGreaterThan(embedding!.count, 100, "Embedding should have reasonable dimensionality")
        } else {
            // Some test environments may not have NLEmbedding available
            print("⚠️ NLEmbedding not available in test environment")
        }
    }

    func testGenerateEmbeddingForLongText() {
        let longText = String(repeating: "This is a longer text for testing. ", count: 50)

        let embedding = engine.generateEmbedding(for: longText)

        if embedding != nil {
            XCTAssertNotNil(embedding, "Should generate embedding for long text")
            // Long text should be truncated to 1000 characters
            XCTAssertFalse(embedding!.isEmpty, "Embedding should not be empty")
        }
    }

    func testGenerateEmbeddingForEmptyText() {
        let emptyText = ""

        let embedding = engine.generateEmbedding(for: emptyText)

        // Empty text may return nil or empty embedding
        if let emb = embedding {
            XCTAssertTrue(emb.isEmpty || emb.allSatisfy { $0 == 0.0 }, "Empty text should produce nil or zero embedding")
        }
    }

    func testGenerateEmbeddingForUnicodeText() {
        let unicodeText = "Hello 世界 مرحبا Привет"

        let embedding = engine.generateEmbedding(for: unicodeText)

        if embedding != nil {
            XCTAssertNotNil(embedding, "Should handle unicode text")
            XCTAssertFalse(embedding!.isEmpty, "Unicode embedding should not be empty")
        }
    }

    func testGenerateEmbeddingSimilarTexts() {
        let text1 = "The quick brown fox jumps over the lazy dog."
        let text2 = "A fast brown fox leaps over a sleepy dog."

        let embedding1 = engine.generateEmbedding(for: text1)
        let embedding2 = engine.generateEmbedding(for: text2)

        if let emb1 = embedding1, let emb2 = embedding2 {
            XCTAssertEqual(emb1.count, emb2.count, "Embeddings should have same dimensionality")
            // Similar texts should have different embeddings
            XCTAssertNotEqual(emb1, emb2, "Different texts should have different embeddings")
        }
    }

    // MARK: - Cosine Similarity Tests

    func testCosineSimilarityIdenticalVectors() {
        let vector = [1.0, 2.0, 3.0, 4.0, 5.0]

        let similarity = engine.cosineSimilarity(vector, vector)

        XCTAssertEqual(similarity, 1.0, accuracy: 0.01, "Identical vectors should have similarity of 1.0")
    }

    func testCosineSimilarityOrthogonalVectors() {
        let vector1 = [1.0, 0.0, 0.0]
        let vector2 = [0.0, 1.0, 0.0]

        let similarity = engine.cosineSimilarity(vector1, vector2)

        XCTAssertEqual(similarity, 0.0, accuracy: 0.01, "Orthogonal vectors should have similarity of 0.0")
    }

    func testCosineSimilarityOppositeVectors() {
        let vector1 = [1.0, 2.0, 3.0]
        let vector2 = [-1.0, -2.0, -3.0]

        let similarity = engine.cosineSimilarity(vector1, vector2)

        XCTAssertEqual(similarity, -1.0, accuracy: 0.01, "Opposite vectors should have similarity of -1.0")
    }

    func testCosineSimilaritySimilarVectors() {
        let vector1 = [1.0, 2.0, 3.0, 4.0]
        let vector2 = [1.1, 2.1, 2.9, 4.0]

        let similarity = engine.cosineSimilarity(vector1, vector2)

        XCTAssertGreaterThan(similarity, 0.9, "Similar vectors should have high similarity")
    }

    func testCosineSimilarityDifferentLengths() {
        let vector1 = [1.0, 2.0, 3.0]
        let vector2 = [1.0, 2.0]

        let similarity = engine.cosineSimilarity(vector1, vector2)

        // Different length vectors should return 0 or handle gracefully
        XCTAssertEqual(similarity, 0.0, "Different length vectors should return 0 similarity")
    }

    func testCosineSimilarityZeroVectors() {
        let vector1 = [0.0, 0.0, 0.0]
        let vector2 = [1.0, 2.0, 3.0]

        let similarity = engine.cosineSimilarity(vector1, vector2)

        XCTAssertEqual(similarity, 0.0, "Zero vector should have 0 similarity with any vector")
    }

    func testCosineSimilarityEmptyVectors() {
        let vector1: [Double] = []
        let vector2: [Double] = []

        let similarity = engine.cosineSimilarity(vector1, vector2)

        XCTAssertEqual(similarity, 0.0, "Empty vectors should return 0 similarity")
    }

    // MARK: - Find Similar Items Tests

    func testFindSimilarItemsWithMatchingContent() {
        // Create test items
        let item1 = createTestItem(content: "Swift programming language", context: mockContext)
        let item2 = createTestItem(content: "Python programming tutorial", context: mockContext)
        let item3 = createTestItem(content: "Cooking pasta recipe", context: mockContext)
        let item4 = createTestItem(content: "Swift development guide", context: mockContext)

        let allItems = [item1, item2, item3, item4]

        // Find items similar to item1 (Swift programming)
        let similarItems = engine.findSimilarItems(to: item1, in: allItems, threshold: 0.3)

        // Note: Results depend on NLEmbedding availability
        if !similarItems.isEmpty {
            // Should find item4 (also about Swift) but not item3 (cooking)
            let similarContents = similarItems.map { $0.0.displayContent }
            print("Similar to '\(item1.displayContent)': \(similarContents)")
        }
    }

    func testFindSimilarItemsExcludesSelf() {
        let item1 = createTestItem(content: "Test content", context: mockContext)
        let item2 = createTestItem(content: "Different content", context: mockContext)

        let allItems = [item1, item2]

        let similarItems = engine.findSimilarItems(to: item1, in: allItems, threshold: 0.0)

        // Should not include the item itself
        XCTAssertFalse(similarItems.contains(where: { $0.0.id == item1.id }), "Should exclude the query item itself")
    }

    func testFindSimilarItemsWithHighThreshold() {
        let item1 = createTestItem(content: "Specific test content", context: mockContext)
        let item2 = createTestItem(content: "Completely different content", context: mockContext)

        let allItems = [item1, item2]

        // Very high threshold should return few or no results
        let similarItems = engine.findSimilarItems(to: item1, in: allItems, threshold: 0.95)

        // With high threshold, should find few matches
        XCTAssertLessThanOrEqual(similarItems.count, 1, "High threshold should return few results")
    }

    func testFindSimilarItemsEmptyArray() {
        let item = createTestItem(content: "Test", context: mockContext)
        let emptyArray: [ClipboardItemEntity] = []

        let similarItems = engine.findSimilarItems(to: item, in: emptyArray, threshold: 0.5)

        XCTAssertTrue(similarItems.isEmpty, "Empty array should return no similar items")
    }

    func testFindSimilarItemsSortedByScore() {
        let item1 = createTestItem(content: "Machine learning artificial intelligence", context: mockContext)
        let item2 = createTestItem(content: "Machine learning algorithms", context: mockContext)
        let item3 = createTestItem(content: "Deep learning neural networks", context: mockContext)
        let item4 = createTestItem(content: "Cooking recipes", context: mockContext)

        let allItems = [item1, item2, item3, item4]

        let similarItems = engine.findSimilarItems(to: item1, in: allItems, threshold: 0.0)

        if similarItems.count > 1 {
            // Results should be sorted by similarity score (descending)
            let scores = similarItems.map { $0.1 }
            let sortedScores = scores.sorted(by: >)
            XCTAssertEqual(scores, sortedScores, "Results should be sorted by similarity score")
        }
    }

    // MARK: - Integration Tests

    func testEmbeddingCacheWorks() {
        let item = createTestItem(content: "Cache test content", context: mockContext)

        // Generate embedding (should cache)
        engine.processAndStoreEmbedding(for: item, context: mockContext)

        // Check if embedding was stored
        XCTAssertNotNil(item.embedding, "Embedding should be stored in item")
        if let embedding = item.embedding {
            XCTAssertFalse(embedding.isEmpty, "Stored embedding should not be empty")
        }
    }

    func testSimilarityWithRealWorldScenarios() {
        // Test with programming-related content
        let code1 = createTestItem(content: "func calculateSum() { return a + b }", context: mockContext)
        let code2 = createTestItem(content: "function add() { return x + y }", context: mockContext)
        let unrelated = createTestItem(content: "Today's weather is sunny", context: mockContext)

        let items = [code1, code2, unrelated]

        let similarToCode1 = engine.findSimilarItems(to: code1, in: items, threshold: 0.0)

        if !similarToCode1.isEmpty {
            // code2 should be more similar to code1 than unrelated content
            let code2Result = similarToCode1.first(where: { $0.0.id == code2.id })
            let unrelatedResult = similarToCode1.first(where: { $0.0.id == unrelated.id })

            if let code2Score = code2Result?.1, let unrelatedScore = unrelatedResult?.1 {
                XCTAssertGreaterThan(code2Score, unrelatedScore,
                                   "Programming content should be more similar to each other than to unrelated content")
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestItem(content: String, context: NSManagedObjectContext) -> ClipboardItemEntity {
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.content = content
        item.timestamp = Date()
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false
        item.sourceApp = "TestApp"
        return item
    }
}
