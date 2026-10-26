---
description: Set up a team brain in the current repository — shared intent, constraints, decisions, lessons and sensitive paths in git, imported into CLAUDE.md, checked in CI. Use when someone says "set up the team brain", "init team brain", "add TeamBrain to this repo", or the first time the plugin is used in a repo. Safe to re-run.
argument-hint: "[one line on what this system is for]"
---

# Initialize the team brain

What the human said this system is for, if given: $ARGUMENTS

1. From the repository root, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/init.sh"`. It never overwrites the team's files. Show the human what it created, updated and kept.
2. Read the repository (README, manifests, folder layout, existing CLAUDE.md / AGENTS.md / docs) before asking anything. The repo is the source of current-state truth; do not ask what it already says.
3. Fill `intent/project-intent.md` with the human, in their words. Ask in one message, offering what you inferred from the repo as a default they can accept:
   - **Purpose** — why this system exists and for whom.
   - **Owner** — who signs off on the intent and constraints.
   - **We do not** — what it deliberately does not do.
   Primary tradeoff and Revisit when are optional; delete them if nothing real comes up.
4. Tune `brain/sensitive-paths.txt` to this repo: keep the defaults that match real folders, add the repo's actual auth, money, data, secrets and infrastructure paths, remove ones that match nothing. Show the final list.
5. Constraints: add only rules the team has actually agreed on, each with `Why:`. If the human names none, leave the section empty — constraints are added when evidence justifies them, not predicted up front. If an existing CLAUDE.md or docs already state hard rules, offer to move them into `brain/constraints.md` with a `Why:` each.
6. Run `bash brain/check.sh`. Fix anything it reports as a problem.
7. Finish with: the files to commit, the suggestion to land them as one pull request so the team reviews its own brain, and the next step — `/team-brain:start <outcome>` for the first feature.

Do not invent purpose, owners or constraints. If the human is not there to answer, write what the repository clearly shows, mark the rest `TODO(owner)`, and say so.
