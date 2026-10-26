# Team brain

This folder is the team's shared engineering judgment, versioned with the code.
Every Claude Code session in this repo loads it (via the import block in `CLAUDE.md`),
and other assistants read it through `AGENTS.md`. Nothing here depends on the plugin to be useful.

| File | What it holds | How it changes |
|------|---------------|----------------|
| `../intent/project-intent.md` | Why the system exists, owner, what it does not do | Owner signs off |
| `constraints.md` | Agreed rules, each with `Why:`; named exceptions | Pull request, owner approves |
| `decisions.md` | Architecture decisions with cost and rejected alternatives | `/team-brain:decide` |
| `lessons.md` | Corrections the team does not want to repeat | `/team-brain:remember`, pull request |
| `sensitive-paths.txt` | Paths where edits go to a human first | Pull request |
| `check.sh` | Plain bash check, runs in CI | — |

Rules of the brain:

1. The brain is the team's, not one person's. It grows by pull request.
2. Structure the boundary, not the reasoning. Write down what the code cannot show.
3. Constraints are added when evidence justifies them, and every one traces to intent.
4. A constraint is never worked around silently: name it, get approval, set a deadline.
5. AI recommends; a human approves anything sensitive or hard to undo.
6. Keep it short. A brain nobody reads is not a brain.
