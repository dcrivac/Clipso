# CLAUDE.md

Guidance for Claude Code and other AI assistants working in this repository.

## What Clipso is

Clipso is a macOS menu bar clipboard manager written in Swift (SwiftUI + AppKit). It polls the
pasteboard, stores history in Core Data, and layers on-device AI over it: OCR for images, sentence
embeddings for semantic search, and clustering for automatic project tagging. Everything runs
locally — the only network calls the app makes are license validation against `api.clipso.app`.

The repository holds three separate deliverables:

| Deliverable | Location | Runtime |
|---|---|---|
| macOS app | `AI/`, `Core/`, `Managers/`, `Models/`, `Views/`, `Utilities/`, `ClipsoApp.swift` | Swift 5, macOS 13.0+ |
| License server | `backend/` | Node.js + Express + PostgreSQL |
| Marketing site | `website/` (source), `docs/` (GitHub Pages deploy) | Static HTML/CSS/JS |

Product identity: bundle `com.crivac.clipso`, scheme and product name `Clipso`, current
`MARKETING_VERSION` 1.0.3.

---

## Read this before editing any Swift file

The repository contains several Swift files that are **not compiled**. Editing them has no effect on
the built app, and it is the single easiest mistake to make here.

**`ClipboardManagerApp.swift` (2490 lines, repo root) is dead code.** It is an earlier monolithic
version of the entire app, including its own `@main struct ClipboardManagerApp`, `AppDelegate`,
`ClipboardMonitor`, `ContentView`, and so on. It is not referenced by `Clipso.xcodeproj`. The live
entry point is **`ClipsoApp.swift`**. If you are asked to change app behavior and you find the
relevant code in `ClipboardManagerApp.swift`, you are in the wrong file — find its counterpart under
`AI/`, `Core/`, `Managers/`, `Models/`, `Views/`, or `Utilities/`.

Also excluded from the build target:

- **`Managers/PaddleConfig.swift`** — a second `struct PaddleConfig` that shadows nothing. The
  `PaddleConfig` the app actually compiles and uses is declared inside
  `Managers/LicenseManager.swift` (top of the file). Change checkout URLs and price IDs there.
