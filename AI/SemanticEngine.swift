import Foundation
import NaturalLanguage
import CoreData

// MARK: - Semantic Engine
class SemanticEngine {
    static let shared = SemanticEngine()
    private var embeddingModel: NLEmbedding?
    private var embeddingCache: [UUID: [Double]] = [:]
    private let cacheQueue = DispatchQueue(label: "embedding.cache", attributes: .concurrent)

    init() {
        // Initialize NLEmbedding for sentence embeddings
        if let embedding = NLEmbedding.sentenceEmbedding(for: .english) {
            self.embeddingModel = embedding
            print("✅ Semantic Engine initialized with NLEmbedding")
        } else {
            print("⚠️ NLEmbedding not available - semantic features disabled")
        }
    }

    // Generate embedding vector for text
    func generateEmbedding(for text: String) -> [Double]? {
        guard let model = embeddingModel else { return nil }
        guard !text.isEmpty else { return nil }

        // Limit text length to avoid performance issues
        let processText = String(text.prefix(1000))

        // Get embedding vector from NLEmbedding
        guard let vector = model.vector(for: processText) else {
            return nil
        }

        // Convert to array of doubles
        return Array(vector)
    }

    // Convert embedding array to Data for Core Data storage
    func embeddingToData(_ embedding: [Double]) -> Data? {
        return try? JSONEncoder().encode(embedding)
    }

    // Convert Data back to embedding array
    func dataToEmbedding(_ data: Data) -> [Double]? {
        return try? JSONDecoder().decode([Double].self, from: data)
    }

    // Calculate cosine similarity between two embedding vectors
    func cosineSimilarity(_ vec1: [Double], _ vec2: [Double]) -> Double {
        guard vec1.count == vec2.count, !vec1.isEmpty else { return 0.0 }

        var dotProduct = 0.0
        var magnitude1 = 0.0
        var magnitude2 = 0.0

        for i in 0..<vec1.count {
            dotProduct += vec1[i] * vec2[i]
            magnitude1 += vec1[i] * vec1[i]
            magnitude2 += vec2[i] * vec2[i]
        }

        let denominator = sqrt(magnitude1) * sqrt(magnitude2)
        guard denominator > 0 else { return 0.0 }

        return dotProduct / denominator
    }

    // Find semantically similar items
    func findSimilarItems(to item: ClipboardItemEntity,
                         in allItems: [ClipboardItemEntity],
                         threshold: Double = 0.7) -> [(ClipboardItemEntity, Double)] {
        guard let targetEmbedding = getEmbedding(for: item) else {
            return []
        }

        var results: [(ClipboardItemEntity, Double)] = []

        for otherItem in allItems {
            guard otherItem.id != item.id else { continue }
            guard let otherEmbedding = getEmbedding(for: otherItem) else { continue }

            let similarity = cosineSimilarity(targetEmbedding, otherEmbedding)
            if similarity >= threshold {
                results.append((otherItem, similarity))
            }
        }

        // Sort by similarity (highest first)
        return results.sorted { $0.1 > $1.1 }
    }

    // Get or generate embedding for an item
    private func getEmbedding(for item: ClipboardItemEntity) -> [Double]? {
        // Check cache first
        if let cached = getCachedEmbedding(for: item.id) {
            return cached
        }

        // Check if stored in Core Data
        if let embeddingData = item.embedding,
           let embedding = dataToEmbedding(embeddingData) {
            setCachedEmbedding(embedding, for: item.id)
            return embedding
        }

        // Generate new embedding
        let text = item.displayContent
        guard !text.isEmpty else { return nil }
        guard let embedding = generateEmbedding(for: text) else { return nil }

        setCachedEmbedding(embedding, for: item.id)
        return embedding
    }

    // Cache management
    private func getCachedEmbedding(for id: UUID) -> [Double]? {
        return cacheQueue.sync {
            return embeddingCache[id]
        }
    }

    private func setCachedEmbedding(_ embedding: [Double], for id: UUID) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.embeddingCache[id] = embedding

            // Limit cache size to 100 most recent items
            if let cache = self?.embeddingCache, cache.count > 100 {
                let keysToRemove = Array(cache.keys.prefix(cache.count - 100))
                keysToRemove.forEach { self?.embeddingCache.removeValue(forKey: $0) }
            }
        }
    }

    // Process item and store embedding in Core Data
    func processAndStoreEmbedding(for item: ClipboardItemEntity, context: NSManagedObjectContext) {
        let text = item.displayContent
        guard !text.isEmpty else { return }
        guard let embedding = generateEmbedding(for: text) else { return }
        guard let embeddingData = embeddingToData(embedding) else { return }

        context.perform {
            item.embedding = embeddingData

            do {
                try context.save()
                self.setCachedEmbedding(embedding, for: item.id)
                print("✅ Stored embedding for item \(item.id)")
            } catch {
                print("❌ Failed to save embedding: \(error)")
            }
        }
    }

    // Batch process existing items
    func processExistingItems(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "embedding == nil")

        context.perform {
            do {
                let items = try context.fetch(fetchRequest)
                print("🔄 Processing \(items.count) items without embeddings...")

                for item in items {
                    self.processAndStoreEmbedding(for: item, context: context)
                }

                print("✅ Batch embedding processing complete")
            } catch {
                print("❌ Failed to fetch items for embedding: \(error)")
            }
        }
    }
}
