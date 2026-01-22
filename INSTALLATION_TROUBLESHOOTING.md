# Installation Troubleshooting

## "Clipso is damaged and can't be opened" Error

If you see this error when trying to open Clipso, don't worry - **the app is not actually damaged**. This is macOS Gatekeeper blocking the app because it's not yet notarized by Apple.

### Quick Fix (Recommended)

1. **Open Terminal** (Applications → Utilities → Terminal)
2. **Run this command**:
   ```bash
   xattr -cr /Applications/Clipso.app
   ```
3. **Try opening Clipso again** - it should work now!

### Alternative Method: Right-Click to Open

1. **Don't** double-click the app
2. **Right-click** (or Control+click) on `Clipso.app` in your Applications folder
3. Select **"Open"** from the menu
4. Click **"Open"** in the security dialog
5. The app will now launch and won't show this error again

### Why Does This Happen?

The current release of Clipso is not code-signed or notarized by Apple. This is common for open-source indie apps. The developer is working on proper code signing for future releases.

### Is It Safe?

Yes! Clipso is 100% open source. You can:
- View the complete source code at https://github.com/dcrivac/Clipso
- Build it yourself from source
- Verify the checksum of your download matches the official release

### Verify Your Download (Optional)

To ensure your download wasn't tampered with:

```bash
# Download the checksum file from the release page
# Then run:
shasum -a 256 -c Clipso-*.dmg.sha256
```

If you see "OK", your download is authentic.

### Build From Source (Ultimate Safety)

If you prefer to build from source:

```bash
git clone https://github.com/dcrivac/Clipso.git
cd Clipso
xcodebuild -project Clipso.xcodeproj -scheme Clipso -configuration Release
```

### Future Releases

The developer is working on adding proper code signing and notarization to future releases. Once implemented, you won't see this error anymore.

### Still Having Issues?

Open an issue at: https://github.com/dcrivac/Clipso/issues

---

**Note to Developer**: See `CODE_SIGNING_GUIDE.md` for instructions on setting up proper code signing and notarization.
