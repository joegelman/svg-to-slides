# svg-to-slides

Convert SVG files to editable vector shapes in Google Slides — no OAuth, no API keys, no manual Keynote detour.

Drop SVGs into a folder on your Desktop. Within seconds they appear as a multi-slide PPTX in your Google Drive, with every path individually selectable and editable in Slides.

---

## How it works

```
SVG file(s)
    │
    ▼  drag onto Desktop alias
~/Library/Application Support/svg-to-slides-drop/   ← TCC-free staging area
    │
    ▼  launchd polls every 5 s
svg_to_slides.py                                      ← SVG → PPTX (DrawingML)
    │
    ▼  mv
~/Library/CloudStorage/GoogleDrive-*/My Drive/…      ← Drive Desktop syncs it
    │
    ▼  Google Drive "Convert uploads" (optional)
Google Slides native file
```

`launchd` runs the watcher as a background agent. It cannot read `~/Documents` or `~/Desktop` (macOS TCC restrictions), so a staging folder inside `~/Library/Application Support/` is used as the drop zone, exposed to the user via a Desktop alias.

SVG paths are converted to DrawingML `<a:custGeom>` shapes — one `<p:sp>` per `<path>` element — so every sub-path is independently selectable in Slides after import.

---

## Requirements

- macOS (tested on Sequoia 15)
- [Homebrew](https://brew.sh)
- ImageMagick (`brew install imagemagick`) — only for PNG→SVG tracing
- potrace (`brew install potrace`) — only for PNG→SVG tracing
- Python 3 + python-pptx + lxml

```sh
brew install imagemagick potrace
pip3 install --break-system-packages python-pptx lxml
```

---

## Installation

**Double-click `Install.command`** in Finder. That's it.

Terminal opens, installs Python deps locally (no `sudo`, no `--break-system-packages`), detects your Google Drive automatically, loads the background agent, and creates the Desktop alias. Press Return when done to close the window.

From the command line:

```sh
git clone https://github.com/joegelman/svg-to-slides.git
cd svg-to-slides
./install.sh   # thin wrapper around Install.command
```

`Install.command` will:
1. Install `python-pptx` and `lxml` to `~/.local/share/svg-to-slides/lib/` (isolated, no system pollution)
2. Install `svg_to_slides.py` to `~/.local/bin/`
3. Auto-detect your Google Drive and create an `SVG to Slides` output folder inside it
4. Create the staging drop folder and load the launchd agent
5. Create a Desktop alias pointing at the drop folder

To reconfigure the Drive destination after install, edit `~/.config/svg-to-slides.conf` and reload the agent:

```sh
launchctl unload ~/Library/LaunchAgents/com.$USER.svg-to-slides.plist
launchctl load  ~/Library/LaunchAgents/com.$USER.svg-to-slides.plist
```

---

## Configuration

`~/.config/svg-to-slides.conf` (shell syntax, sourced by the watcher):

```sh
DROP_DIR="$HOME/Library/Application Support/svg-to-slides-drop"
DRIVE_DIR="$HOME/Library/CloudStorage/GoogleDrive-you@example.com/My Drive/SVG to Slides"
```

`DROP_DIR` — where you drop SVG files. Defaults to the Application Support path above.  
`DRIVE_DIR` — where finished PPTX files are moved. Leave unset to keep them in `DROP_DIR`.

---

## Usage

### Drag and drop (primary workflow)

1. Drag one or more `.svg` files onto the **SVG to Slides Drop** alias on your Desktop.
2. Wait up to 10 seconds.
3. A `slides.pptx` (or `name.pptx` for a single file) appears in your Drive folder.
4. Open it in Google Slides — shapes are fully editable vectors.

If you enabled **Convert uploads** in Google Drive settings (Drive on web → Settings ⚙ → Convert uploads), the PPTX auto-becomes a native Slides file with no extra steps.

### Command line

```sh
python3 ~/.local/bin/svg_to_slides.py icon.svg logo.svg banner.svg
# → slides.pptx in the same directory, one slide per SVG
```

### PNG → SVG tracing

```sh
./png_to_svg.sh ~/path/to/icons/*.png
# → ../svgs/<name>.svg relative to each input file
```

Traces dark pixels on a transparent background via ImageMagick + potrace. Adjust the `-threshold` value in `png_to_svg.sh` if the output is too noisy or too sparse.

---

## Finder Quick Action (alternative)

A Quick Action lets you right-click any SVG in Finder and convert it on the spot, without using the drop zone.

1. Open Automator → New Document → Quick Action.
2. Set **Workflow receives** = `image files` in `Finder`.
3. Add a **Run Shell Script** action, pass input **as arguments**:
   ```sh
   python3 ~/.local/bin/svg_to_slides.py "$@"
   ```
4. Save as `Convert SVG to PPTX`.

Right-click any `.svg` → Quick Actions → **Convert SVG to PPTX**. The PPTX lands next to the source file.

---

## File inventory

| Path | Description |
|---|---|
| `~/.local/bin/svg_to_slides.py` | Core SVG→PPTX converter |
| `~/Documents/png_to_svg.sh` | PNG→SVG tracer (ImageMagick + potrace) |
| `~/Library/Scripts/svg_to_slides_watch.sh` | Watcher script run by launchd |
| `~/Library/LaunchAgents/com.$USER.svg-to-slides.plist` | launchd agent (polls every 5 s) |
| `~/Library/Application Support/svg-to-slides-drop/` | Staging drop folder |
| `~/.config/svg-to-slides.conf` | User configuration |
| `/tmp/svg-to-slides.log` | Live log (`tail -f` to watch) |

---

## Monitoring

```sh
tail -f /tmp/svg-to-slides.log
```

To manually trigger a conversion run:

```sh
/bin/sh ~/Library/Scripts/svg_to_slides_watch.sh
```

To reload the agent after config changes:

```sh
launchctl unload ~/Library/LaunchAgents/com.$USER.svg-to-slides.plist
launchctl load  ~/Library/LaunchAgents/com.$USER.svg-to-slides.plist
```

---

## Uninstallation

```sh
./uninstall.sh
```

---

## Technical notes

**Why not Folder Actions or WatchPaths?**  
Both are silently broken on macOS Sequoia (15.x). Folder Action `on adding folder items` handlers never fire. `WatchPaths` in launchd plists also never delivers events. Polling with `StartInterval` is the only reliable mechanism.

**Why the staging folder?**  
macOS TCC blocks launchd agents from reading `~/Documents`, `~/Desktop`, and `~/Library/CloudStorage`. The `~/Library/Application Support/` subtree is exempt. The watcher reads from there, then `mv`s the output to Drive (write access to CloudStorage is permitted even when read is blocked).

**SVG path conversion**  
SVG path commands (M, L, C, S, Q, Z, arcs) are translated to DrawingML equivalents. Quadratic beziers (Q/q) are promoted to cubic. Arc commands (A/a) fall back to a straight line to the endpoint — complex arc shapes may look angular; re-export with more path segments if needed.

**potrace coordinate system**  
potrace outputs `transform="translate(0,H) scale(0.1,-0.1)"` on its path group — a Y-axis flip to convert internal raster coordinates to SVG screen space. The converter applies this transform correctly (scale then translate, right-to-left per SVG spec) before mapping to DrawingML coordinates.

---

## License

MIT
