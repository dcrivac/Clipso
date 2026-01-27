#!/bin/bash

# Simple Build Script for Clipso v1.0.3
# This script builds the app without requiring xcodebuild in PATH

set -e

VERSION="1.0.3"
APP_NAME="Clipso"
SCHEME="Clipso"

echo "🚀 Building ${APP_NAME} v${VERSION} with Paddle Integration"
echo "=================================================="

# Check if xcodebuild exists
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found in PATH"
    echo ""
    echo "This script needs to run on macOS with Xcode installed."
    echo ""
    echo "📱 You're running this on Linux/remote server."
    echo ""
    echo "✅ SOLUTION: Run this on your Mac instead:"
    echo ""
    echo "1. Clone/pull the latest code on your Mac"
    echo "2. Open Terminal"
    echo "3. cd to the Clipso directory"
    echo "4. Run: ./scripts/simple-build.sh"
    echo ""
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
rm -rf release/
mkdir -p release/

# Build the app
echo "🔨 Building ${APP_NAME}..."
xcodebuild clean -scheme ${SCHEME} -configuration Release

xcodebuild build \
    -scheme ${SCHEME} \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Find the built app
echo "📦 Locating built app..."
APP_PATH=$(find build/DerivedData/Build/Products/Release -name "${APP_NAME}.app" -type d | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Could not find ${APP_NAME}.app"
    echo "Searched in: build/DerivedData/Build/Products/Release"
    exit 1
fi

echo "✅ Found app at: $APP_PATH"

# Copy to release directory
echo "📁 Copying to release directory..."
cp -R "$APP_PATH" release/

# Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder release/${APP_NAME}.app \
    -ov -format UDZO \
    release/${APP_NAME}-${VERSION}.dmg

# Calculate SHA256
echo "🔐 Calculating SHA256..."
cd release/
shasum -a 256 ${APP_NAME}-${VERSION}.dmg > ${APP_NAME}-${VERSION}.dmg.sha256
SHA256=$(cat ${APP_NAME}-${VERSION}.dmg.sha256 | awk '{print $1}')
cd ..

echo ""
echo "✅ Build Complete!"
echo "=================================================="
echo "📦 DMG: release/${APP_NAME}-${VERSION}.dmg"
echo "🔐 SHA256: ${SHA256}"
echo ""
echo "🧪 Test the app:"
echo "   open release/${APP_NAME}-${VERSION}.dmg"
echo ""
echo "   1. Install to Applications"
echo "   2. Launch Clipso"
echo "   3. Click menu bar → 'Activate License'"
echo "   4. Test 'Purchase Lifetime' → Should open Paddle!"
echo "   5. Test 'Purchase Annual' → Should open Paddle!"
echo ""
