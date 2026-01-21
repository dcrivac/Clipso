# Development Mode - Testing Pro Features

## Overview

As the developer of Clipso, you can bypass license activation to test Pro features without purchasing a license. This is only available in **Debug builds** and will not work in Release builds.

## How to Enable Development Mode

### Method 1: Using the Settings UI (Recommended)

1. Build and run Clipso in **Debug** configuration
2. Right-click the Clipso menu bar icon
3. Click "Settings..."
4. Find the "Developer Mode" section (highlighted in orange)
5. Toggle "Enable Pro Features (Testing)" to ON

✅ You now have access to all Pro features!

### Method 2: Using Code/Debugger

If you want to enable it programmatically or via the debugger console:

```swift
// In your code or LLDB debugger:
LicenseManager.shared.enableDevelopmentMode()

// To disable:
LicenseManager.shared.disableDevelopmentMode()

// To toggle:
LicenseManager.shared.toggleDevelopmentMode()
```

## What Gets Unlocked

When Development Mode is enabled, you get access to:

- ✅ **AI Semantic Search** - Find items by meaning, not just keywords
- ✅ **Context Detection** - Automatic project grouping
- ✅ **Unlimited Items** - No 250 item limit (was limited to 250 in free)
- ✅ **Unlimited Retention** - Keep items forever (was limited to 30 days)
- ✅ All UI elements marked as "Pro"

## How It Works

The development mode bypass is implemented in `LicenseManager.swift`:

```swift
func hasProAccess() -> Bool {
    #if DEBUG
    // In debug builds, allow development mode bypass for testing
    if isDevelopmentMode {
        return true
    }
    #endif

    return isProUser && (licenseType == .lifetime || licenseType == .annual || licenseType == .monthly)
}
```

This means:
- ✅ Only works in **Debug** builds (when running from Xcode)
- ❌ Does **NOT** work in **Release** builds (production/distributed versions)
- ✅ No risk of users exploiting this in production
- ✅ Safe to commit to your repository

## Testing Pro Features

Here's what you should test when Development Mode is enabled:

### 1. Semantic Search
- Search for items by meaning (e.g., "email addresses", "code snippets")
- Verify AI-powered search results are relevant
- Test search performance with many items

### 2. Context Detection
- Copy items from different apps
- Verify automatic project grouping
- Test context window settings

### 3. UI Elements
- Verify "Pro" badges appear correctly
- Test upgrade prompts are hidden when Pro is active
- Check Settings shows "Pro License Active"

### 4. Limits
- Copy more than 250 items (free limit)
- Verify retention beyond 30 days works
- Test performance with unlimited items

## Verifying Status

You'll know Development Mode is active when:

1. **Console Output**: You'll see this in Xcode console:
   ```
   🔧 Development Mode: ENABLED
      Pro features are now accessible
   ```

2. **Settings UI**: The Developer Mode toggle is ON (orange highlight)

3. **License Status**: Settings may still show "Free Plan" but Pro features work

## Disabling Development Mode

Simply toggle OFF the "Enable Pro Features (Testing)" switch in Settings, or call:

```swift
LicenseManager.shared.disableDevelopmentMode()
```

## Production Builds

When you build for Release (Archive → Distribute):
- All `#if DEBUG` code is stripped out
- `isDevelopmentMode` property doesn't exist
- Development Mode toggle doesn't appear in Settings
- Only legitimate license activation works

## Troubleshooting

**Q: I toggled it ON but Pro features still don't work**
- Make sure you're running a **Debug** build from Xcode
- Check the Xcode console for "🔧 Development Mode: ENABLED"
- Try rebuilding the app

**Q: I don't see the Developer Mode section in Settings**
- Verify you're running in Debug configuration (not Release)
- Check your build scheme (Product → Scheme → Edit Scheme → Run → Build Configuration = Debug)

**Q: Will this bypass work in production?**
- No! The `#if DEBUG` compiler flag ensures this code is completely removed from Release builds
- This is 100% safe to use during development

## Files Modified

- `Managers/LicenseManager.swift` - Added development mode flag and bypass logic
- `Views/SettingsView.swift` - Added UI toggle in Settings window
- `DEVELOPMENT_MODE.md` - This documentation

## Example Usage

```swift
// Before testing Pro features in debug build:
LicenseManager.shared.enableDevelopmentMode()

// Now you can test:
if LicenseManager.shared.canUseSemanticSearch() {
    print("✅ Semantic search is available!")
}

if LicenseManager.shared.canUseContextDetection() {
    print("✅ Context detection is available!")
}

print("Max items: \(LicenseManager.shared.getMaxItems())") // Now returns Int.max
print("Max retention: \(LicenseManager.shared.getMaxRetentionDays())") // Now returns Int.max
```

---

Happy testing! 🚀
