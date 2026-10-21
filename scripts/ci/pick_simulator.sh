#!/bin/sh
# Uses $IOS_SIMULATOR if that device exists on the runner, otherwise the first available iPhone.
set -e
wanted="${IOS_SIMULATOR:-iPhone 17}"
devices=$(xcrun simctl list devices available -j)
if printf '%s' "$devices" | jq -e --arg name "$wanted" '[.devices[][] | select(.name == $name)] | length > 0' >/dev/null; then
  chosen="$wanted"
else
  chosen=$(printf '%s' "$devices" | jq -r '[.devices[][] | select(.name | startswith("iPhone"))] | .[0].name // empty')
fi
[ -n "$chosen" ] || { echo "✖ No iPhone simulator available"; exit 1; }
[ -n "$GITHUB_ENV" ] && echo "IOS_SIMULATOR=$chosen" >> "$GITHUB_ENV"
echo "✔ Simulator: $chosen"
