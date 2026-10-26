---
description: Make and record an architecture decision in the team brain — tradeoffs with a real cost, rejected alternatives, rollback — appended to brain/decisions.md. Also records a named exception when a constraint has to be broken. Use for new services, data models, schemas, dependencies, service boundaries, "how should we design X", or "we need to break constraint Y".
argument-hint: "[the decision or the constraint to break]"
---

# Decide

The question: $ARGUMENTS

1. Read `intent/project-intent.md`, `brain/constraints.md` and `brain/decisions.md`. If an earlier decision already answers this, say so and stop, or treat the new one as superseding it.
2. Work it through, briefly, with the human:
   - **Context** — what exists today and why it is not enough.
   - **Decision** — one paragraph. If it needs more, the scope is too big; split it.
   - **Gained / Gave up** — both must have entries. A decision with no cost was not thought through.
   - **Rejected** — at least one real alternative and why not.
   - **Rollback** — how to undo it, or say plainly that it is one-way.
3. Recommend; the human decides. Do not record a decision as accepted until they agree. One-way decisions need the intent owner named in `intent/project-intent.md`.
4. Append it to `brain/decisions.md` as `## ADR-NNN: Title (YYYY-MM-DD)` with the fields `Context`, `Decision`, `Gained`, `Gave up`, `Rejected`, `Rollback`, `Status` (next number after the last ADR). If it supersedes an older ADR, set that one's Status to `superseded by ADR-NNN` — do not delete it.
5. If the decision creates a rule the team must keep following, offer to add it to `brain/constraints.md` with `Why: ADR-NNN`.

## Breaking a constraint
Never work around a constraint silently. Name it, state why it must be broken, and add a row to the Exceptions table in `brain/constraints.md` with Date, Constraint, Reason, Approved by (the owner — ask; do not fill it in yourself) and Deadline. If the exception will be permanent, the constraint itself should change instead.
