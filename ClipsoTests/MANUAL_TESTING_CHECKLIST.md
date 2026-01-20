# Manual Testing Checklist

This checklist helps catch UI bugs that automated tests can't easily detect, like the Settings menu item not responding.

## Before Each Release

Run through this checklist before releasing a new version to ensure all critical user interactions work.

---

## 1. Menu Bar Icon & Menu

### Menu Bar Icon
- [ ] **App appears in menu bar** - Clipso icon is visible in the macOS menu bar after launch
- [ ] **Icon is correct** - Displays clipboard icon (doc.on.clipboard symbol)
- [ ] **Left click works** - Opens the clipboard history popover
- [ ] **Right click works** - Opens the context menu (same as left click on macOS)

### Menu Items Visibility
- [ ] **Menu appears** - Right-clicking icon shows menu with all expected items
- [ ] **License status shown** - Either "✓ Pro License Active" or "Upgrade to Pro..." is visible
- [ ] **Activate License item** - "Activate License..." menu item is present
- [ ] **Settings item** - "Settings..." menu item is present
- [ ] **Quit item** - "Quit Clipso" menu item is present
- [ ] **Separators** - Menu has proper visual separators between sections

### Menu Items Functionality
- [ ] **Settings opens** - Clicking "Settings..." opens the Settings window
- [ ] **Settings keyboard shortcut** - Cmd+, opens Settings when app is active
- [ ] **Activate License opens** - Clicking "Activate License..." opens the license activation window
- [ ] **Upgrade button (free users)** - Clicking "Upgrade to Pro..." initiates purchase flow
- [ ] **Quit works** - Clicking "Quit Clipso" terminates the application
- [ ] **Quit keyboard shortcut** - Cmd+Q quits the application

---

## 2. Settings Window

### Opening Settings
- [ ] **Opens from menu** - Settings window appears after clicking menu item
- [ ] **Opens from popover** - Gear icon in popover opens settings
- [ ] **Opens from keyboard** - Cmd+, shortcut opens settings
- [ ] **Window appears** - Settings window is visible and properly sized (600x600)
- [ ] **Window is on top** - Settings window gains focus and appears in front

### Settings Window Structure
- [ ] **Title is correct** - Window title shows "Settings" or "Clipso Settings"
- [ ] **All sections visible** - License, History, Security, AI Features, Excluded Apps, Keyboard Shortcut
- [ ] **Can scroll** - If content is long, scrolling works properly
- [ ] **Window is resizable** - Can resize window if needed (or fixed if intended)
- [ ] **Can close** - Red X button closes the window

### Settings Sections
- [ ] **License Section** - Shows Pro/Free status correctly
- [ ] **History Retention** - Sliders work and update values
- [ ] **Security** - Encryption toggle works
- [ ] **AI Features** - All AI toggles and controls work
- [ ] **Excluded Applications** - Can add/remove apps from exclusion list
- [ ] **Keyboard Shortcut** - Shows Cmd+Shift+V info correctly

### Settings Persistence
- [ ] **Settings save** - Changes persist after closing and reopening Settings
- [ ] **Settings survive restart** - Settings persist after quitting and relaunching app

---

## 3. License Activation Window

### Opening License Activation
- [ ] **Opens from menu** - "Activate License..." menu item opens window
- [ ] **Opens from settings** - "Activate License" button in settings opens window
- [ ] **Window appears** - License activation window is visible (500x400)
- [ ] **Window is on top** - Window gains focus

### License Activation Functionality
- [ ] **Can enter license key** - Text field accepts input
- [ ] **Can paste license** - Cmd+V pastes license key
- [ ] **Activate button works** - Button responds to clicks
- [ ] **Error messages show** - Invalid licenses show appropriate errors
- [ ] **Success messages show** - Valid licenses show success confirmation
- [ ] **Window closes on success** - Window auto-closes after successful activation

---

## 4. Clipboard History Popover

### Opening Popover
- [ ] **Opens from menu bar click** - Left clicking icon opens popover
- [ ] **Opens from keyboard** - Cmd+Shift+V opens popover
- [ ] **Popover appears** - Popover is visible and properly positioned
- [ ] **Correct size** - Popover is 400x500 pixels

