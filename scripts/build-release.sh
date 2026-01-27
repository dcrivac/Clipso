#!/bin/bash

# Clipso Build and Release Script
# Builds app with Paddle integration, creates DMG, and publishes release

set -e  # Exit on any error

# Configuration
VERSION="1.0.3"
APP_NAME="Clipso"
BUNDLE_ID="com.clipso.ClipboardManager"
SCHEME="Clipso"
BUILD_DIR="build"
RELEASE_DIR="release"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "🚀 Building ${APP_NAME} v${VERSION} with Paddle Integration"
echo "=================================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf ${BUILD_DIR}
rm -rf ${RELEASE_DIR}
mkdir -p ${RELEASE_DIR}

# Build the app
echo "🔨 Building Release version..."
xcodebuild clean \
    -scheme ${SCHEME} \
    -configuration Release

xcodebuild archive \
    -scheme ${SCHEME} \
    -configuration Release \
    -archivePath ${BUILD_DIR}/${APP_NAME}.xcarchive \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export the app
echo "📦 Exporting app..."
xcodebuild -exportArchive \
    -archivePath ${BUILD_DIR}/${APP_NAME}.xcarchive \
    -exportPath ${BUILD_DIR}/Export \
    -exportOptionsPlist ExportOptions.plist

# Copy app to release directory
echo "📁 Preparing release files..."
APP_PATH="${BUILD_DIR}/Export/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    # Try alternate path
    APP_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app"
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

cp -R "$APP_PATH" ${RELEASE_DIR}/

# Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder ${RELEASE_DIR}/${APP_NAME}.app \
    -ov -format UDZO \
    ${RELEASE_DIR}/${DMG_NAME}

# Calculate SHA256
echo "🔐 Calculating SHA256..."
cd ${RELEASE_DIR}
shasum -a 256 ${DMG_NAME} > ${DMG_NAME}.sha256
SHA256=$(cat ${DMG_NAME}.sha256 | awk '{print $1}')
cd ..

# Create release notes
echo "📝 Creating release notes..."
cat > ${RELEASE_DIR}/RELEASE_NOTES.md << EOF
# ${APP_NAME} v${VERSION} - Paddle Integration

## 🎉 What's New

### Paddle Billing Integration
- ✅ Replaced LemonSqueezy with Paddle for payment processing
- ✅ New license activation system
- ✅ Improved checkout experience
- ✅ Better transaction management

### Purchase Options
- 💎 **Lifetime License**: \$29.99 (one-time payment)
- 📅 **Annual Subscription**: \$7.99/year

### Features
- ✅ Secure license validation
- ✅ Device limit enforcement (3 devices per license)
- ✅ Periodic re-validation
- ✅ Enhanced Pro features unlocking

## 📦 Installation

1. Download \`${DMG_NAME}\`
2. Open the DMG file
3. Drag ${APP_NAME}.app to Applications
4. Launch from Applications folder
5. Grant necessary permissions when prompted

## 🔐 Verification

\`\`\`
SHA256: ${SHA256}
\`\`\`

Verify with:
\`\`\`bash
shasum -a 256 ${DMG_NAME}
\`\`\`

## 🛠️ Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon or Intel processor

## 📖 Getting Started

### Free Version
- Download and start using immediately
- Unlimited clipboard history
- 10 AI semantic searches per day

### Pro Version
- Click "Activate License" in menu bar
- Purchase Lifetime or Annual license
- Unlock unlimited AI searches and all Pro features

## 🐛 Bug Fixes

- Fixed download links pointing to 404
- Updated all payment processing to Paddle
- Improved error handling in license activation

## 🔗 Links

- **Website**: https://dcrivac.github.io/Clipso/
- **GitHub**: https://github.com/dcrivac/Clipso
- **Support**: https://github.com/dcrivac/Clipso/issues

---

**Full Changelog**: https://github.com/dcrivac/Clipso/compare/v1.0.2...v${VERSION}
EOF

# Create ZIP for alternate download
echo "🗜️ Creating ZIP archive..."
cd ${RELEASE_DIR}
zip -r ${APP_NAME}-${VERSION}.zip ${APP_NAME}.app
shasum -a 256 ${APP_NAME}-${VERSION}.zip > ${APP_NAME}-${VERSION}.zip.sha256
cd ..

echo ""
echo "✅ Build Complete!"
echo "=================================================="
echo "📦 Files created in ${RELEASE_DIR}/:"
ls -lh ${RELEASE_DIR}/
echo ""
echo "📋 Release Info:"
echo "   Version: ${VERSION}"
echo "   DMG: ${DMG_NAME}"
echo "   SHA256: ${SHA256}"
echo ""
echo "🎯 Next Steps:"
echo "   1. Test the DMG: open ${RELEASE_DIR}/${DMG_NAME}"
echo "   2. Verify Paddle buttons work"
echo "   3. Run: ./scripts/create-github-release.sh"
echo ""
