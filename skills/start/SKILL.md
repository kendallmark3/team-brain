---
description: Start Progressive Intent work on a feature in the current project — write the smallest sufficient intent, build the smallest useful delta, let the human observe, continue or stop. Use at the beginning of a feature or fix.
argument-hint: "[the outcome you want]"
---

# Start
Get from a stated outcome to something the human can observe.

The outcome, if given: $ARGUMENTS

1. If `intent/current-feature.md` does not exist, create it from `${CLAUDE_PLUGIN_ROOT}/templates/feature-template.md`. If it holds a finished feature, ask whether to start a new one before replacing it.
2. Write the human's Outcome and Success / Evidence in their words. Ask only for what is missing from those two. Delete the other sections unless the human gave real inputs, outputs, or boundaries.
3. Run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/pre-implement.sh"` from the project root. Code edits are blocked until it passes.
4. If a `brain/` folder exists, check the plan against `brain/constraints.md`, `brain/lessons.md` and `brain/decisions.md`. If the plan would break a constraint, say which one before building — do not work around it.
5. Read repository state, determine the smallest useful delta (feature-planner skill), build it, and run the project's tests.
6. Show the human the result and ask: continue or stop. Feedback goes to the progressive-intent skill. On stop, suggest `/team-brain:review`.
