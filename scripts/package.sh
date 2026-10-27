#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
bash scripts/build.sh
bash scripts/test-dsp.sh
swift test
bash scripts/smoke-test.sh
app="$root/.build/DerivedData/Build/Products/${BUILD_CONFIGURATION:-Release}/BeatMeat.app"
lipo "$app/Contents/MacOS/BeatMeat" -verify_arch arm64 x86_64
stage=$(mktemp -d "$root/.build/package.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/BeatMeat.app"
identity=${BEATMEAT_SIGN_IDENTITY:--}
if [[ $identity == - ]]; then
 codesign --force --sign - "$stage/BeatMeat.app"
else
 codesign --force --options runtime --timestamp --sign "$identity" "$stage/BeatMeat.app"
fi
codesign --verify --strict "$stage/BeatMeat.app"
mkdir -p dist
# Replace only the generated distribution artifacts. Preserve the previous app.
if [[ -e dist/BeatMeat.app ]]; then
 previous=$(mktemp -d "$root/.build/previous-app.XXXXXX")
 mv dist/BeatMeat.app "$previous/BeatMeat.app"
fi
ditto "$stage/BeatMeat.app" dist/BeatMeat.app
ditto -c -k --sequesterRsrc --keepParent "$stage/BeatMeat.app" "$root/dist/BeatMeat-macOS.zip"
hdiutil create -volname 'BeatMeat by MP-Audio' -srcfolder "$stage" -ov -format UDZO "$root/dist/BeatMeat-macOS.dmg"
printf 'Prepared universal app, ZIP and DMG in %s/dist. Notarization has not been performed.\n' "$root"
