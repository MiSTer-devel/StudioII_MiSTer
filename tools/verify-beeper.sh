#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

python3 "$repo_dir/tools/beeper-curve-test.py"
make -C "$repo_dir/verilator" lint
make -B -C "$repo_dir/verilator" headless

echo "Beeper model, RTL lint, and headless build passed."
