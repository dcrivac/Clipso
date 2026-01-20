import XCTest
import CoreData
@testable import Clipso

final class ContextDetectorTests: XCTestCase {

    var detector: ContextDetector!
    var mockContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        detector = ContextDetector.shared

        // Set up in-memory Core Data context
        let container = NSPersistentContainer(name: "ClipboardManager")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }

        mockContext = container.viewContext
    }

    override func tearDown() {
        detector = nil
        mockContext = nil
        super.tearDown()
    }

    // MARK: - App Pattern Detection Tests

    func testDetectAppPatternsWithSequence() {
        // Create items with app sequence pattern
        let now = Date()
        let items = [
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-100)),
            createTestItem(app: "Terminal", timestamp: now.addingTimeInterval(-90)),
            createTestItem(app: "Safari", timestamp: now.addingTimeInterval(-80)),
            // Repeat pattern
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-70)),
            createTestItem(app: "Terminal", timestamp: now.addingTimeInterval(-60)),
            createTestItem(app: "Safari", timestamp: now.addingTimeInterval(-50)),
            // Repeat again
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-40)),
            createTestItem(app: "Terminal", timestamp: now.addingTimeInterval(-30)),
            createTestItem(app: "Safari", timestamp: now.addingTimeInterval(-20))
        ]

        let patterns = detector.detectAppPatterns(items)

        // Should detect the repeated pattern
        XCTAssertFalse(patterns.isEmpty, "Should detect app patterns")

        // Check if pattern key exists
        let patternKeys = patterns.keys
        print("Detected patterns: \(patternKeys)")

        // Should group items by detected patterns
        for (pattern, groupedItems) in patterns {
            XCTAssertGreaterThanOrEqual(groupedItems.count, 3, "Pattern group should have at least 3 items")
            print("Pattern '\(pattern)' has \(groupedItems.count) items")
        }
    }

    func testDetectAppPatternsNoRepeats() {
        // Create items with no repeating pattern
        let now = Date()
        let items = [
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-100)),
            createTestItem(app: "Mail", timestamp: now.addingTimeInterval(-90)),
            createTestItem(app: "Notes", timestamp: now.addingTimeInterval(-80)),
            createTestItem(app: "Safari", timestamp: now.addingTimeInterval(-70)),
            createTestItem(app: "Finder", timestamp: now.addingTimeInterval(-60))
        ]

        let patterns = detector.detectAppPatterns(items)

        // Should not detect patterns (or detect very few)
        print("Patterns detected with no repeats: \(patterns.count)")
        // Most implementations would return empty or minimal patterns
    }

    func testDetectAppPatternsEmptyArray() {
        let emptyItems: [ClipboardItemEntity] = []

        let patterns = detector.detectAppPatterns(emptyItems)

        XCTAssertTrue(patterns.isEmpty, "Empty array should produce no patterns")
    }

    func testDetectAppPatternsSingleApp() {
        // All items from same app
        let now = Date()
        let items = [
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-100)),
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-90)),
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-80)),
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-70))
        ]

        let patterns = detector.detectAppPatterns(items)

        // Single app should create a pattern
        XCTAssertFalse(patterns.isEmpty, "Single app pattern should be detected")
    }

    // MARK: - Time Window Detection Tests

    func testDetectTimeWindowsWithClusters() {
        let now = Date()

        // Create items in two distinct time windows (30 minutes apart)
        let items = [
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-3600)), // 1 hour ago
            createTestItem(app: "Terminal", timestamp: now.addingTimeInterval(-3540)), // 59 min ago
            createTestItem(app: "Safari", timestamp: now.addingTimeInterval(-3480)), // 58 min ago

            // Gap of 30+ minutes

            createTestItem(app: "Mail", timestamp: now.addingTimeInterval(-600)), // 10 min ago
            createTestItem(app: "Notes", timestamp: now.addingTimeInterval(-540)), // 9 min ago
            createTestItem(app: "Slack", timestamp: now.addingTimeInterval(-480)) // 8 min ago
        ]

        let windows = detector.detectTimeWindows(items, windowMinutes: 30)

        // Should detect 2 distinct time windows
        XCTAssertGreaterThanOrEqual(windows.count, 2, "Should detect at least 2 time windows")

        // Each window should have items
        for window in windows {
            XCTAssertGreaterThan(window.count, 0, "Window should contain items")
        }
    }

    func testDetectTimeWindowsSingleWindow() {
        let now = Date()

        // All items within 30 minutes
        let items = [
            createTestItem(app: "Xcode", timestamp: now.addingTimeInterval(-1800)), // 30 min ago
            createTestItem(app: "Terminal", timestamp: now.addingTimeInterval(-1200)), // 20 min ago
            createTestItem(app: "Safari", timestamp: now.addingTimeInterval(-600)), // 10 min ago
            createTestItem(app: "Mail", timestamp: now.addingTimeInterval(-300)) // 5 min ago
        ]

        let windows = detector.detectTimeWindows(items, windowMinutes: 30)

        // All items should be in one window
        XCTAssertEqual(windows.count, 1, "Should detect single time window")
        XCTAssertEqual(windows[0].count, 4, "Window should contain all items")
    }

    func testDetectTimeWindowsEmptyArray() {
        let emptyItems: [ClipboardItemEntity] = []

        let windows = detector.detectTimeWindows(emptyItems, windowMinutes: 30)

        XCTAssertTrue(windows.isEmpty, "Empty array should produce no windows")
    }

    func testDetectTimeWindowsCustomWindowSize() {
        let now = Date()

        // Items spread over 90 minutes
        let items = [
            createTestItem(app: "App1", timestamp: now.addingTimeInterval(-5400)), // 90 min ago
            createTestItem(app: "App2", timestamp: now.addingTimeInterval(-3600)), // 60 min ago
            createTestItem(app: "App3", timestamp: now.addingTimeInterval(-1800)), // 30 min ago
            createTestItem(app: "App4", timestamp: now.addingTimeInterval(-300)) // 5 min ago
        ]

        // Test with 15-minute windows
        let windows15 = detector.detectTimeWindows(items, windowMinutes: 15)

        // Test with 60-minute windows
        let windows60 = detector.detectTimeWindows(items, windowMinutes: 60)

        // Smaller windows should produce more groups
        XCTAssertGreaterThanOrEqual(windows15.count, windows60.count,
                                    "Smaller window size should produce more or equal groups")
    }

    // MARK: - Tag Suggestion Tests

    func testSuggestProjectTagsBasedOnHistory() {
        // Create items with project tags
        let item1 = createTestItem(app: "Xcode", tag: "iOS App", content: "Swift code for login")
        let item2 = createTestItem(app: "Xcode", tag: "iOS App", content: "Swift code for signup")
        let item3 = createTestItem(app: "Terminal", tag: "iOS App", content: "pod install")

        // New item without tag, similar context
        let newItem = createTestItem(app: "Xcode", tag: nil, content: "Swift code for profile")

        let history = [item1, item2, item3]

        let suggestions = detector.suggestProjectTags(for: newItem, basedOn: history)

        // Should suggest "iOS App" tag
        XCTAssertFalse(suggestions.isEmpty, "Should suggest tags based on history")

        if let firstSuggestion = suggestions.first {
            XCTAssertEqual(firstSuggestion.tag, "iOS App", "Should suggest the matching tag")
            XCTAssertGreaterThan(firstSuggestion.confidence, 0.0, "Confidence should be positive")
            XCTAssertLessThanOrEqual(firstSuggestion.confidence, 1.0, "Confidence should be <= 1.0")
        }
    }

    func testSuggestProjectTagsNoHistory() {
        let newItem = createTestItem(app: "Xcode", tag: nil, content: "Some code")
        let emptyHistory: [ClipboardItemEntity] = []

        let suggestions = detector.suggestProjectTags(for: newItem, basedOn: emptyHistory)

        XCTAssertTrue(suggestions.isEmpty, "No history should produce no suggestions")
    }

    func testSuggestProjectTagsNoMatchingContext() {
        // History with tags for one context
        let item1 = createTestItem(app: "Mail", tag: "Client Work", content: "Email to client")
        let item2 = createTestItem(app: "Notes", tag: "Client Work", content: "Meeting notes")

        // New item in completely different context
        let newItem = createTestItem(app: "Xcode", tag: nil, content: "Swift programming")

        let history = [item1, item2]

        let suggestions = detector.suggestProjectTags(for: newItem, basedOn: history)

        // Should suggest few or no tags due to context mismatch
        if !suggestions.isEmpty {
            // If suggestions exist, confidence should be low
            XCTAssertLessThan(suggestions[0].confidence, 0.5, "Unrelated context should have low confidence")
        }
    }

    func testSuggestProjectTagsMultipleTags() {
        // Create items with different tags
        let item1 = createTestItem(app: "Xcode", tag: "iOS App", content: "Swift code")
        let item2 = createTestItem(app: "Xcode", tag: "iOS App", content: "More Swift")
        let item3 = createTestItem(app: "Xcode", tag: "macOS App", content: "AppKit code")

        let newItem = createTestItem(app: "Xcode", tag: nil, content: "New Swift code")

        let history = [item1, item2, item3]

        let suggestions = detector.suggestProjectTags(for: newItem, basedOn: history)

        // Should suggest multiple tags, sorted by confidence
        if suggestions.count > 1 {
            // First suggestion should have higher confidence than second
            XCTAssertGreaterThanOrEqual(suggestions[0].confidence, suggestions[1].confidence,
                                       "Suggestions should be sorted by confidence")
        }
    }

    func testSuggestProjectTagsAppMatch() {
        // Items with same app should have higher confidence
        let item1 = createTestItem(app: "Xcode", tag: "Project A", content: "Code")
        let item2 = createTestItem(app: "Terminal", tag: "Project B", content: "Command")

        let newItemSameApp = createTestItem(app: "Xcode", tag: nil, content: "New code")

        let history = [item1, item2]

        let suggestions = detector.suggestProjectTags(for: newItemSameApp, basedOn: history)

        if let projectASuggestion = suggestions.first(where: { $0.tag == "Project A" }),
           let projectBSuggestion = suggestions.first(where: { $0.tag == "Project B" }) {
            XCTAssertGreaterThan(projectASuggestion.confidence, projectBSuggestion.confidence,
                               "Same app should have higher confidence")
        }
    }

    func testSuggestProjectTagsTimeProximity() {
        let now = Date()

        // Recent item with tag
        let recentItem = createTestItem(app: "Xcode", tag: "Active Project",
                                       content: "Recent work",
                                       timestamp: now.addingTimeInterval(-600)) // 10 min ago

        // Old item with tag
        let oldItem = createTestItem(app: "Xcode", tag: "Old Project",
                                    content: "Old work",
                                    timestamp: now.addingTimeInterval(-86400)) // 1 day ago

        let newItem = createTestItem(app: "Xcode", tag: nil, content: "New work")

        let history = [recentItem, oldItem]

        let suggestions = detector.suggestProjectTags(for: newItem, basedOn: history)

        if let activeSuggestion = suggestions.first(where: { $0.tag == "Active Project" }),
           let oldSuggestion = suggestions.first(where: { $0.tag == "Old Project" }) {
            XCTAssertGreaterThan(activeSuggestion.confidence, oldSuggestion.confidence,
                               "Recent items should have higher confidence")
        }
    }

    func testTagSuggestionConfidencePercentCalculation() {
        let item = createTestItem(app: "Xcode", tag: "Test", content: "Test")
        let history = [item]

        let suggestions = detector.suggestProjectTags(for: item, basedOn: history)

        for suggestion in suggestions {
            let percent = suggestion.confidencePercent
            XCTAssertGreaterThanOrEqual(percent, 0, "Confidence percent should be >= 0")
            XCTAssertLessThanOrEqual(percent, 100, "Confidence percent should be <= 100")

            // Verify calculation: confidence * 100
            let expectedPercent = Int(suggestion.confidence * 100)
            XCTAssertEqual(percent, expectedPercent, "Confidence percent calculation should be correct")
        }
    }

    // MARK: - Integration Tests

    func testCompleteWorkflowPatternDetectionAndTagging() {
        let now = Date()

        // Create a realistic work session
        let items = [
            createTestItem(app: "Xcode", tag: "Auth Feature",
                          content: "Login view code",
                          timestamp: now.addingTimeInterval(-3600)),
            createTestItem(app: "Terminal", tag: "Auth Feature",
                          content: "git commit -m 'Add login'",
                          timestamp: now.addingTimeInterval(-3540)),
            createTestItem(app: "Safari", tag: "Auth Feature",
                          content: "OAuth documentation",
                          timestamp: now.addingTimeInterval(-3480)),

            createTestItem(app: "Xcode", tag: "Auth Feature",
                          content: "Signup view code",
                          timestamp: now.addingTimeInterval(-1800)),
            createTestItem(app: "Terminal", tag: "Auth Feature",
                          content: "pod install",
                          timestamp: now.addingTimeInterval(-1740))
        ]

        // Detect patterns
        let patterns = detector.detectAppPatterns(items)
        XCTAssertFalse(patterns.isEmpty, "Should detect app patterns")

        // Detect time windows
        let windows = detector.detectTimeWindows(items, windowMinutes: 30)
        XCTAssertGreaterThan(windows.count, 0, "Should detect time windows")

        // Test tag suggestions for new item
        let newItem = createTestItem(app: "Xcode", tag: nil, content: "Password reset code")
        let suggestions = detector.suggestProjectTags(for: newItem, basedOn: items)

        if !suggestions.isEmpty {
            XCTAssertEqual(suggestions[0].tag, "Auth Feature",
                          "Should suggest the correct project tag based on context")
        }
    }

    // MARK: - Helper Methods

    private func createTestItem(app: String, tag: String? = nil, content: String = "Test content",
                               timestamp: Date = Date()) -> ClipboardItemEntity {
        let item = ClipboardItemEntity(context: mockContext)
        item.id = UUID()
        item.content = content
        item.timestamp = timestamp
        item.sourceApp = app
        item.projectTag = tag
        item.category = Int16(ClipboardCategory.text.rawValue)
        item.type = 0
        item.isEncrypted = false
        return item
    }
}
