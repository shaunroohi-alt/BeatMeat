#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/BeatMeat.iconset"
for size in 16 32 128 256 512; do
 sips -z "$size" "$size" "$root/Resources/AppIcon.png" --out "$stage/BeatMeat.iconset/icon_${size}x${size}.png" >/dev/null
 double=$((size * 2))
 sips -z "$double" "$double" "$root/Resources/AppIcon.png" --out "$stage/BeatMeat.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$stage/BeatMeat.iconset" -o "$root/Resources/AppIcon.icns"
