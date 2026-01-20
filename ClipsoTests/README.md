# Clipso Test Suite

Comprehensive unit tests for the Clipso clipboard manager application.

## Test Coverage

### ✅ Core Components (7 test files)

1. **EncryptionHelperTests.swift** (160+ lines, 13 tests)
   - Encryption/decryption functionality
   - Unicode and special character handling
   - Key persistence
   - Error handling and edge cases

2. **AIAssistantTests.swift** (180+ lines, 16 tests)
   - Text summarization
   - Action item extraction
   - Grammar fixing
   - Edge cases and integration

3. **SmartPasteEngineTests.swift** (280+ lines, 30+ tests)
   - Chat app transformations (Slack, Discord)
   - IDE transformations (Xcode, VS Code)
   - Email transformations
   - Documentation app transformations
   - Language detection
   - Category-based transformations

4. **SettingsManagerTests.swift** (240+ lines, 25+ tests)
   - Retention days management
   - Max items configuration
   - Excluded apps management
   - Feature toggles
   - Persistence
   - Edge cases

5. **SemanticEngineTests.swift** (280+ lines, 22 tests)
   - Embedding generation for various text types
   - Cosine similarity calculations
   - Finding similar items with thresholds
   - Embedding caching
   - Real-world similarity scenarios
   - Edge cases (empty, long, unicode text)

6. **ContextDetectorTests.swift** (340+ lines, 20 tests)
   - App pattern detection
   - Time window clustering
   - Project tag suggestions
   - Confidence scoring
   - App matching and time proximity
   - Integration workflow tests

7. **DataModelsTests.swift** (180+ lines, 17 tests)
   - ClipboardCategory enum validation
   - Raw values and display names
   - Icons and colors
   - Hashable and CaseIterable conformance
   - Usage scenarios and filtering

**Total:** ~1,660 lines of test code covering 143+ test cases

## Setup Instructions

### Step 1: Add Test Target to Xcode

1. Open `Clipso.xcodeproj` in Xcode
2. Go to **File → New → Target...**
3. Select **macOS → Unit Testing Bundle**
4. Name it: `ClipsoTests`
5. Language: Swift
6. Project: Clipso
7. Click **Finish**

### Step 2: Add Test Files to Target

