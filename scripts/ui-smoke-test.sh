#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
[[ $(uname -s) == Darwin ]] || { echo 'Native window validation requires macOS.' >&2; exit 2; }
app="$root/.build/DerivedData/Build/Products/${BUILD_CONFIGURATION:-Release}/BeatMeat.app"
codesign --force --sign - "$app"
mkdir -p "$root/.build"
output=$(mktemp -d "$root/.build/ui-validation.XXXXXX")
python3 - "$app" "$output" "$root/.build/validation" <<'PY'
import json,subprocess,sys,shutil
from pathlib import Path
app,output,destination=map(Path,sys.argv[1:])
subprocess.run(['/usr/bin/open','-n','-W',str(app),'--args','--ui-smoke-test',str(output)],check=True,timeout=120)
result=json.loads((output/'ui-validation.json').read_text())
if result.get('status')!='passed' or result.get('width',0)<800 or result.get('height',0)<600:
 raise SystemExit('Native window validation failed')
if not (output/'workspace.png').is_file():raise SystemExit('Missing native window image')
destination.mkdir(parents=True,exist_ok=True)
for name in ['ui-validation.json','workspace.png']:shutil.copy2(output/name,destination/name)
print(json.dumps(result,indent=2))
PY
