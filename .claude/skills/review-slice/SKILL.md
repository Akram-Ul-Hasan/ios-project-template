---
name: review-slice
description: Review a change (branch, diff or files) by running the review agents in parallel and merging their findings into one ranked report. Use when asked to review code before an MR.
---

# Review a slice

1. Determine the scope: `git diff dev...HEAD --stat` (or the files the user names).
2. Run these agents in parallel, each on the same scope:
   - `architecture-auditor` — target graph, layer leaks, DI.
   - `swift-code-reviewer` — Swift 6 concurrency, memory, cancellation, crash safety.
   - `convention-checker` — the 36 mandatory rules in `CLAUDE.md`.
   - `ios-perf-auditor` — main-thread work, view invalidation, images, lists.
3. Merge: de-duplicate, then rank by severity (crash/security/data-loss → architecture → correctness → conventions →
   performance → nits). Each finding: file:line, what's wrong, a concrete failure scenario, the fix.
4. Drop findings you can't support with the code. Say plainly when an area has no findings.
5. Run the `preflight` skill if the change hasn't been verified.
