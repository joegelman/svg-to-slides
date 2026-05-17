#!/bin/sh
# svg-to-slides watcher — called every 5 s by launchd.
# Sources ~/.config/svg-to-slides.conf for DROP_DIR and DRIVE_DIR.

CONF="$HOME/.config/svg-to-slides.conf"
[ -f "$CONF" ] && . "$CONF"

: "${DROP_DIR:=$HOME/Library/Application Support/svg-to-slides-drop}"
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

count=$(find "$DROP_DIR" -maxdepth 1 -name "*.svg" -type f 2>/dev/null | wc -l | tr -d ' ')
[ "$count" -eq 0 ] && exit 0

find "$DROP_DIR" -maxdepth 1 -name "*.svg" -type f -print0 | \
    xargs -0 python3 "$HOME/.local/bin/svg_to_slides.py" && \
find "$DROP_DIR" -maxdepth 1 -name "*.svg" -type f -delete

# Move PPTX to Drive if configured
if [ -n "$DRIVE_DIR" ]; then
    find "$DROP_DIR" -maxdepth 1 -name "*.pptx" -type f -print0 | \
        xargs -0 -I{} mv {} "$DRIVE_DIR/"
fi
