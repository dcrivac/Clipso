# Release Build Guide for Clipso

## Overview

This guide walks you through creating a production-ready release build of Clipso for distribution.

## Prerequisites

- Xcode installed
- Clipso project building successfully
- (Optional) Apple Developer ID for code signing

## Step 1: Archive the App in Xcode

### Using Xcode GUI:

1. **Open Xcode** with Clipso project

2. **Select "Any Mac" as destination:**
   - Top bar → Select scheme dropdown
   - Choose "Any Mac (Apple Silicon, Intel)"

3. **Create Archive:**
   - Menu: **Product → Archive**
   - OR: Press **⌘⇧B** (Command + Shift + B)
   - Wait for archive to complete (1-2 minutes)

4. **Organizer Window Opens:**
   - Shows your archived build
   - Select the latest archive
   - Click **"Distribute App"**

5. **Choose Distribution Method:**
   - Select **"Copy App"** (for direct distribution)
   - Click **"Next"**

6. **Export Options:**
   - Click **"Export"**
   - Choose save location (e.g., Desktop/Clipso-Release)
   - Click **"Export"**

7. **Result:**
   - You now have: `Clipso.app`
   - Located in your export folder

## Step 2: Create DMG for Distribution (Recommended)

### Option A: Using create-dmg (Easiest)

Install create-dmg tool:
```bash
brew install create-dmg
```

Create DMG:
```bash
cd /Users/crivac/Projects/Clipso

# Create DMG with your exported .app
create-dmg \
  --volname "Clipso" \
  --volicon "assets/logo.svg" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Clipso.app" 175 120 \
  --hide-extension "Clipso.app" \
  --app-drop-link 425 120 \
  "Clipso-v1.0.0.dmg" \
  "/path/to/exported/Clipso.app"
```

### Option B: Manual DMG Creation

1. **Create folder with app:**
   ```bash
   mkdir -p DMG-Contents
   cp -R /path/to/exported/Clipso.app DMG-Contents/
   ln -s /Applications DMG-Contents/Applications
   ```

2. **Create DMG using Disk Utility:**
   - Open **Disk Utility**
   - File → New Image → Image from Folder
   - Select `DMG-Contents` folder
   - Save as: `Clipso-v1.0.0.dmg`
   - Image Format: **compressed**
   - Encryption: **none**
   - Click **Save**

3. **Clean up:**
   ```bash
   rm -rf DMG-Contents
   ```

## Step 3: Test the Release Build

### Test Installation:

1. **Mount the DMG:**
   ```bash
   open Clipso-v1.0.0.dmg
   ```

2. **Drag to Applications:**
   - Drag Clipso.app to Applications folder

3. **Run the app:**
   - Open from Applications
   - Right-click → Open (first time, to bypass Gatekeeper)
   - Test all features:
     - Menu bar icon appears
     - Cmd+Shift+V opens history
     - Settings work
     - License menu shows
     - Free tier limits work

4. **Test on fresh system (optional):**
   - Copy DMG to another Mac
   - Install and test
   - Verify no dependencies missing

## Step 4: Code Signing (Optional but Recommended)

### If you have an Apple Developer ID:

