#!/bin/sh
# Asserts the AppModules target graph matches the allowed-dependency table (§4).
# The compiler blocks undeclared imports; this blocks bad edges being *declared* in Package.swift.
# Uses only tools that ship with macOS + Xcode (swift, jq, tsort).
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
json=$(swift package dump-package --package-path "$root/Packages/AppModules")

violations=$(printf '%s' "$json" | jq -r '
  def deps: [.dependencies[] | (.byName // .target // .product)[0]];
  def isFeatureDomain: endswith("Domain") and . != "SharedDomain";

  [.targets[] | select(.type != "test") | .name] as $all
  | [$all[] | select(isFeatureDomain)] as $domains
  | (
      # Rule 17: no third-party packages.
      (.dependencies[] | "external package dependency is not allowed: \(.sourceControl[0].identity // .fileSystem[0].identity // "unknown")"),
      (.targets[] | . as $t | .name as $n
        | (if .type == "test" then $all
           elif $n == "Localization" or $n == "SharedDomain" then []
           elif $n == "Core" then ["SharedDomain", "Localization"]
           elif $n == "DesignSystem" then ["Core", "SharedDomain", "Localization"]
           elif $n == "TestSupport" then ["Core", "SharedDomain"]
           elif ($n | isFeatureDomain) then ["SharedDomain"] + [$domains[] | select(. != $n)]
           elif ($n | endswith("Data")) then [($n | rtrimstr("Data")) + "Domain", "SharedDomain", "Core"]
           elif ($n | endswith("Presentation")) then ["SharedDomain", "DesignSystem", "Core", "Localization"] + $domains
           else null end) as $allowed
        | if $allowed == null then "\($n): unknown target kind, add a rule to scripts/check_target_graph.sh"
          else ($t | deps[] | select(. as $d | $allowed | index($d) | not) | "\($n) → \(.) is not allowed (§4)")
          end)
    )')

status=0
if [ -n "$violations" ]; then
  printf '%s\n' "$violations" | sed 's/^/✖ /'
  status=1
fi

# Cycles (mainly <F>Domain → <G>Domain edges, which must form a DAG).
edges=$(printf '%s' "$json" | jq -r '.targets[] | .name as $n | .dependencies[] | "\($n) \((.byName // .target // .product)[0])"')
cycle=$(printf '%s\n' "$edges" | tsort 2>&1 >/dev/null)   # BSD tsort exits 0 on a cycle, so read stderr
if [ -n "$edges" ] && [ -n "$cycle" ]; then
  echo "✖ dependency cycle:"
  printf '%s\n' "$cycle" | sed 's/^/  /'
  status=1
fi

[ "$status" -eq 0 ] && echo "✔ target graph OK"
exit "$status"
