#!/usr/bin/env bash
# Directed checks for boot-slot isolation and native CHIP-8 address routing.
# Uses an already-built headless Verilator model; it never starts a build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM="$ROOT/verilator/obj_dir_headless/Vtop"
FW="$ROOT/software/RCA-Studio-II-Fullset/Collections/Emma 02/StudioII/chip8.bin"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

[[ -x "$SIM" ]] || { echo "error: build the RTL sim: (cd verilator && make headless)" >&2; exit 1; }
[[ -f "$FW" ]] || { echo "error: missing interpreter: $FW" >&2; exit 1; }

# Distinct bytes at every boundary, plus one rejected byte at offset $900.
python3 - "$TMP/boundaries.ch8" "$FW" "$TMP/truncated.rom" <<'PY'
import sys
data = bytearray((i * 73 + 19) & 0xff for i in range(0x901))
for offset, value in ((0x000, 0x10), (0x4ff, 0x4f), (0x500, 0x50),
                      (0x8ff, 0x8f), (0x900, 0x90)):
    data[offset] = value
open(sys.argv[1], "wb").write(data)
open(sys.argv[3], "wb").write(open(sys.argv[2], "rb").read(0x2ff))
PY

run_case() {
    local machine=$1 bios=$2 fw=$3
    echo "CHIP-8 loader: $machine"
    if [[ -n "$fw" ]]; then
        "$SIM" --machine "$machine" --bios "$bios" --chip8-fw "$fw" \
            --ch8 "$TMP/boundaries.ch8" --loader-check --quiet
    else
        "$SIM" --machine "$machine" --bios "$bios" \
            --ch8 "$TMP/boundaries.ch8" --loader-check --quiet
    fi
}

run_case studio2     "$ROOT/rom/studio2.rom"      "$FW" || exit 1
run_case mpt02       "$ROOT/rom/studio3_pal.bin" "$FW" || exit 1
run_case studio3ntsc "$ROOT/rom/studio3_ntsc.bin" "$FW" || exit 1
run_case visicom     "$ROOT/rom/visicom.rom"      "$FW" || exit 1

echo "CHIP-8 loader: missing chip8.bin companion"
run_case studio2 "$ROOT/rom/studio2.rom" "" || exit 1

echo "CHIP-8 loader: truncated chip8.bin companion"
run_case studio2 "$ROOT/rom/studio2.rom" "$TMP/truncated.rom" || exit 1

echo "CHIP-8 loader checks passed"
