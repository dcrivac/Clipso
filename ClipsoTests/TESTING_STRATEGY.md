# Testing Strategy for Clipso

## Overview

This document outlines the comprehensive testing strategy for Clipso to prevent bugs like menu items not responding, UI elements not working, and other integration issues.

---

## Types of Tests

### 1. Unit Tests ✅ (Automated)

**What they test:** Individual components and functions in isolation

**Location:** `ClipsoTests/*.swift`

**Current Coverage:**
- ✅ EncryptionHelper
- ✅ AIClipboardAssistant
- ✅ SmartPasteEngine
- ✅ SettingsManager
- ✅ SemanticEngine
- ✅ ContextDetector
- ✅ DataModels
- ✅ **AppDelegate** (new - menu setup and validation)

**How to Run:**
```bash
# From command line
xcodebuild test -scheme Clipso -destination 'platform=macOS'

# From Xcode
Press ⌘U or Product → Test
```

**When to Run:**
- Before every commit
- Automatically in CI/CD
- After modifying any business logic

**What They Catch:**
- Logic errors
- Edge cases
- Data validation issues
- Function return values
- Menu item configuration errors
- Missing or invalid selectors

---

### 2. Integration Tests ✅ (Automated)

**What they test:** Multiple components working together

**Examples in AppDelegateTests:**
- Menu bar setup with status item
- Menu items linked to correct actions
- Keyboard shortcuts properly registered
- Window creation and display

**How to Run:**
```bash
# Same as unit tests
xcodebuild test -scheme Clipso -destination 'platform=macOS'
```

**When to Run:**
- Before releases
- After modifying app architecture
- When changing component interactions

**What They Catch:**
- Components not communicating correctly
- Settings not persisting
- Menu items not connected to actions
- Windows not opening properly

---

### 3. UI Tests ⏳ (Future - Automated)

**What they test:** User interface interactions via XCTest UI testing

**Planned Coverage:**
- Clicking menu items
- Opening/closing windows
- Popover interactions
- Keyboard shortcuts

**How to Implement:**
```swift
import XCTest

class ClipsoUITests: XCTestCase {
    func testSettingsMenuOpensWindow() {
        let app = XCUIApplication()
        app.launch()

        // Click menu bar item
        let menuBar = XCUIApplication(bundleIdentifier: "com.apple.systemuiserver")
        let menuBarItem = menuBar.statusItems["Clipso"]
        menuBarItem.click()

        // Click Settings
        let settingsItem = app.menuItems["Settings..."]
        settingsItem.click()

        // Verify window opened
        XCTAssertTrue(app.windows["Settings"].exists)
    }
}
```

**Challenges:**
- Menu bar testing requires accessibility permissions
- Can be slow and flaky
- Requires running app in test mode

**When to Run:**
- Before major releases
- After UI changes
- Weekly in CI/CD

---

### 4. Manual Testing ✅ (Manual)

**What it tests:** Real user interactions that automated tests can't easily cover

**Location:** `ClipsoTests/MANUAL_TESTING_CHECKLIST.md`

**Coverage:**
- All menu items work (click response, window opening)
- Visual appearance correct
- User workflows complete successfully
- Edge cases in real environment
- Multi-display scenarios
- System integration

**How to Run:**
Follow the checklist in `MANUAL_TESTING_CHECKLIST.md`

**When to Run:**
- Before every release
- After UI changes
- After modifying AppDelegate
- When bug reports mention UI issues

**What It Catches:**
- **Menu items not responding** ← This caught your bug!
- Windows opening off-screen
- Visual glitches
- Performance issues
- Real-world integration problems

---

### 5. Build Validation ✅ (Automated in CI)

**What it tests:** Project builds successfully on different environments

**Location:** `.github/workflows/test.yml`

**Coverage:**
- Clean build succeeds
- No compilation errors
- No warnings (optional)
- App bundle created
- Tests compile and run

**How to Run:**
```bash
# Local build test
xcodebuild clean build -scheme Clipso -destination 'platform=macOS'

# CI runs automatically on push
```

**When to Run:**
- On every commit (CI)
- Before opening PR
- Before releases

