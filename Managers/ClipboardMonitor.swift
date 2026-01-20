import SwiftUI
import AppKit
import CoreData
import UniformTypeIdentifiers

// MARK: - Clipboard Monitor (Enhanced with OCR)
class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private let context: NSManagedObjectContext
    private let settings = SettingsManager.shared

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func startMonitoring() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.lastChangeCount = self.pasteboard.changeCount
            NSLog("📋 Clipboard monitoring started. Initial change count: \(self.lastChangeCount)")

            // Write debug file to confirm function is called
            let debugMsg = "\n=== Monitoring started at \(Date()) ===\n"
            if let data = debugMsg.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: "/tmp/clipboard_monitor_debug.txt") {
                    if let handle = FileHandle(forWritingAtPath: "/tmp/clipboard_monitor_debug.txt") {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                } else {
                    try? data.write(to: URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt"))
                }
            }

            // Create timer on main thread
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.checkClipboard()
            }

            // Ensure timer runs in common modes
            if let timer = self.timer {
                RunLoop.main.add(timer, forMode: .common)
            }

            NSLog("✅ Timer created and scheduled")
            self.cleanupOldItems()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount

        if currentChangeCount != lastChangeCount {
            NSLog("📋 Clipboard changed! Count: \(lastChangeCount) → \(currentChangeCount)")
            try? "Clipboard changed at \(Date())".write(toFile: "/tmp/clipboard_monitor_debug.txt", atomically: false, encoding: .utf8)
            lastChangeCount = currentChangeCount

            if let frontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName {
                NSLog("📱 Current app: \(frontmostApp)")
                if settings.excludedApps.contains(frontmostApp) {
                    NSLog("⏭️ Skipping - app is excluded")
                    return
                }
            }

            captureClipboardContent()
        }
    }

    private func captureClipboardContent() {
        let types = pasteboard.types ?? []
        NSLog("📋 Available pasteboard types: \(types)")
        try? "captureClipboardContent called\n".data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt"), options: .atomic)

        var content = ""
        var itemType: Int16 = 0
        var category: Int16 = 0
        var imageData: Data?
        var image: NSImage?

        if types.contains(.string), let text = pasteboard.string(forType: .string) {
            content = text
            itemType = 0
            category = Int16(categorizeText(text).rawValue)
            NSLog("✅ Captured text: \(content.prefix(50))...")
            try? "Captured text: \(content.prefix(50))\n".data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt"), options: .atomic)
        } else if types.contains(.png) || types.contains(.tiff),
                let img = NSImage(pasteboard: pasteboard),
                let tiffData = img.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffData),
                let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            content = "Image"
            itemType = 1
            category = Int16(ClipboardCategory.image.rawValue)
            imageData = pngData
            image = img
            NSLog("✅ Captured image")
        } else if types.contains(.URL), let url = pasteboard.string(forType: .URL) {
            content = url
            itemType = 2
            category = Int16(ClipboardCategory.link.rawValue)
            NSLog("✅ Captured URL: \(content)")
        } else {
            NSLog("⚠️ No supported content type found")
        }

        if !content.isEmpty {
            NSLog("Content not empty, checking for duplicates...")
            try? "Content not empty: \(content.prefix(30))\n".data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt"), options: .atomic)

            let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "content == %@", content)
            fetchRequest.fetchLimit = 1

            do {
                let existingItems = try context.fetch(fetchRequest)
                if existingItems.isEmpty {
                    NSLog("💾 Saving new clipboard item...")
                    try? "Saving new item...\n".data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt"), options: .atomic)

                    let item = ClipboardItemEntity(context: context)
                    item.id = UUID()
                    item.timestamp = Date()
                    item.type = itemType
                    item.category = category
                    item.imageData = imageData
                    item.isFavorite = false
                    item.accessCount = 0
                    item.contextScore = 0.5

                    if settings.enableEncryption {
                        item.encryptedContent = EncryptionHelper.encrypt(content)
                        item.isEncrypted = true
                    } else {
                        item.content = content
                        item.isEncrypted = false
                    }

                    if let frontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName {
                        item.sourceApp = frontmostApp
                    }

                    // OCR for images
                    if settings.enableOCR, let img = image {
                        OCREngine.shared.extractText(from: img) { [weak self] extractedText in
                            DispatchQueue.main.async {
                                if let text = extractedText {
                                    item.ocrText = text
                                    self?.context.perform {
                                        PersistenceController.shared.save()
                                    }
                                }
                            }
                        }
                    }

                    debugLog("💾 Calling save()...")
                    PersistenceController.shared.save()
                    debugLog("✅ After save() call")

                    // Process embeddings in background if semantic search enabled
                    if settings.enableSemanticSearch {
                        EmbeddingProcessor.shared.processNewItem(item, context: context)
                    }

                    enforceItemLimit()
                    NSLog("✅ Clipboard item saved successfully")
                } else {
                    NSLog("⏭️ Duplicate content - skipping")
                }
            } catch {
                NSLog("❌ Failed to check duplicates: \(error.localizedDescription)")
                try? "ERROR: \(error.localizedDescription)\n".data(using: .utf8)?.write(to: URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt"), options: .atomic)
            }
        } else {
            NSLog("⚠️ Content is empty, not saving")
        }
    }

    private func categorizeText(_ text: String) -> ClipboardCategory {
        if text.range(of: #"^https?://[^\s]+"#, options: .regularExpression) != nil {
            return .link
        } else if text.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return .email
        } else if text.range(of: #"^\+?[\d\s\-\(\)]{10,}$"#, options: .regularExpression) != nil {
            return .phone
        } else if text.range(of: #"^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"#, options: .regularExpression) != nil {
            return .color
        }

        let codePatterns = ["func ", "function ", "const ", "let ", "var ", "class ", "def ", "import "]
        if codePatterns.contains(where: { text.contains($0) }) {
            return .code
        }

        return .text
    }

    private func enforceItemLimit() {
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ClipboardItemEntity.timestamp, ascending: false)]

        do {
            let items = try context.fetch(fetchRequest)
            let maxItems = settings.effectiveMaxItems
            if items.count > maxItems {
                let itemsToDelete = items.suffix(from: maxItems)
                for item in itemsToDelete {
                    context.delete(item)
                }
                PersistenceController.shared.save()
            }
        } catch {
            print("Failed to enforce limit: \(error)")
        }
    }

    private func cleanupOldItems() {
        let retentionDays = settings.effectiveRetentionDays
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else {
            print("⚠️ Failed to calculate cutoff date for cleanup")
            return
        }
        let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)

        do {
            let oldItems = try context.fetch(fetchRequest)
            for item in oldItems {
                context.delete(item)
            }
            if !oldItems.isEmpty {
                PersistenceController.shared.save()
            }
        } catch {
            print("Failed to cleanup: \(error)")
        }
    }
}
