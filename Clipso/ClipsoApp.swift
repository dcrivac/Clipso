import SwiftUI
import AppKit
import CoreData
import CryptoKit
import Carbon
import Vision
import NaturalLanguage
import UniformTypeIdentifiers
import Combine

// Ensure Core Data entity extensions are visible
// If you still get errors, make sure ClipboardItemEntity+CoreDataClass.swift 
// and ClipboardItemEntity+CoreDataProperties.swift are included in your target

// MARK: - Main App Entry Point
@main
struct ClipsoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// MARK: - App Delegate (Manages Menu Bar & Global Shortcuts)
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Application launching...")
        
        // Request necessary permissions
        requestAccessibilityPermissions()
        
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover with Core Data context
        let context = PersistenceController.shared.container.viewContext
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ContentView()
                .environment(\.managedObjectContext, context)
        )

        // Setup license menu
        setupMenuBarMenu()

        // Start clipboard monitoring with a delay to ensure everything is set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            print("🔍 Starting clipboard monitor...")
            self.clipboardMonitor = ClipboardMonitor(context: context)
            self.clipboardMonitor?.startMonitoring()
        }
        
        // Register global keyboard shortcut (Cmd+Shift+V)
        registerGlobalShortcut()
        
        // Monitor clicks outside popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover?.isShown == true {
                self?.popover?.performClose(nil)
            }
        }
        
        print("✅ Application launched successfully")
    }
    
    private func requestAccessibilityPermissions() {
        // Check if we can get the frontmost application (requires permissions)
        if NSWorkspace.shared.frontmostApplication == nil {
            print("⚠️ May need accessibility permissions")
        }
        
        // Test clipboard access
        let testPasteboard = NSPasteboard.general
        let _ = testPasteboard.changeCount
        print("📋 Clipboard access: OK")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func registerGlobalShortcut() {
        let keyCode: UInt32 = 9 // V key
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4356), id: 1)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        var eventHandler: EventHandlerRef?
        var eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))]
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            delegate.togglePopover()
            return noErr
        }, 1, &eventTypes, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - License Menu Setup
    private func setupMenuBarMenu() {
        let menu = NSMenu()

        // License status
        let licenseManager = LicenseManager.shared
        if licenseManager.isProUser {
            let licenseItem = NSMenuItem(
                title: "✓ Pro License Active",
                action: nil,
                keyEquivalent: ""
            )
            licenseItem.isEnabled = false
            menu.addItem(licenseItem)
        } else {
            menu.addItem(NSMenuItem(
                title: "Upgrade to Pro...",
                action: #selector(showUpgrade),
                keyEquivalent: "u"
            ))
        }

        menu.addItem(NSMenuItem(
            title: "Activate License...",
            action: #selector(showLicenseActivation),
            keyEquivalent: "l"
        ))

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit Clipso",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    @objc private func showUpgrade() {
        LicenseManager.shared.purchaseLifetime()
    }

    @objc private func showLicenseActivation() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Activate License"
        window.contentView = NSHostingController(rootView: LicenseActivationView()).view
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

// MARK: - Core Data Entity Extension
extension ClipboardItemEntity {
    var clipboardCategory: ClipboardCategory {
        get { ClipboardCategory(rawValue: Int(category)) ?? .text }
        set { category = Int16(newValue.rawValue) }
    }
    
    var displayContent: String {
        if isEncrypted, let encData = encryptedContent {
            return EncryptionHelper.decrypt(encData) ?? "[Encrypted]"
        }
        return content ?? ""
    }
    
    var displayImage: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }
}

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

// MARK: - Encryption Helper
class EncryptionHelper {
    private static let keychain = "com.clipboardmanager.encryption.key"
    