### Popover Contents
- [ ] **Shows clipboard items** - Recent clipboard history is displayed
- [ ] **Items are formatted** - Each item shows preview, timestamp, app source
- [ ] **Icons display** - Category icons show correctly
- [ ] **Search bar works** - Can search/filter clipboard items
- [ ] **Gear icon present** - Settings gear icon is visible

### Popover Actions
- [ ] **Can click items** - Clicking item pastes it
- [ ] **Can delete items** - Swipe or delete button removes items
- [ ] **Settings gear works** - Clicking gear icon opens settings
- [ ] **Can close** - Clicking outside or pressing Escape closes popover
- [ ] **Auto-closes** - Popover closes after selecting an item

---

## 5. Global Keyboard Shortcuts

### Cmd+Shift+V (Toggle Popover)
- [ ] **Works from any app** - Shortcut opens popover regardless of active app
- [ ] **Shows popover** - Popover appears on first press
- [ ] **Hides popover** - Popover closes on second press (toggle)
- [ ] **Brings app to front** - Clipso activates when popover opens

### Cmd+, (Settings)
- [ ] **Works when Clipso is active** - Opens settings when Clipso has focus
- [ ] **Opens correct window** - Settings window appears, not other windows

### Cmd+Q (Quit)
- [ ] **Quits application** - App terminates completely
- [ ] **Cleans up** - Menu bar icon disappears
- [ ] **Saves state** - Clipboard history persists for next launch

---

## 6. Clipboard Monitoring

### Monitoring Functionality
- [ ] **Monitors clipboard** - Detects when you copy text in other apps
- [ ] **Saves to history** - Copied items appear in clipboard history
- [ ] **Detects source app** - Shows which app the item was copied from
- [ ] **Categorizes content** - Correctly identifies URLs, code, images, etc.
- [ ] **Respects exclusions** - Doesn't save items from excluded apps

### Monitoring Edge Cases
- [ ] **Works on launch** - Monitoring starts immediately after app launch
- [ ] **Works continuously** - No items are missed during normal usage
- [ ] **Handles images** - Image clipboard items are detected and saved
- [ ] **Handles files** - File clipboard items are detected and saved
- [ ] **Performance** - Monitoring doesn't slow down the system

---

## 7. AI Features (Pro Users)

### OCR for Screenshots
- [ ] **OCR toggle works** - Can enable/disable in settings
- [ ] **Detects screenshots** - Recognizes screenshot clipboard items
- [ ] **Extracts text** - OCR correctly extracts visible text from images
- [ ] **Shows OCR results** - Extracted text is displayed in item preview

### Smart Paste
- [ ] **Smart Paste toggle works** - Can enable/disable in settings
- [ ] **Detects app context** - Recognizes target application
- [ ] **Transforms content** - Applies appropriate formatting for context
- [ ] **Works for code** - Formats code correctly for IDEs
- [ ] **Works for chat** - Formats properly for Slack, Discord, etc.

### Semantic Search
- [ ] **Semantic toggle works** - Can enable/disable in settings
- [ ] **Finds similar items** - Search by meaning, not just keywords
- [ ] **Relevance ranking** - Results are sorted by relevance
- [ ] **Threshold adjustment** - Similarity threshold slider works

### Context Detection
- [ ] **Auto-detect toggle works** - Can enable/disable in settings
- [ ] **Detects projects** - Recognizes related clipboard items
- [ ] **Suggests tags** - Project tags are suggested automatically
- [ ] **Groups by context** - Related items are grouped together

---

## 8. Error Handling & Edge Cases

### Permission Issues
- [ ] **Accessibility warning** - Shows alert if accessibility permissions not granted
- [ ] **Guides to settings** - Provides instructions to grant permissions
- [ ] **Clipboard access** - Handles clipboard permission denials gracefully

### Data Issues
- [ ] **Empty history** - App handles empty clipboard history gracefully
- [ ] **Large items** - Very large clipboard items don't crash app
- [ ] **Unicode content** - Handles emoji and special characters correctly
- [ ] **Binary content** - Non-text clipboard items don't cause errors

### Network Issues (Pro Features)
- [ ] **Offline mode** - App works without internet (local features only)
- [ ] **API failures** - AI features fail gracefully if API is down
- [ ] **License check** - Handles license server being unreachable

