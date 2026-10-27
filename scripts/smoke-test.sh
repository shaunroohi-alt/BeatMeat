#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
[[ $(uname -s) == Darwin ]] || { echo 'Native app validation requires macOS.' >&2; exit 2; }
app="$root/.build/DerivedData/Build/Products/${BUILD_CONFIGURATION:-Release}/BeatMeat.app"
[[ -x "$app/Contents/MacOS/BeatMeat" ]] || { echo 'Build BeatMeat with scripts/build.sh first.' >&2; exit 2; }
mkdir -p "$root/.build"
run_dir=$(mktemp -d "$root/.build/validation.XXXXXX")
python3 - "$app/Contents/MacOS/BeatMeat" "$run_dir" "$root/.build/validation" <<'PY'
import json,subprocess,sys,shutil
from pathlib import Path
binary,output,destination=map(Path,sys.argv[1:])
# The app's explicit command-line self-test exits before starting its GUI.
subprocess.run([str(binary),'--smoke-test',str(output)],check=True,timeout=90)
result=json.loads((output/'validation.json').read_text())
if result.get('status')!='passed':
 raise SystemExit('Native self-test did not report status=passed')
for name in ['self-test.wav','self-test.beatmeat']:
 p=output/name
 if not p.exists() or (p.is_file() and p.stat().st_size==0):
  raise SystemExit('Native self-test did not produce '+name)
project=output/'self-test.beatmeat'/'Project.json'
json.loads(project.read_text())
if (output/'self-test.wav').stat().st_size<44:
 raise SystemExit('Rendered WAV is too short to contain its header')
if destination.exists():shutil.rmtree(destination)
shutil.copytree(output,destination)
print(json.dumps(result,indent=2))
PY