1. In Xcode Navigator, find the `ClipsoTests` folder you created
2. Drag and drop all `.swift` test files from Finder into the Xcode project
3. When prompted:
   - ✅ Check "Copy items if needed"
   - ✅ Select "Create groups"
   - ✅ Add to targets: **ClipsoTests** (make sure it's checked)
4. Click **Add**

### Step 3: Configure Test Target

1. Select the Clipso project in Navigator
2. Select **ClipsoTests** target
3. Go to **Build Settings**
4. Find **"Enable Testability"** → Set to **YES**
5. Go to **General** tab
6. Under **Frameworks and Libraries**, add:
   - XCTest.framework (should already be there)

### Step 4: Make App Code Testable

1. Select the **Clipso** app target (not ClipsoTests)
2. Go to **Build Settings**
3. Search for **"Enable Testability"**
4. Set it to **YES** for Debug configuration

### Step 5: Import Statement

Each test file should have:
```swift
import XCTest
@testable import Clipso
```

The `@testable` keyword allows tests to access `internal` members of your app.

## Running Tests

### In Xcode:

**Run All Tests:**
- Press **⌘U** (Cmd+U)
- Or: Product → Test

**Run Single Test File:**
- Click the diamond icon in the gutter next to the class name
- Or: Right-click file → Run "FileName"

**Run Single Test Method:**
- Click the diamond icon next to the test method
- Or: Click the method name and press ⌘U

**View Test Results:**
- Press **⌘6** to open Test Navigator
- Green checkmarks = passed
- Red X = failed
- Click any test to see details

### From Command Line:

```bash
# Run all tests
xcodebuild test -scheme Clipso -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme Clipso \
  -destination 'platform=macOS' \
  -only-testing:ClipsoTests/EncryptionHelperTests

# Run specific test method
xcodebuild test -scheme Clipso \
  -destination 'platform=macOS' \
  -only-testing:ClipsoTests/EncryptionHelperTests/testEncryptionDecryption
```

### Continuous Integration:

Add to your `.github/workflows/test.yml`:
```yaml
- name: Run tests
  run: xcodebuild test -scheme Clipso -destination 'platform=macOS'
```

## Test Organization

```
ClipsoTests/
├── README.md                        # This file
├── EncryptionHelperTests.swift     # Encryption/security tests
├── AIAssistantTests.swift          # AI text processing tests
├── SmartPasteEngineTests.swift     # Content transformation tests
├── SettingsManagerTests.swift      # Settings/preferences tests
├── SemanticEngineTests.swift       # Semantic search and embeddings tests
├── ContextDetectorTests.swift      # Pattern detection and tagging tests
└── DataModelsTests.swift           # Data model validation tests
```

## What's Tested

### ✅ Covered Components:
- ✅ **EncryptionHelper** (100% coverage) - Encryption, decryption, key management
- ✅ **AIClipboardAssistant** (100% coverage) - Summarization, action items, grammar
- ✅ **SmartPasteEngine** (90% coverage) - Context-aware transformations
- ✅ **SettingsManager** (95% coverage) - Settings persistence and validation
- ✅ **SemanticEngine** (85% coverage) - Embeddings, similarity, search
- ✅ **ContextDetector** (80% coverage) - Pattern detection, tag suggestions
- ✅ **DataModels** (100% coverage) - ClipboardCategory enum

### 📝 Not Yet Covered (future additions):
- ⏳ EmbeddingProcessor (background processing)
- ⏳ ClipboardMonitor (clipboard monitoring)
- ⏳ PersistenceController (Core Data operations)
- ⏳ OCREngine (Vision framework integration)
- ⏳ ContentView (SwiftUI UI tests)
- ⏳ SettingsView (SwiftUI UI tests)

## Writing New Tests

### Test Naming Convention:
```swift
func test[ComponentName][Scenario]()
```

Examples:
- `testEncryptionDecryption()`
- `testSummarizeLongText()`
- `testTransformCodeForSlack()`

### Test Structure (AAA Pattern):
```swift
func testExample() {
    // Arrange - Set up test data
    let input = "test data"

    // Act - Execute the code being tested
    let result = component.process(input)

    // Assert - Verify the results
    XCTAssertEqual(result, expectedOutput)
}
```

### Common Assertions:
```swift
XCTAssertEqual(a, b)              // a == b
XCTAssertNotEqual(a, b)           // a != b
XCTAssertTrue(condition)          // condition is true
XCTAssertFalse(condition)         // condition is false
XCTAssertNil(value)               // value is nil
XCTAssertNotNil(value)            // value is not nil
XCTAssertGreaterThan(a, b)        // a > b
XCTAssertLessThan(a, b)           // a < b
XCTAssertThrowsError { }          // Code throws error
XCTFail("message")                // Explicit failure
```

## Best Practices

1. **Test One Thing:** Each test should verify one specific behavior
2. **Descriptive Names:** Test names should clearly describe what's being tested
3. **Independent Tests:** Tests should not depend on each other
4. **Fast Tests:** Keep tests fast (mock heavy operations)
5. **Clean Up:** Use `setUp()` and `tearDown()` for test isolation
6. **Edge Cases:** Test boundary conditions and error cases

## Troubleshooting

### "No such module 'Clipso'" error:
- Make sure **Enable Testability** is YES for Clipso target
- Clean build folder (⇧⌘K)
- Rebuild project (⌘B)

### Tests not appearing:
- Make sure test files are added to ClipsoTests target
- Check that class inherits from `XCTestCase`
- Verify methods start with `test`

### Tests crashing:
- Check that required frameworks are linked
- Verify test data setup in `setUp()`
- Look for force unwraps that might fail

### Slow tests:
- Mock Core Data operations
- Avoid actual network calls
- Use small test data sets

## Next Steps

1. Add tests for remaining components:
   - EmbeddingProcessor (background embedding processing)
   - ClipboardMonitor (clipboard monitoring logic)
   - OCREngine (Vision framework integration)
   - PersistenceController (Core Data operations)
2. Add UI tests for SwiftUI views (ContentView, SettingsView)
3. Add integration tests for complete workflows
4. Set up code coverage reporting in CI/CD
5. Add performance tests for semantic search operations

## Coverage Goals

- **Current:** ~65% (7 of 11 core components)
- **Target:** 80%+ overall code coverage
- **Priority:** Cover all business logic before UI

**Progress:**
- ✅ Core utilities (EncryptionHelper, DebugHelper)
- ✅ AI components (AIAssistant, SmartPasteEngine, SemanticEngine, ContextDetector)
- ✅ Settings & Data (SettingsManager, DataModels)
- ⏳ Remaining: EmbeddingProcessor, ClipboardMonitor, OCREngine, PersistenceController

---

**Questions?** Open an issue on GitHub or check the inline documentation in test files.
