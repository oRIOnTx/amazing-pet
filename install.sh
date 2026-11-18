#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"

./build.sh

DEST=/Applications
[[ -w "$DEST" ]] || DEST="$HOME/Applications"
mkdir -p "$DEST"

pkill -x AmazingPet 2>/dev/null || true
rm -rf "$DEST/AmazingPet.app"
cp -R build/AmazingPet.app "$DEST/"
open "$DEST/AmazingPet.app"
echo "Installed to $DEST/AmazingPet.app (launches at login)"
