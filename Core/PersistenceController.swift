import Foundation
import CoreData

// MARK: - Core Data Persistence
class PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample data for previews
        for i in 0..<5 {
            let item = ClipboardItemEntity(context: context)
            item.id = UUID()
            item.timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600))
            item.content = "Sample text \(i)"
            item.category = Int16(ClipboardCategory.text.rawValue)
            item.type = 0
            item.isEncrypted = false
        }

        do {
            try context.save()
        } catch {
            print("Failed to save preview context: \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Use the .xcdatamodeld file
        container = NSPersistentContainer(name: "ClipboardManager")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let context = container.viewContext
        debugLog("💾 save() called. hasChanges: \(context.hasChanges)")

        if context.hasChanges {
            do {
                try context.save()
                debugLog("✅ Context saved successfully!")
            } catch {
                debugLog("❌ Save ERROR: \(error)")
            }
        } else {
            debugLog("⚠️ No changes to save")
        }
    }
}
