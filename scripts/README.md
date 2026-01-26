# Release Scripts

Automated scripts for building and releasing Clipso with Paddle integration.

## Quick Start

**Option 1: Complete Release (Recommended)**
```bash
./scripts/release.sh
```
This runs the entire release process automatically.

**Option 2: Individual Steps**
```bash
# 1. Build the app
./scripts/build-release.sh

# 2. Test the DMG
open release/Clipso-1.0.3.dmg

# 3. Create GitHub release
./scripts/create-github-release.sh

# 4. Update download links
./scripts/update-download-links.sh
```

---

## Scripts Overview

### `release.sh` - Master Script
Complete automated release process.

**What it does:**
1. Builds app with Paddle integration
2. Creates DMG and ZIP files
3. Creates GitHub release
4. Uploads release files
5. Updates website download links
6. Commits and pushes changes

**Usage:**
```bash
./scripts/release.sh
```

**Interactive prompts:**
- Confirmation before starting
- Optional testing before release
- Optional push to GitHub

---

### `build-release.sh` - Build Script
Builds the app and creates release files.

**What it does:**
1. Cleans previous builds
2. Builds Release configuration with Xcode
3. Exports app bundle
4. Creates DMG file
5. Creates ZIP archive
6. Calculates SHA256 checksums
7. Generates release notes

**Output:**
- `release/Clipso-1.0.3.dmg`
- `release/Clipso-1.0.3.dmg.sha256`
- `release/Clipso-1.0.3.zip`
- `release/Clipso-1.0.3.zip.sha256`
- `release/RELEASE_NOTES.md`

**Usage:**
```bash
./scripts/build-release.sh
```

**Requirements:**
- Xcode installed
- Valid code signing (or disabled for testing)

---

### `create-github-release.sh` - GitHub Release
Creates release on GitHub and uploads files.

**What it does:**
1. Checks if release files exist
2. Authenticates with GitHub CLI
3. Creates release tag
4. Uploads DMG, ZIP, and checksums
5. Publishes release notes

**Output:**
- GitHub release at: `https://github.com/dcrivac/Clipso/releases/tag/v1.0.3`
- Download URL: `https://github.com/dcrivac/Clipso/releases/download/v1.0.3/Clipso-1.0.3.dmg`

**Usage:**
```bash
./scripts/create-github-release.sh
```

**Requirements:**
- GitHub CLI (`gh`) installed
- Authenticated with GitHub
- Release files in `release/` directory

**Install GitHub CLI:**
```bash
brew install gh
gh auth login
```

---

### `update-download-links.sh` - Update Links
Updates all download links in website files.

**What it does:**
1. Finds all download links
2. Updates to v1.0.3
3. Updates in:
   - `website/index.html`
   - `docs/index.html`
   - `README.md`

**Usage:**
```bash
./scripts/update-download-links.sh
```

**After running:**
```bash
git diff  # Review changes
git add -A
git commit -m "Update download links to v1.0.3"
git push
```

---

## Version Configuration

To release a different version, update `VERSION` in each script:

```bash
# In all scripts, change:
VERSION="1.0.3"

# To your desired version:
VERSION="1.0.4"
```

Or use `sed` to update all at once:
```bash
sed -i 's/VERSION="1.0.3"/VERSION="1.0.4"/' scripts/*.sh
```

---

## Testing

### Test the DMG
```bash
# After build-release.sh
open release/Clipso-1.0.3.dmg

# Install and test:
# 1. Drag to Applications
# 2. Launch Clipso
# 3. Click menu bar icon → "Activate License"
# 4. Click "Purchase Lifetime" or "Purchase Annual"
# 5. Verify Paddle checkout opens (not LemonSqueezy!)
```

### Verify Paddle Integration
```bash
# Check URLs in app
strings release/Clipso.app/Contents/MacOS/Clipso | grep -i "paddle\|checkout"

# Should show:
# https://sandbox-checkout.paddle.com
# https://checkout.paddle.com
```

---

## Troubleshooting

### Build Fails
```bash
# Clean Xcode cache
rm -rf ~/Library/Developer/Xcode/DerivedData

# Try building manually
xcodebuild clean -scheme ClipboardManager
xcodebuild archive -scheme ClipboardManager -archivePath build/Clipso.xcarchive
```

### GitHub CLI Not Installed
```bash
brew install gh
gh auth login
```

### Permission Denied
```bash
chmod +x scripts/*.sh
```

### DMG Creation Fails
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

---

## Files Created

After running `release.sh`:

```
release/
├── Clipso-1.0.3.dmg           # macOS disk image
├── Clipso-1.0.3.dmg.sha256    # Checksum for DMG
├── Clipso-1.0.3.zip           # ZIP archive
├── Clipso-1.0.3.zip.sha256    # Checksum for ZIP
├── Clipso.app/                # Built app bundle
└── RELEASE_NOTES.md           # Release description
```

---

## Workflow

### Complete Release
```bash
# 1. Make code changes (fix bugs, add features, update Paddle config)
git add -A
git commit -m "Your changes"

# 2. Run release script
./scripts/release.sh

# 3. Script handles:
#    - Building
#    - Creating DMG
#    - GitHub release
#    - Updating links
#    - Committing
#    - Pushing

# 4. Verify on website
#    https://dcrivac.github.io/Clipso/
```

### Manual Release (More Control)
```bash
# 1. Build
./scripts/build-release.sh

# 2. Test locally
open release/Clipso-1.0.3.dmg
# Install, launch, test Paddle buttons

# 3. If tests pass, create release
./scripts/create-github-release.sh

# 4. Update website links
./scripts/update-download-links.sh

# 5. Commit and push
git add -A
git commit -m "Release v1.0.3"
git push
```

---

## Support

- **Issues**: https://github.com/dcrivac/Clipso/issues
- **Releases**: https://github.com/dcrivac/Clipso/releases
- **Website**: https://dcrivac.github.io/Clipso/
