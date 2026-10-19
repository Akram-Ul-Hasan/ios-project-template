#!/bin/sh
# Greps app code for APIs the mandatory rules ban (§6l, §6n, §7).
#   scripts/banned_api_check.sh            → every Swift file in App/ and Packages/AppModules/Sources, plus plists and xcconfigs
#   scripts/banned_api_check.sh FILE...    → only those files (pre-commit passes the staged ones)
# Crash rules (force unwrap, try!, as!, fatalError) accept a `// crash-safe: <reason>` comment on the same line.
# Tests are not scanned: force unwraps and try! are fine there.
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1

if [ "$#" -gt 0 ]; then
  files=$(printf '%s\n' "$@" | grep -E '^(App|Packages/AppModules/Sources|Config)/.*\.(swift|plist|xcconfig)$')
else
  files=$(find App Packages/AppModules/Sources Config -type f \( -name '*.swift' -o -name '*.plist' -o -name '*.xcconfig' \) 2>/dev/null)
fi
[ -z "$files" ] && exit 0

# shellcheck disable=SC2086
printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 awk '
  function report(msg) { printf "%s:%d: %s\n", FILENAME, FNR, msg; found = 1 }

  # Any file type
  /NSAllowsArbitraryLoads/ { report("NSAllowsArbitraryLoads: ATS must stay on (§6l)") }
  /http:\/\// && !/apple\.com\/DTDs/ { report("hardcoded http:// URL: HTTPS only, hosts come from Env (§6l)") }

  FILENAME !~ /\.swift$/ { next }

  {
    code = $0
    gsub(/"([^"\\]|\\.)*"/, "\"\"", code)   # ignore string contents
    sub(/\/\/.*$/, "", code)                 # ignore line comments
    crashSafe = ($0 ~ /\/\/ crash-safe:/)

    if (code ~ /(^|[^[:alnum:]_.])(print|debugPrint|NSLog)\(/) report("print/debugPrint/NSLog: use AppLogger (rule 22)")
    if (code ~ /DispatchQueue\.main/)                          report("DispatchQueue.main: use @MainActor (rule 29)")
    if (code ~ /UserDefaults\.standard/ && FILENAME !~ /UserDefaultsPreferencesStore\.swift$/) report("UserDefaults.standard: use PreferencesStore (rule 20)")
    if (code ~ /@AppStorage/)                                  report("@AppStorage: use PreferencesStore (rule 20)")
    if (code ~ /(^|[^[:alnum:]_])AsyncImage([^[:alnum:]_]|$)/) report("AsyncImage: use AppImage (rule 13)")
    if (code ~ /static (let|var) shared([^[:alnum:]_]|$)/)     report("static shared singleton: inject through the containers (rule 24)")
    if (code ~ /NavigationLink\(destination:/)                 report("NavigationLink(destination:): navigate through AppRouter (rule 15)")
    if (code ~ /\.onTapGesture/)                               report(".onTapGesture: use TapArea or a Button (rule 10)")
    if (code ~ /(^|[^[:alnum:]_])unowned([^[:alnum:]_]|$)/)    report("unowned: use [weak self] (rule 28)")

    if (!crashSafe) {
      if (code ~ /try!/)                                   report("try!: handle the error (rule 28)")
      if (code ~ /as!/)                                    report("as!: use as? (rule 28)")
      if (code ~ /(fatalError|preconditionFailure)\(/)     report("fatalError/preconditionFailure: recover or throw (rule 28)")
      bang = code
      gsub(/try!|as!/, "", bang)
      if (bang ~ /[[:alnum:]_)\]]!([^=]|$)/)               report("force unwrap: use guard let / if let (rule 28)")
    }
  }

  END { exit found }
'
status=$?
[ "$status" -eq 0 ] && [ "$#" -eq 0 ] && echo "✔ no banned APIs"
exit "$status"
