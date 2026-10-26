#!/usr/bin/env bash
# SessionStart: if this repository has a team brain, tell Claude it is active and what to honor.
# Repositories without brain/ are left alone — nothing is printed.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"

root="$(project_dir)"
[ -d "$root/brain" ] || exit 0

count() { if [ -f "$1" ]; then grep -c "$2" "$1" 2>/dev/null || true; else echo 0; fi; }
constraints=$(count "$root/brain/constraints.md" '^- .*Why:')
decisions=$(count "$root/brain/decisions.md" '^## ADR-')
lessons=$(count "$root/brain/lessons.md" '^- ')

sensitive=""
if [ -f "$root/brain/sensitive-paths.txt" ]; then
  sensitive="$(grep -v -E '^[[:space:]]*(#|$)' "$root/brain/sensitive-paths.txt" | tr '\n' ' ')"
fi

imported="no"
if [ -f "$root/CLAUDE.md" ] && grep -q 'team-brain:begin' "$root/CLAUDE.md"; then imported="yes"; fi

feature="none"
if [ -f "$root/intent/current-feature.md" ]; then
  if bash "$here/pre-implement.sh" "$root/intent/current-feature.md" >/dev/null 2>&1; then
    feature="ready"
  else
    feature="not sufficient yet (code edits are gated until Outcome and Success / Evidence are written)"
  fi
fi

cat <<EOF
Team brain active for this repository (brain/: ${constraints} constraints, ${decisions} decisions, ${lessons} lessons; current feature intent: ${feature}).
- The brain is the team's, versioned in git. Honor intent/project-intent.md, brain/constraints.md and brain/lessons.md.
- Never work around a constraint silently. Name the violation and use /team-brain:decide to record an exception.
- Record architecture choices with /team-brain:decide. When the human corrects you in a way the whole team should keep, offer /team-brain:remember.
- Before a pull request, run /team-brain:review.
EOF
[ -n "$sensitive" ] && echo "- Sensitive paths (edits go to the human for approval): ${sensitive}"
[ "$imported" = "no" ] && echo "- CLAUDE.md does not import the brain yet; /team-brain:init will add the import block."
exit 0
