# 🚀 Release v1.0.3 - Quick Start Guide

## What This Fixes

**Problem**: The "Activate License" window in the macOS app has purchase buttons pointing to **LemonSqueezy** instead of **Paddle**.

**Solution**: Build new v1.0.3 release with Paddle integration using automated scripts.

---

## ⚡ Quick Release (One Command)

```bash
cd /home/user/Clipso
./scripts/release.sh
```

That's it! The script will:
1. ✅ Build app with Paddle integration
2. ✅ Create DMG and ZIP files
3. ✅ Create GitHub release v1.0.3
4. ✅ Upload files
5. ✅ Update download links
6. ✅ Commit and push

**Time**: ~5-10 minutes

---

## 📋 Step-by-Step (If You Want Control)

### Step 1: Build the App
```bash
cd /home/user/Clipso
./scripts/build-release.sh
```

Output:
- `release/Clipso-1.0.3.dmg` ← Install this to test
- `release/Clipso-1.0.3.zip`
- SHA256 checksums

### Step 2: Test the DMG (Important!)
```bash
open release/Clipso-1.0.3.dmg
```

**Test these:**
1. Install Clipso.app to Applications
2. Launch the app
3. Click menu bar icon → **"Activate License"**
4. Click **"Purchase Lifetime ($29.99)"**
5. ✅ **Verify it opens Paddle checkout** (not LemonSqueezy!)
6. Click **"Purchase Annual ($7.99)"**
7. ✅ **Verify it opens Paddle checkout** (not LemonSqueezy!)

**If tests pass, continue!**

### Step 3: Create GitHub Release
```bash
./scripts/create-github-release.sh
```

This creates:
- GitHub release tag: `v1.0.3`
- Uploads DMG and ZIP files
- Publishes release notes

### Step 4: Update Download Links
```bash
./scripts/update-download-links.sh
```

Updates download links from v1.0.2 → v1.0.3 in:
- `website/index.html`
- `docs/index.html`
- `README.md`

### Step 5: Commit and Push
```bash
git add -A
git commit -m "Release v1.0.3 with Paddle integration"
git push origin main
```

---

## 🔧 Prerequisites

### Install GitHub CLI (if not installed)
```bash
brew install gh
gh auth login
```

Follow prompts to authenticate.

### Verify Xcode
```bash
xcode-select --version
```

If not installed:
```bash
xcode-select --install
```

---

## ✅ After Release

### 1. Verify GitHub Release
Visit: https://github.com/dcrivac/Clipso/releases/tag/v1.0.3

Should show:
- ✅ Clipso-1.0.3.dmg
- ✅ Clipso-1.0.3.zip
- ✅ SHA256 checksums
- ✅ Release notes

### 2. Test Download from GitHub
```bash
# Download
curl -L -O https://github.com/dcrivac/Clipso/releases/download/v1.0.3/Clipso-1.0.3.dmg

# Verify checksum
curl -L -O https://github.com/dcrivac/Clipso/releases/download/v1.0.3/Clipso-1.0.3.dmg.sha256
shasum -c Clipso-1.0.3.dmg.sha256
```

### 3. Check Website (GitHub Pages)
After ~2 minutes, visit: https://dcrivac.github.io/Clipso/

Download links should point to v1.0.3

### 4. Test End-to-End
1. Download from website
2. Install app
3. Open "Activate License"
4. Click purchase buttons
5. ✅ Paddle checkout opens!

---

## 🐛 Troubleshooting

### Build Fails with "Archive failed"
```bash
# Clean and retry
xcodebuild clean -scheme ClipboardManager
rm -rf build/
./scripts/build-release.sh
```

### GitHub CLI Authentication Error
```bash
gh auth logout
gh auth login
```

### Permission Denied
```bash
chmod +x scripts/*.sh
```

### DMG Not Created
```bash
# Install command line tools
xcode-select --install
```

---

## 📦 What Gets Created

```
release/
├── Clipso-1.0.3.dmg           ← Main download
├── Clipso-1.0.3.dmg.sha256    ← Checksum
├── Clipso-1.0.3.zip           ← Alternative download
├── Clipso-1.0.3.zip.sha256    ← Checksum
├── Clipso.app/                ← Built app
└── RELEASE_NOTES.md           ← Auto-generated notes
```

---

## 🎯 The Fix

**Before (v1.0.2):**
- Menu bar → "Activate License" → Purchase buttons → LemonSqueezy ❌

**After (v1.0.3):**
- Menu bar → "Activate License" → Purchase buttons → Paddle ✅

**Changed:**
- Rebuilt with updated `LicenseManager.swift`
- Uses `PaddleConfig.swift` (loads from Info.plist)
- Purchase URLs: `https://sandbox-checkout.paddle.com/...`

---

## 💡 Tips

**Fast Build (Skip tests):**
```bash
./scripts/release.sh
# Press 'y' to start
# Press 'n' to skip testing
# Press 'y' to continue with release
```

**Build Only (No Release):**
```bash
./scripts/build-release.sh
# Test locally, don't publish yet
```

**Update Links After Manual Release:**
```bash
# If you created release manually on GitHub
./scripts/update-download-links.sh
git add -A && git commit -m "Update to v1.0.3" && git push
```

---

## 🚀 Ready to Go!

Run this now:
```bash
cd /home/user/Clipso
./scripts/release.sh
```

The script is interactive and will guide you through each step!

**Questions during run:**
1. "Continue?" → `y`
2. "Test the DMG?" → `y` (recommended)
3. "Tests passed?" → `y` (after testing)
4. "Push to GitHub?" → `y`

**Total time**: ~5-10 minutes

---

## 📞 Need Help?

- **Script docs**: `scripts/README.md`
- **GitHub Issues**: https://github.com/dcrivac/Clipso/issues
- **Paddle docs**: `PADDLE_CREDENTIALS.md`

---

**Let's fix those purchase buttons!** 🎉
