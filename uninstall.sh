#!/bin/bash
# uninstall.sh — remove svg-to-slides from macOS
set -e

LABEL="com.${USER}.svg-to-slides"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "Unloading launchd agent..."
launchctl unload "$PLIST" 2>/dev/null && echo "✓ Agent unloaded" || echo "  (agent was not loaded)"

echo "Removing files..."

rm -f "$PLIST"                                                && echo "✓ Removed plist"
rm -f "$HOME/Library/Scripts/svg_to_slides_watch.sh"         && echo "✓ Removed watcher script"
rm -f "$HOME/.local/bin/svg_to_slides.py"                    && echo "✓ Removed svg_to_slides.py"
rm -f "$HOME/.local/bin/png_to_svg.sh"                       && echo "✓ Removed png_to_svg.sh"
rm -rf "$HOME/.local/share/svg-to-slides"                    && echo "✓ Removed Python libs"

ALIAS="$HOME/Desktop/SVG to Slides Drop"
if [[ -L "$ALIAS" || -e "$ALIAS" ]]; then
  rm -f "$ALIAS" && echo "✓ Removed Desktop alias"
fi

echo ""
echo "The drop folder and config are left in place:"
echo "  $HOME/Library/Application Support/svg-to-slides-drop/"
echo "  $HOME/.config/svg-to-slides.conf"
echo ""
echo "Remove them manually if you want a clean slate:"
echo "  rm -rf \"$HOME/Library/Application Support/svg-to-slides-drop\""
echo "  rm -f  \"$HOME/.config/svg-to-slides.conf\""
