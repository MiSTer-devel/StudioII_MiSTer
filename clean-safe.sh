#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE="$ROOT/rbf_archive"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
declare -A SEEN_RBF=()

mkdir -p -- "$ARCHIVE"

archive_rbf() {
    local source="$1"
    local filename stem extension target copy_number

    [[ -n "${SEEN_RBF[$source]+present}" ]] && return 0
    SEEN_RBF["$source"]=1

    filename="${source##*/}"
    stem="${filename%.*}"
    extension=".${filename##*.}"
    target="$ARCHIVE/${stem}_${TIMESTAMP}${extension}"
    copy_number=1

    while [[ -e "$target" ]]; do
        ((copy_number += 1))
        target="$ARCHIVE/${stem}_${TIMESTAMP}-${copy_number}${extension}"
    done

    printf '  %s > %s\n' "$source" "$target"
    cp -- "$source" "$target"
}

echo "Archiving generated RBF files with timestamp $TIMESTAMP..."

if [[ -d "$ROOT/output_files" ]]; then
    while IFS= read -r -d '' rbf; do
        archive_rbf "$rbf"
    done < <(find "$ROOT/output_files" -type f -iname '*.rbf' -print0)
fi

while IFS= read -r -d '' dse_dir; do
    while IFS= read -r -d '' rbf; do
        archive_rbf "$rbf"
    done < <(find "$dse_dir" -type f -iname '*.rbf' -print0)
done < <(find "$ROOT" -type d -iname '*dse*' -not -path "$ARCHIVE/*" -print0)

echo 'RBF archive complete. Starting normal cleanup...'
exec "$ROOT/clean.sh"
