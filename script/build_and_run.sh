#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
[[ $(uname -s) == Darwin ]] || { echo 'Run this native application on a Mac with Xcode.' >&2; exit 2; }
mode=${1:-run}
case "$mode" in run|--verify|--debug|--logs|--telemetry) ;; *) echo "Usage: $0 [--verify|--debug|--logs|--telemetry]" >&2; exit 2;; esac
pkill -x BeatMeat >/dev/null 2>&1 || true
bash "$root/scripts/build.sh"
app="$root/.build/DerivedData/Build/Products/${BUILD_CONFIGURATION:-Release}/BeatMeat.app"
codesign --force --sign - "$app"
case "$mode" in
 --debug) lldb -- "$app/Contents/MacOS/BeatMeat" ;;
 --logs|--telemetry) open -n "$app"; /usr/bin/log stream --info --style compact --predicate 'process == "BeatMeat"' ;;
 --verify) open -n "$app"; sleep 2; pgrep -x BeatMeat >/dev/null ;;
 run) open -n "$app" ;;
esac
