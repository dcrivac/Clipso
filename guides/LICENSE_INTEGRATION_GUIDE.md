# LicenseManager Integration Guide

This guide shows you exactly where to add code to integrate the freemium licensing system into Clipso.

## Overview

We'll integrate LicenseManager into:
1. **AppDelegate** - Add license menu items
2. **ContentView** - Gate AI features with upgrade prompts
3. **SettingsManager** - Apply item/retention limits
4. **ClipboardMonitor** - Enforce freemium restrictions

---

## Step 1: Update AppDelegate (Add License Menu Items)

### Location: `ClipsoApp.swift` - Line ~36-80 (in `applicationDidFinishLaunching`)

### Add this code AFTER creating the popover (around line 59):

```swift
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

    // 🆕 ADD LICENSE MENU
    setupMenuBarMenu()

    // ... rest of existing code ...
}

// 🆕 ADD THIS NEW METHOD at the end of AppDelegate class
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
```

**Important:** After adding the menu, you need to change how the status button works:
- Remove: `button.action = #selector(togglePopover)`
- Add right-click for menu: The menu will show on left-click now
- To keep Cmd+Shift+V working, the global shortcut handles popover toggle

---

## Step 2: Update ContentView (Gate AI Features)

### Location: `ClipsoApp.swift` - Line ~1609 (ContentView struct)

### Add LicenseManager and state variables at the top of ContentView:

```swift
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItemEntity.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<ClipboardItemEntity>

    // 🆕 ADD THESE
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showUpgradePrompt = false
    @State private var upgradeFeature = "Pro Features"

    // ... rest of existing state variables ...
```

### Find the search mode toggle (around line ~1650) and update it:

```swift
// Search mode selector (existing code, update it)
Picker("Search Mode", selection: $searchMode) {
    Text("Keyword").tag(SearchMode.keyword)

    // 🆕 ADD PRO BADGE
    if licenseManager.canUseSemanticSearch() {
        Text("Semantic").tag(SearchMode.semantic)
        Text("Hybrid").tag(SearchMode.hybrid)
    } else {
        Text("Semantic 🔒 Pro").tag(SearchMode.semantic)
        Text("Hybrid 🔒 Pro").tag(SearchMode.hybrid)
    }
}
.pickerStyle(.segmented)
.disabled(!licenseManager.canUseSemanticSearch() &&
          (searchMode == .semantic || searchMode == .hybrid))
.onChange(of: searchMode) { newMode in
    // 🆕 CHECK LICENSE
    if (newMode == .semantic || newMode == .hybrid) &&
       !licenseManager.canUseSemanticSearch() {
        upgradeFeature = "AI Semantic Search"
        showUpgradePrompt = true
        searchMode = .keyword
    }
}
```

### Add the upgrade prompt sheet at the end of ContentView body:

```swift
var body: some View {
    VStack {
        // ... all existing UI ...
    }
    // 🆕 ADD THIS SHEET
    .sheet(isPresented: $showUpgradePrompt) {
        ProUpgradePromptView(feature: upgradeFeature)
    }
}
```

---

## Step 3: Update SettingsManager (Apply Limits)

### Location: `ClipsoApp.swift` - Line ~287 (SettingsManager class)

### Update the computed properties to respect license limits:

```swift
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var retentionDays: Int {
        didSet { UserDefaults.standard.set(retentionDays, forKey: "retentionDays") }
    }

    @Published var maxItems: Int {
        didSet { UserDefaults.standard.set(maxItems, forKey: "maxItems") }
    }

    // ... other properties ...

    // 🆕 ADD THESE COMPUTED PROPERTIES
    var effectiveRetentionDays: Int {
        let licensedMax = LicenseManager.shared.getMaxRetentionDays()
        return min(retentionDays, licensedMax)
    }

    var effectiveMaxItems: Int {
        let licensedMax = LicenseManager.shared.getMaxItems()
        return min(maxItems, licensedMax)
    }

    // ... rest of class ...
}
```

---

## Step 4: Update ClipboardMonitor (Enforce Limits)

### Location: `ClipsoApp.swift` - Find ClipboardMonitor class (~line 506)

### Find the `clipboardChanged()` method and add limit enforcement:

