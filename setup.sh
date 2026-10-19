#!/bin/sh
# One-time developer setup. Installs nothing third-party.
set -e
cd "$(dirname "$0")"

# 1. Versioned git hooks (§12)
git config core.hooksPath scripts/git-hooks
chmod +x scripts/git-hooks/* scripts/*.sh 2>/dev/null || true
echo "✔ git hooks installed (core.hooksPath = scripts/git-hooks)"

# 2. Pinned Xcode (.xcode-version), same check as CI
expected=$(tr -d '[:space:]' < .xcode-version)
actual=$(xcodebuild -version 2>/dev/null | awk 'NR==1 {print $2}')
if [ "$actual" != "$expected" ]; then
  echo "✖ Xcode $expected is required (found ${actual:-none}). Install it and run: sudo xcode-select -s /Applications/Xcode-$expected.app"
  exit 1
fi
echo "✔ Xcode $actual"
