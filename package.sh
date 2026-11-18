#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"

NAME="AmazingPet-${VERSION:-dev}"
APP=build/AmazingPet.app

./build.sh

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
  ditto -c -k --keepParent "$APP" build/notarize.zip
  xcrun notarytool submit build/notarize.zip --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
  xcrun stapler staple "$APP"
  rm build/notarize.zip
fi

rm -rf dist build/dmg
mkdir -p dist build/dmg
ditto -c -k --keepParent "$APP" "dist/$NAME.zip"
cp -R "$APP" build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -volname "Amazing Pet" -srcfolder build/dmg -ov -format UDZO "dist/$NAME.dmg" >/dev/null
rm -rf build/dmg
(cd dist && shasum -a 256 *.zip *.dmg > SHA256SUMS.txt)
ls -lh dist
