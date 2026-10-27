#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
[[ $(uname -s) == Darwin ]] || { echo 'Run this installer on your Mac.' >&2; exit 2; }
source_app=${1:-"$root/dist/BeatMeat.app"}
[[ -d "$source_app" ]] || { echo 'BeatMeat.app is missing. Run scripts/package.sh first.' >&2; exit 2; }
identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")
[[ $identifier == com.mpaudio.beatmeat ]] || { echo 'This bundle is not BeatMeat.' >&2; exit 1; }
codesign --verify --strict "$source_app"
destination="$HOME/Applications/BeatMeat.app"
mkdir -p "$HOME/Applications"
stage=$(mktemp -d "$HOME/Applications/.BeatMeat-install.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$source_app" "$stage/BeatMeat.app"
codesign --verify --strict "$stage/BeatMeat.app"
if [[ -e "$destination" ]]; then
 backup=$(mktemp -d "$HOME/Applications/BeatMeat-backup.XXXXXX")
 mv "$destination" "$backup/BeatMeat.app"
fi
mv "$stage/BeatMeat.app" "$destination"
codesign --verify --strict "$destination"
printf 'Installed %s. Open it with Finder or: open "%s"\n' "$destination" "$destination"
