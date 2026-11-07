#!/usr/bin/env bash
# Quick Launcher for Cyber Leap: Protocol Zero
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check standard godot executable paths
GODOT_CANDIDATES=(
    "godot4"
    "godot"
    "/home/zhang/godot_engine/Godot_v4.3-stable_linux.x86_64"
    "/usr/bin/godot"
    "/usr/local/bin/godot"
)

GODOT_BIN=""
for candidate in "${GODOT_CANDIDATES[@]}"; do
    if command -v "$candidate" >/dev/null 2>&1; then
        GODOT_BIN="$candidate"
        break
    elif [ -f "$candidate" ] && [ -x "$candidate" ]; then
        GODOT_BIN="$candidate"
        break
    fi
done

if [ -z "$GODOT_BIN" ]; then
    echo "[Error] Godot 4 binary not found. Please install Godot 4 or specify path."
    exit 1
fi

echo "Launching Cyber Leap with $GODOT_BIN..."
"$GODOT_BIN" --path "$DIR" "$@"
