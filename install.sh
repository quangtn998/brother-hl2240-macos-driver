#!/bin/bash
# Install the HL-2240D driver built by build.sh and add the USB printer queue.
# Run with: sudo ./install.sh   (or give friends the .pkg from make-pkg.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/build"
INSTALL_DIR="/Library/Printers/Brother-HL2240-brlaser"
PPD_DIR="/Library/Printers/PPDs/Contents/Resources"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi
if [[ ! -x "$OUT/rastertobrlaser" || ! -f "$OUT/ppd/br2240d.ppd" ]]; then
  echo "Build first: ./build.sh" >&2
  exit 1
fi

echo "==> Installing filter to $INSTALL_DIR"
# CUPS refuses filters that are not root-owned or are group/world writable.
install -d -o root -g wheel -m 755 "$INSTALL_DIR"
install -o root -g wheel -m 755 "$OUT/rastertobrlaser" "$INSTALL_DIR/rastertobrlaser"
install -o root -g wheel -m 644 "$OUT/ppd/br2240d.ppd" "$INSTALL_DIR/br2240d.ppd"
# Locally built binary: make sure no quarantine flag blocks execution.
xattr -c "$INSTALL_DIR/rastertobrlaser" 2>/dev/null || true

echo "==> Installing PPD to $PPD_DIR"
# Listed here, macOS can pick the driver when adding the printer by hand.
install -d -o root -g wheel -m 755 "$PPD_DIR"
gzip -c "$OUT/ppd/br2240d.ppd" > "$PPD_DIR/Brother HL-2240D brlaser.gz"
chown root:wheel "$PPD_DIR/Brother HL-2240D brlaser.gz"
chmod 644 "$PPD_DIR/Brother HL-2240D brlaser.gz"

"$ROOT/pkg-scripts/postinstall"

echo "==> Done. Test print:  lp -d Brother_HL_2240D <file.pdf>"
echo "   or print from any app and choose \"Brother HL-2240D\"."