    static func encrypt(_ text: String) -> Data? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard let key = getOrCreateKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    static func decrypt(_ encryptedData: Data) -> String? {
        guard let key = getOrCreateKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    private static func getOrCreateKey() -> SymmetricKey? {
        if let keyData = loadKeyFromKeychain() {
            return SymmetricKey(data: keyData)
        }
        
        let key = SymmetricKey(size: .bits256)
        if saveKeyToKeychain(key.withUnsafeBytes { Data($0) }) {
            return key
        }
        
        return nil
    }
    
    private static func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychain,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    private static func saveKeyToKeychain(_ keyData: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychain,
            kSecValueData as String: keyData
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var retentionDays: Int {
        didSet { UserDefaults.standard.set(retentionDays, forKey: "retentionDays") }
    }
    
    @Published var maxItems: Int {
        didSet { UserDefaults.standard.set(maxItems, forKey: "maxItems") }
    }
    
    @Published var excludedApps: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedApps), forKey: "excludedApps")
        }
    }
    
    @Published var enableEncryption: Bool {
        didSet { UserDefaults.standard.set(enableEncryption, forKey: "enableEncryption") }
    }
    
    @Published var enableOCR: Bool {
        didSet { UserDefaults.standard.set(enableOCR, forKey: "enableOCR") }
    }
    
    @Published var enableSmartPaste: Bool {
        didSet { UserDefaults.standard.set(enableSmartPaste, forKey: "enableSmartPaste") }
    }

    @Published var enableSemanticSearch: Bool {
        didSet { UserDefaults.standard.set(enableSemanticSearch, forKey: "enableSemanticSearch") }
    }

    @Published var enableAutoProjects: Bool {
        didSet { UserDefaults.standard.set(enableAutoProjects, forKey: "enableAutoProjects") }
    }

    @Published var contextWindowMinutes: Int {
        didSet { UserDefaults.standard.set(contextWindowMinutes, forKey: "contextWindowMinutes") }
    }

    @Published var similarityThreshold: Double {
        didSet { UserDefaults.standard.set(similarityThreshold, forKey: "similarityThreshold") }
    }

    init() {
        self.retentionDays = UserDefaults.standard.object(forKey: "retentionDays") as? Int ?? 30
        self.maxItems = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 100

        let savedApps = UserDefaults.standard.array(forKey: "excludedApps") as? [String] ?? []
        self.excludedApps = Set(savedApps)

        self.enableEncryption = UserDefaults.standard.bool(forKey: "enableEncryption")
        self.enableOCR = UserDefaults.standard.object(forKey: "enableOCR") as? Bool ?? true
        self.enableSmartPaste = UserDefaults.standard.object(forKey: "enableSmartPaste") as? Bool ?? true
        self.enableSemanticSearch = UserDefaults.standard.object(forKey: "enableSemanticSearch") as? Bool ?? true
        self.enableAutoProjects = UserDefaults.standard.object(forKey: "enableAutoProjects") as? Bool ?? true
        self.contextWindowMinutes = UserDefaults.standard.object(forKey: "contextWindowMinutes") as? Int ?? 30
        self.similarityThreshold = UserDefaults.standard.object(forKey: "similarityThreshold") as? Double ?? 0.75
    }

    // MARK: - License-based limits
    var effectiveRetentionDays: Int {
        let licensedMax = LicenseManager.shared.getMaxRetentionDays()
        return min(retentionDays, licensedMax)
    }

    var effectiveMaxItems: Int {
        let licensedMax = LicenseManager.shared.getMaxItems()
        return min(maxItems, licensedMax)
    }

    static let suggestedExclusions = [
        "1Password", "Bitwarden", "LastPass", "Dashlane", "KeePassXC"
    ]
}

// MARK: - OCR Engine
class OCREngine {
    static let shared = OCREngine()
    
