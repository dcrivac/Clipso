import SwiftUI
import AppKit
import CoreData
import Carbon

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
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    var eventMonitor: Any?

    // Retain windows to prevent deallocation
    var settingsWindow: NSWindow?
    var licenseWindow: NSWindow?

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
        // If window already exists, bring it to front
        if let existingWindow = licenseWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window and retain it
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Activate License"
        window.delegate = self
        window.contentView = NSHostingController(rootView: LicenseActivationView()).view
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Retain window to prevent deallocation
        licenseWindow = window
    }

    @objc private func showSettings() {
        // Try the modern macOS 13+ selector first (with safety check)
        let modernSelector = Selector(("showSettingsWindow:"))
        if NSApp.responds(to: modernSelector) {
            if NSApp.sendAction(modernSelector, to: nil, from: nil) {
                return
            }
        }

        // Fall back to the older selector for macOS 12 and earlier (with safety check)
        let legacySelector = Selector(("showPreferencesWindow:"))
        if NSApp.responds(to: legacySelector) {
            if NSApp.sendAction(legacySelector, to: nil, from: nil) {
                return
            }
        }

        // If custom window already exists, bring it to front
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // If neither selector worked, open a custom settings window
        print("⚠️ Native settings selectors not available, using custom window")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Settings"
        window.delegate = self
        window.contentView = NSHostingController(
            rootView: SettingsView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        ).view
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Retain window to prevent deallocation
        settingsWindow = window
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Clean up window references when windows are closed
        if let window = notification.object as? NSWindow {
            if window == settingsWindow {
                settingsWindow = nil
            } else if window == licenseWindow {
                licenseWindow = nil
            }
        }
    }
}
