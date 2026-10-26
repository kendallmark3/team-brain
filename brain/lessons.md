# Lessons
<!-- Corrections the team does not want to repeat. One line each, as an instruction, with where it came from. -->
- Treat --force-with-lease as safe; only bare --force, -f, --mirror or +refspec are force pushes. (earlier IDE plugin, false positive)
- Do not use `\n` in a sed replacement or `\|` in sed patterns; BSD sed on macOS ignores them. Split in bash or use sed -E. (team-brain build, 2026-10-26)
- Test every hook with jq, python3 and node absent, not just present. (team-brain build, 2026-10-26)
- Do not create a blank intent/current-feature.md during init; it gates the whole repo the day the brain merges. (team-brain build, 2026-10-26)
- Portable files beat plugins inside client enterprises without admin rights; keep AGENTS.md and brain/check.sh working alone. (Zayo rollout discussion, 2026-09)