    func extractText(from image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
            
            completion(text.isEmpty ? nil : text)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

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

// MARK: - Context Detector
class ContextDetector {
    static let shared = ContextDetector()
    private let semanticEngine = SemanticEngine.shared

    // MARK: - App Pattern Detection
    func detectAppPatterns(_ items: [ClipboardItemEntity]) -> [String: [ClipboardItemEntity]] {
        var patterns: [String: [ClipboardItemEntity]] = [:]

        // Take last 50 items for pattern analysis
        let recentItems = Array(items.prefix(50))

        // Build app sequences (sliding window of 3)
        var appSequences: [String: Int] = [:]

        for i in 0..<(recentItems.count - 2) {
            let apps = [
                recentItems[i].sourceApp ?? "",
                recentItems[i+1].sourceApp ?? "",
                recentItems[i+2].sourceApp ?? ""
            ].filter { !$0.isEmpty }

            if apps.count >= 2 {
                let pattern = apps.sorted().joined(separator: " + ")
                appSequences[pattern, default: 0] += 1
            }
        }

        // Find common patterns (appeared 3+ times)
        let commonPatterns = appSequences.filter { $0.value >= 3 }.keys

        // Group items by detected patterns
        for item in recentItems {
            guard let itemApp = item.sourceApp, !itemApp.isEmpty else { continue }

            for pattern in commonPatterns {
                if pattern.contains(itemApp) {
                    patterns[pattern, default: []].append(item)
                }
            }
        }

        return patterns
    }

    // MARK: - Time Window Detection
    func detectTimeWindows(_ items: [ClipboardItemEntity], windowMinutes: Int = 30) -> [[ClipboardItemEntity]] {
        var windows: [[ClipboardItemEntity]] = []

        // Sort by timestamp
        let sortedItems = items.sorted { $0.timestamp < $1.timestamp }

        var currentWindow: [ClipboardItemEntity] = []
        var windowStart: Date?

        for item in sortedItems {
            let timestamp = item.timestamp

            if let start = windowStart {
                let minutesDiff = Calendar.current.dateComponents([.minute], from: start, to: timestamp).minute ?? 0

                if minutesDiff <= windowMinutes {
                    // Add to current window
                    currentWindow.append(item)
                } else {
                    // Start new window
                    if !currentWindow.isEmpty {
                        windows.append(currentWindow)
                    }
                    currentWindow = [item]
                    windowStart = timestamp
                }
            } else {
                // First item
                currentWindow.append(item)
                windowStart = timestamp
            }
        }

        // Add last window
        if !currentWindow.isEmpty {
            windows.append(currentWindow)
        }

        // Merge adjacent windows if >70% similar
        return mergeSimilarWindows(windows)
    }

    private func mergeSimilarWindows(_ windows: [[ClipboardItemEntity]]) -> [[ClipboardItemEntity]] {
        guard windows.count > 1 else { return windows }

        var merged: [[ClipboardItemEntity]] = []
        var current = windows[0]

        for i in 1..<windows.count {
            let next = windows[i]
            let similarity = calculateWindowSimilarity(current, next)

            if similarity > 0.7 {
                current.append(contentsOf: next)
            } else {
                merged.append(current)
                current = next
            }
        }

        merged.append(current)
        return merged
    }

    private func calculateWindowSimilarity(_ window1: [ClipboardItemEntity], _ window2: [ClipboardItemEntity]) -> Double {
        // Calculate similarity based on common apps
        let apps1 = Set(window1.compactMap { $0.sourceApp })
        let apps2 = Set(window2.compactMap { $0.sourceApp })

        guard !apps1.isEmpty && !apps2.isEmpty else { return 0.0 }

        let intersection = apps1.intersection(apps2).count
        let union = apps1.union(apps2).count

        return Double(intersection) / Double(union)
    }

    // MARK: - Content Similarity Clustering
    func detectContentClusters(_ items: [ClipboardItemEntity], threshold: Double = 0.75) -> [[ClipboardItemEntity]] {
        var clusters: [[ClipboardItemEntity]] = []
        var processed: Set<UUID> = []

        for item in items {
            guard !processed.contains(item.id) else { continue }

            // Find similar items
            let similarItems = semanticEngine.findSimilarItems(to: item, in: items, threshold: threshold)

            if !similarItems.isEmpty {
                var cluster = [item]
                cluster.append(contentsOf: similarItems.map { $0.0 })

                // Mark all as processed
                cluster.forEach { processed.insert($0.id) }

                clusters.append(cluster)
            } else {
                processed.insert(item.id)
            }
        }

        return clusters
    }

    // MARK: - Project Tag Suggestions
    func suggestProjectTags(for item: ClipboardItemEntity, basedOn history: [ClipboardItemEntity]) -> [TagSuggestion] {
        var suggestions: [TagSuggestion] = []

        // Learn from manually tagged items
        let taggedItems = history.filter { $0.projectTag != nil && !$0.projectTag!.isEmpty }

        guard !taggedItems.isEmpty else { return [] }

        // Group by tag
        var tagGroups: [String: [ClipboardItemEntity]] = [:]
        for taggedItem in taggedItems {
            guard let tag = taggedItem.projectTag else { continue }
            tagGroups[tag, default: []].append(taggedItem)
        }

        // For each tag, check if current item matches the pattern
        for (tag, group) in tagGroups {
            var score = 0.0
            var matchCount = 0

            // Check app match
            if let itemApp = item.sourceApp {
                let groupApps = Set(group.compactMap { $0.sourceApp })
                if groupApps.contains(itemApp) {
                    score += 0.3
                    matchCount += 1
                }
            }

            // Check content similarity
            let similarItems = group.filter { otherItem in
                let similar = semanticEngine.findSimilarItems(to: item, in: [otherItem], threshold: 0.7)
                return !similar.isEmpty
            }

            if !similarItems.isEmpty {
                score += 0.4 * (Double(similarItems.count) / Double(group.count))
                matchCount += 1
            }

            // Check time proximity (within last hour)
            let itemTime = item.timestamp
            let recentItems = group.filter { otherItem in
                let otherTime = otherItem.timestamp
                let minutes = Calendar.current.dateComponents([.minute], from: otherTime, to: itemTime).minute ?? Int.max
                return abs(minutes) <= 60
            }

            if !recentItems.isEmpty {
                score += 0.3
                matchCount += 1
            }

            // Only suggest if at least 2 criteria match
            if matchCount >= 2 && score > 0.5 {
                suggestions.append(TagSuggestion(tag: tag, confidence: score))
            }
        }

        // Sort by confidence
        return suggestions.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Context Score Calculation
    func calculateContextScores(_ items: [ClipboardItemEntity]) -> [UUID: Double] {
        var scores: [UUID: Double] = [:]

        guard let currentApp = NSWorkspace.shared.frontmostApplication?.localizedName else {
            return scores
        }

        for item in items {
            var score = 0.0

            // Recency (40%)
            let timestamp = item.timestamp
            let hoursSince = Calendar.current.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
            let recencyScore = max(0, 0.4 - Double(hoursSince) * 0.02)
            score += recencyScore

            // App match (30%)
            if item.sourceApp == currentApp {
                score += 0.3
            }

            // Frequency (20%)
            let frequencyScore = min(0.2, Double(item.accessCount) * 0.02)
            score += frequencyScore

            // Has project tag (10%)
            if item.projectTag != nil && !item.projectTag!.isEmpty {
                score += 0.1
            }

            scores[item.id] = min(1.0, max(0.0, score))
        }

        return scores
    }
}

// Tag suggestion structure
struct TagSuggestion: Identifiable {
    let id = UUID()
    let tag: String
    let confidence: Double

    var confidencePercent: Int {
        Int(confidence * 100)
    }
}

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

// MARK: - Debug Helper
func debugLog(_ message: String) {
    NSLog(message)
    let msg = "[\(Date())] \(message)\n"
    if let data = msg.data(using: .utf8) {
        let url = URL(fileURLWithPath: "/tmp/clipboard_monitor_debug.txt")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }
}

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

// MARK: - Data Models
enum ClipboardCategory: Int, CaseIterable {
    case text = 0, code = 1, link = 2, email = 3, phone = 4, color = 5, image = 6
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .code: return "Code"
        case .link: return "Link"
        case .email: return "Email"
        case .phone: return "Phone"
        case .color: return "Color"
        case .image: return "Image"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
        case .email: return "envelope"
        case .phone: return "phone"
        case .color: return "paintpalette"
        case .image: return "photo"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .blue
        case .code: return .purple
        case .link: return .green
        case .email: return .orange
        case .phone: return .pink
        case .color: return .red
        case .image: return .cyan
        }
    }
}

// MARK: - Main Content View (Enhanced with AI features)
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItemEntity.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<ClipboardItemEntity>
    
