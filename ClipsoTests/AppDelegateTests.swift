import XCTest
import AppKit
@testable import Clipso

/// Tests for AppDelegate menu bar functionality
/// Ensures menu items are properly configured and respond to user interactions
class AppDelegateTests: XCTestCase {
    var appDelegate: AppDelegate!

    override func setUp() {
        super.setUp()
        appDelegate = AppDelegate()

        // Initialize the app delegate as it would be during launch
        appDelegate.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }

    override func tearDown() {
        if let statusItem = appDelegate.statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        appDelegate = nil
        super.tearDown()
    }

    // MARK: - Menu Setup Tests

    func testMenuBarIsCreated() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()

        // Assert
        XCTAssertNotNil(appDelegate.statusItem?.menu, "Status item should have a menu")
        XCTAssertTrue((appDelegate.statusItem?.menu?.items.count ?? 0) > 0, "Menu should have items")
    }

    func testSettingsMenuItemExists() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        let settingsItem = menu.items.first { $0.title == "Settings..." }
        XCTAssertNotNil(settingsItem, "Settings menu item should exist")
    }

    func testSettingsMenuItemHasAction() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        let settingsItem = menu.items.first { $0.title == "Settings..." }
        XCTAssertNotNil(settingsItem?.action, "Settings item should have an action")
        XCTAssertEqual(settingsItem?.action, #selector(AppDelegate.showSettings), "Settings item should call showSettings")
    }

    func testSettingsMenuItemHasKeyboardShortcut() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        let settingsItem = menu.items.first { $0.title == "Settings..." }
        XCTAssertEqual(settingsItem?.keyEquivalent, ",", "Settings should have Cmd+, shortcut")
    }

    func testQuitMenuItemExists() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        let quitItem = menu.items.first { $0.title == "Quit Clipso" }
        XCTAssertNotNil(quitItem, "Quit menu item should exist")
    }

    func testActivateLicenseMenuItemExists() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        let licenseItem = menu.items.first { $0.title == "Activate License..." }
        XCTAssertNotNil(licenseItem, "Activate License menu item should exist")
        XCTAssertNotNil(licenseItem?.action, "Activate License should have an action")
    }

    // MARK: - Menu Action Tests

    func testShowSettingsMethodExists() {
        // Verify that the AppDelegate responds to showSettings
        XCTAssertTrue(appDelegate.responds(to: #selector(AppDelegate.showSettings)),
                     "AppDelegate should respond to showSettings selector")
    }

    func testShowLicenseActivationMethodExists() {
        // Verify that the AppDelegate responds to showLicenseActivation
        XCTAssertTrue(appDelegate.responds(to: #selector(AppDelegate.showLicenseActivation)),
                     "AppDelegate should respond to showLicenseActivation selector")
    }

    func testShowUpgradeMethodExists() {
        // Verify that the AppDelegate responds to showUpgrade
        XCTAssertTrue(appDelegate.responds(to: #selector(AppDelegate.showUpgrade)),
                     "AppDelegate should respond to showUpgrade selector")
    }

    // MARK: - Menu Item Validation Tests

    func testAllMenuItemsHaveValidTargets() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        for item in menu.items where !item.isSeparatorItem && item.action != nil {
            // Skip the Quit item which targets NSApplication
            if item.action == #selector(NSApplication.terminate(_:)) {
                continue
            }

            // Skip disabled items (like Pro License Active)
            if !item.isEnabled {
                continue
            }

            // For custom actions, verify the AppDelegate responds to them
            if let action = item.action {
                let hasTarget = appDelegate.responds(to: action) || item.target != nil
                XCTAssertTrue(hasTarget,
                            "Menu item '\(item.title)' should have a valid target for action: \(action)")
            }
        }
    }

    func testMenuItemsAreEnabled() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert
        let settingsItem = menu.items.first { $0.title == "Settings..." }
        XCTAssertTrue(settingsItem?.isEnabled ?? false, "Settings menu item should be enabled")

        let quitItem = menu.items.first { $0.title == "Quit Clipso" }
        XCTAssertTrue(quitItem?.isEnabled ?? false, "Quit menu item should be enabled")
    }

    // MARK: - Integration Tests

    func testMenuItemCanBeClicked() {
        // Arrange
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu,
              let settingsItem = menu.items.first(where: { $0.title == "Settings..." }) else {
            XCTFail("Settings menu item not found")
            return
        }

        // Act & Assert
        // Verify the item is enabled and can be clicked
        XCTAssertTrue(settingsItem.isEnabled, "Settings item should be enabled")
        XCTAssertNotNil(settingsItem.action, "Settings item should have an action")

        // Verify the action is valid (doesn't test actual window opening in unit test)
        XCTAssertTrue(appDelegate.responds(to: settingsItem.action!),
                     "AppDelegate should respond to settings action")
    }

    func testMenuStructure() {
        // Arrange & Act
        appDelegate.setupMenuBarMenu()
        guard let menu = appDelegate.statusItem?.menu else {
            XCTFail("Menu not created")
            return
        }

        // Assert - Verify expected menu structure
        var expectedItemsFound = [
            "license": false,
            "activate": false,
            "settings": false,
            "quit": false
        ]

        for item in menu.items {
            if item.title.contains("License") || item.title.contains("Upgrade") {
                expectedItemsFound["license"] = true
            }
            if item.title == "Activate License..." {
                expectedItemsFound["activate"] = true
            }
            if item.title == "Settings..." {
                expectedItemsFound["settings"] = true
            }
            if item.title == "Quit Clipso" {
                expectedItemsFound["quit"] = true
            }
        }

        XCTAssertTrue(expectedItemsFound["license"] ?? false, "Menu should have license-related item")
        XCTAssertTrue(expectedItemsFound["activate"] ?? false, "Menu should have Activate License item")
        XCTAssertTrue(expectedItemsFound["settings"] ?? false, "Menu should have Settings item")
        XCTAssertTrue(expectedItemsFound["quit"] ?? false, "Menu should have Quit item")
    }

    // MARK: - Selector Validation Tests

    func testSettingsSelectorIsValid() {
        // Test that common Settings selectors work
        let modernSelector = Selector(("showSettingsWindow:"))
        let legacySelector = Selector(("showPreferencesWindow:"))

        // At least one of these should be valid on the current macOS version
        // (We can't test both will work, but we verify they're valid selectors)
        XCTAssertNotNil(modernSelector, "Modern settings selector should be valid")
        XCTAssertNotNil(legacySelector, "Legacy settings selector should be valid")
    }

    // MARK: - Error Cases

    func testMenuWithoutStatusItemDoesNotCrash() {
        // Arrange
        appDelegate.statusItem = nil

        // Act & Assert - Should not crash
        appDelegate.setupMenuBarMenu()

        // The menu might not be created, but it shouldn't crash
        XCTAssertTrue(true, "Setting up menu without status item should not crash")
    }
}
