# ⚠️ IMPORTANT: Run on macOS, Not Linux

## The Issue

You're trying to run `xcodebuild` on a **Linux server** (this Claude Code environment), but:
- `xcodebuild` only works on **macOS**
- You need **Xcode** installed
- DMG creation requires macOS tools

## ✅ Solution: Run on Your Mac

### Step 1: Get Code on Your Mac

**Option A: Clone from GitHub**
```bash
# On your Mac terminal:
cd ~/Desktop
git clone https://github.com/dcrivac/Clipso.git
cd Clipso
```

**Option B: Pull latest changes**
```bash
# If you already have it:
cd ~/path/to/Clipso
git pull origin main
```

### Step 2: Run Build Script on Mac
```bash
# On your Mac:
./scripts/simple-build.sh
```

This will:
1. ✅ Build Clipso.app with Paddle integration
2. ✅ Create DMG file
3. ✅ Calculate SHA256 checksum
4. ✅ Save to `release/Clipso-1.0.3.dmg`

**Time**: ~2-3 minutes

### Step 3: Test the DMG
```bash
open release/Clipso-1.0.3.dmg
```

**Critical Test:**
1. Install Clipso.app to Applications
2. Launch Clipso
3. Click menu bar icon → **"Activate License"**
4. Click **"Purchase Lifetime ($29.99)"**
   - ✅ Should open: Paddle checkout (sandbox)
   - ❌ Should NOT open: LemonSqueezy
5. Click **"Purchase Annual ($7.99)"**
   - ✅ Should open: Paddle checkout (sandbox)

**If both open Paddle** → Success! ✅

### Step 4: Create GitHub Release (Mac)

**Install GitHub CLI** (if not already installed):
```bash
brew install gh
gh auth login
```

**Create the release:**
```bash
./scripts/create-github-release.sh
```

This uploads:
- Clipso-1.0.3.dmg
- SHA256 checksum
- Release notes

---

## 🤔 Why Can't I Build on Linux?

Because:
- ❌ `xcodebuild` doesn't exist on Linux
- ❌ Can't create macOS apps on Linux
- ❌ DMG files require macOS tools (`hdiutil`)
- ❌ Xcode is macOS-only

**You MUST build on macOS.**

---

## 🚀 Quick Commands (On Your Mac)

```bash
# 1. Clone or pull latest code
git pull origin main

# 2. Build
./scripts/simple-build.sh

# 3. Test the DMG
open release/Clipso-1.0.3.dmg
# Install, launch, test "Purchase" buttons

# 4. If tests pass, create release
./scripts/create-github-release.sh

# 5. Update website download links
./scripts/update-download-links.sh

# 6. Commit and push
git add -A
git commit -m "Release v1.0.3 with Paddle integration"
git push origin main
```

---

## 📱 Alternative: Use Xcode GUI (Easiest)

If you prefer, use Xcode:

1. **On your Mac**, open: `Clipso.xcodeproj`
2. Select **Product** → **Archive**
3. Click **Distribute App** → **Copy App**
4. Save the .app file
5. Create DMG manually:
   ```bash
   hdiutil create -volname "Clipso" \
       -srcfolder Clipso.app \
       -ov -format UDZO \
       Clipso-1.0.3.dmg
   ```

---

## 🎯 What You're Fixing

**Problem**:
- Current v1.0.2 DMG has **LemonSqueezy** purchase buttons
- Menu bar → "Activate License" → Purchase → LemonSqueezy ❌

**After building v1.0.3**:
- New DMG will have **Paddle** purchase buttons
- Menu bar → "Activate License" → Purchase → Paddle ✅

**Why?**
- Your source code already has Paddle integration
- v1.0.2 was built BEFORE the Paddle changes
- Need to rebuild to include new code

---

## 📋 Summary

1. **Move to your Mac** (or work on Mac)
2. **Pull latest code** from GitHub
3. **Run**: `./scripts/simple-build.sh`
4. **Test the DMG** (verify Paddle buttons)
5. **Create GitHub release** (if tests pass)
6. **Update website** (download links)

**The code is ready, just needs to be built on macOS!** 🚀

---

## ❓ Questions?

- **Don't have a Mac?** You'll need one to build macOS apps
- **Can I use GitHub Actions?** Yes, but requires macOS runner (costs money)
- **Virtual Mac?** Possible with MacStadium or similar services

**Easiest**: Just run on your physical Mac! 💻
