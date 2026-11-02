#!/bin/bash
# Remove the HL-2240D queue, filter and PPD (installed by install.sh or the .pkg).
# Run with: sudo bash uninstall.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

lpadmin -x Brother_HL_2240D 2>/dev/null || true
rm -rf "/Library/Printers/Brother-HL2240-brlaser"
rm -f "/Library/Printers/PPDs/Contents/Resources/Brother HL-2240D brlaser.gz"
pkgutil --forget local.brother-hl2240d.brlaser >/dev/null 2>&1 || true
echo "Removed."
