#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
[[ $(uname -s) == Darwin ]] || { echo 'BeatMeat requires macOS 14 or newer with Xcode. No macOS binary was produced.' >&2; exit 2; }
command -v xcodebuild >/dev/null || { echo 'Install Xcode and select its developer directory first.' >&2; exit 2; }
cd "$root"
bash scripts/make-icon.sh
python3 scripts/generate-project.py
xcodebuild -project BeatMeat.xcodeproj -scheme BeatMeat \
 -configuration "${BUILD_CONFIGURATION:-Release}" -destination 'generic/platform=macOS' \
 -derivedDataPath .build/DerivedData ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
 CODE_SIGNING_ALLOWED=NO build
