---
name: preflight
description: Run every check CI runs, before committing or opening a merge request. Use before any commit, push or MR, or when asked to verify the project.
---

# Preflight

Run in order and stop at the first failure; fix, then re-run from that step.

```sh
swift format lint --strict --recursive App AppTests Packages/AppModules   # fix: swift format format -i <file>
scripts/check_target_graph.sh
scripts/check_imports.sh
scripts/banned_api_check.sh
for s in Development Staging Production; do
  xcodebuild build -quiet -project ios-project-template.xcodeproj -scheme ProjectTemplate-$s \
    -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
done
swift test --package-path Packages/AppModules
xcodebuild test -quiet -project ios-project-template.xcodeproj -scheme ProjectTemplate-Development \
  -destination 'platform=iOS Simulator,name=iPhone 17' -collect-test-diagnostics never
```

Also confirm manually:
- new strings exist in every language; no literal user-facing text;
- no new third-party dependency; no `Package.swift` edge outside the table in `CLAUDE.md`;
- UI changes checked in `PreviewMatrix` (light/dark, large text, iPad).

Report each step's result; never claim green without running it.
