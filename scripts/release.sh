#!/bin/bash

# Master Release Script
# Runs the complete release process: build, create release, update links

set -e

VERSION="1.0.3"

echo "🚀 Clipso v${VERSION} - Complete Release Process"
echo "=================================================="
echo ""
echo "This script will:"
echo "  1. Build the app with Paddle integration"
echo "  2. Create DMG and ZIP files"
echo "  3. Create GitHub release"
echo "  4. Upload release files"
echo "  5. Update download links on website"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# Step 1: Build
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Building App"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/build-release.sh

# Step 2: Test (optional)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Testing (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 DMG created at: release/Clipso-${VERSION}.dmg"
echo ""
read -p "Test the DMG before releasing? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open release/Clipso-${VERSION}.dmg
    echo ""
    echo "🧪 Please test the app:"
    echo "   1. Install from DMG"
    echo "   2. Launch Clipso"
    echo "   3. Click menu bar icon → 'Activate License'"
    echo "   4. Verify 'Purchase Lifetime' and 'Purchase Annual' open Paddle"
    echo ""
    read -p "Tests passed? Continue with release? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Release cancelled"
        exit 1
    fi
fi

# Step 3: Create GitHub Release
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Creating GitHub Release"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/create-github-release.sh

# Step 4: Update Download Links
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Updating Download Links"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./scripts/update-download-links.sh

# Step 5: Commit and Push
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Committing Changes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

git add -A
git commit -m "Release v${VERSION} with Paddle integration

- Built new DMG with Paddle payment integration
- Updated purchase buttons to use Paddle checkout
- Fixed LemonSqueezy → Paddle migration
- Updated download links to v${VERSION}

Download: https://github.com/dcrivac/Clipso/releases/download/v${VERSION}/Clipso-${VERSION}.dmg"

echo ""
read -p "Push to GitHub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main
    echo "   ✅ Pushed to GitHub"
fi

echo ""
echo "🎉 RELEASE COMPLETE!"
echo "=================================================="
echo ""
echo "✅ All steps completed successfully!"
echo ""
echo "📦 Release v${VERSION}"
echo "   🔗 https://github.com/dcrivac/Clipso/releases/tag/v${VERSION}"
echo ""
echo "📥 Download:"
echo "   https://github.com/dcrivac/Clipso/releases/download/v${VERSION}/Clipso-${VERSION}.dmg"
echo ""
echo "🌐 Website will update automatically (GitHub Pages)"
echo "   https://dcrivac.github.io/Clipso/"
echo ""
echo "🎯 Verification:"
echo "   1. Download from website"
echo "   2. Install and launch"
echo "   3. Test Paddle purchase buttons"
echo ""
