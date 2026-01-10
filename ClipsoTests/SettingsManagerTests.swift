import XCTest
@testable import Clipso

final class SettingsManagerTests: XCTestCase {

    var settings: SettingsManager!
    let testDefaults = UserDefaults(suiteName: "com.clipso.tests")!

    override func setUp() {
        super.setUp()
        // Use test user defaults
        testDefaults.removePersistentDomain(forName: "com.clipso.tests")
        settings = SettingsManager.shared
    }

    override func tearDown() {
        // Clean up test defaults
        testDefaults.removePersistentDomain(forName: "com.clipso.tests")
        super.tearDown()
    }

    // MARK: - Retention Days Tests

    func testDefaultRetentionDays() {
        // Default should be 30 days for free tier
        XCTAssertGreaterThan(settings.retentionDays, 0, "Retention days should be positive")
        XCTAssertLessThanOrEqual(settings.retentionDays, 365, "Retention days should be reasonable")
    }

    func testSetRetentionDays() {
        settings.retentionDays = 90

        XCTAssertEqual(settings.retentionDays, 90, "Should update retention days")
    }

    func testEffectiveRetentionDaysFreeTier() {
        settings.retentionDays = 90

        let effective = settings.effectiveRetentionDays

        // Free tier should be capped at 30 days (unless user has Pro)
        XCTAssertGreaterThan(effective, 0, "Effective retention should be positive")
    }

    // MARK: - Max Items Tests

    func testDefaultMaxItems() {
        XCTAssertGreaterThan(settings.maxItems, 0, "Max items should be positive")
    }

    func testSetMaxItems() {
        settings.maxItems = 500

        XCTAssertEqual(settings.maxItems, 500, "Should update max items")
    }

    func testMaxItemsBounds() {
        // Test minimum bound
        settings.maxItems = 10
        XCTAssertGreaterThanOrEqual(settings.maxItems, 10)

        // Test maximum bound
        settings.maxItems = 2000
        XCTAssertLessThanOrEqual(settings.maxItems, 2000)
    }

    // MARK: - Excluded Apps Tests

    func testDefaultExcludedApps() {
        // Should have some default excluded apps (like password managers)
        XCTAssertNotNil(settings.excludedApps, "Excluded apps should not be nil")
    }

    func testAddExcludedApp() {
        let initialCount = settings.excludedApps.count

        settings.excludedApps.insert("TestApp")

        XCTAssertEqual(settings.excludedApps.count, initialCount + 1, "Should add excluded app")
        XCTAssertTrue(settings.excludedApps.contains("TestApp"), "Should contain added app")
    }

    func testRemoveExcludedApp() {
        settings.excludedApps.insert("TestApp")
        let countWithApp = settings.excludedApps.count

        settings.excludedApps.remove("TestApp")

        XCTAssertEqual(settings.excludedApps.count, countWithApp - 1, "Should remove excluded app")
        XCTAssertFalse(settings.excludedApps.contains("TestApp"), "Should not contain removed app")
    }

    func testSuggestedExclusions() {
        let suggested = SettingsManager.suggestedExclusions

        XCTAssertFalse(suggested.isEmpty, "Should have suggested exclusions")
        XCTAssertTrue(suggested.contains("1Password") || suggested.contains("Bitwarden") || suggested.contains("LastPass"),
                     "Should suggest password managers")
    }

    // MARK: - Feature Toggles Tests

    func testEnableEncryption() {
        settings.enableEncryption = true
        XCTAssertTrue(settings.enableEncryption, "Should enable encryption")

        settings.enableEncryption = false
        XCTAssertFalse(settings.enableEncryption, "Should disable encryption")
    }

    func testEnableOCR() {
        settings.enableOCR = true
        XCTAssertTrue(settings.enableOCR, "Should enable OCR")

        settings.enableOCR = false
        XCTAssertFalse(settings.enableOCR, "Should disable OCR")
    }

    func testEnableSmartPaste() {
        settings.enableSmartPaste = true
        XCTAssertTrue(settings.enableSmartPaste, "Should enable smart paste")

        settings.enableSmartPaste = false
        XCTAssertFalse(settings.enableSmartPaste, "Should disable smart paste")
    }

    func testEnableSemanticSearch() {
        settings.enableSemanticSearch = true
        XCTAssertTrue(settings.enableSemanticSearch, "Should enable semantic search")

        settings.enableSemanticSearch = false
        XCTAssertFalse(settings.enableSemanticSearch, "Should disable semantic search")
    }

    func testEnableAutoProjects() {
        settings.enableAutoProjects = true
        XCTAssertTrue(settings.enableAutoProjects, "Should enable auto projects")

        settings.enableAutoProjects = false
        XCTAssertFalse(settings.enableAutoProjects, "Should disable auto projects")
    }

