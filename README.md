# svg-to-slides

Convert SVG files to editable vector shapes for use in Google Slides.

**github.com/joegelman/svg-to-slides** · glmn.co

---

## SYNOPSIS

```
Install.command          # first-time setup, double-click in Finder
svg_to_slides.py FILE [FILE ...]
png_to_svg.sh FILE [FILE ...]
```

---

## DESCRIPTION

`svg_to_slides.py` reads one or more SVG files and writes a PPTX where each converted SVG occupies one slide. Every `<path>` element becomes a discrete DrawingML `<a:custGeom>` shape with a tight bounding box — individually selectable and editable after import into Google Slides.

A launchd agent polls a drop folder every 5 seconds. SVGs placed there are converted and the resulting PPTX is moved into Google Drive automatically.

`png_to_svg.sh` traces dark pixels in a PNG to SVG paths via ImageMagick and potrace.

---

## INSTALL

Double-click `Install.command`. Terminal opens, runs setup, closes.

```sh
git clone https://github.com/joegelman/svg-to-slides.git
cd svg-to-slides
./install.sh
```

What it does:

- Installs `python-pptx` and `lxml` to `~/.local/share/svg-to-slides/lib/`
- Copies scripts to `~/.local/bin/`
- Detects Google Drive and creates `…/My Drive/SVG to Slides/`
- Creates the drop folder and loads the launchd agent
- Adds a Desktop alias pointing at the drop folder

**Dependencies:** Python 3, pip3 (Xcode CLT). For PNG tracing: `brew install imagemagick potrace`. ***Google Drive for Desktop installed** and logged in on your machine.*

---

## USAGE

**Drop zone**

Drag `.svg` files onto **SVG to Slides Drop** on the Desktop. A `slides.pptx` appears in the configured Drive folder within 10 seconds. Enable *Convert uploads* in Google Drive settings to auto-convert to a native Slides file.

**Command line**

```sh
svg_to_slides.py a.svg b.svg c.svg
# → slides.pptx alongside the input files, one slide per SVG

png_to_svg.sh icons/*.png
# → ../svgs/<name>.svg relative to each input
```

**Finder Quick Action (optional)**

Automator → Quick Action → Run Shell Script → pass input as arguments:

```sh
python3 ~/.local/bin/svg_to_slides.py "$@"
```

Save as `Convert SVG to PPTX`. Appears in right-click → Quick Actions.

---

## CONFIGURATION

`~/.config/svg-to-slides.conf` — sourced by the watcher on each poll.

```sh
DROP_DIR="$HOME/Library/Application Support/svg-to-slides-drop"
DRIVE_DIR="$HOME/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/SVG to Slides"
```

Reload after changes:

```sh
launchctl unload ~/Library/LaunchAgents/com.$USER.svg-to-slides.plist
launchctl load   ~/Library/LaunchAgents/com.$USER.svg-to-slides.plist
```

---

## FILES

| Path | |
|---|---|
| `~/.local/bin/svg_to_slides.py` | converter |
| `~/.local/bin/png_to_svg.sh` | PNG tracer |
| `~/Library/Scripts/svg_to_slides_watch.sh` | watcher |
| `~/Library/LaunchAgents/com.$USER.svg-to-slides.plist` | launchd agent |
| `~/Library/Application Support/svg-to-slides-drop/` | drop folder |
| `~/.config/svg-to-slides.conf` | config |
| `/tmp/svg-to-slides.log` | log |

---

## DIAGNOSTICS

```sh
tail -f /tmp/svg-to-slides.log
/bin/sh ~/Library/Scripts/svg_to_slides_watch.sh   # manual trigger
```

---

## UNINSTALL

```sh
./uninstall.sh
```

Leaves `svg-to-slides-drop/` and `svg-to-slides.conf` in place. Remove manually if desired.

---

## NOTES

Folder Actions and `WatchPaths` are silently broken on macOS Sequoia. `StartInterval` polling is used instead.

macOS TCC blocks launchd from reading `~/Documents`, `~/Desktop`, and `~/Library/CloudStorage`. The drop folder lives in `~/Library/Application Support/` where launchd has access. The watcher writes PPTX output to Drive via `mv`; **write access to CloudStorage is permitted even when read is blocked.**

Arc commands (`A`/`a`) in SVG paths fall back to straight lines. Re-export with more path segments if arcs appear angular.

---

## LICENSE

MIT
