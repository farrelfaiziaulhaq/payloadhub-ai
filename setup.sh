#!/usr/bin/env bash
# PayloadHub-AI — setup cepat (Linux/macOS)
# Jalankan dari root repository: ./setup.sh
set -euo pipefail

if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "Python 3.10+ belum terpasang. Install dari https://www.python.org/downloads/" >&2
  exit 1
fi

exec "$PYTHON" "$(cd "$(dirname "$0")" && pwd)/scripts/payloadhub.py" setup "$@"
