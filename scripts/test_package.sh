#!/bin/sh
# Runs every AppModules test target on an iOS Simulator. Override the device with IOS_SIMULATOR="iPhone 17 Pro".
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/Packages/AppModules"
xcodebuild test -quiet -scheme AppModules \
  -destination "platform=iOS Simulator,name=${IOS_SIMULATOR:-iPhone 17}" \
  -derivedDataPath "$root/.build/DerivedData-package" "$@"
