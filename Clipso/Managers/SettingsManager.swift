import Foundation
import Combine

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
