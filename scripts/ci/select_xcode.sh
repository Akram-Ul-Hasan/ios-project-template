#!/bin/sh
# Points the job at the Xcode pinned in .xcode-version (via DEVELOPER_DIR, so no sudo is needed).
set -e
version=$(tr -d '[:space:]' < .xcode-version)
for app in "/Applications/Xcode_${version}.app" "/Applications/Xcode-${version}.app" /Applications/Xcode.app; do
  developer="$app/Contents/Developer"
  [ -x "$developer/usr/bin/xcodebuild" ] || continue
  found=$(DEVELOPER_DIR="$developer" xcodebuild -version | awk 'NR==1 {print $2}')
  if [ "$found" = "$version" ]; then
    [ -n "$GITHUB_ENV" ] && echo "DEVELOPER_DIR=$developer" >> "$GITHUB_ENV"
    echo "✔ Xcode $version at $app"
    exit 0
  fi
done
echo "✖ Xcode $version (from .xcode-version) is not installed on this runner. Installed:"
ls -d /Applications/Xcode*.app 2>/dev/null || true
exit 1
