#!/bin/sh
# Scaffolds a feature from scripts/feature_template (§9):
#   scripts/create_feature.sh OrderHistory
# Creates OrderHistoryDomain / OrderHistoryData / OrderHistoryPresentation targets with their tests, a container in
# App/DI, a mock fixture, a localized title, and the Package.swift / test plan entries — with exactly the §4 edges.
# Uses only tools that ship with macOS + Xcode (sed, awk, jq, find, swift).
set -e

usage() {
  echo "Usage: scripts/create_feature.sh FeatureName   (PascalCase, e.g. Orders or OrderHistory)"
  exit 1
}

name="$1"
[ -n "$name" ] || usage
echo "$name" | grep -Eq '^[A-Z][A-Za-z0-9]+$' || usage

root=$(cd "$(dirname "$0")/.." && pwd)
template="$root/scripts/feature_template"
package="$root/Packages/AppModules/Package.swift"
l10n="$root/Packages/AppModules/Sources/Localization/L10n.swift"
catalog="$root/Packages/AppModules/Sources/Localization/Resources/Localizable.xcstrings"
plan="$root/ProjectTemplate.xctestplan"

if [ -d "$root/Packages/AppModules/Sources/Features/$name" ]; then
  echo "✖ Feature '$name' already exists"
  exit 1
fi

camel=$(printf '%s' "$name" | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }')
lower=$(printf '%s' "$name" | sed -E 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]')
title=$(printf '%s' "$name" | sed -E 's/([a-z0-9])([A-Z])/\1 \2/g')

substitute() {
  sed -e "s/__Feature__/$name/g" -e "s/__featureCamel__/$camel/g" -e "s/__feature_lower__/$lower/g"
}

# 1. Copy the template, renaming paths and contents.
created=""
cd "$template"
for file in $(find . -type f | sed 's|^\./||'); do
  target="$root/$(printf '%s' "$file" | substitute)"
  mkdir -p "$(dirname "$target")"
  substitute < "$file" > "$target"
  created="$created $target"
done
cd "$root"

# 2. Package.swift: product entries, targets and test targets, inserted at the create_feature markers.
insert_before() { # marker block file   (the block goes through the environment: BSD awk -v rejects newlines)
  BLOCK="$2" awk -v marker="$1" 'index($0, marker) { print ENVIRON["BLOCK"] } { print }' "$3" > "$3.tmp" && mv "$3.tmp" "$3"
}
insert_before "// create_feature: products" \
  "                \"${name}Domain\", \"${name}Data\", \"${name}Presentation\"," "$package"
insert_before "// create_feature: targets" \
  "        // Feature: $name
        .target(name: \"${name}Domain\", dependencies: [\"SharedDomain\"], path: \"Sources/Features/$name/Domain\"),
        .target(
            name: \"${name}Data\", dependencies: [\"${name}Domain\", \"SharedDomain\", \"Core\"],
            path: \"Sources/Features/$name/Data\"),
        .target(
            name: \"${name}Presentation\",
            dependencies: [\"${name}Domain\", \"SharedDomain\", \"DesignSystem\", \"Core\", \"Localization\"],
            path: \"Sources/Features/$name/Presentation\")," "$package"
insert_before "// create_feature: tests" \
  "        .testTarget(name: \"${name}DomainTests\", dependencies: [\"${name}Domain\", \"TestSupport\"]),
        .testTarget(name: \"${name}DataTests\", dependencies: [\"${name}Data\", \"TestSupport\"]),
        .testTarget(name: \"${name}PresentationTests\", dependencies: [\"${name}Presentation\", \"TestSupport\"])," "$package"

# 3. Localized screen title: catalog key in every language (Bangla marked for review) + L10n accessor.
insert_before "// create_feature: accessors" \
  "    public enum $name {
        public static var title: String { tr(\"$lower.title\") }
    }
" "$l10n"
jq --indent 2 --arg key "$lower.title" --arg value "$title" '
  .strings[$key] = {
    extractionState: "manual",
    localizations: {
      en: { stringUnit: { state: "translated", value: $value } },
      bn: { stringUnit: { state: "needs_review", value: $value } }
    }
  }
  | .strings |= (to_entries | sort_by(.key) | from_entries)' "$catalog" \
  | sed -E 's/^( *"[^"]*"): /\1 : /' > "$catalog.tmp" && mv "$catalog.tmp" "$catalog"

# 4. Test plan entries.
jq --indent 2 --arg name "$name" '
  .testTargets += [
    { target: { containerPath: "container:Packages/AppModules", identifier: "\($name)DomainTests", name: "\($name)DomainTests" } },
    { target: { containerPath: "container:Packages/AppModules", identifier: "\($name)DataTests", name: "\($name)DataTests" } },
    { target: { containerPath: "container:Packages/AppModules", identifier: "\($name)PresentationTests", name: "\($name)PresentationTests" } }
  ]' "$plan" \
  | sed -E -e 's/^( *"[^"]*"): /\1 : /' -e 's#container:Packages/AppModules#container:Packages\\/AppModules#' \
  > "$plan.tmp" && mv "$plan.tmp" "$plan"

# 5. Format and verify the graph.
swift_files=$(printf '%s\n' $created | grep '\.swift$')
# shellcheck disable=SC2086
swift format format -i $swift_files "$package" "$l10n"
"$root/scripts/check_target_graph.sh"

cat <<EOF

✔ Created feature $name.
Next:
  1. AppContainer: add \`let $camel: ${name}Container\` and create it in init (App/DI/${name}Container.swift).
  2. Show it: a tab root in MainTabView or a Route case + RouteView mapping (+ DeepLink case, parser test, push payload).
  3. Replace the placeholder API: path in ${name}Endpoint, fields in ${name}ItemResponse + mapper guards + tests.
  4. Translate "$lower.title" into Bangla in Localizable.xcstrings (marked needs_review).
  5. Run preflight: swift format lint, scripts/check_target_graph.sh, scripts/check_imports.sh, tests.
EOF
