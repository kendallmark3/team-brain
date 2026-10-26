# Agent instructions

This repository keeps a team brain that every AI assistant (Claude Code, Copilot, Cursor, Codex) should follow.

Read before changing code:

1. `intent/project-intent.md` — why the system exists, its owner, and what it does not do.
2. `intent/current-feature.md` (if present) — the current feature. Do not change code until it states an Outcome and Success / Evidence.
3. `brain/constraints.md` — agreed rules. Each has a `Why:`. Never work around one silently; name the violation.
4. `brain/lessons.md` — corrections the team does not want to repeat.
5. `brain/decisions.md` — past architecture decisions, with what they cost and what was rejected.

Paths listed in `brain/sensitive-paths.txt` need explicit human approval before you edit them.
Run `bash brain/check.sh` to confirm the brain is sound.
