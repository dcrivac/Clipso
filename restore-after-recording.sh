#!/bin/bash

# restore-after-recording.sh
# Restores your Mac settings after demo video recording

echo "🔄 Restoring Mac settings..."
echo ""

# 1. Show desktop icons again
echo "✓ Showing desktop icons..."
defaults write com.apple.finder CreateDesktop -bool true
killall Finder 2>/dev/null

# 2. Disable Do Not Disturb
echo "✓ Restoring notifications..."

echo ""
echo "✅ Mac settings restored!"
echo ""
echo "Your desktop is back to normal."
echo ""
