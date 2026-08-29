#!/usr/bin/env bash

set -u

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

find . -type f \( \
    -name '*.bak' -o \
    -name '*.orig' -o \
    -name '*.rej' -o \
    -name '*~' -o \
    -name '*.qws' -o \
    -name '*.ppf' -o \
    -name '*.ddb' -o \
    -name '*.csv' -o \
    -name '*.cmp' -o \
    -name '*.sip' -o \
    -name '*.spd' -o \
    -name '*.bsf' -o \
    -name '*.f' -o \
    -name '*.sopcinfo' -o \
    -name '*.xml' \
\) -delete

rm -rf -- \
    db \
    incremental_db \
    output_files \
    simulation \
    greybox_tmp \
    hc_output \
    .qsys_edit \
    hps_isw_handoff \
    sys/.qsys_edit \
    sys/vip \
    new_rtl_netlist \
    old_rtl_netlist

find sys rtl -maxdepth 1 -type d -name '*_sim' -exec rm -rf -- {} + 2>/dev/null || true

rm -f -- \
    build_id.v \
    c5_pin_model_dump.txt \
    PLLJ_PLLSPE_INFO.txt \
    ./*.cdf \
    ./*.rpt

if [[ -t 0 ]]; then
    read -r -p 'Press Enter to continue...'
fi
