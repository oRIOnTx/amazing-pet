#!/bin/sh
set -eu

last="$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || echo v0.0.0)"
version="${last#v}"
major="${version%%.*}"
rest="${version#*.}"
minor="${rest%%.*}"
patch="${rest#*.}"

range="HEAD"
[ "$last" = "v0.0.0" ] || range="$last..HEAD"

bump=0
for commit in $(git rev-list "$range"); do
  subject="$(git log -1 --format=%s "$commit")"
  body="$(git log -1 --format=%b "$commit")"
  level=0
  if printf '%s\n' "$subject" | grep -qE '^[a-z]+(\([^)]*\))?!:' || printf '%s\n' "$body" | grep -q '^BREAKING CHANGE:'; then
    level=3
  elif printf '%s\n' "$subject" | grep -qE '^feat(\([^)]*\))?:'; then
    level=2
  elif printf '%s\n' "$subject" | grep -qE '^(fix|perf)(\([^)]*\))?:'; then
    level=1
  fi
  [ "$level" -gt "$bump" ] && bump="$level"
done

case "$bump" in
  3) major=$((major + 1)); minor=0; patch=0 ;;
  2) minor=$((minor + 1)); patch=0 ;;
  1) patch=$((patch + 1)) ;;
esac

echo "$major.$minor.$patch"
