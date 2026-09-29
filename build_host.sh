#!/usr/bin/env bash
set -euo pipefail
CC=gcc
CFLAGS="-std=c11 -Wall -Wextra -Werror -O2"
OUT=${OUT:-hostinfo_native}
mkdir -p build reports

$CC $CFLAGS hostinfo.c -o build/$OUT
rm -f build/t.txt
./build/$OUT build/t.txt
./build/$OUT build/t.txt
./analyze.sh build/$OUT
