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
struct ClipboardManagerApp: App {
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
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
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
    
    init() {
        self.retentionDays = UserDefaults.standard.object(forKey: "retentionDays") as? Int ?? 30
        self.maxItems = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 100
        
        let savedApps = UserDefaults.standard.array(forKey: "excludedApps") as? [String] ?? []
        self.excludedApps = Set(savedApps)
        
        self.enableEncryption = UserDefaults.standard.bool(forKey: "enableEncryption")
        self.enableOCR = UserDefaults.standard.object(forKey: "enableOCR") as? Bool ?? true
        self.enableSmartPaste = UserDefaults.standard.object(forKey: "enableSmartPaste") as? Bool ?? true
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
        lastChangeCount = pasteboard.changeCount
        print("📋 Clipboard monitoring started. Initial change count: \(lastChangeCount)")
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        
        // Ensure timer is added to the run loop
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        cleanupOldItems()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            print("📋 Clipboard changed! Count: \(lastChangeCount) → \(currentChangeCount)")
            lastChangeCount = currentChangeCount
            
            if let frontmostApp = NSWorkspace.shared.frontmostApplication?.localizedName {
                print("📱 Current app: \(frontmostApp)")
                if settings.excludedApps.contains(frontmostApp) {
                    print("⏭️ Skipping - app is excluded")
                    return
                }
            }
            
            captureClipboardContent()
        }
    }
    
    private func captureClipboardContent() {
        let types = pasteboard.types ?? []
        print("📋 Available pasteboard types: \(types)")
        
        var content = ""
        var itemType: Int16 = 0
        var category: Int16 = 0
        var imageData: Data?
        var image: NSImage?
        
        if types.contains(.string), let text = pasteboard.string(forType: .string) {
            content = text
            itemType = 0
            category = Int16(categorizeText(text).rawValue)
            print("✅ Captured text: \(content.prefix(50))...")
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
            print("✅ Captured image")
        } else if types.contains(.URL), let url = pasteboard.string(forType: .URL) {
            content = url
            itemType = 2
            category = Int16(ClipboardCategory.link.rawValue)
            print("✅ Captured URL: \(content)")
        } else {
            print("⚠️ No supported content type found")
        }
        
        if !content.isEmpty {
            let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "content == %@", content)
            fetchRequest.fetchLimit = 1
            
            do {
                let existingItems = try context.fetch(fetchRequest)
                if existingItems.isEmpty {
                    print("💾 Saving new clipboard item...")
                    
                    let item = ClipboardItemEntity(context: context)
                    item.id = UUID()
                    item.timestamp = Date()
                    item.type = itemType
                    item.category = category
                    item.imageData = imageData
                    
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
                    
                    PersistenceController.shared.save()
                    enforceItemLimit()
                    print("✅ Clipboard item saved successfully")
                } else {
                    print("⏭️ Duplicate content - skipping")
                }
            } catch {
                print("❌ Failed to check duplicates: \(error.localizedDescription)")
            }
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
            if items.count > settings.maxItems {
                let itemsToDelete = items.suffix(from: settings.maxItems)
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
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -settings.retentionDays, to: Date())!
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
    @ObservedObject private var settings = SettingsManager.shared
    
    var filteredItems: [ClipboardItemEntity] {
        var filtered = Array(items)
        
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                let content = item.displayContent.localizedCaseInsensitiveContains(searchText)
                let ocr = (item.ocrText ?? "").localizedCaseInsensitiveContains(searchText)
                return content || ocr
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.clipboardCategory == category }
        }
        
        return filtered
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
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredItems, id: \.id) { item in
                            ClipboardItemRow(item: item, settings: settings)
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
}

// MARK: - Settings View (Enhanced)
struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var newExcludedApp = ""
    
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.clipboardCategory.icon)
                .font(.title3)
                .foregroundColor(item.clipboardCategory.color)
                .frame(width: 24)
            
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
                }
                
                HStack(spacing: 8) {
                    Text(item.clipboardCategory.displayName)
                        .font(.caption2)
                        .foregroundColor(item.clipboardCategory.color)
                    
                    if let app = item.sourceApp {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(app)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if item.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    if item.ocrText != nil {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
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
        .background(isHovered ? Color.blue.opacity(0.05) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            copyToClipboard(item, smart: false)
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
