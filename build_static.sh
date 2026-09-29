#!/usr/bin/env bash
set -euo pipefail
CROSS=${CROSS:-}
CC=${CROSS}gcc
CFLAGS="-std=c11 -Wall -Wextra -Werror -O2"
OUT=${OUT:-hostinfo_static}
mkdir -p build reports

$CC $CFLAGS -static hostinfo.c -o build/$OUT
if [ -z "$CROSS" ]; then ./build/$OUT build/t_static.txt; fi
CROSS=$CROSS ./analyze.sh build/$OUT
