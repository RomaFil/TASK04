#!/usr/bin/env bash
# Usage: [CROSS=prefix-] ./analyze.sh build/<binary>
set -uo pipefail
BIN=$1; CROSS=${CROSS:-}
NAME=$(basename "$BIN"); OUTF=reports/${NAME}@$(hostname).txt
mkdir -p reports
{
  echo "### $NAME analysed on $(hostname) ($(uname -m)), $(date -Is)"
  echo "## file";              file "$BIN"
  echo "## size on disk";      stat -c '%s bytes' "$BIN"
  echo "## readelf -h";        ${CROSS}readelf -h "$BIN" | grep -E 'Class|Machine|Type'
  echo "## interpreter";       ${CROSS}readelf -l "$BIN" | grep -i interpreter || echo "none"
  echo "## NEEDED";            ${CROSS}readelf -d "$BIN" | grep -E 'NEEDED|RUNPATH' || echo "none"
  echo "## ldd";               ldd "$BIN" 2>&1 || true
  echo "## size";              ${CROSS}size "$BIN"
  echo "## GLIBC required";    ${CROSS}objdump -T "$BIN" | grep -o 'GLIBC_[0-9.]*' | sort -uV
  echo "## strings: total";    ${CROSS}strings "$BIN" | wc -l
  echo "## strings: GCC/GLIBC"; ${CROSS}strings "$BIN" | grep -E 'GCC:|GLIBC' | sort -u | head
} | tee "$OUTF"
