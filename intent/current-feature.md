# Current Feature

## Outcome
A team can install one plugin and, in any repository, run /team-brain:init to get a shared brain that loads into every Claude Code session, routes risky edits and commands to a human, and is checked in CI.

## Success / Evidence
- tests/run.sh passes on Linux and macOS, including with jq, python3 and node each absent.
- `claude plugin validate .` passes and the plugin installs from the GitHub marketplace in a clean config.
- In a fresh repo, init + filling Purpose and Owner makes brain/check.sh pass, and the session-start hook announces the brain.

## Constraints / Boundaries
- Keep intent-drive-starter's feature loop and pre-implement gate behavior unchanged.
