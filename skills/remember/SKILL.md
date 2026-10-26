---
description: Capture a correction or lesson into the team brain (brain/lessons.md) so every developer's sessions inherit it. Use when the human says "remember this", "add this to the brain", "team should always/never…", or corrects the same mistake twice.
argument-hint: "[the lesson]"
---

# Remember

The lesson: $ARGUMENTS (if empty, use the correction the human just made in this session).

1. Decide what it is:
   - **Team lesson** — true for anyone working in this repo → `brain/lessons.md`.
   - **Hard rule with a reason** that should be enforced → offer `brain/constraints.md` with `Why:` instead.
   - **Architecture choice** → `/team-brain:decide`.
   - **Personal preference** of one developer → not the team brain; say so and leave it out.
   - **Something the code or tests already show** → not worth storing; say so.
2. Write it as one line, as an instruction, with where it came from: `- Do X, not Y. (source: PR #, incident, date, or who)`.
3. Read `brain/lessons.md` first. If an existing line covers it, sharpen that line instead of adding a new one. If two lines overlap, merge them. Remove lines that are no longer true.
4. Show the exact diff. Suggest landing it by pull request so the team reviews what its brain learns.
