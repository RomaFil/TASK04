#!/usr/bin/env bash
set -euo pipefail
CROSS=${CROSS:-aarch64-linux-gnu-}
CC=${CROSS}gcc
CFLAGS="-std=c11 -Wall -Wextra -Werror -O2"
OUT=${OUT:-hostinfo_cross}
mkdir -p build reports

$CC $CFLAGS hostinfo.c -o build/$OUT
CROSS=$CROSS ./analyze.sh build/$OUT     
