# Decisions
<!-- Architecture decisions, newest last. Every entry names what it cost (Gave up) and what was rejected. -->

## ADR-001: Build on intent-drive-starter, not a fresh framework (2026-10-26)
- Context: TeamBrain (teambrain-repro, early 2026) and intent-drive-starter (Progressive Intent) overlap; teams should not choose between two systems.
- Decision: Fork the starter's plugin-is-its-own-marketplace layout and its pre-implement gate unchanged, and add the team layer (brain/, guards, decide/remember/review) on top.
- Gained: one install; the feature loop teams already learned keeps working.
- Gave up: the original TeamBrain 7-question intent check and big up-front constraints documents.
- Rejected: two separate plugins — double gating, two mental models.
- Rollback: the starter is unchanged; teams can uninstall team-brain and install it alone.
- Status: accepted

## ADR-002: Minimum sufficient intent replaces the mandatory reasoning ritual (2026-10-26)
- Context: TeamBrain asked Claude to answer seven questions before any change; in practice it was skipped or became noise.
- Decision: Gate only on Outcome + Success / Evidence (starter rule). Put judgment in the brain (constraints, lessons, decisions) instead of in a per-change questionnaire.
- Gained: less ceremony; the gate measures something a human actually wrote.
- Gave up: forced up-front restatement of assumptions and risks for every change.
- Rejected: keeping intent-check as a hard gate — high cost, low signal.
- Rollback: add a constraint or lesson to a repo's brain if a team wants the ritual back.
- Status: accepted

## ADR-003: The brain grows by pull request, not private memory (2026-10-26)
- Context: corrections made to one developer's AI are lost to everyone else.
- Decision: /team-brain:remember writes one-line lessons to brain/lessons.md and asks for a PR; /team-brain:decide appends ADRs to brain/decisions.md.
- Gained: the team reviews what its AI learns; history is in git.
- Gave up: instant capture — a lesson only reaches teammates after merge.
- Rejected: per-user Claude memory (not shared), an external knowledge service (breaks portability).
- Rollback: delete brain/lessons.md; nothing else depends on it.
- Status: accepted

## ADR-004: Bash hooks with a parser fallback chain (2026-10-26)
- Context: hooks read JSON from Claude Code; a sed-only parser broke on escaped quotes, and jq is not on every Mac.
- Decision: hooks/lib.sh tries jq, python3, node, then a portable sed best effort; anything unparseable fails open.
- Gained: works on stock macOS and Linux without installing anything.
- Gave up: a single-language, more testable implementation.
- Rejected: Node-only hooks — native Claude Code installs do not ship node; Python-only — not guaranteed on CI images.
- Rollback: replace lib.sh json_get; hooks call only that function.
- Status: accepted
