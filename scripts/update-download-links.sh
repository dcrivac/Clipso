#!/bin/bash

# Update Website Download Links Script
# Updates all download links to point to the new release

set -e

VERSION="1.0.3"
APP_NAME="Clipso"
REPO="dcrivac/Clipso"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${APP_NAME}-${VERSION}.dmg"

echo "🔗 Updating Download Links to v${VERSION}"
echo "=================================================="

# Function to update links in a file
update_file() {
    local file=$1
    local old_pattern="releases/download/v[0-9]\.[0-9]\.[0-9]/[^\"]*\.dmg"

    if [ -f "$file" ]; then
        echo "📝 Updating $file..."
        sed -i.bak -E "s|${old_pattern}|releases/download/v${VERSION}/${APP_NAME}-${VERSION}.dmg|g" "$file"
        rm -f "${file}.bak"
        echo "   ✅ Updated"
    fi
}

# Update website files
update_file "website/index.html"
update_file "docs/index.html"
update_file "README.md"

echo ""
echo "✅ Download Links Updated!"
echo "=================================================="
echo "📥 New download URL:"
echo "   ${DOWNLOAD_URL}"
echo ""
echo "📂 Files updated:"
echo "   - website/index.html"
echo "   - docs/index.html"
echo "   - README.md"
echo ""
echo "🎯 Next Steps:"
echo "   1. Review changes: git diff"
echo "   2. Commit: git add -A && git commit -m 'Update download links to v${VERSION}'"
echo "   3. Push: git push"
echo ""
