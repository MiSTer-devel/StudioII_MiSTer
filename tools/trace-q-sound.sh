#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

base=software/RCA-Studio-II-Fullset/RCA-Studio-II-Fullset_v36.0
bios="$base/0 BIOS/Soundic Victory Home TV Programmer (MPT-02) (Australia) (BIOS) (PAL) (1978).bin"
cart="$base/2 Other/Q-Sound Test (2026.08.30) (FliP).st2"
sim=verilator/obj_dir_headless/Vtop
out=refs/mpt-02-audio

"$sim" --machine mpt02 --bios "$bios" --cart "$cart" \
    --press a1@60:4 --press a3@90:4 --press a6@120:4 \
    --press a2@150:4 --press a3@180:4 --press a6@210:4 \
    --press a0@240:4 --frames 400 --trace-q --quiet > "$out/q-sound-core-100-100.log"

"$sim" --machine mpt02 --bios "$bios" --cart "$cart" \
    --press a1@60:4 --press a3@90:4 --press a5@120:4 \
    --press a2@150:4 --press a3@180:4 --press a5@210:4 \
    --press a5@240:4 --press a5@270:4 \
    --press a0@300:4 --frames 450 --trace-q --quiet > "$out/q-sound-core-10-30.log"

