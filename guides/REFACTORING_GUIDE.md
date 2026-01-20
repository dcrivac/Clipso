# Swift Code Refactoring Guide

## Overview

ClipsoApp.swift is currently 2,765 lines - we're breaking it into focused, maintainable files.

**Status:** Folder structure created, 2 components extracted
**Remaining:** 18 major components to extract

---

## File Structure

```
Clipso/
├── ClipsoApp.swift                    (NEW - just app entry ~50 lines)
├── Core/
│   ├── PersistenceController.swift    (Lines 225-287)
│   ├── ClipboardItemEntity+Ext.swift  (Lines 205-223)
│   └── EncryptionHelper.swift         (Lines 289-358)
├── Managers/
│   ├── SettingsManager.swift          (Lines 360-436)
│   ├── ClipboardMonitor.swift         (Lines 1410-1652)
│   └── LicenseManager.swift           (Already separate ✓)
├── AI/
│   ├── SemanticEngine.swift           (Lines 615-785)
│   ├── EmbeddingProcessor.swift       (Lines 787-912)
│   ├── ContextDetector.swift          (Lines 914-1175)
│   ├── OCREngine.swift                (Lines 438-471)
│   ├── SmartPasteEngine.swift         (Lines 473-558)
│   ├── AIAssistant.swift              (Lines 560-613)
│   └── SmartSearchEngine.swift        (Lines 1177-1392)
├── Views/
│   ├── ContentView.swift              (Lines 1695-2132)
│   ├── SettingsView.swift             (Lines 2171-2454)
│   ├── TagInputSheet.swift            (Lines 2134-2169)
│   └── FlowLayout.swift               (Lines 2456-2765)
├── Models/
│   └── DataModels.swift               (Lines 1654-1693) ✓ DONE
└── Utilities/
    └── DebugHelper.swift              (Lines 1394-1408) ✓ DONE
```

---

## Extraction Steps

### 1. Core Data Components

#### a) PersistenceController (Lines 225-287)

```bash
# Extract to: Clipso/Core/PersistenceController.swift
```

**Key imports needed:**
```swift
import CoreData
```

**Code section:** Everything from `// MARK: - Core Data Persistence` to end of `PersistenceController` struct

---

#### b) Entity Extension (Lines 205-223)

```bash
# Extract to: Clipso/Core/ClipboardItemEntity+Ext.swift
```

**Key imports:**
```swift
import CoreData
import CryptoKit
```

**Code section:** The `extension ClipboardItemEntity` block

---

#### c) EncryptionHelper (Lines 289-358)

```bash
# Extract to: Clipso/Core/EncryptionHelper.swift
```

**Key imports:**
```swift
import Foundation
import CryptoKit
```

**Code section:** `// MARK: - Encryption Helper` through end of `EncryptionHelper` struct

---

### 2. Manager Classes

#### a) SettingsManager (Lines 360-436)

```bash
# Extract to: Clipso/Managers/SettingsManager.swift
```

**Key imports:**
```swift
import Foundation
import Combine
```

**Code section:** `// MARK: - Settings Manager` through end of `SettingsManager` class

---

#### b) ClipboardMonitor (Lines 1410-1652)

```bash
# Extract to: Clipso/Managers/ClipboardMonitor.swift
```

**Key imports:**
```swift
import SwiftUI
import AppKit
import CoreData
import Vision
import UniformTypeIdentifiers
```

**Code section:** `// MARK: - Clipboard Monitor` through end of `ClipboardMonitor` class

**Dependencies:** Needs `DebugHelper`, `SettingsManager`, `OCREngine`

---

### 3. AI Components

#### a) SemanticEngine (Lines 615-785)

```bash
# Extract to: Clipso/AI/SemanticEngine.swift
```

**Key imports:**
```swift
import Foundation
import NaturalLanguage
```

**Code section:** `// MARK: - Semantic Engine` through end of `SemanticEngine` class

---

#### b) EmbeddingProcessor (Lines 787-912)

```bash
# Extract to: Clipso/AI/EmbeddingProcessor.swift
```

**Key imports:**
```swift
import Foundation
import NaturalLanguage
```

**Code section:** `// MARK: - Embedding Processor` through end of `EmbeddingProcessor` class

---

#### c) ContextDetector (Lines 914-1175)

```bash
# Extract to: Clipso/AI/ContextDetector.swift
```

**Key imports:**
```swift
import Foundation
import CoreData
import NaturalLanguage
```