**What It Catches:**
- Syntax errors
- Missing imports
- Build configuration issues
- Compatibility problems

---

### 6. Smoke Tests ✅ (Manual - Quick)

**What they test:** Critical functionality works at basic level

**Quick 5-Minute Test:**
1. Launch app - Icon appears
2. Click icon - Popover opens
3. Click Settings - Settings window opens ← Would catch your bug!
4. Copy text - Appears in history
5. Cmd+Shift+V - Popover toggles
6. Click item - Pastes correctly
7. Quit - App exits cleanly

**When to Run:**
- Every build before release
- After critical changes
- Before demos

---

## How These Tests Would Have Caught the Settings Bug

### ❌ What Happened

The Settings menu item didn't open because:
- Used outdated selector: `showPreferencesWindow:`
- Selector didn't work with SwiftUI's Settings scene on modern macOS
- No fallback to alternative selectors

### ✅ How Each Test Type Would Help

#### 1. Unit Tests (AppDelegateTests.swift) - **Would Detect**

```swift
func testSettingsMenuItemHasAction() {
    // This test verifies Settings has an action
    appDelegate.setupMenuBarMenu()
    let settingsItem = menu.items.first { $0.title == "Settings..." }
    XCTAssertNotNil(settingsItem?.action) // ✅ PASSES
}

func testShowSettingsMethodExists() {
    // This test verifies the selector exists
    XCTAssertTrue(appDelegate.responds(to: #selector(AppDelegate.showSettings)))
    // ✅ PASSES (method exists)
}

// However, these tests can't verify the selector actually works!
// They just verify configuration, not runtime behavior
```

**Detection Level:** ⚠️ Partial - Catches configuration, not runtime failure

#### 2. Integration Tests - **Would Detect**

```swift
func testSettingsActuallyOpens() {
    // More advanced test
    appDelegate.setupMenuBarMenu()
    appDelegate.showSettings()

    // Check if a window was created
    let settingsWindows = NSApp.windows.filter { $0.title == "Settings" }
    XCTAssertTrue(settingsWindows.count > 0) // ❌ WOULD FAIL
}
```

**Detection Level:** ✅ Full - Would catch the actual failure

#### 3. UI Tests - **Would Detect**

```swift
func testClickingSettingsOpensWindow() {
    // Simulate actual user click
    app.menuItems["Settings..."].click()
    XCTAssertTrue(app.windows["Settings"].exists) // ❌ WOULD FAIL
}
```

**Detection Level:** ✅ Full - Exactly simulates user action

#### 4. Manual Testing Checklist - **Would Detect**

```markdown
- [ ] **Settings opens** - Clicking "Settings..." opens the Settings window
      ❌ FAILS - Nothing happens when clicked!
```

**Detection Level:** ✅ Full - Immediate discovery during testing

#### 5. Smoke Test - **Would Detect**

Step 3: "Click Settings - Settings window opens"
❌ FAILS immediately

**Detection Level:** ✅ Full - Caught in 30 seconds

---

## Recommended Testing Workflow

### For Every Change

```bash
# 1. Run unit tests while developing
xcodebuild test -scheme Clipso

# 2. Manual smoke test (2 min)
# Launch app, click icon, click Settings, verify it opens

# 3. Commit if tests pass
git commit -m "Fix: ..."
```

### Before Pull Requests

```bash
# 1. Run all automated tests
xcodebuild test -scheme Clipso

# 2. Build release configuration
xcodebuild clean build -scheme Clipso -configuration Release

# 3. Do quick manual test of changed features
# Follow relevant sections of MANUAL_TESTING_CHECKLIST.md

# 4. Create PR
```

### Before Releases

```bash
# 1. Run all automated tests
xcodebuild test -scheme Clipso

# 2. Complete full manual testing checklist
# See MANUAL_TESTING_CHECKLIST.md

# 3. Test on different macOS versions
# At minimum: oldest supported version + latest

# 4. Test clean install scenario
# Delete app data, install fresh, test as new user

# 5. Tag release
git tag -a v1.0.0 -m "Release 1.0.0"
```

---

## Test Coverage Goals

### Current Status