### Memory & Performance
- [ ] **Memory usage** - App doesn't consume excessive memory over time
- [ ] **Startup time** - App launches quickly (< 2 seconds)
- [ ] **Responsive UI** - UI remains responsive under heavy clipboard activity
- [ ] **Database size** - Old items are cleaned up per retention settings

---

## 9. Upgrade & Purchase Flow

### Free Users
- [ ] **Upgrade menu visible** - "Upgrade to Pro..." shown in menu
- [ ] **Clicking upgrade** - Opens purchase/upgrade flow
- [ ] **Purchase completes** - Can complete purchase successfully
- [ ] **License activates** - After purchase, Pro features become available

### Pro Users
- [ ] **Pro status shown** - "✓ Pro License Active" shown in menu
- [ ] **Pro features work** - All AI features are accessible
- [ ] **License persists** - Pro status survives app restarts
- [ ] **Can deactivate** - "Deactivate License" button works in settings

---

## 10. Multi-Display & System Integration

### Multi-Display Support
- [ ] **Menu bar on all displays** - Icon appears on correct display
- [ ] **Popover on active display** - Opens on display where icon was clicked
- [ ] **Windows on active display** - Settings/License windows open on active display

### System Integration
- [ ] **Launches on login** - If enabled, launches when user logs in
- [ ] **Survives system sleep** - Works correctly after waking from sleep
- [ ] **Survives user switch** - Works after fast user switching
- [ ] **macOS updates** - Continues working after macOS updates

### Dark Mode & Accessibility
- [ ] **Respects dark mode** - UI adapts to system dark mode setting
- [ ] **Respects text size** - Honors system font size settings
- [ ] **VoiceOver compatible** - Works with macOS VoiceOver screen reader
- [ ] **High contrast mode** - Readable in high contrast mode

---

## Testing Instructions

### How to Test

1. **Fresh Install Testing**
   - Delete app from Applications
   - Delete `~/Library/Application Support/Clipso` folder
   - Delete `~/Library/Preferences/com.yourcompany.Clipso.plist`
   - Install fresh copy and test as new user

2. **Update Testing**
   - Install previous version
   - Use app and generate clipboard history
   - Install new version over old version
   - Verify data persists and upgrade works

3. **Multi-Version Testing**
   - Test on macOS 12 (Monterey)
   - Test on macOS 13 (Ventura)
   - Test on macOS 14 (Sonoma)
   - Test on macOS 15 (Sequoia)

### Test Environments

- [ ] **Clean macOS installation** - VM or fresh Mac
- [ ] **User's actual setup** - Real-world environment
- [ ] **Different macOS versions** - Minimum supported version and latest
- [ ] **Different hardware** - Intel and Apple Silicon Macs

### Regression Testing

After any code changes to these files, re-test the related section:
- `ClipsoApp.swift` changes → Test sections 1, 2, 3
- `ContentView.swift` changes → Test section 4
- `SettingsView.swift` changes → Test section 2
- `ClipboardMonitor.swift` changes → Test section 6
- AI feature files → Test section 7

---

## Reporting Issues

When a checklist item fails, report with:
1. **macOS version** - e.g., "macOS 14.2 Sonoma"
2. **Clipso version** - e.g., "v1.2.3"
3. **Steps to reproduce** - Exact steps that caused the failure
4. **Expected behavior** - What should have happened
5. **Actual behavior** - What actually happened
6. **Screenshots** - If applicable
7. **Console logs** - Check Console.app for Clipso logs

---

## Quick Smoke Test (5 minutes)

Before any release, run this minimal test:

1. [ ] Launch app - Icon appears in menu bar
2. [ ] Click icon - Popover opens with clipboard history
3. [ ] Right-click icon → Settings - Settings window opens
4. [ ] Copy text in another app - Text appears in Clipso history
5. [ ] Cmd+Shift+V - Popover opens/closes
6. [ ] Click clipboard item - Item pastes correctly
7. [ ] Quit app - App quits cleanly

If all 7 pass, the app is basically functional. If any fail, investigate before release.

---

**Last Updated:** 2026-01-20
**Version:** 1.0
