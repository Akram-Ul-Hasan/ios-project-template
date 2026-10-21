---
name: add-component
description: Add a reusable DesignSystem component. Use when a UI element is needed by two or more screens and nothing in the component catalog fits.
---

# Add a DesignSystem component

1. Check the component catalog in `CLAUDE.md` first; extend an existing component if it's close.
2. Create `Packages/AppModules/Sources/DesignSystem/Components/<Group>/<Name>.swift`. No feature knowledge, no
   feature imports.
3. Tokens only: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppSize`, `AppIconSize`, `AppAnimation`,
   `AppShadow`. Add a token (one owner) rather than a literal.
4. Taps through `TapArea`/`Button`; accessibility labels for icon-only controls; Dynamic Type safe (no fixed text
   heights); RTL safe (leading/trailing).
5. Must compile on macOS too: guard iOS-only modifiers with `#if os(iOS)`.
6. Add `#Preview`s in light and dark (and `PreviewMatrix` for layout-heavy components). Preview-only text may use
   `Text(verbatim:)`; real strings go through `L10n`.
7. Pure logic (sizing, formatting choices) gets a test in `DesignSystemTests`.
8. Add a line to the component catalog in `CLAUDE.md`. Run the `preflight` skill.
