#!/bin/bash
# Package the driver as a double-click installer for other Macs:
#   dist/Brother-HL2240D-Driver.zip  (installer .pkg + uninstall + guide)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/build"
DIST="$ROOT/dist"
STAGE="$OUT/pkgroot"
PKG_ID="local.brother-hl2240d.brlaser"
VERSION="6"
NAME="Brother-HL2240D-Driver"

"$ROOT/build.sh"

echo "==> Staging payload"
rm -rf "$STAGE" "$DIST"
mkdir -p "$STAGE/Library/Printers/Brother-HL2240-brlaser" \
         "$STAGE/Library/Printers/PPDs/Contents/Resources" \
         "$DIST/$NAME"
install -m 755 "$OUT/rastertobrlaser" "$STAGE/Library/Printers/Brother-HL2240-brlaser/"
install -m 644 "$OUT/ppd/br2240d.ppd" "$STAGE/Library/Printers/Brother-HL2240-brlaser/"
gzip -c "$OUT/ppd/br2240d.ppd" > "$STAGE/Library/Printers/PPDs/Contents/Resources/Brother HL-2240D brlaser.gz"
chmod 644 "$STAGE/Library/Printers/PPDs/Contents/Resources/Brother HL-2240D brlaser.gz"
chmod +x "$ROOT/pkg-scripts/postinstall"

# Strip extended attributes so no AppleDouble "._*" files end up installed.
xattr -cr "$STAGE" "$ROOT/pkg-scripts" 2>/dev/null || true
export COPYFILE_DISABLE=1

echo "==> Building installer"
# --ownership recommended: payload is installed as root:wheel, as CUPS requires.
pkgbuild --root "$STAGE" --identifier "$PKG_ID" --version "$VERSION" \
  --install-location / --ownership recommended \
  --scripts "$ROOT/pkg-scripts" \
  "$DIST/$NAME/$NAME.pkg"

# pkgbuild turns the protected com.apple.provenance xattr into "._*" payload
# entries. Rebuild Payload/Bom with cpio, which stores no xattrs.
EXP="$OUT/pkgexpand"
rm -rf "$EXP"
pkgutil --expand "$DIST/$NAME/$NAME.pkg" "$EXP"
(cd "$STAGE" && find . | cpio -o --format odc -R 0:0 2>/dev/null | gzip -9) > "$EXP/Payload"
# Bom lists every path as root:wheel (uid/gid 0/0).
# Files also need size and cksum CRC, in lsbom's format.
(cd "$STAGE" && find . | while IFS= read -r f; do
  if [[ -f "$f" ]]; then
    read -r crc size _ < <(cksum "$f")
    printf '%s\t%s\t0/0\t%s\t%s\n' "$f" "$(stat -f %p "$f")" "$size" "$crc"
  else
    printf '%s\t%s\t0/0\n' "$f" "$(stat -f %p "$f")"
  fi
done) > "$EXP/bom.txt"
rm -f "$EXP/Bom" && mkbom -i "$EXP/bom.txt" "$EXP/Bom" && rm "$EXP/bom.txt"
rm -f "$DIST/$NAME/$NAME.pkg"
pkgutil --flatten "$EXP" "$DIST/$NAME/$NAME.pkg"

cp "$ROOT/uninstall.sh" "$DIST/$NAME/uninstall.sh"
cp "$ROOT/HUONG-DAN-CAI-DAT.txt" "$DIST/$NAME/"
# GPL-2: ship the license; full source is in vendor/brlaser of this project.
cp "$ROOT/vendor/brlaser/COPYING" "$DIST/$NAME/LICENSE-brlaser.txt"

echo "==> Zipping"
(cd "$DIST" && ditto -c -k --norsrc --noextattr --noqtn --keepParent "$NAME" "$NAME.zip")
echo "==> Done: $DIST/$NAME.zip"