- **`INTEGRATION_CODE_SNIPPETS.swift`** — a documentation file of copy-paste examples, not a module.
- **`ClipsoTests/` and `Tests/`** — see [Testing](#testing).
- **`ClipboardManager.xcdatamodeld.zip`** — a stale archived copy of the Core Data model. The live
  model is the `ClipboardManager.xcdatamodeld/` directory.

`guides/CLAUDE.MD` is an outdated architecture document written before the code was split out of the
monolith. Every line reference in it points into `ClipboardManagerApp.swift` and is wrong. Prefer
this file; do not trust that one.

### Adding a new Swift file

There is no Swift Package Manager manifest and no file-system-synchronized group — `project.pbxproj`
lists every source file explicitly. A new file is invisible to the compiler until it is registered
in **three** places in `Clipso.xcodeproj/project.pbxproj`:

1. A `PBXFileReference` entry (in the file reference section).
2. A `PBXBuildFile` entry referencing that file reference.
3. An entry in the target's `PBXSourcesBuildPhase` `files` list.

Add it to the matching `PBXGroup` too so it appears in the Xcode navigator. If you have Xcode
available, adding the file through the IDE does all of this correctly and is far less error-prone
than hand-editing the pbxproj.

---

## Building

**The app cannot be built on Linux.** It needs macOS with Xcode; Swift on Linux has no AppKit,
SwiftUI, Vision, CryptoKit, or Carbon. In a Linux container, restrict yourself to reading and
editing source, and let CI or a Mac do the compiling. `BUILD_ON_MACOS.md` covers this.

```bash
# Debug build, the same invocation CI uses
xcodebuild build \
  -project Clipso.xcodeproj \
  -scheme Clipso \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath ./DerivedData \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Signed release archive + DMG + ZIP
./scripts/build-release.sh

# Full release: build, DMG, GitHub release, website download links, commit
./scripts/release.sh
```

`scripts/README.md` documents each script. Release mechanics and signing live in
`RELEASE_PROCESS.md`, `CODE_SIGNING_GUIDE.md`, and `DEPLOYMENT_GUIDE.md`.

### Backend

```bash
cd backend
npm install
npm run dev      # nodemon
npm test         # jest — this one actually runs
```

Needs PostgreSQL with `backend/schema.sql` applied and a `.env` built from `backend/.env.example`.

---

## Testing

**There is no Xcode test target.** `ClipsoTests/` (10 XCTest files) and `Tests/LicenseManagerTests.swift`
exist as source but are not part of `Clipso.xcodeproj`, and the shared scheme sets
`buildForTesting = "NO"`. Consequences:

- `xcodebuild test` fails. Do not add it to CI or suggest it as a verification step.
- CI builds the app and checks the `.app` bundle exists; that is the whole Swift-side gate.
- Swift test files you add or edit are documentation until someone creates the target. Say so plainly
  rather than reporting tests as passing.

`ClipsoTests/README.md` has step-by-step instructions for wiring up the target, and
`ClipsoTests/MANUAL_TESTING_CHECKLIST.md` covers the manual pass that currently substitutes for it.
The backend's jest suite (`backend/server.test.js`) is the only automated test that runs today.

---

## Architecture

### Startup path

`ClipsoApp.swift` holds `@main struct ClipsoApp` plus `AppDelegate`, which owns everything the menu
bar app does:

- Creates the `NSStatusItem`; left click toggles an `NSPopover` hosting `ContentView`, right click
  opens the menu (Show, Upgrade/Activate or "Pro License Active", Settings, Quit).
- Registers the global hotkey **Cmd+Shift+V** through Carbon `RegisterEventHotKey` (keycode 9).
- Starts `ClipboardMonitor` 0.5s after launch, once the Core Data context is ready.
- Retains `settingsWindow` and `licenseWindow` in properties — these windows deallocate and vanish
  if you drop the reference, which is why they are stored rather than local.

The `Settings` scene in the `App` body is mostly vestigial; settings are opened through the menu.

### Capture pipeline

`Managers/ClipboardMonitor.swift` is the heart of the app. A 0.5s `Timer` (added to
`RunLoop.main` in `.common` mode so it survives menu tracking) compares `NSPasteboard.general.changeCount`:

1. Frontmost app is checked against `SettingsManager.excludedApps` → skip if excluded.
2. Content is read as string, PNG/TIFF image, or URL, in that order.
3. Text is classified by `categorizeText()` — regex for link/email/phone/hex color, then a keyword
   scan for code, defaulting to `.text`.
4. A fetch on `content == %@` rejects exact duplicates.
5. The entity is created; when `enableEncryption` is on, the plaintext goes to `encryptedContent` and
   `content` is left nil.
6. If OCR is enabled and the item is an image, `OCREngine` runs asynchronously and saves `ocrText`
   when it finishes.
7. If semantic search is enabled, `EmbeddingProcessor.processNewItem` is dispatched to a background
   queue.
8. `enforceItemLimit()` trims to `settings.effectiveMaxItems`.

`cleanupOldItems()` runs once at monitoring start and deletes anything older than
`effectiveRetentionDays`.

### Core Data

Model name is **`ClipboardManager`**, not `Clipso` — `PersistenceController` passes that string to
`NSPersistentContainer`, and renaming the `.xcdatamodeld` without updating it will crash on launch
(`fatalError` in `loadPersistentStores`).

One entity, `ClipboardItemEntity`, with 18 attributes. The original set (`id`, `timestamp`,
`content`, `type`, `category`, `imageData`, `encryptedContent`, `isEncrypted`, `sourceApp`,
`ocrText`, `tags`, `isFavorite`) is joined by the AI-era additions: `embedding`, `projectTag`,
`contextScore`, `relatedItemIDs`, `lastAccessedAt`, `accessCount`.

Properties are hand-written in `ClipboardItemEntity+CoreDataProperties.swift` (codegen is manual), so
**a new attribute must be added to both the `.xcdatamodeld` and that file**. There are no versioned
model files and no mapping model — added attributes must be optional or carry a default so
lightweight migration succeeds for existing users.

`Core/ClipboardItemEntity+Ext.swift` adds the accessors views should use: `clipboardCategory`,
`displayContent` (transparently decrypts, falls back to `"[Encrypted]"`), and `displayImage`. Read
`displayContent`, not `content`, anywhere an item is shown.

### AI layer (`AI/`)

All on-device, all Apple frameworks — no model files, no network.

- **`SemanticEngine`** — wraps `NLEmbedding.sentenceEmbedding(for: .english)`. Text is truncated to
  1000 characters, embeddings are JSON-encoded into the `embedding` Binary attribute, and there is an
  in-memory `[UUID: [Double]]` cache behind a concurrent queue. Provides `cosineSimilarity` and
  `findSimilarItems`. `embeddingModel` is optional and nil on systems without the model — every
  caller must handle the nil case and degrade to keyword behavior.
- **`EmbeddingProcessor`** — serial utility queue that generates embeddings, refreshes each item's
  `relatedItemIDs` (top 5 above 0.75 similarity), and recomputes `contextScore` as
  recency (≤0.4) + frontmost-app match (0.3) + access frequency (≤0.3), clamped to 0…1.
- **`SmartSearchEngine`** — `SearchMode` is `.keyword`, `.semantic`, or `.hybrid`. Hybrid merges both
  result sets and ranks them 40% keyword / 30% semantic / 20% recency / 10% frequency.
- **`ContextDetector`** — app-usage patterns, 30-minute time-window clustering, content-similarity
  clusters, and `TagSuggestion`s learned from tags the user has already applied.
- **`OCREngine`** — `VNRecognizeTextRequest` at `.accurate`, `en-US` only, performed on a background
  queue with a completion handler.
- **`SmartPasteEngine`** — rewrites content for the destination app: fenced code blocks for
  Slack/Discord/Notion/Obsidian, re-indentation for Xcode/VS Code, shell quoting for
  Terminal/iTerm, markdown links for URLs.
- **`AIClipboardAssistant`** — summarize, extract action items, naive grammar fixes, via `NLTokenizer`.

### Licensing (`Managers/LicenseManager.swift`)

`LicenseManager.shared` is an `ObservableObject` published into the views. Free versus Pro is
decided by `hasProAccess()`, and gating flows through four methods:

| Method | Free | Pro |
|---|---|---|
| `canUseSemanticSearch()` | false | true |
| `canUseContextDetection()` | false | true |
| `getMaxItems()` | 250 | `Int.max` |
| `getMaxRetentionDays()` | 30 | `Int.max` |

**Never read `SettingsManager.maxItems` or `retentionDays` directly when enforcing a limit.** Use
`effectiveMaxItems` / `effectiveRetentionDays`, which are `min(userSetting, licensedMax)`. That is
the whole enforcement mechanism, and bypassing it silently removes the free-tier cap.

License keys, email, type, and last-validation date are stored in the Keychain under
`com.clipboardmanager.license.*` keys, revalidated against the backend every 7 days by a timer.
Purchases open `website/checkout.html` on the marketing site with a `price_id` query parameter; the
app never handles payment itself.

In `#if DEBUG` builds, `isDevelopmentMode` (toggled from Settings) makes `hasProAccess()` return true
so Pro features can be exercised without a key. The flag and its methods are compiled out of Release
builds — keep any new use of it inside `#if DEBUG`. See `DEVELOPMENT_MODE.md`.

### Views (`Views/`)

`ContentView` is the popover: search field, search-mode picker (locked options show 🔒 for free
users and snap back to `.keyword`), category filter row, and the item list. `SettingsView` is the
settings window, including a "rebuild embeddings" action. `TagInputSheet` is the tag entry sheet.

`FlowLayout.swift` is misleadingly named — besides the `FlowLayout` container it also holds
**`CategoryButton`** and **`ClipboardItemRow`**, the row view where most list rendering and the
context menu live. Look there before concluding a view doesn't exist.

### Configuration and secrets

`Info.plist` carries Paddle settings (`PADDLE_VENDOR_ID`, price IDs, `PADDLE_USE_SANDBOX`) and the
two usage-description strings for accessibility and Apple Events. It currently holds **sandbox**
credentials with `PADDLE_USE_SANDBOX` set to true.

Paddle IDs, vendor tokens, and the Postgres password come from `.env.local` (template in
`.env.template`) and `backend/.env`. `.gitignore` excludes `.env*`, `Info-*.plist`, `*-Secrets.plist`,
`secrets/`, and `PADDLE_CREDENTIALS.md`. Do not commit real keys, and do not move an API key into a
client-side default — `PaddleConfig` deliberately leaves `apiKey` empty.

---

## Conventions

- **Singletons everywhere.** Engines and managers expose `static let shared`. Follow the pattern for
  new engines rather than introducing dependency injection piecemeal.
- **`// MARK: -` section headers** at the top of every type and between logical groups.
- **Emoji-prefixed logging.** `✅` success, `❌` error, `⚠️` warning, `🔄` in progress, `📋` clipboard,
  `💾` save. Keep the vocabulary consistent.
- `debugLog()` in `Utilities/DebugHelper.swift` appends to `/tmp/clipboard_monitor_debug.txt` as well
  as `NSLog`. It is the fastest way to trace the monitor, which is hard to observe under a debugger.
- Core Data writes go through `PersistenceController.shared.save()`, which no-ops when there are no
  changes. Background work uses `context.perform`.
- Errors are generally logged and swallowed rather than propagated; the app favors staying alive over
  surfacing failures. Match that in the capture path, but prefer real error handling in new
  user-facing flows.
- Two-space-free style: 4-space indentation, standard Swift API design naming. There is no SwiftLint
  or swift-format configuration — match the surrounding file.

The `code-quality` CI job warns (without failing) about trailing whitespace, `TODO:`/`FIXME:`
markers, and `print(` calls. The codebase has many `print`/`NSLog` calls by design; you do not need to
remove them, but don't add gratuitous new ones.

---

## CI and release

Workflows in `.github/workflows/`:

- **`test.yml`** ("Build") — the main gate. Runs on pushes to `main`, `develop`, and **`claude/**`**,
  and on PRs. Matrix of macos-13/14/latest × Debug/Release (Release only on latest), plus the
  `code-quality` job and a `build-status` aggregate for branch protection. Builds only; no tests.
- **`main.yml`** — builds a universal binary, signs it, produces a DMG with checksums, and creates a
  GitHub release on `v*` tags.
- **`release.yml`** — the tag-driven signed and **notarized** DMG pipeline (`xcrun notarytool`).
- **`test-build.yml`** — manual `workflow_dispatch` diagnostic.
- **`claude.yml`, `claude-code-review.yml`** — Claude Code automation on issues and PRs.

Because `test.yml` matches `claude/**`, pushing an agent branch triggers a full matrix build. Expect
CI to run and check it.

Signing secrets used by the workflows: `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PASSWORD`,
`KEYCHAIN_PASSWORD`, `CODESIGN_IDENTITY`, plus notarization credentials. The Debug configuration
pins `DEVELOPMENT_TEAM = DKN2U77MAZ`; Release signs ad-hoc (`CODE_SIGN_IDENTITY = "-"`) unless CI
supplies a real identity.

Version bumps touch `MARKETING_VERSION` in both build configurations of `project.pbxproj`, and the
download links in `website/index.html` and `docs/index.html`.

## Website

`website/` is the working source and `docs/` is what GitHub Pages serves (it has the `CNAME` and an
extra `blog/`). **The two directories have already drifted** — `docs/index.html` and
`website/index.html` differ. When you change marketing pages, change both, or the deployed site
won't match. `scripts/update-download-links.sh` handles the release-link updates.

`website/checkout.html` is the Paddle.js checkout page the macOS app opens for purchases; it reads
`price_id` from the query string.

---

## Where the rest of the documentation lives

The repository root and `guides/` hold ~40 markdown files, mostly release, marketing, and Paddle
setup runbooks. The ones worth reading before touching related code:

- `BUILD_ON_MACOS.md`, `RELEASE_PROCESS.md`, `CODE_SIGNING_GUIDE.md`, `DEPLOYMENT_GUIDE.md` — build & ship
- `DEVELOPMENT_MODE.md` — testing Pro features without a license
- `SECURITY_IMPROVEMENTS.md` — encryption and Keychain decisions
- `guides/LICENSE_INTEGRATION_GUIDE.md`, `guides/PADDLE_SETUP.md`, `PADDLE_400_ERROR_FIX.md` — licensing
- `ClipsoTests/TESTING_STRATEGY.md`, `guides/TEST_COVERAGE_ANALYSIS.md` — testing intent
- `backend/README.md` — license server setup
