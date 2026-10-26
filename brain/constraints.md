# Constraints
<!-- Rules the team has actually agreed on. One bullet each, and every bullet says Why: (trace to intent/project-intent.md or to evidence).
     If a constraint cannot be justified, remove it. Add constraints when evidence justifies them, not up front. -->

## Constraints
- The brain lives in plain Markdown and text inside the target repo; nothing requires the plugin to read it. Why: intent "portability over enforcement"; consultants often cannot install plugins on client machines.
- Hooks fail open: a missing tool, unparseable input or internal error exits 0. Why: intent "we do not block work because a hook itself failed".
- Guards route risky actions to a human ("ask"); only root/home recursive deletes are refused outright. Why: intent "AI recommends; a human approves".
- Markdown is never gated, so the intent can always be written. Why: carried from intent-drive-starter; a gate that blocks its own fix is a deadlock.
- Repositories without a brain/ folder are left completely alone, including at session start. Why: the plugin installs at user scope and runs in every repo.
- init never overwrites the team's files; it refreshes only what the plugin owns (brain/check.sh, the CLAUDE.md managed block). Why: the brain belongs to the team.
- Command guards judge the command word that runs, never text inside quotes. Why: evidence — earlier plugin flagged `echo "drop table..."` and commit messages.
- Scripts must run on macOS bash 3.2 and BSD tools as well as Linux. Why: evidence — a GNU-only awk/sed construct broke an earlier checker on Macs.
- The CI checker exits 2 when run outside a brain repo. Why: evidence — a checker that reports green from the wrong directory is worse than none.

## Exceptions
<!-- A constraint is never worked around silently. Name it, get the owner's approval, set a deadline. -->

| Date | Constraint | Reason | Approved by | Deadline |
|------|------------|--------|-------------|----------|
| — | — | — | — | — |
