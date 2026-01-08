#!/bin/bash

# ClipboardManager DMG Creation Script
# Run this after exporting ClipboardManager.app from Xcode

set -e

echo "🚀 Creating ClipboardManager DMG..."
echo ""

# Check if .app exists
if [ ! -d "$HOME/Desktop/ClipboardManager-Release/ClipboardManager.app" ]; then
    echo "❌ Error: ClipboardManager.app not found!"
    echo ""
    echo "Please export the app from Xcode first:"
    echo "1. Product → Archive"
    echo "2. Distribute App → Copy App"
    echo "3. Export to: ~/Desktop/ClipboardManager-Release/"
    echo ""
    exit 1
fi

# Create DMG
echo "📦 Creating DMG..."
cd "$HOME/Desktop/ClipboardManager-Release"

create-dmg \
  --volname "ClipboardManager" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "ClipboardManager.app" 175 120 \
  --hide-extension "ClipboardManager.app" \
  --app-drop-link 425 120 \
  "ClipboardManager-v1.0.0-macOS.dmg" \
  "ClipboardManager.app"

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "📍 Location: ~/Desktop/ClipboardManager-Release/ClipboardManager-v1.0.0-macOS.dmg"
echo ""

# Calculate checksum
echo "🔐 Calculating checksum..."
shasum -a 256 "ClipboardManager-v1.0.0-macOS.dmg" > "ClipboardManager-v1.0.0-macOS.dmg.sha256"

echo "✅ Checksum saved: ClipboardManager-v1.0.0-macOS.dmg.sha256"
echo ""

# Show file size
SIZE=$(du -h "ClipboardManager-v1.0.0-macOS.dmg" | cut -f1)
echo "📊 DMG Size: $SIZE"
echo ""

echo "🎉 Release build complete!"
echo ""
echo "Next steps:"
echo "1. Test the DMG by double-clicking it"
echo "2. Upload to GitHub Releases"
echo "3. Update landing page download links"
echo ""
