#!/bin/bash

# GitHub Release Creation Script
# Creates a new release and uploads DMG/ZIP files

set -e

VERSION="1.0.3"
APP_NAME="Clipso"
RELEASE_DIR="release"
REPO="dcrivac/Clipso"

echo "📦 Creating GitHub Release v${VERSION}"
echo "=================================================="

# Check if release files exist
if [ ! -f "${RELEASE_DIR}/${APP_NAME}-${VERSION}.dmg" ]; then
    echo "❌ Error: DMG not found. Run ./scripts/build-release.sh first"
    exit 1
fi

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) not installed"
    echo "Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "🔐 Authenticating with GitHub..."
    gh auth login
fi

echo "🏷️ Creating release v${VERSION}..."

# Create the release
gh release create "v${VERSION}" \
    --repo ${REPO} \
    --title "Clipso v${VERSION} - Paddle Integration" \
    --notes-file ${RELEASE_DIR}/RELEASE_NOTES.md \
    ${RELEASE_DIR}/${APP_NAME}-${VERSION}.dmg \
    ${RELEASE_DIR}/${APP_NAME}-${VERSION}.dmg.sha256 \
    ${RELEASE_DIR}/${APP_NAME}-${VERSION}.zip \
    ${RELEASE_DIR}/${APP_NAME}-${VERSION}.zip.sha256

echo ""
echo "✅ Release Created Successfully!"
echo "=================================================="
echo "🔗 View at: https://github.com/${REPO}/releases/tag/v${VERSION}"
echo ""
echo "📥 Download URL:"
echo "   https://github.com/${REPO}/releases/download/v${VERSION}/${APP_NAME}-${VERSION}.dmg"
echo ""
echo "🎯 Next Steps:"
echo "   1. Update website download links to v${VERSION}"
echo "   2. Test download and installation"
echo "   3. Verify Paddle purchase buttons work"
echo ""