1. **Sign the app:**
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name" \
     /path/to/Clipso.app
   ```

2. **Verify signature:**
   ```bash
   codesign --verify --verbose /path/to/Clipso.app
   spctl --assess --verbose /path/to/Clipso.app
   ```

3. **Notarize (for distribution):**
   ```bash
   # Create a zip for notarization
   ditto -c -k --keepParent Clipso.app Clipso.zip

   # Submit for notarization
   xcrun notarytool submit Clipso.zip \
     --apple-id "your@email.com" \
     --team-id "YOUR_TEAM_ID" \
     --password "app-specific-password"

   # Wait for approval (5-10 minutes)
   # Then staple the ticket
   xcrun stapler staple Clipso.app
   ```

### Without Apple Developer ID:

Users will see a warning when opening the app for the first time. They need to:
1. Right-click → Open
2. Click "Open" in the security dialog

This is normal for unsigned apps from outside the Mac App Store.

## Step 5: Prepare for GitHub Release

### Create Release Package:

1. **Rename DMG with version:**
   ```bash
   mv Clipso-v1.0.0.dmg Clipso-v1.0.0-macOS.dmg
   ```

2. **Calculate checksum:**
   ```bash
   shasum -a 256 Clipso-v1.0.0-macOS.dmg > Clipso-v1.0.0-macOS.dmg.sha256
   ```

3. **Create release notes:**
   Create `RELEASE_NOTES.md`:
   ```markdown
   # Clipso v1.0.0

   ## 🎉 First Release - AI-Powered Clipboard Manager

   ### ✨ Features
   - AI semantic search - find by meaning, not just keywords
   - Context detection - auto-organizes into projects
   - 🔒 Freemium model:
     - Free: 250 items, 30-day retention, keyword search
     - Pro: Unlimited items, AI features, $7.99/year
   - OCR text extraction from images
   - Encryption support
   - Global hotkey (Cmd+Shift+V)

   ### 📦 Installation
   1. Download `Clipso-v1.0.0-macOS.dmg`
   2. Open the DMG
   3. Drag Clipso to Applications
   4. Right-click → Open (first time only)

   ### 💰 Pricing
   - Free tier: Full features, 250 items, 30 days
   - Pro tier: $7.99/year or $29.99 lifetime (launch special)

   ### 📊 Requirements
   - macOS 13.0 or later
   - Apple Silicon or Intel Mac

   ### 🔗 Links
   - Landing Page: https://dcrivac.github.io/Clipso
   - Documentation: https://github.com/dcrivac/Clipso
   - Support: Open an issue on GitHub
   ```

## Step 6: Upload to GitHub Releases

### Via GitHub Web Interface:

1. **Go to repository:**
   https://github.com/dcrivac/Clipso

2. **Create new release:**
   - Click "Releases" (right sidebar)
   - Click "Create a new release"

3. **Fill in release details:**
   - Tag: `v1.0.0`
   - Title: `Clipso v1.0.0 - AI-Powered Clipboard Manager`
   - Description: Paste contents of `RELEASE_NOTES.md`

4. **Upload files:**
   - Drag and drop:
     - `Clipso-v1.0.0-macOS.dmg`
     - `Clipso-v1.0.0-macOS.dmg.sha256`

5. **Publish:**
   - Check "Set as the latest release"
   - Click **"Publish release"**

### Via Command Line (gh CLI):

```bash
# Install GitHub CLI if needed
brew install gh

# Login
gh auth login

# Create release
gh release create v1.0.0 \
  Clipso-v1.0.0-macOS.dmg \
  Clipso-v1.0.0-macOS.dmg.sha256 \
  --title "Clipso v1.0.0" \
  --notes-file RELEASE_NOTES.md
```

## Step 7: Update Download Links

Update landing page download links to point to GitHub release:

```html
<!-- Change from: -->
<a href="https://github.com/dcrivac/Clipso/releases">Download Free</a>

<!-- To: -->
<a href="https://github.com/dcrivac/Clipso/releases/download/v1.0.2/Clipso-1.0.2.dmg">Download Free</a>
```

## Quick Command Summary

```bash
# 1. Build in Xcode (GUI)
# Product → Archive → Distribute → Copy App

# 2. Create DMG
create-dmg \
  --volname "Clipso" \
  --window-size 600 400 \
  --app-drop-link 425 120 \
  "Clipso-v1.0.0.dmg" \
  "/path/to/Clipso.app"

# 3. Calculate checksum
shasum -a 256 Clipso-v1.0.0.dmg > Clipso-v1.0.0.dmg.sha256

# 4. Create GitHub release
gh release create v1.0.0 \
  Clipso-v1.0.0-macOS.dmg \
  Clipso-v1.0.0-macOS.dmg.sha256 \
  --title "Clipso v1.0.0" \
  --notes-file RELEASE_NOTES.md
```

## Troubleshooting

### Archive fails:
- Clean build folder: Product → Clean Build Folder
- Check for build errors
- Make sure scheme is set to "Release"

### App won't open on other Macs:
- Missing code signature (normal, users need to right-click → Open)
- Add code signing if you have Developer ID

### DMG creation fails:
- Check paths are correct
- Install create-dmg: `brew install create-dmg`
- Or use manual Disk Utility method

### Users get "App is damaged" warning:
- This happens with unsigned apps on macOS 12+
- Users can fix with: `xattr -cr /Applications/Clipso.app`
- Or get code signed with Developer ID

## Next Steps

After creating release:
1. ✅ Test DMG installation
2. ✅ Upload to GitHub Releases
3. ✅ Update landing page download links
4. ✅ Announce on social media
5. ✅ Post on Product Hunt, Hacker News, Reddit

---

**You're ready to launch!** 🚀
