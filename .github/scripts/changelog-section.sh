#!/bin/sh
set -eu

section="$1"
awk -v header="## [$section]" '
  index($0, header) == 1 { found = 1; next }
  found && /^## \[/ { exit }
  found && /^\[[^]]+\]: / { exit }
  found { print }
' CHANGELOG.md | sed -e '/./,$!d'
