#!/bin/sh
set -eu

range="$1"
case "$range" in
  0000000*) exit 0 ;;
esac

changed="$(git diff --name-only "$range")"
if printf '%s\n' "$changed" | grep -qE '^(Sources|Resources)/' && ! printf '%s\n' "$changed" | grep -qx 'CHANGELOG.md'; then
  echo "::warning title=Changelog not updated::App code changed but CHANGELOG.md was not. If users will notice this change, add a line under [Unreleased]."
else
  echo "Changelog check passed."
fi