**Code section:** `// MARK: - Context Detector` through end of `ContextDetector` class

---

#### d) OCREngine (Lines 438-471)

```bash
# Extract to: Clipso/AI/OCREngine.swift
```

**Key imports:**
```swift
import AppKit
import Vision
```

**Code section:** `// MARK: - OCR Engine` through end of `OCREngine` struct

---

#### e) SmartPasteEngine (Lines 473-558)

```bash
# Extract to: Clipso/AI/SmartPasteEngine.swift
```

**Key imports:**
```swift
import AppKit
```

**Code section:** `// MARK: - Smart Paste Engine` through end of `SmartPasteEngine` struct

---

#### f) AIAssistant (Lines 560-613)

```bash
# Extract to: Clipso/AI/AIAssistant.swift
```

**Key imports:**
```swift
import Foundation
```

**Code section:** `// MARK: - AI Assistant` through end of `AIAssistant` class

---

#### g) SmartSearchEngine (Lines 1177-1392)

```bash
# Extract to: Clipso/AI/SmartSearchEngine.swift
```

**Key imports:**
```swift
import Foundation
import CoreData
```

**Code section:** `// MARK: - Smart Search Engine` through end of `SmartSearchEngine` class

**Dependencies:** Needs `SemanticEngine`

---

### 4. View Components

#### a) ContentView (Lines 1695-2132)

```bash
# Extract to: Clipso/Views/ContentView.swift
```

**Key imports:**
```swift
import SwiftUI
import CoreData
import AppKit
```

**Code section:** `// MARK: - Main Content View` through end of `ContentView` struct

**Dependencies:** Many - this is the main UI component

---

#### b) SettingsView (Lines 2171-2454)

```bash
# Extract to: Clipso/Views/SettingsView.swift
```

**Key imports:**
```swift
import SwiftUI
```

**Code section:** `// MARK: - Settings View` through end of `SettingsView` struct

---

#### c) TagInputSheet (Lines 2134-2169)

```bash
# Extract to: Clipso/Views/TagInputSheet.swift
```

**Key imports:**
```swift
import SwiftUI
```

**Code section:** `// MARK: - Tag Input Sheet` through end of `TagInputSheet` struct

---

#### d) FlowLayout (Lines 2456-2765)

```bash
# Extract to: Clipso/Views/FlowLayout.swift
```

**Key imports:**
```swift
import SwiftUI
```

**Code section:** `// MARK: - Flow Layout` through end of file

---

### 5. Create New Minimal ClipsoApp.swift

After extracting all components, replace ClipsoApp.swift with:

```swift
import SwiftUI
import AppKit

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
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ... Keep the AppDelegate implementation (lines 30-203) ...
    }

    // ... Rest of AppDelegate methods ...
}
```

---

## Adding Files to Xcode Project

After extraction, you need to add all new files to Xcode:

1. **Open Xcode** → Open `Clipso.xcodeproj`
2. **Right-click on Clipso folder** in project navigator
3. **Select "Add Files to 'Clipso'"**
4. **Select all new folders**: Core, Managers, AI, Views, Models, Utilities
5. **Check:** "Copy items if needed" and "Create groups"
6. **Click "Add"**

---

## Testing After Refactoring

1. **Clean Build Folder:** Product → Clean Build Folder (⇧⌘K)
2. **Build:** Product → Build (⌘B)
3. **Fix any import errors** that appear
4. **Run:** Product → Run (⌘R)
5. **Test all features** to ensure nothing broke

---

## Common Issues & Fixes

### Issue: "Cannot find type X in scope"
**Fix:** Add missing import statement to the file

### Issue: "Value of type X has no member Y"
**Fix:** Make sure dependencies are properly imported

### Issue: Build errors after adding files
**Fix:** Check that all files are added to the Clipso target (File Inspector → Target Membership)

---

## Benefits After Refactoring

✅ **Faster builds** - Swift compiles files in parallel
✅ **Easier navigation** - Find code in seconds
✅ **Better testing** - Test components in isolation
✅ **Cleaner architecture** - Clear separation of concerns
✅ **Less merge conflicts** - Changes isolated to specific files
✅ **Easier onboarding** - New developers can understand structure quickly

---

## Estimated Time

- **Extracting all components:** 2-3 hours
- **Adding to Xcode + fixing imports:** 30 minutes
- **Testing:** 30 minutes
- **Total:** 3-4 hours

Take your time and test after each major extraction!
