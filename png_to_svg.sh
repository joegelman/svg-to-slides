#!/bin/bash
# Trace black parts of a PNG as SVG paths on transparent background.
# Output goes to a sibling svgs/ folder next to the input file.
# Usage: png_to_svg.sh <file.png> [<file2.png> ...]

set -e

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <file.png> [<file2.png> ...]"
  exit 1
fi

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    echo "Skipping: $input (not found)"
    continue
  fi

  dir=$(dirname "$input")
  base=$(basename "$input" .png)
  outdir="$dir/../svgs"
  mkdir -p "$outdir"
  output="$outdir/$base.svg"

  tmp=$(mktemp /tmp/png_to_svg_XXXXXX.bmp)
  magick "$input" -colorspace Gray -threshold 50% "$tmp"
  potrace "$tmp" --svg --output "$output"
  rm "$tmp"

  echo "✓ $output"
done