```swift
private func clipboardChanged() {
    // ... existing clipboard detection code ...

    // 🆕 ADD LIMIT CHECK BEFORE SAVING
    let settings = SettingsManager.shared
    let maxItems = settings.effectiveMaxItems

    // Count current items
    let fetchRequest: NSFetchRequest<ClipboardItemEntity> = ClipboardItemEntity.fetchRequest()
    let currentCount = (try? context.count(for: fetchRequest)) ?? 0

    if currentCount >= maxItems {
        print("⚠️ Hit item limit (\(maxItems)). Upgrade to Pro for unlimited.")
        // Optionally: Show notification or alert
        // For now, just prevent saving
        return
    }

    // ... continue with saving clipboard item ...
}
```

### Update the cleanup method to use effective retention:

```swift
private func cleanupOldItems() {
    let settings = SettingsManager.shared
    let retentionDays = settings.effectiveRetentionDays // 🆕 USE EFFECTIVE

    // ... rest of existing cleanup logic ...
}

private func enforceItemLimit() {
    let settings = SettingsManager.shared
    let maxItems = settings.effectiveMaxItems // 🆕 USE EFFECTIVE

    // ... rest of existing limit enforcement logic ...
}
```

---

## Step 5: Update SettingsView (Show License Status)

### Location: `ClipsoApp.swift` - Find SettingsView (~line 984)

### Add license status section at the top of settings:

```swift
struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var licenseManager = LicenseManager.shared // 🆕 ADD THIS
    @State private var showLicenseActivation = false // 🆕 ADD THIS

    var body: some View {
        Form {
            // 🆕 ADD LICENSE STATUS SECTION
            Section(header: Text("License")) {
                HStack {
                    if licenseManager.isProUser {
                        VStack(alignment: .leading) {
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
                        VStack(alignment: .leading) {
                            Text("Free Plan")
                                .font(.headline)
                            Text("250 items • 30-day retention")
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

            // ... existing settings sections ...
        }
        .sheet(isPresented: $showLicenseActivation) {
            LicenseActivationView()
        }
    }
}
```

---

## Step 6: Add Pro Feature Indicators

### Update History Retention Section in SettingsView:

```swift
Section(header: Text("History")) {
    HStack {
        Text("Retention: \(settings.retentionDays) days")
        if !licenseManager.isProUser && settings.retentionDays > 30 {
            Text("(Limited to 30 days on Free)")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    Slider(value: .init(
        get: { Double(settings.retentionDays) },
        set: { settings.retentionDays = Int($0) }
    ), in: 1...365, step: 1)
    .disabled(!licenseManager.isProUser && settings.retentionDays > 30)

    HStack {
        Text("Max items: \(settings.maxItems)")
        if !licenseManager.isProUser && settings.maxItems > 250 {
            Text("(Limited to 250 on Free)")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    Slider(value: .init(
        get: { Double(settings.maxItems) },
        set: { settings.maxItems = Int($0) }
    ), in: 50...1000, step: 50)
    .disabled(!licenseManager.isProUser && settings.maxItems > 250)
}
```

---

## Testing Checklist

After integration, test these scenarios:

### Free User Experience:
- [ ] App shows "Free Plan" in settings
- [ ] Semantic/Hybrid search modes show 🔒 Pro badge
- [ ] Clicking locked search mode shows upgrade prompt
- [ ] Can only store up to 250 items
- [ ] Items older than 30 days are deleted
- [ ] Menu bar shows "Upgrade to Pro..." option

### Pro User Experience (After Activation):
- [ ] Settings show "Pro License Active"
- [ ] All search modes available
- [ ] No item limit
- [ ] No retention limit
- [ ] Menu bar shows "✓ Pro License Active"
- [ ] License persists after app restart

### License Activation:
- [ ] "Activate License..." opens activation window
- [ ] Can enter email and license key
- [ ] Invalid key shows error
- [ ] Valid key activates Pro features immediately
- [ ] License stored in Keychain securely

---

## Summary of Changes

**Files Modified:**
1. `ClipsoApp.swift` - Added license menu, feature gating, limits

**New Files:**
1. `LicenseManager.swift` - License validation and feature gating

**Key Integration Points:**
- ✅ AppDelegate: License menu items
- ✅ ContentView: AI feature gating with upgrade prompts
- ✅ SettingsManager: Effective limits based on license
- ✅ ClipboardMonitor: Enforce item/retention limits
- ✅ SettingsView: License status display

**Freemium Restrictions:**
- Free: 250 items, 30 days, keyword search only
- Pro: Unlimited items, unlimited retention, AI features

---

## Next Steps

1. Add LicenseManager.swift to Xcode project ✅ (in progress)
2. Apply these code changes to ClipsoApp.swift
3. Build and test (⌘B)
4. Test free user flow
5. Get Paddle credentials and test checkout
6. Test license activation
7. Launch! 🚀
