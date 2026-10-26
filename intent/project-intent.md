# Project Intent

## Purpose
Give any engineering team a shared, versioned "team brain" for AI-assisted work: the intent, agreed rules, decisions and lessons live in the repository, load into every Claude Code session automatically, and are enforced by hooks — so every developer's AI works from the same judgment without anyone pasting prompts.

## Owner
Mark Kendall (LearnTeachMaster / Kendall Software)

## Primary tradeoff
We prioritize portability and low ceremony over enforcement strength. The brain must still work as plain files when the plugin is not installed or not allowed.

## We do not
- Replace human review. AI recommends; a human approves anything sensitive or hard to undo.
- Store the brain anywhere but the repository. No external service, no per-user memory.
- Predict constraints up front. Rules are added when evidence justifies them.
- Ship stack-specific rules (TypeScript, Java, ...). Those belong in each repo's own brain.
- Block work because a hook itself failed. Hooks fail open.

## Revisit when
- Claude Code changes the plugin, hook or skill contract.
- A client environment cannot run bash hooks at all.
- Teams report the gates slow them down more than they help.
