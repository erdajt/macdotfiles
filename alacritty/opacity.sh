#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/alacritty/alacritty.toml"
STEP=0.05
MIN_OPACITY=0.2
MAX_OPACITY=1.0

usage() {
    echo "Usage: $0 [+|-]" >&2
    exit 1
}

[ $# -eq 1 ] || usage

case "$1" in
    +) DELTA="$STEP" ;;
    -) DELTA="-$STEP" ;;
    *) usage ;;
esac

python - <<PY
import pathlib
import re

config_path = pathlib.Path("${CONFIG}")
text = config_path.read_text()
match = re.search(r"(?m)^opacity\s*=\s*([0-9.]+)", text)
if not match:
    raise SystemExit("Could not find window opacity in config.")

current = float(match.group(1))
delta = float("${DELTA}")
new_value = max(${MIN_OPACITY}, min(${MAX_OPACITY}, current + delta))
updated = re.sub(r"(?m)^opacity\s*=.*$", f"opacity = {new_value:.2f}", text, count=1)
config_path.write_text(updated)
PY

alacritty msg config-reload >/dev/null 2>&1 || true
