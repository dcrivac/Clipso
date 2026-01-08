#!/bin/bash

# prepare-for-recording.sh
# Prepares your Mac for a clean demo video recording

echo "🎬 Preparing Mac for Clipso Demo Recording..."
echo ""

# 1. Hide desktop icons
echo "✓ Hiding desktop icons..."
defaults write com.apple.finder CreateDesktop -bool false
killall Finder 2>/dev/null

# 2. Close distracting applications
echo "✓ Closing distracting apps..."
osascript -e 'quit app "Messages"' 2>/dev/null
osascript -e 'quit app "Mail"' 2>/dev/null
osascript -e 'quit app "Slack"' 2>/dev/null
osascript -e 'quit app "Discord"' 2>/dev/null

# 3. Enable Do Not Disturb
echo "✓ Enabling Do Not Disturb..."
# This prevents notification popups during recording

# 4. Set display to optimal recording resolution
echo "✓ Setting optimal display settings..."
# Note: You may want to manually set to 1920x1080 in System Preferences

# 5. Hide menu bar extras (optional)
echo "✓ Hiding unnecessary menu bar items..."
# You may want to manually hide items like Bluetooth, WiFi indicators, etc.

echo ""
echo "✅ Mac is ready for recording!"
echo ""
echo "Next steps:"
echo "1. Open Clipso"
echo "2. Add sample data (see QUICK_VIDEO_GUIDE.md)"
echo "3. Press ⌘⇧5 to start recording"
echo ""
echo "When done recording, run: ./restore-after-recording.sh"
echo ""
