# Snippet Manager App Brainstorm

## App Name Ideas
- **Snippo** (matches Clipso branding)
- **CodeStash**
- **SnipVault**
- **Fragmento**

---

## Core Value Proposition

> "Find any code snippet by describing what it does, not what you named it."

Traditional snippet managers require perfect organization. You save a snippet, forget the name, and never find it again. This app uses semantic search to find snippets by meaning—search "sort array by date" and find your snippet even if you named it "chronological ordering util".

---

## Target Users

1. **Developers** who save reusable code patterns
2. **DevOps engineers** with shell scripts and config templates
3. **Technical writers** with documentation templates
4. **Students** building a personal code library

---

## Core Features

### MVP (Free Tier)

| Feature | Description |
|---------|-------------|
| **Snippet Storage** | Save text/code with title and optional notes |
| **Auto Language Detection** | Detects 20+ languages (Swift, Python, JS, Go, Rust, SQL, Bash, etc.) |
| **Syntax Highlighting** | Beautiful code rendering with popular themes |
| **Keyword Search** | Traditional substring matching |
| **Tags** | Manual tagging with color coding |
| **Global Hotkey** | `Cmd+Shift+S` to open anywhere |
| **Quick Add** | Capture selected text from any app |
| **Copy to Clipboard** | One-click copy with optional formatting |
| **Favorites** | Pin frequently used snippets |
| **Import/Export** | JSON backup and restore |

### Premium ($7.99/year - matches Clipso pricing)

| Feature | Description |
|---------|-------------|
| **Semantic Search** | Find snippets by meaning using NLEmbedding |
| **Smart Suggestions** | "You might also need..." based on current snippet |
| **iCloud Sync** | E2E encrypted sync across Macs |
| **Snippet Folders** | Organize into projects/categories |
| **Variables/Placeholders** | Define `{{variable}}` placeholders that prompt on paste |
| **Auto-Expansion** | Type abbreviation (e.g., `!fetch`) and it expands |
| **Snippet History** | Version history for edited snippets |
| **URL Snippets** | Save code from GitHub Gists, Stack Overflow with source link |

---

## Differentiation from Competitors

| Competitor | Weakness | Our Advantage |
|------------|----------|---------------|
| **Dash** | Expensive ($30), complex | Simple, affordable, semantic search |
| **SnippetsLab** | No semantic search | AI-powered discovery |
| **Alfred Snippets** | Basic, no syntax highlighting | Full code editor experience |
| **Raycast Snippets** | Tied to Raycast ecosystem | Standalone, privacy-focused |
| **GitHub Gists** | Requires internet, public by default | 100% local, private |

**Key differentiator:** First snippet manager with on-device semantic search.

---

## Technical Architecture

### Reusable from Clipso

| Component | Clipso Source | Adaptation |
|-----------|---------------|------------|
| `SemanticEngine.swift` | NLEmbedding wrapper | Works as-is |
| `SmartSearchEngine.swift` | Hybrid ranking | Adjust weights for code |
| `EncryptionHelper.swift` | AES-256-GCM | Works as-is |
| `LicenseManager.swift` | Paddle integration | Update product IDs |
| `SettingsManager.swift` | UserDefaults wrapper | Add snippet-specific settings |
| Menu bar architecture | AppDelegate pattern | Works as-is |
| Global hotkey | Carbon Events | Change key combo |

### New Components

```
SnippetManager/
├── Core/
│   ├── SnippetEntity.swift          # CoreData model
│   ├── LanguageDetector.swift       # Auto-detect programming language
│   ├── SyntaxHighlighter.swift      # Highlight.js or TreeSitter
│   └── PlaceholderEngine.swift      # {{variable}} expansion
├── AI/
│   ├── SemanticEngine.swift         # (from Clipso)
│   ├── CodeEmbedding.swift          # Code-aware embeddings
│   └── SuggestionEngine.swift       # Related snippet recommendations
├── Views/
│   ├── SnippetListView.swift        # Main list with search
│   ├── SnippetEditorView.swift      # Code editor with highlighting
│   ├── QuickAddView.swift           # Capture from selection
│   └── SettingsView.swift           # Preferences
└── Managers/
    ├── SnippetStore.swift           # CRUD operations
    ├── SyncManager.swift            # iCloud sync
    └── ExpansionManager.swift       # Text expansion triggers
```

### Data Model

```swift
@Model
class Snippet {
    var id: UUID
    var title: String
    var content: String
    var language: Language        // enum: swift, python, js, etc.
    var tags: [String]
    var folder: String?
    var isFavorite: Bool
    var abbreviation: String?     // for auto-expansion (!fetch)
    var placeholders: [String]    // extracted {{variables}}
    var sourceURL: String?        // if imported from web
    var embedding: Data?          // semantic vector
    var createdAt: Date
    var updatedAt: Date
    var accessCount: Int
    var lastAccessedAt: Date?
}
```