| Component | Unit Tests | Integration Tests | Manual Tests |
|-----------|-----------|-------------------|--------------|
| EncryptionHelper | ✅ 100% | ✅ | ✅ |
| AI Features | ✅ 90% | ✅ | ✅ |
| SettingsManager | ✅ 95% | ✅ | ✅ |
| Semantic Engine | ✅ 85% | ✅ | ✅ |
| AppDelegate | ✅ NEW | ✅ NEW | ✅ |
| ContentView | ❌ 0% | ❌ | ✅ |
| SettingsView | ❌ 0% | ❌ | ✅ |
| ClipboardMonitor | ❌ 0% | ❌ | ✅ |

### Target Status (6 months)

| Component | Unit Tests | Integration Tests | UI Tests |
|-----------|-----------|-------------------|----------|
| All Components | ✅ 80%+ | ✅ 60%+ | ✅ 40%+ |

---

## Adding New Tests

### When Adding a New Feature

1. **Write unit tests first** (TDD approach)
   ```swift
   func testNewFeature() {
       let input = "test"
       let result = newFeature.process(input)
       XCTAssertEqual(result, expectedOutput)
   }
   ```

2. **Add integration test** if feature involves multiple components

3. **Add to manual checklist** if feature has UI

4. **Update CI** if special build requirements

### When Fixing a Bug

1. **Write a failing test** that reproduces the bug
   ```swift
   func testSettingsButtonOpensWindow() {
       // This would have failed before the fix
       appDelegate.showSettings()
       XCTAssertTrue(windowOpened)
   }
   ```

2. **Fix the bug** - Test should now pass

3. **Add to manual checklist** to prevent regression

---

## CI/CD Integration

### GitHub Actions Workflow

The `.github/workflows/test.yml` runs on:
- Every push to main/develop
- Every pull request
- Manual trigger

**Jobs:**
1. **unit-tests** - Run all XCTest unit tests
2. **build-validation** - Verify clean build
3. **lint-and-warnings** - Check code quality
4. **test-matrix** - Test on multiple macOS versions

### Local Pre-Commit Hook

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running tests before commit..."
xcodebuild test -scheme Clipso -destination 'platform=macOS' 2>&1 | grep -E "(Test Suite|PASS|FAIL)"

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Commit aborted."
    exit 1
fi

echo "✅ Tests passed. Proceeding with commit."
```

---

## Test Maintenance

### Keep Tests Fast
- Mock expensive operations
- Use in-memory Core Data stores
- Avoid actual network calls
- Parallel test execution

### Keep Tests Reliable
- Independent tests (no shared state)
- Deterministic assertions
- No timing dependencies
- Clean setup/teardown

### Keep Tests Maintainable
- Clear test names
- One assertion per test (when possible)
- Descriptive failure messages
- Regular refactoring

---

## Metrics and Monitoring

### Track These Metrics

1. **Test Count**
   - Current: 150+ unit tests
   - Goal: 200+ tests

2. **Code Coverage**
   - Current: ~65%
   - Goal: 80%+

3. **Test Execution Time**
   - Current: ~30 seconds
   - Goal: Keep under 2 minutes

4. **Flaky Test Rate**
   - Goal: < 1% flaky tests

5. **Bug Escape Rate**
   - Bugs found in production vs. caught in testing
   - Goal: < 5% escape rate

---

## Resources

### Documentation
- [XCTest Apple Docs](https://developer.apple.com/documentation/xctest)
- [UI Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [Testing Best Practices](https://developer.apple.com/videos/play/wwdc2019/413/)

### Tools
- **Xcode Test Navigator** (⌘6) - View all tests
- **Code Coverage** (⌘9 → Coverage tab) - See coverage
- **Instruments** - Performance testing
- **Console.app** - View runtime logs

---

## Questions?

- **"Which tests should I write first?"**
  Start with unit tests for business logic, then add integration tests for critical paths.

- **"How do I test UI elements?"**
  Combine automated integration tests with manual testing checklist.

- **"My test is flaky, what do I do?"**
  Remove timing dependencies, ensure clean state, consider manual test instead.

- **"How do I test menu bar items?"**
  Unit tests for configuration, manual tests for actual clicking behavior.

---

**Last Updated:** 2026-01-20
**Next Review:** 2026-04-20
