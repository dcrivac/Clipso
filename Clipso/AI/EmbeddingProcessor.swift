import Foundation
import CoreData
import AppKit

// MARK: - Embedding Processor
class EmbeddingProcessor {
    static let shared = EmbeddingProcessor()
    private let processingQueue = DispatchQueue(label: "embeddings.processing", qos: .utility)
    private let semanticEngine = SemanticEngine.shared
    private var isProcessing = false

    // Process a new clipboard item
    func processNewItem(_ item: ClipboardItemEntity, context: NSManagedObjectContext) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            print("🔄 Processing new item: \(item.id)")

            // Generate and store embedding
            self.semanticEngine.processAndStoreEmbedding(for: item, context: context)

            // Find similar items
            self.updateRelatedItems(for: item, context: context)

            // Update context scores
            self.updateContextScores(context: context)

            print("✅ Finished processing item: \(item.id)")
        }
    }

    // Batch process existing items without embeddings
    func processExistingItems(context: NSManagedObjectContext) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isProcessing else {
                print("⚠️  Embedding processing already in progress")
                return
            }

            self.isProcessing = true
            print("🔄 Starting batch embedding processing...")

            self.semanticEngine.processExistingItems(context: context)

            // Update all context scores after batch processing
            self.updateContextScores(context: context)

            self.isProcessing = false
            print("✅ Batch processing complete")
        }
    }

    // Update related items based on similarity
    private func updateRelatedItems(for item: ClipboardItemEntity, context: NSManagedObjectContext) {
        context.perform {
            let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
            fetchRequest.fetchLimit = 100 // Process recent items only

            do {
                let allItems = try context.fetch(fetchRequest)
                let similarItems = self.semanticEngine.findSimilarItems(
                    to: item,
                    in: allItems,
                    threshold: 0.75
                )

                // Store top 5 related items
                let relatedIDs = similarItems
                    .prefix(5)
                    .map { $0.0.id.uuidString }
                    .joined(separator: ",")

                item.relatedItemIDs = relatedIDs.isEmpty ? nil : relatedIDs

                try context.save()
                print("✅ Updated related items for \(item.id): \(similarItems.count) similar items found")
            } catch {
                print("❌ Failed to update related items: \(error)")
            }
        }
    }

    // Update context scores for all items
    private func updateContextScores(context: NSManagedObjectContext) {
        context.perform {
            let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
            fetchRequest.fetchLimit = 50 // Recent items only

            do {
                let items = try context.fetch(fetchRequest)
                guard !items.isEmpty else { return }

                // Get current app context
                let currentApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""

                // Calculate scores based on recency, app match, and frequency
                for item in items {
                    var score = 0.0

                    // Recency score (0.0-0.4)
                    let daysSinceCreated = Calendar.current.dateComponents([.day], from: item.timestamp, to: Date()).day ?? 0
                    let recencyScore = max(0, 0.4 - Double(daysSinceCreated) * 0.02)

                    // App match score (0.0-0.3)
                    let appScore = (item.sourceApp == currentApp) ? 0.3 : 0.0

                    // Frequency score (0.0-0.3)
                    let frequencyScore = min(0.3, Double(item.accessCount) * 0.03)

                    score = recencyScore + appScore + frequencyScore

                    item.contextScore = min(1.0, max(0.0, score))
                }

                try context.save()
                print("✅ Updated context scores for \(items.count) items")
            } catch {
                print("❌ Failed to update context scores: \(error)")
            }
        }
    }

    // Refresh context scores periodically
    func refreshContextScores(context: NSManagedObjectContext) {
        processingQueue.async { [weak self] in
            self?.updateContextScores(context: context)
        }
    }
}
