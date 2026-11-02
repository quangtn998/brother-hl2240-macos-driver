#!/bin/bash
# Build the brlaser CUPS filter natively (universal arm64 + x86_64) and
# generate the HL-2240D PPD. No cmake/Homebrew needed: only Xcode CLT.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/vendor/brlaser"
OUT="$ROOT/build"
VERSION="6"
INSTALL_DIR="/Library/Printers/Brother-HL2240-brlaser"

rm -rf "$OUT"
mkdir -p "$OUT/ppd"

# config.h normally produced by cmake's configure_file
cat > "$OUT/config.h" <<EOF
#define PACKAGE "brlaser"
#define VERSION "$VERSION"
EOF

echo "==> Compiling rastertobrlaser"
clang++ -std=c++11 -O2 -Wall -Wno-missing-braces -Wno-deprecated-declarations \
  -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
  -I"$OUT" \
  "$SRC/src/main.cc" "$SRC/src/job.cc" "$SRC/src/line.cc" "$SRC/src/debug.cc" \
  -lcups -o "$OUT/rastertobrlaser"

echo "==> Compiling unit tests"
for t in line block job; do
  extra=()
  case "$t" in
    line) extra=("$SRC/src/line.cc") ;;
    job)  extra=("$SRC/src/job.cc" "$SRC/src/line.cc") ;;
  esac
  clang++ -std=c++11 -O1 -I"$OUT" -I"$SRC/src" \
    "$SRC/test/test_$t.cc" ${extra[@]+"${extra[@]}"} -o "$OUT/test_$t"
  "$OUT/test_$t" >/dev/null && echo "    test_$t OK"
done

echo "==> Generating PPD"
# Filter path is absolute: /usr/libexec/cups/filter is SIP-protected on macOS.
sed "s#@FILTER@#$INSTALL_DIR/rastertobrlaser#; s#@VERSION@#$VERSION#" \
  "$ROOT/hl2240d.drv" > "$OUT/hl2240d.drv"
ppdc -d "$OUT/ppd" -I /usr/share/cups/ppdc "$OUT/hl2240d.drv"
cupstestppd -W translations "$OUT/ppd/"*.ppd || true

echo "==> Done: $OUT/rastertobrlaser, $(ls "$OUT/ppd")"
