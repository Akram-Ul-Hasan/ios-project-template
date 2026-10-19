<!-- MR title must be a one-line Conventional Commit: type(scope)?: subject. It becomes the squash commit. -->

## What

<!-- What does this change do? -->

## Why

<!-- Why is it needed? -->

Closes #<!-- issue -->

## Screenshots

<!-- UI changes only: light + dark, iPhone + iPad. Delete this section otherwise. -->

| Light | Dark |
|---|---|
| | |

## Checklist

- [ ] Preflight passed (format lint → target graph → banned APIs → build all schemes → tests)
- [ ] No new third-party dependency
- [ ] Every new string is in `Localizable.xcstrings` in every language
- [ ] `PreviewMatrix` checked (SE, Max landscape, iPad, split, large Dynamic Type, dark)
- [ ] No `Package.swift` dependency edge outside the target graph (§4)
- [ ] Tests added for new logic (mappers: one test per guard)
