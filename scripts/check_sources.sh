#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for file in $(find SecureVault SecureVaultTests -name '*.swift' -type f); do
  swiftc -frontend -parse "$file"
done
python3 - <<'PY'
from pathlib import Path
import json
import yaml
spec = yaml.safe_load(Path('project.yml').read_text())
assert 'SecureVault' in spec['targets']
for json_file in Path('SecureVault/Resources/Assets.xcassets').rglob('*.json'):
    json.loads(json_file.read_text())
print('Swift syntax, project.yml and asset JSON: OK')
PY
