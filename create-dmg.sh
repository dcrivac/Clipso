#!/bin/bash

# Clipso DMG Creation Script
# Run this after exporting Clipso.app from Xcode

set -e

echo "🚀 Creating Clipso DMG..."
echo ""

# Check if .app exists
if [ ! -d "$HOME/Desktop/Clipso-Release/Clipso.app" ]; then
    echo "❌ Error: Clipso.app not found!"
    echo ""
    echo "Please export the app from Xcode first:"
    echo "1. Product → Archive"
    echo "2. Distribute App → Copy App"
    echo "3. Export to: ~/Desktop/Clipso-Release/"
    echo ""
    exit 1
fi

# Create DMG
echo "📦 Creating DMG..."
cd "$HOME/Desktop/Clipso-Release"

create-dmg \
  --volname "Clipso" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Clipso.app" 175 120 \
  --hide-extension "Clipso.app" \
  --app-drop-link 425 120 \
  "Clipso-v1.0.0-macOS.dmg" \
  "Clipso.app"

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "📍 Location: ~/Desktop/Clipso-Release/Clipso-v1.0.0-macOS.dmg"
echo ""

# Calculate checksum
echo "🔐 Calculating checksum..."
shasum -a 256 "Clipso-v1.0.0-macOS.dmg" > "Clipso-v1.0.0-macOS.dmg.sha256"

echo "✅ Checksum saved: Clipso-v1.0.0-macOS.dmg.sha256"
echo ""

# Show file size
SIZE=$(du -h "Clipso-v1.0.0-macOS.dmg" | cut -f1)
echo "📊 DMG Size: $SIZE"
echo ""

echo "🎉 Release build complete!"
echo ""
echo "Next steps:"
echo "1. Test the DMG by double-clicking it"
echo "2. Upload to GitHub Releases"
echo "3. Update landing page download links"
echo ""
