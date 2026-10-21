---
name: new-feature
description: Scaffold a new feature (Domain/Data/Presentation targets, tests, container, fixture) and wire it into the app. Use when the user asks for a new feature, module or screen backed by an API.
---

# New feature

1. Pick a PascalCase name (`OrderHistory`). Run `scripts/create_feature.sh <Name>`.
   It creates the three targets + test targets with the allowed edges, `App/DI/<Name>Container.swift`,
   `App/Resources/Mock/<name>/<name>-items.mock.json`, a localized title and test plan entries.
2. Replace the placeholder API (see the `add-endpoint` skill): endpoint path, request/response DTOs mirroring the spec,
   mapper guards with one test each, mock fixture with realistic data.
3. Domain: rename `<Name>ItemEntity` to the real entity; data only (rule 1). Shared entities go to `SharedDomain`.
4. Wire it:
   - `AppContainer`: `let <name>: <Name>Container`, created in `init` with `authenticatedClient`, `mockData`, `errorHandler`.
   - Show it: a tab root in `App/Route/MainTabView.swift` or a `Route` case + `RouteView` mapping.
   - Deep-linkable? Use the `add-deeplink` skill.
5. Screen: one adaptive layout from the portrait design, `ViewStateContainer` or `PaginatedList`, `.commonAppBar`,
   `.refreshable`, strings via `L10n`, a `PreviewMatrix` preview.
6. Translate the new title key into Bangla (it is created as `needs_review`).
7. Run the `preflight` skill.
