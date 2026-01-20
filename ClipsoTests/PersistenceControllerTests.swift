import XCTest
import CoreData
@testable import Clipso

final class PersistenceControllerTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }

    override func tearDown() {
        // Clean up all test data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ClipboardItemEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)

        persistenceController = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSharedInstanceExists() {
        let shared = PersistenceController.shared

        XCTAssertNotNil(shared, "Shared instance should exist")
        XCTAssertNotNil(shared.container, "Shared instance should have container")
    }

    func testInMemoryStoreCreation() {
        let inMemoryController = PersistenceController(inMemory: true)

        XCTAssertNotNil(inMemoryController.container, "In-memory controller should have container")

        // Verify it's in-memory by checking store URL
        if let storeDescription = inMemoryController.container.persistentStoreDescriptions.first {
            XCTAssertEqual(storeDescription.url?.path, "/dev/null", "Should use /dev/null for in-memory store")
        }
    }

    func testPersistentStoreCreation() {
        let persistentController = PersistenceController(inMemory: false)

        XCTAssertNotNil(persistentController.container, "Persistent controller should have container")
        XCTAssertNotNil(persistentController.container.persistentStoreCoordinator.persistentStores.first,
                       "Should have at least one persistent store")
    }

    func testContainerName() {
        XCTAssertEqual(persistenceController.container.name, "ClipboardManager",
                      "Container should use correct model name")
    }

    func testAutomaticMergeFromParent() {
        XCTAssertTrue(persistenceController.container.viewContext.automaticallyMergesChangesFromParent,
                     "View context should automatically merge changes from parent")
    }

    // MARK: - Preview Controller Tests

    func testPreviewControllerExists() {
        let preview = PersistenceController.preview

        XCTAssertNotNil(preview, "Preview controller should exist")
        XCTAssertNotNil(preview.container, "Preview controller should have container")
    }

    func testPreviewControllerHasSampleData() {
        let preview = PersistenceController.preview
        let context = preview.container.viewContext

        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()

        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertGreaterThanOrEqual(items.count, 5, "Preview should have at least 5 sample items")

            // Verify sample data properties
            for item in items {
                XCTAssertNotNil(item.id, "Sample item should have ID")
                XCTAssertNotNil(item.timestamp, "Sample item should have timestamp")
                XCTAssertNotNil(item.content, "Sample item should have content")
            }
        } catch {
            XCTFail("Failed to fetch preview sample data: \(error)")
        }
    }

    func testPreviewControllerIsInMemory() {
        let preview = PersistenceController.preview

        if let storeDescription = preview.container.persistentStoreDescriptions.first {
            XCTAssertEqual(storeDescription.url?.path, "/dev/null",
                          "Preview controller should use in-memory store")
        }
    }

    // MARK: - Save Operation Tests

    func testSaveWithChanges() {
        // Create a new item
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.content = "Test content"
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false

        XCTAssertTrue(context.hasChanges, "Context should have changes after creating item")

        // Save
        persistenceController.save()

        // Verify save succeeded
        XCTAssertFalse(context.hasChanges, "Context should have no changes after save")

        // Verify item persisted
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 1, "Should have one saved item")
            XCTAssertEqual(items.first?.content, "Test content", "Content should be preserved")
        } catch {
            XCTFail("Failed to fetch saved item: \(error)")
        }
    }

    func testSaveWithNoChanges() {
        XCTAssertFalse(context.hasChanges, "Fresh context should have no changes")

        // Save should be a no-op
        persistenceController.save()

        XCTAssertFalse(context.hasChanges, "Context should still have no changes")
    }

    func testSaveMultipleItems() {
        // Create multiple items
        for i in 0..<10 {
            let item = ClipboardItemEntity(context: context)
            item.id = UUID()
            item.timestamp = Date()
            item.content = "Item \(i)"
            item.category = Int16(ClipboardCategory.text.rawValue)
            item.type = 0
            item.isEncrypted = false
        }

        persistenceController.save()

        // Verify all items saved
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 10, "Should save all 10 items")
        } catch {
            XCTFail("Failed to fetch saved items: \(error)")
        }
    }

    func testSaveAfterUpdate() {
        // Create and save an item
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.content = "Original content"
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false

        persistenceController.save()

        // Update the item
        item.content = "Updated content"

        XCTAssertTrue(context.hasChanges, "Context should have changes after update")

        persistenceController.save()

        // Verify update persisted
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 1, "Should still have one item")
            XCTAssertEqual(items.first?.content, "Updated content", "Content should be updated")
        } catch {
            XCTFail("Failed to fetch updated item: \(error)")
        }
    }

    func testSaveAfterDelete() {
        // Create and save an item
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.content = "To be deleted"
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false

        persistenceController.save()

        // Delete the item
        context.delete(item)

        persistenceController.save()

        // Verify deletion persisted
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 0, "Should have no items after deletion")
        } catch {
            XCTFail("Failed to fetch after deletion: \(error)")
        }
    }

    // MARK: - Core Data Entity Tests

    func testCreateClipboardItemEntity() {
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.content = "Test"
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false

        XCTAssertNotNil(item, "Should create ClipboardItemEntity")
        XCTAssertEqual(item.managedObjectContext, context, "Item should be in correct context")
    }

    func testClipboardItemEntityProperties() {
        let item = ClipboardItemEntity(context: context)
        let testID = UUID()
        let testDate = Date()

        item.id = testID
        item.timestamp = testDate
        item.content = "Test content"
        item.category = Int16(ClipboardCategory.code.rawValue)
        item.type = 1
        item.isEncrypted = true
        item.sourceApp = "TestApp"
        item.ocrText = "OCR text"
        item.isFavorite = true
        item.accessCount = 5
        item.contextScore = 0.85
        item.projectTag = "TestProject"

        XCTAssertEqual(item.id, testID)
        XCTAssertEqual(item.timestamp, testDate)
        XCTAssertEqual(item.content, "Test content")
        XCTAssertEqual(item.category, Int16(ClipboardCategory.code.rawValue))
        XCTAssertEqual(item.type, 1)
        XCTAssertTrue(item.isEncrypted)
        XCTAssertEqual(item.sourceApp, "TestApp")
        XCTAssertEqual(item.ocrText, "OCR text")
        XCTAssertTrue(item.isFavorite)
        XCTAssertEqual(item.accessCount, 5)
        XCTAssertEqual(item.contextScore, 0.85)
        XCTAssertEqual(item.projectTag, "TestProject")
    }

    func testClipboardItemEntityWithImageData() {
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.category = Int16(ClipboardCategory.image.rawValue)
        item.type = 0
        item.isEncrypted = false

        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        item.imageData = imageData

        XCTAssertEqual(item.imageData, imageData, "Image data should be preserved")
    }

    func testClipboardItemEntityWithEmbedding() {
        let item = ClipboardItemEntity(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.content = "Test"
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false

        let embedding = [0.1, 0.2, 0.3, 0.4, 0.5]
        let embeddingData = try? JSONEncoder().encode(embedding)
        item.embedding = embeddingData

        XCTAssertNotNil(item.embedding, "Embedding should be stored")

        // Verify decoding
        if let storedData = item.embedding {
            let decoded = try? JSONDecoder().decode([Double].self, from: storedData)
            XCTAssertEqual(decoded, embedding, "Embedding should decode correctly")
        }
    }

    // MARK: - Fetch Request Tests

    func testFetchAllItems() {
        // Create multiple items
        for i in 0..<5 {
            let item = ClipboardItemEntity(context: context)
            item.id = UUID()
            item.timestamp = Date()
            item.content = "Item \(i)"
            item.category = Int16(ClipboardCategory.text.rawValue)
            item.type = 0
            item.isEncrypted = false
        }

        persistenceController.save()

        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()

        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 5, "Should fetch all items")
        } catch {
            XCTFail("Failed to fetch items: \(error)")
        }
    }

    func testFetchWithPredicate() {
        // Create items with different categories
        let textItem = ClipboardItemEntity(context: context)
        textItem.id = UUID()
        textItem.timestamp = Date()
        textItem.content = "Text"
        textItem.category = Int16(ClipboardCategory.text.rawValue)
        textItem.type = 0
        textItem.isEncrypted = false

        let codeItem = ClipboardItemEntity(context: context)
        codeItem.id = UUID()
        codeItem.timestamp = Date()
        codeItem.content = "Code"
        codeItem.category = Int16(ClipboardCategory.code.rawValue)
        codeItem.type = 0
        codeItem.isEncrypted = false

        persistenceController.save()

        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %d", ClipboardCategory.code.rawValue)

        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 1, "Should fetch only code items")
            XCTAssertEqual(items.first?.content, "Code")
        } catch {
            XCTFail("Failed to fetch with predicate: \(error)")
        }
    }

    func testFetchWithSortDescriptor() {
        // Create items with different timestamps
        for i in 0..<3 {
            let item = ClipboardItemEntity(context: context)
            item.id = UUID()
            item.timestamp = Date().addingTimeInterval(TimeInterval(i * 3600))
            item.content = "Item \(i)"
            item.category = Int16(ClipboardCategory.text.rawValue)
            item.type = 0
            item.isEncrypted = false
        }

        persistenceController.save()

        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 3, "Should fetch all items")

            // Verify sorted by timestamp descending
            for i in 0..<(items.count - 1) {
                XCTAssertGreaterThanOrEqual(items[i].timestamp, items[i + 1].timestamp,
                                           "Items should be sorted by timestamp descending")
            }
        } catch {
            XCTFail("Failed to fetch with sort: \(error)")
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSave() {
        let expectation = self.expectation(description: "Concurrent saves complete")
        expectation.expectedFulfillmentCount = 3

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        for i in 0..<3 {
            queue.async {
                let item = ClipboardItemEntity(context: self.context)
                item.id = UUID()
                item.timestamp = Date()
                item.content = "Concurrent item \(i)"
                item.category = Int16(ClipboardCategory.text.rawValue)
                item.type = 0
                item.isEncrypted = false

                self.persistenceController.save()
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0, handler: nil)

        // Verify all items saved
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            XCTAssertEqual(items.count, 3, "All concurrent saves should succeed")
        } catch {
            XCTFail("Failed to fetch after concurrent saves: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testSavePerformance() {
        measure {
            for i in 0..<100 {
                let item = ClipboardItemEntity(context: context)
                item.id = UUID()
                item.timestamp = Date()
                item.content = "Performance test item \(i)"
                item.category = Int16(ClipboardCategory.text.rawValue)
                item.type = 0
                item.isEncrypted = false
            }

            persistenceController.save()

            // Clean up for next iteration
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ClipboardItemEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
        }
    }

    func testFetchPerformance() {
        // Setup: Create 1000 items
        for i in 0..<1000 {
            let item = ClipboardItemEntity(context: context)
            item.id = UUID()
            item.timestamp = Date()
            item.content = "Item \(i)"
            item.category = Int16(ClipboardCategory.text.rawValue)
            item.type = 0
            item.isEncrypted = false
        }
        persistenceController.save()

        measure {
            let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
            _ = try? context.fetch(fetchRequest)
        }
    }
}
