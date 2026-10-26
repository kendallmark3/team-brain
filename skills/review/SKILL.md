---
description: Review a change against the team brain before a pull request — the current intent and its deltas, constraints, lessons, decisions and sensitive paths — not just the diff. Use when someone says "review", "is this ready", "PR", "ready to merge", or "can I ship this".
argument-hint: "[branch, PR or path — default: current changes vs main]"
---

# Review against the brain

Scope: $ARGUMENTS (default: `git diff` of the current branch against its base, plus uncommitted changes).

1. Run `bash brain/check.sh` if it exists. Report any problem first.
2. For anything bigger than a small change, delegate to the `reviewer` agent with the diff and the paths of the brain files, so the review comes from a context that did not write the code. Otherwise review inline.
3. Check, and report each as ✓ or ✗ with file and line:
   - **Intent** — does the change deliver the Outcome in `intent/current-feature.md` and meet its Success / Evidence, including appended deltas? Was anything a delta said to keep changed?
   - **Constraints** — any rule in `brain/constraints.md` broken? A break without a row in Exceptions is a ✗.
   - **Lessons** — any line in `brain/lessons.md` ignored?
   - **Decisions** — does it contradict an accepted ADR in `brain/decisions.md` without a new ADR?
   - **Sensitive paths** — list every changed file matching `brain/sensitive-paths.txt` and the risk in one line each.
   - **Evidence** — tests run and passing; what a reviewer can look at.
4. End with: ready / not ready, the shortest list of what to fix, and any new lesson worth capturing (offer `/team-brain:remember`). Do not fix things during the review unless asked.
