#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

python3 -m venv venv
venv/bin/pip install -r requirements.txt

if ! command -v mips-linux-gnu-as >/dev/null 2>&1; then
  echo "Install mips-linux-gnu-binutils for full ROM rebuild support."
  echo "On Debian/Ubuntu: sudo apt install binutils-mips-linux-gnu"
fi

if [[ ! -f baserom.us.z64 ]]; then
  ln -sf "Mario Party 2 (USA).z64" baserom.us.z64
fi

venv/bin/python tools/scan_overlays.py
venv/bin/python tools/sym_converter.py --download
venv/bin/splat split marioparty2.yaml
venv/bin/python tools/verify_rom.py

echo "Setup complete. Run 'make verify' to validate segment coverage."