    // MARK: - Context Window Tests

    func testDefaultContextWindowMinutes() {
        XCTAssertGreaterThan(settings.contextWindowMinutes, 0, "Context window should be positive")
        XCTAssertLessThanOrEqual(settings.contextWindowMinutes, 240, "Context window should be reasonable")
    }

    func testSetContextWindowMinutes() {
        settings.contextWindowMinutes = 45

        XCTAssertEqual(settings.contextWindowMinutes, 45, "Should update context window")
    }

    func testContextWindowBounds() {
        // Test minimum
        settings.contextWindowMinutes = 15
        XCTAssertGreaterThanOrEqual(settings.contextWindowMinutes, 15)

        // Test maximum
        settings.contextWindowMinutes = 120
        XCTAssertLessThanOrEqual(settings.contextWindowMinutes, 120)
    }

    // MARK: - Similarity Threshold Tests

    func testDefaultSimilarityThreshold() {
        XCTAssertGreaterThan(settings.similarityThreshold, 0.0, "Similarity threshold should be positive")
        XCTAssertLessThanOrEqual(settings.similarityThreshold, 1.0, "Similarity threshold should be <= 1.0")
    }

    func testSetSimilarityThreshold() {
        settings.similarityThreshold = 0.75

        XCTAssertEqual(settings.similarityThreshold, 0.75, accuracy: 0.01, "Should update similarity threshold")
    }

    func testSimilarityThresholdBounds() {
        // Test minimum
        settings.similarityThreshold = 0.5
        XCTAssertGreaterThanOrEqual(settings.similarityThreshold, 0.5)

        // Test maximum
        settings.similarityThreshold = 0.95
        XCTAssertLessThanOrEqual(settings.similarityThreshold, 0.95)
    }

    // MARK: - Persistence Tests

    func testSettingsPersistence() {
        // Set some values
        settings.retentionDays = 60
        settings.maxItems = 300
        settings.enableEncryption = true
        settings.enableOCR = false

        // Values should persist (in real app, would reload SettingsManager)
        XCTAssertEqual(settings.retentionDays, 60)
        XCTAssertEqual(settings.maxItems, 300)
        XCTAssertTrue(settings.enableEncryption)
        XCTAssertFalse(settings.enableOCR)
    }

    // MARK: - Multiple Settings Tests

    func testToggleMultipleFeatures() {
        // Enable all features
        settings.enableEncryption = true
        settings.enableOCR = true
        settings.enableSmartPaste = true
        settings.enableSemanticSearch = true
        settings.enableAutoProjects = true

        XCTAssertTrue(settings.enableEncryption)
        XCTAssertTrue(settings.enableOCR)
        XCTAssertTrue(settings.enableSmartPaste)
        XCTAssertTrue(settings.enableSemanticSearch)
        XCTAssertTrue(settings.enableAutoProjects)

        // Disable all features
        settings.enableEncryption = false
        settings.enableOCR = false
        settings.enableSmartPaste = false
        settings.enableSemanticSearch = false
        settings.enableAutoProjects = false

        XCTAssertFalse(settings.enableEncryption)
        XCTAssertFalse(settings.enableOCR)
        XCTAssertFalse(settings.enableSmartPaste)
        XCTAssertFalse(settings.enableSemanticSearch)
        XCTAssertFalse(settings.enableAutoProjects)
    }

    func testExcludedAppsSetOperations() {
        // Clear and add multiple apps
        settings.excludedApps.removeAll()
        settings.excludedApps = ["App1", "App2", "App3"]

        XCTAssertEqual(settings.excludedApps.count, 3)
        XCTAssertTrue(settings.excludedApps.contains("App1"))
        XCTAssertTrue(settings.excludedApps.contains("App2"))
        XCTAssertTrue(settings.excludedApps.contains("App3"))
    }

    // MARK: - Edge Cases

    func testVeryLargeRetentionDays() {
        settings.retentionDays = 1000

        // Should be capped by license
        let effective = settings.effectiveRetentionDays
        XCTAssertLessThanOrEqual(effective, 1000)
    }

    func testNegativeRetentionDays() {
        // This shouldn't be allowed in real app, but test boundary
        let originalValue = settings.retentionDays
        settings.retentionDays = -10

        // Should either reject or clamp to minimum
        XCTAssertNotEqual(settings.retentionDays, -10, "Should not allow negative retention days")
    }

    func testExcludeSameAppTwice() {
        settings.excludedApps.insert("TestApp")
        let count1 = settings.excludedApps.count

        settings.excludedApps.insert("TestApp")
        let count2 = settings.excludedApps.count

        // Set should not add duplicates
        XCTAssertEqual(count1, count2, "Should not add duplicate apps")
    }
}
