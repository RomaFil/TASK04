#!/usr/bin/env bash
set -euo pipefail
CROSS=${CROSS:-}                    
CC=${CROSS}gcc
CFLAGS="-std=c11 -Wall -Wextra -Werror -O2"
OUT=${OUT:-hostinfo_static}
mkdir -p build reports

$CC $CFLAGS -static hostinfo.c -o build/$OUT
[ -z "$CROSS" ] && ./build/$OUT build/t_static.txt
CROSS=$CROSS ./analyze.sh build/$OUT