    @State private var searchText = ""
    @State private var selectedCategory: ClipboardCategory?
    @State private var showingSettings = false
    @State private var selectedItem: ClipboardItemEntity?
    @State private var showingAIPanel = false
    @State private var searchMode: SearchMode = .hybrid
    @State private var selectedTag: String?
    @State private var showingTagSheet = false
    @ObservedObject private var settings = SettingsManager.shared
    private let smartSearch = SmartSearchEngine.shared
    private let contextDetector = ContextDetector.shared

    // License management
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showUpgradePrompt = false
    @State private var upgradeFeature = "Pro Features"

    var filteredItems: [ClipboardItemEntity] {
        var filtered = Array(items)

        // Apply smart search if text is entered
        if !searchText.isEmpty && settings.enableSemanticSearch {
            let searchResults = smartSearch.search(query: searchText, in: filtered, mode: searchMode)
            filtered = searchResults.map { $0.item }
        } else if !searchText.isEmpty {
            // Fallback to keyword search if semantic disabled
            filtered = filtered.filter { item in
                let content = item.displayContent.localizedCaseInsensitiveContains(searchText)
                let ocr = (item.ocrText ?? "").localizedCaseInsensitiveContains(searchText)
                return content || ocr
            }
        }

        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.clipboardCategory == category }
        }

        // Apply tag filter
        if let tag = selectedTag {
            filtered = filtered.filter { $0.projectTag == tag }
        }

        // Sort by context score if no search
        if searchText.isEmpty && settings.enableSemanticSearch {
            filtered = filtered.sorted { ($0.contextScore) > ($1.contextScore) }
        }

        return filtered
    }

    var availableTags: [String] {
        let tags = items.compactMap { $0.projectTag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Clipboard Manager")
                        .font(.headline)
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingSettings) {
                        SettingsView()
                            .frame(width: 400, height: 500)
                    }
                    
                    Text("\(items.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search (includes OCR text)...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

                // Search mode picker (only show when semantic search enabled and searching)
                if settings.enableSemanticSearch && !searchText.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: searchMode == .semantic ? "brain" : searchMode == .keyword ? "text.magnifyingglass" : "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Search Mode", selection: $searchMode) {
                            Text("Keyword").tag(SearchMode.keyword)

                            if licenseManager.canUseSemanticSearch() {
                                Text("Semantic").tag(SearchMode.semantic)
                                Text("Smart").tag(SearchMode.hybrid)
                            } else {
                                Text("Semantic 🔒").tag(SearchMode.semantic)
                                Text("Smart 🔒").tag(SearchMode.hybrid)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: searchMode) { newMode in
                            if (newMode == .semantic || newMode == .hybrid) &&
                               !licenseManager.canUseSemanticSearch() {
                                upgradeFeature = "AI Semantic Search"
                                showUpgradePrompt = true
                                searchMode = .keyword
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }

                // Project tags (if any exist)
                if !availableTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            ForEach(availableTags, id: \.self) { tag in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTag = selectedTag == tag ? nil : tag
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        if selectedTag == tag {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(selectedTag == tag ? tagColor(for: tag) : tagColor(for: tag).opacity(0.15))
                                    )
                                    .foregroundColor(selectedTag == tag ? .white : tagColor(for: tag))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 4)
                }

                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryButton(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(ClipboardCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.displayName,
                                icon: category.icon,
                                color: category.color,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Items list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history yet" : "No results found")
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Copy something to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Results count header
                HStack {
                    Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !searchText.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 3) {
                            Image(systemName: searchMode == .semantic ? "brain" : searchMode == .keyword ? "text.magnifyingglass" : "sparkles")
                                .font(.caption2)
                            Text(searchMode == .hybrid ? "Smart Search" : searchMode == .semantic ? "Semantic" : "Keyword")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardItemRow(item: item, settings: settings)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                                .animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.02), value: filteredItems.count)
                                .contextMenu {
                                    Button("Copy") {
                                        copyToClipboard(item, smart: false)
                                    }
                                    
                                    if settings.enableSmartPaste {
                                        Button("Smart Paste") {
                                            copyToClipboard(item, smart: true)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Menu("AI Actions") {
                                        Button("Summarize") {
                                            selectedItem = item
                                            showAISummary(item)
                                        }
                                        Button("Extract To-Dos") {
                                            selectedItem = item
                                            showActionItems(item)
                                        }
                                        Button("Fix Grammar") {
                                            selectedItem = item
                                            fixGrammar(item)
                                        }
                                    }

                                    if settings.enableSemanticSearch {
                                        Divider()

                                        Menu("Tag as...") {
                                            // Show suggested tags
                                            let suggestions = contextDetector.suggestProjectTags(for: item, basedOn: Array(items))
                                            if !suggestions.isEmpty {
                                                ForEach(suggestions.prefix(3)) { suggestion in
                                                    Button("\(suggestion.tag) (\(suggestion.confidencePercent)%)") {
                                                        setTag(for: item, tag: suggestion.tag)
                                                    }
                                                }
                                                Divider()
                                            }

                                            // Show existing tags
                                            ForEach(availableTags, id: \.self) { tag in
                                                Button(tag) {
                                                    setTag(for: item, tag: tag)
                                                }
                                            }

                                            Divider()

                                            Button("New Tag...") {
                                                selectedItem = item
                                                showingTagSheet = true
                                            }

                                            if item.projectTag != nil {
                                                Button("Remove Tag") {
                                                    removeTag(from: item)
                                                }
                                            }
                                        }
                                    }

                                    Divider()

                                    Button("Delete") {
                                        deleteItem(item)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingTagSheet) {
            if let item = selectedItem {
                TagInputSheet(item: item, onSave: { tag in
                    setTag(for: item, tag: tag)
                    showingTagSheet = false
                })
            }
        }
        .sheet(isPresented: $showUpgradePrompt) {
            ProUpgradePromptView(feature: upgradeFeature)
        }
    }

    private func copyToClipboard(_ item: ClipboardItemEntity, smart: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let image = item.displayImage {
            pasteboard.writeObjects([image])
        } else {
            var content = item.displayContent
            
            if smart, let app = NSWorkspace.shared.frontmostApplication?.localizedName {
                content = SmartPasteEngine.shared.transform(
                    content: content,
                    targetApp: app,
                    category: item.clipboardCategory
                )
            }
            
            pasteboard.setString(content, forType: .string)
        }
    }
    
    private func deleteItem(_ item: ClipboardItemEntity) {
        viewContext.delete(item)
        PersistenceController.shared.save()
    }
    
    private func showAISummary(_ item: ClipboardItemEntity) {
        let summary = AIClipboardAssistant.shared.summarize(item.displayContent)
        let alert = NSAlert()
        alert.messageText = "Summary"
        alert.informativeText = summary
        alert.addButton(withTitle: "Copy Summary")
        alert.addButton(withTitle: "Close")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(summary, forType: .string)
        }
    }
    
    private func showActionItems(_ item: ClipboardItemEntity) {
        let items = AIClipboardAssistant.shared.extractActionItems(item.displayContent)
        let alert = NSAlert()
        alert.messageText = "Action Items Found"
        alert.informativeText = items.isEmpty ? "No action items detected" : items.joined(separator: "\n\n")
        alert.addButton(withTitle: "Copy Items")
        alert.addButton(withTitle: "Close")
        
        if alert.runModal() == .alertFirstButtonReturn && !items.isEmpty {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(items.joined(separator: "\n"), forType: .string)
        }
    }
    
    private func fixGrammar(_ item: ClipboardItemEntity) {
        let fixed = AIClipboardAssistant.shared.fixGrammar(item.displayContent)
        let alert = NSAlert()
        alert.messageText = "Grammar Fixed"
        alert.informativeText = fixed
        alert.addButton(withTitle: "Copy Fixed Version")
        alert.addButton(withTitle: "Close")

        if alert.runModal() == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fixed, forType: .string)
        }
    }

    private func setTag(for item: ClipboardItemEntity, tag: String) {
        item.projectTag = tag
        PersistenceController.shared.save()
        print("✅ Tagged item \(item.id) with: \(tag)")
    }

    private func removeTag(from item: ClipboardItemEntity) {
        item.projectTag = nil
        PersistenceController.shared.save()
        print("✅ Removed tag from item \(item.id)")
    }

    private func tagColor(for tag: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .indigo, .teal]
        let hash = abs(tag.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Tag Input Sheet
struct TagInputSheet: View {
    let item: ClipboardItemEntity
    let onSave: (String) -> Void
    @State private var tagName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Project Tag")
                .font(.headline)

            TextField("Tag name (e.g., \"Auth Feature\")", text: $tagName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    if !tagName.isEmpty {
                        onSave(tagName)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(tagName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

// MARK: - Settings View (Enhanced)
struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var newExcludedApp = ""
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showLicenseActivation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // License status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("License")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            if licenseManager.isProUser {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("✓ Pro License Active")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    if let email = licenseManager.licenseEmail {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(licenseManager.licenseType.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Deactivate") {
                                    licenseManager.deactivateLicense()
                                }
                                .foregroundColor(.red)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Free Plan")
                                        .font(.headline)
                                    Text("250 items • 30-day retention • Keyword search")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Upgrade to Pro") {
                                    licenseManager.purchaseLifetime()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        Button("Activate License...") {
                            showLicenseActivation = true
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // History settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History Retention")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("Keep items for:")
                            Stepper("\(settings.retentionDays) days", value: $settings.retentionDays, in: 1...365)
                        }
                        
                        HStack {
                            Text("Maximum items:")
                            Stepper("\(settings.maxItems)", value: $settings.maxItems, in: 50...1000, step: 50)
                        }
                    }
                    
                    Divider()
                    
                    // Security settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Security")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Toggle("Enable encryption", isOn: $settings.enableEncryption)
                        
                        Text("When enabled, clipboard content is encrypted using AES-256")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // AI Features
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Features")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Toggle("Enable OCR for screenshots", isOn: $settings.enableOCR)
                        Text("Automatically extract text from images")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle("Enable Smart Paste", isOn: $settings.enableSmartPaste)
                        Text("Auto-format content based on target app")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Toggle("Enable Semantic Search & Context Detection", isOn: $settings.enableSemanticSearch)
                        Text("AI-powered search and project context detection")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if settings.enableSemanticSearch {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Auto-detect Projects", isOn: $settings.enableAutoProjects)
                                    .padding(.leading, 20)
                                Text("Group clipboard items by app patterns and time windows")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 20)

                                HStack {
                                    Text("Context Window:")
                                        .padding(.leading, 20)
                                    Stepper("\(settings.contextWindowMinutes) minutes", value: $settings.contextWindowMinutes, in: 15...120, step: 15)
                                }

                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Similarity Threshold:")
                                            .padding(.leading, 20)
                                        Spacer()
                                        Text(String(format: "%.2f", settings.similarityThreshold))
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: $settings.similarityThreshold, in: 0.5...0.95, step: 0.05)
                                        .padding(.leading, 20)
                                    Text("Higher values = stricter matching")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 20)
                                }

                                Button("Rebuild Embeddings") {
                                    rebuildEmbeddings()
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Excluded apps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Excluded Applications")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Clipboard won't monitor these apps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("App name", text: $newExcludedApp)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Add") {
                                if !newExcludedApp.isEmpty {
                                    settings.excludedApps.insert(newExcludedApp)
                                    newExcludedApp = ""
                                }
                            }
                            .disabled(newExcludedApp.isEmpty)
                        }
                        
                        if !SettingsManager.suggestedExclusions.allSatisfy({ settings.excludedApps.contains($0) }) {
                            Text("Suggested:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 6) {
                                ForEach(SettingsManager.suggestedExclusions, id: \.self) { app in
                                    if !settings.excludedApps.contains(app) {
                                        Button(action: { settings.excludedApps.insert(app) }) {
                                            HStack(spacing: 4) {
                                                Text(app)
                                                    .font(.caption)
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        if !settings.excludedApps.isEmpty {
                            Text("Currently excluded:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                            
                            FlowLayout(spacing: 6) {
                                ForEach(Array(settings.excludedApps).sorted(), id: \.self) { app in
                                    HStack(spacing: 4) {
                                        Text(app)
                                            .font(.caption)
                                        Button(action: { settings.excludedApps.remove(app) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyboard Shortcut")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("⌘ ⇧ V")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            
                            Text("to open clipboard manager")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showLicenseActivation) {
            LicenseActivationView()
        }
    }

    private func rebuildEmbeddings() {
        let context = PersistenceController.shared.container.viewContext
        EmbeddingProcessor.shared.processExistingItems(context: context)

        let alert = NSAlert()
        alert.messageText = "Rebuilding Embeddings"
        alert.informativeText = "Processing embeddings in the background. This may take a few moments."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let icon: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clipboard Item Row (Enhanced)
struct ClipboardItemRow: View {
    let item: ClipboardItemEntity
    let settings: SettingsManager
    @State private var isHovered = false

    private var contextScorePercent: Int {
        Int(item.contextScore * 100)
    }

    private var contextScoreColor: Color {
        switch item.contextScore {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .gray
        }
    }

    private var hasRelatedItems: Bool {
        item.relatedItemIDs != nil && !item.relatedItemIDs!.isEmpty
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon with context score indicator
            ZStack(alignment: .topTrailing) {
                Image(systemName: item.clipboardCategory.icon)
                    .font(.title3)
                    .foregroundColor(item.clipboardCategory.color)
                    .frame(width: 24)

                // Context score badge (only if semantic search enabled)
                if settings.enableSemanticSearch && item.contextScore > 0.3 {
                    Circle()
                        .fill(contextScoreColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let image = item.displayImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 100)
                        .cornerRadius(4)
                    
                    if let ocrText = item.ocrText, !ocrText.isEmpty {
                        Text("OCR: \(ocrText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    Text(item.displayContent)
                        .lineLimit(3)
                        .font(.system(.body, design: item.clipboardCategory == .code ? .monospaced : .default))
                        .foregroundColor(.primary)
                }

                // Project tag (if exists)
                if let tag = item.projectTag, !tag.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tagColor(for: tag).opacity(0.15))
                    .foregroundColor(tagColor(for: tag))
                    .cornerRadius(6)
                }

                // Metadata row
                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 3) {
                        Image(systemName: item.clipboardCategory.icon)
                            .font(.caption2)
                        Text(item.clipboardCategory.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.clipboardCategory.color.opacity(0.1))
                    .foregroundColor(item.clipboardCategory.color)
                    .cornerRadius(4)

                    if let app = item.sourceApp {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(app)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Indicators
                    if item.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .help("Encrypted")
                    }

                    if item.ocrText != nil {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .help("OCR Text Available")
                    }

                    if hasRelatedItems && settings.enableSemanticSearch {
                        Image(systemName: "link.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .help("Has Related Items")
                    }

                    Spacer()

                    // Context score (on hover)
                    if isHovered && settings.enableSemanticSearch && item.contextScore > 0 {
                        Text("\(contextScorePercent)%")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(contextScoreColor)
                            .help("Context Relevance Score")
                    }

                    Text(timeAgo(from: item.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isHovered {
                VStack(spacing: 4) {
                    Button(action: {
                        copyToClipboard(item, smart: false)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Copy")
                    
                    if settings.enableSmartPaste {
                        Button(action: {
                            copyToClipboard(item, smart: true)
                        }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                        }
                        .buttonStyle(.plain)
                        .help("Smart Paste")
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.blue.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .onTapGesture {
            copyToClipboard(item, smart: false)
        }
    }

    // Generate consistent color for tags
    private func tagColor(for tag: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .indigo, .teal]
        let hash = abs(tag.hashValue)
        return colors[hash % colors.count]
    }
    
    private func copyToClipboard(_ item: ClipboardItemEntity, smart: Bool) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let image = item.displayImage {
            pasteboard.writeObjects([image])
        } else {
            var content = item.displayContent
            
            if smart, let app = NSWorkspace.shared.frontmostApplication?.localizedName {
                content = SmartPasteEngine.shared.transform(
                    content: content,
                    targetApp: app,
                    category: item.clipboardCategory
                )
            }
            
            pasteboard.setString(content, forType: .string)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
