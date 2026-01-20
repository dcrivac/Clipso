# Clipso

## Project Overview

Clipso is a macOS menu bar application built with SwiftUI that provides intelligent clipboard history management with AI-powered features. It runs as a lightweight utility that monitors clipboard changes and provides quick access to clipboard history through a global keyboard shortcut (Cmd+Shift+V).

## Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI + AppKit
- **Data Persistence**: Core Data
- **Security**: CryptoKit (AES-256 encryption)
- **AI/ML Features**:
  - Vision framework (OCR)
  - NaturalLanguage framework (text analysis)
- **System Integration**: Carbon (global hotkeys)

## Architecture

### Core Components

#### 1. Main App Entry (`ClipboardManagerApp`)
- App entry point at ClipboardManagerApp.swift:16
- Uses NSApplicationDelegateAdaptor pattern
- Manages Core Data persistence controller

#### 2. App Delegate (`AppDelegate`)
- Menu bar status item management at ClipboardManagerApp.swift:30
- Global keyboard shortcut registration (Cmd+Shift+V) at ClipboardManagerApp.swift:100
- Popover window management
- Lifecycle management

#### 3. Core Data Layer

**Persistence Controller** (ClipboardManagerApp.swift:152)
- Manages NSPersistentContainer with model name "ClipboardManager"
- Automatic change merging from parent context
- Preview support for SwiftUI previews

**Entity: ClipboardItemEntity**
- Custom class defined in ClipboardItemEntity+CoreDataClass.swift
- Properties defined in ClipboardItemEntity+CoreDataProperties.swift
- Extension with computed properties at ClipboardManagerApp.swift:132

#### 4. Clipboard Monitoring (`ClipboardMonitor`)
Location: ClipboardManagerApp.swift:506

**Features:**
- 0.5s polling interval for clipboard changes
- Duplicate detection
- App exclusion support
- Automatic categorization
- OCR integration for images
- Cleanup of old items based on retention settings

**Content Types Supported:**
- Text (NSPasteboard.string)
- Images (PNG/TIFF)
- URLs

#### 5. Security (`EncryptionHelper`)
Location: ClipboardManagerApp.swift:211

- AES-256-GCM encryption
- Keychain-based key storage
- Per-item encryption toggle
- Secure key generation and retrieval

#### 6. AI Features

**OCR Engine** (ClipboardManagerApp.swift:329)
- Vision framework text recognition
- Async processing on background queue
- Support for multiple languages
- Stores extracted text in `ocrText` field

**Smart Paste Engine** (ClipboardManagerApp.swift:364)
- Context-aware content transformation
- Supports: Slack, Discord, Xcode, VS Code, Terminal, iTerm, Notion, Obsidian
- Code language detection
- Automatic formatting (markdown code blocks, escaping, etc.)

**AI Clipboard Assistant** (ClipboardManagerApp.swift:451)
- Text summarization
- Action item extraction (TODO, FIXME, etc.)
- Basic grammar correction

### Data Models

#### ClipboardCategory Enum (ClipboardManagerApp.swift:704)
```swift
enum ClipboardCategory: Int, CaseIterable {
    case text = 0
    case code = 1
    case link = 2
    case email = 3
    case phone = 4
    case color = 5
    case image = 6
}
```

**Automatic Categorization Logic** (ClipboardManagerApp.swift:647)
- URL pattern matching
- Email regex validation
- Phone number detection
- Color hex code detection
- Code keyword detection

### UI Components

#### ContentView (ClipboardManagerApp.swift:745)
Main interface with:
- Search bar (searches content + OCR text)
- Category filters
- Item list with lazy loading
- Context menu actions
- AI feature integration

#### SettingsView (ClipboardManagerApp.swift:984)
Settings sections:
- History retention (1-365 days)
- Max items (50-1000)
- Security (encryption toggle)
- AI features (OCR, Smart Paste)
- Excluded applications
- Keyboard shortcut display

#### Supporting Views
- **CategoryButton** (ClipboardManagerApp.swift:1203): Filter buttons
- **ClipboardItemRow** (ClipboardManagerApp.swift:1229): Individual item display
- **FlowLayout** (ClipboardManagerApp.swift:1159): Custom layout for tags

### Settings Management

**SettingsManager** (ClipboardManagerApp.swift:282)
- Singleton pattern with @Published properties
- UserDefaults persistence
- Settings:
  - `retentionDays`: Int (default 30)
  - `maxItems`: Int (default 100)
  - `excludedApps`: Set<String>
  - `enableEncryption`: Bool
  - `enableOCR`: Bool (default true)
  - `enableSmartPaste`: Bool (default true)

### Key Features

1. **Global Keyboard Shortcut**: Cmd+Shift+V anywhere in macOS
2. **Smart Categorization**: Automatic detection of content type
3. **OCR**: Extract text from screenshots/images
4. **Smart Paste**: Context-aware formatting based on target application
5. **Encryption**: Optional AES-256 encryption for sensitive content
6. **App Exclusion**: Skip monitoring from password managers
7. **Duplicate Detection**: Prevents storing identical content
8. **Retention Management**: Auto-cleanup based on age and count limits
9. **AI Actions**: Summarize, extract TODOs, fix grammar

## File Structure

```
ClipboardManager/
├── ClipboardManagerApp.swift           # Main app code (~1377 lines)
├── ClipboardItemEntity+CoreDataClass.swift
├── ClipboardItemEntity+CoreDataProperties.swift
├── ClipboardManager.xcdatamodeld.zip   # Core Data model
├── Info.plist                          # Permissions
└── README.md
```

## Permissions Required

Defined in Info.plist:
- `NSAppleEventsUsageDescription`: Monitor clipboard changes
- `NSAccessibilityUsageDescription`: Detect active application

## Development Notes

### Building
- Requires macOS development environment
- SwiftUI target (macOS 13.0+)
- Core Data model must be included in target
- Entity classes must be visible to app target

### Common Tasks

**Adding a new category:**
1. Add case to ClipboardCategory enum (ClipboardManagerApp.swift:704)
2. Update categorizeText() logic (ClipboardManagerApp.swift:647)
3. Add icon and color mappings

**Modifying AI features:**
- OCR: Modify OCREngine (ClipboardManagerApp.swift:329)
- Smart Paste: Update SmartPasteEngine transforms (ClipboardManagerApp.swift:364)
- Text analysis: Enhance AIClipboardAssistant (ClipboardManagerApp.swift:451)

**Changing retention logic:**
- Item limit: SettingsManager.maxItems + enforceItemLimit() (ClipboardManagerApp.swift:666)
- Age-based: SettingsManager.retentionDays + cleanupOldItems() (ClipboardManagerApp.swift:684)

### Performance Considerations

- Clipboard polling: 0.5s interval (configurable at ClipboardManagerApp.swift:521)
- Lazy loading in ScrollView for large histories
- OCR runs on background queue (ClipboardManagerApp.swift:357)
- Duplicate detection via fetch request before saving

## Potential Enhancements

- iCloud sync support
- Custom keyboard shortcut configuration
- Export/import clipboard history
- Enhanced AI features (language translation, sentiment analysis)
- Cloud-based OCR for better accuracy
- Snippet templates
- Tag system for organization
- Search filters (date range, source app)
