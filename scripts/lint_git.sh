#!/bin/sh
# CI-side twin of the git hooks (§12): hooks can be skipped with --no-verify, this can't.
#   scripts/lint_git.sh <source-branch> <mr-title> <base-sha>
branch="$1"; title="$2"; base="$3"
status=0
type_re='(feat|fix|refactor|perf|test|docs|style|chore|build|ci|revert)(\([a-z0-9-]+\))?!?: .{3,72}$'

echo "$branch" | grep -Eq '^((feat|fix|refactor|chore|docs|test|ci|perf)/[a-z0-9._-]+|(release|hotfix)/[0-9]+\.[0-9]+\.[0-9]+)$' \
  || { echo "✖ Branch '$branch' must look like feat/my_change or release/1.2.0"; status=1; }

# The MR title becomes the squash commit.
title=${title#Draft: }
echo "$title" | grep -Eq "^$type_re" \
  || { echo "✖ MR title '$title' must be a Conventional Commit: type(scope)?: subject"; status=1; }

for sha in $(git rev-list --no-merges "$base..HEAD"); do
  msg=$(git log -1 --format=%B "$sha")
  subject=$(printf '%s\n' "$msg" | head -n1)
  printf '%s\n' "$subject" | grep -Eq "^(Revert \"|$type_re)" \
    || { echo "✖ $(git rev-parse --short "$sha") '$subject' is not a Conventional Commit"; status=1; }
  [ "$(printf '%s\n' "$msg" | grep -cv '^[[:space:]]*$')" -le 1 ] \
    || { echo "✖ $(git rev-parse --short "$sha") is not a one-line commit message"; status=1; }
done

[ "$status" -eq 0 ] && echo "✔ branch, MR title and commits OK"
exit "$status"
