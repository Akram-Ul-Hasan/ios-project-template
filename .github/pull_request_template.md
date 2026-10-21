<!-- PR title must be a one-line Conventional Commit: type(scope)?: subject — CI checks it. -->

## What

<!-- What does this change do? -->

## Why

<!-- Why is it needed? Link the issue: Closes #123 -->

## Screenshots

<!-- UI changes only: light + dark, iPhone + iPad. Delete this section otherwise. -->

| Light | Dark |
|---|---|
| | |

## Checklist

- [ ] Preflight passed (format lint → target graph → imports → banned APIs → build all schemes → tests)
- [ ] No new third-party dependency
- [ ] Every new string is in `Localizable.xcstrings` in every language
- [ ] `PreviewMatrix` checked (SE, Max landscape, iPad, split, large Dynamic Type, dark)
- [ ] No `Package.swift` dependency edge outside the target graph (CLAUDE.md)
- [ ] Tests added for new logic (mappers: one test per guard)