### Language Detection Strategy

Use file extension heuristics + keyword analysis:

```swift
enum Language: String, CaseIterable {
    case swift, python, javascript, typescript, go, rust
    case java, kotlin, csharp, cpp, c, ruby, php
    case sql, graphql, html, css, json, yaml, xml
    case bash, zsh, powershell, dockerfile
    case markdown, plaintext

    static func detect(from content: String) -> Language {
        // 1. Check for shebang: #!/usr/bin/python
        // 2. Check for keywords: func/let (Swift), def/import (Python)
        // 3. Check for syntax patterns: -> for Swift/Rust, => for JS
        // 4. Fall back to plaintext
    }
}
```

---

## User Experience

### Quick Add Flow (Global Hotkey)

1. User selects code in any app
2. Presses `Cmd+Shift+S`
3. Popover appears with:
   - Code preview (auto-highlighted)
   - Auto-detected language (editable)
   - Title field (auto-suggested from first line/comment)
   - Tags (optional)
4. Press Enter to save, Escape to cancel

### Search Flow

1. User presses `Cmd+Shift+S` (no selection)
2. Search bar focused
3. Type query: "fetch json api"
4. Results ranked by: semantic similarity + recency + frequency
5. Press Enter to copy, Cmd+Enter to edit

### Placeholder Expansion

```javascript
// Snippet: "API Fetch Template"
const response = await fetch('{{url}}');
const data = await response.json();
console.log({{logVariable}});
```

When pasted:
1. Prompt appears: "Enter value for `url`:"
2. User types: `https://api.example.com`
3. Prompt: "Enter value for `logVariable`:"
4. User types: `data.results`
5. Final paste with substitutions

---

## Monetization

### Freemium Model (Same as Clipso)

| Tier | Price | Limits |
|------|-------|--------|
| Free | $0 | Unlimited snippets, keyword search, 10 semantic searches/day |
| Premium | $7.99/year | Unlimited semantic search, sync, folders, variables |

### Bundle Opportunity

- **Clipso + Snippo Bundle**: $12.99/year (save $3)
- Cross-promote in each app's settings

---

## Development Phases

### Phase 1: MVP (2-3 weeks)
- [ ] CoreData model + basic CRUD
- [ ] Menu bar app shell (copy from Clipso)
- [ ] Snippet list view with keyword search
- [ ] Syntax highlighting (use Highlightr library)
- [ ] Auto language detection
- [ ] Global hotkey + quick add
- [ ] Copy to clipboard

### Phase 2: AI Features (1-2 weeks)
- [ ] Port SemanticEngine from Clipso
- [ ] Generate embeddings for snippets
- [ ] Hybrid search ranking
- [ ] Premium gating with Paddle

### Phase 3: Power Features (2 weeks)
- [ ] Placeholder/variable system
- [ ] Auto-expansion abbreviations
- [ ] iCloud sync
- [ ] Folders organization
- [ ] Import from Gist/URL

### Phase 4: Polish (1 week)
- [ ] Onboarding flow
- [ ] Keyboard navigation
- [ ] Theme support (light/dark + editor themes)
- [ ] Landing page
- [ ] App Store submission

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Semantic search less useful for code | Train/tune on code-specific patterns; use hybrid ranking |
| Market too niche | Target broader "text snippets" use case, not just code |
| Competition from Raycast/Alfred | Focus on standalone privacy story + semantic search |
| Syntax highlighting performance | Use lazy rendering, virtualized lists |

---

## Success Metrics

- **Week 1**: 100 snippets saved by beta testers
- **Month 1**: 500 downloads, 10% free-to-paid conversion
- **Month 3**: 2,000 downloads, $500 MRR
- **Month 6**: Feature parity with SnippetsLab, 5,000 downloads

---

## Next Steps

1. Create new Xcode project: `SnippetManager` (or chosen name)
2. Copy shared components from Clipso (SemanticEngine, EncryptionHelper, etc.)
3. Design CoreData schema
4. Build menu bar shell with global hotkey
5. Implement basic snippet CRUD
6. Add syntax highlighting
7. Integrate semantic search
8. Set up Paddle for new product

---

## Questions to Decide

1. **App name?** Snippo, CodeStash, or something else?
2. **Separate app or Clipso feature?** Could be a tab in Clipso, but standalone is cleaner
3. **Editor component?** Use NSTextView, CodeEditor package, or web-based (Monaco)?
4. **Sync strategy?** iCloud CloudKit vs. custom solution?
