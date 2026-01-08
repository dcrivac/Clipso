// ============================================================
// INTEGRATION CODE SNIPPETS FOR CLIPBOARDMANAGER
// Copy these code blocks into ClipboardManagerApp.swift
// ============================================================

// ============================================================
// SNIPPET 1: Add to AppDelegate class (after line 128)
// ============================================================

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
        title: "Quit ClipboardManager",
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

// ============================================================
// SNIPPET 2: Call setupMenuBarMenu() in applicationDidFinishLaunching
// Add this line after creating the popover (around line 60)
// ============================================================
// setupMenuBarMenu()


// ============================================================
// SNIPPET 3: Add to ContentView struct (after existing @State variables)
// ============================================================
@StateObject private var licenseManager = LicenseManager.shared
@State private var showUpgradePrompt = false
@State private var upgradeFeature = "Pro Features"


// ============================================================
// SNIPPET 4: Replace search mode onChange handler in ContentView
// Find the Picker("Search Mode", ...) and update its onChange:
// ============================================================
.onChange(of: searchMode) { newMode in
    if (newMode == .semantic || newMode == .hybrid) &&
       !licenseManager.canUseSemanticSearch() {
        upgradeFeature = "AI Semantic Search"
        showUpgradePrompt = true
        searchMode = .keyword
    }
}


// ============================================================
// SNIPPET 5: Update search mode picker labels in ContentView
// Replace the Picker content:
// ============================================================
Picker("Search Mode", selection: $searchMode) {
    Text("Keyword").tag(SearchMode.keyword)

    if licenseManager.canUseSemanticSearch() {
        Text("Semantic").tag(SearchMode.semantic)
        Text("Hybrid").tag(SearchMode.hybrid)
    } else {
        Text("Semantic 🔒 Pro").tag(SearchMode.semantic)
        Text("Hybrid 🔒 Pro").tag(SearchMode.hybrid)
    }
}
.pickerStyle(.segmented)


// ============================================================
// SNIPPET 6: Add upgrade prompt sheet to ContentView body
// Add at the end of ContentView's body, after the last closing brace
// ============================================================
.sheet(isPresented: $showUpgradePrompt) {
    ProUpgradePromptView(feature: upgradeFeature)
}


// ============================================================
// SNIPPET 7: Add to SettingsManager class
// Add these computed properties:
// ============================================================
var effectiveRetentionDays: Int {
    let licensedMax = LicenseManager.shared.getMaxRetentionDays()
    return min(retentionDays, licensedMax)
}

var effectiveMaxItems: Int {
    let licensedMax = LicenseManager.shared.getMaxItems()
    return min(maxItems, licensedMax)
}


// ============================================================
// SNIPPET 8: Update ClipboardMonitor.clipboardChanged()
// Add this check BEFORE creating new clipboard items:
// ============================================================
// Check item limit
let settings = SettingsManager.shared
let maxItems = settings.effectiveMaxItems

let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
let currentCount = (try? context.count(for: fetchRequest)) ?? 0

if currentCount >= maxItems {
    print("⚠️ Hit item limit (\(maxItems)). Upgrade to Pro for unlimited.")
    return
}


// ============================================================
// SNIPPET 9: Update cleanup methods in ClipboardMonitor
// Replace retentionDays and maxItems with effective versions:
// ============================================================
// In cleanupOldItems():
let retentionDays = settings.effectiveRetentionDays  // instead of settings.retentionDays

// In enforceItemLimit():
let maxItems = settings.effectiveMaxItems  // instead of settings.maxItems


// ============================================================
// SNIPPET 10: Add to SettingsView struct (after existing @StateObject)
// ============================================================
@StateObject private var licenseManager = LicenseManager.shared
@State private var showLicenseActivation = false


// ============================================================
// SNIPPET 11: Add License section to SettingsView Form
// Add as the FIRST section in the Form:
// ============================================================
Section(header: Text("License")) {
    HStack {
        if licenseManager.isProUser {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pro License Active")
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


// ============================================================
// SNIPPET 12: Add license activation sheet to SettingsView
// Add after Form closing brace:
// ============================================================
.sheet(isPresented: $showLicenseActivation) {
    LicenseActivationView()
}


// ============================================================
// QUICK INTEGRATION CHECKLIST:
// ============================================================
// 1. ✅ Add LicenseManager.swift to Xcode project
// 2. ✅ Add SNIPPET 1 to AppDelegate class
// 3. ✅ Call setupMenuBarMenu() in applicationDidFinishLaunching (SNIPPET 2)
// 4. ✅ Add SNIPPET 3 to ContentView
// 5. ✅ Update search mode picker with SNIPPET 5
// 6. ✅ Add onChange handler SNIPPET 4
// 7. ✅ Add upgrade sheet SNIPPET 6
// 8. ✅ Add SNIPPET 7 to SettingsManager
// 9. ✅ Update ClipboardMonitor with SNIPPETS 8 & 9
// 10. ✅ Add SNIPPETS 10, 11, 12 to SettingsView
// 11. ✅ Build (⌘B) and test!
