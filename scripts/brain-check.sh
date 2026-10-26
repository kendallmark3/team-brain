#!/usr/bin/env bash
# brain-check — plain bash check of a repository's team brain. No AI, no dependencies beyond awk/grep.
# Runs the same in CI, in a hook, or by hand. Copied into repos as brain/check.sh by /team-brain:init.
#
# Usage: bash brain/check.sh [repo-root] [only-file]   (default: current directory, all files)
# Exit:  0 brain is sound · 1 brain has problems · 2 not a team-brain repo (wrong directory)
set -uo pipefail

root="${1:-$PWD}"
only="${2:-}"
# want <file> — true when this file should be checked on this run.
want() { [ -z "$only" ] || [ "$only" = "$1" ]; }
if [ ! -d "$root/brain" ]; then
  echo "brain-check: no brain/ folder in $root. Run from the repository root (or run /team-brain:init)." >&2
  exit 2
fi
cd "$root" || exit 2

problems=0
warnings=0
fail() { echo "  ✗ $1"; problems=$((problems + 1)); }
warn() { echo "  ! $1"; warnings=$((warnings + 1)); }
ok()   { echo "  ✓ $1"; }

# section_text <file> <heading> — non-comment content under a "## heading" (case-insensitive).
section_text() {
  awk -v want="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')" '
    { line = $0; gsub(/<!--.*-->/, "", line) }
    /^#+[ \t]/ {
      name = tolower(line); sub(/^#+[ \t]*/, "", name); sub(/[ \t:]+$/, "", name)
      on = (name == want); next
    }
    on && line ~ /[^ \t]/ { print line }
  ' "$1"
}

if want intent/project-intent.md; then
echo "Project intent (intent/project-intent.md)"
f="intent/project-intent.md"
if [ ! -f "$f" ]; then
  fail "missing"
else
  for s in "Purpose" "Owner"; do
    if [ -n "$(section_text "$f" "$s")" ]; then ok "$s stated"; else fail "$s is empty"; fi
  done
  if [ -n "$(section_text "$f" "We do not")" ]; then ok "boundaries stated (We do not)"; else warn "We do not is empty — say what this system deliberately does not do"; fi
fi

fi

if want brain/constraints.md; then
echo "Constraints (brain/constraints.md)"
f="brain/constraints.md"
if [ ! -f "$f" ]; then
  fail "missing"
else
  body="$(section_text "$f" "Constraints")"
  total=$(printf '%s\n' "$body" | grep -c '^- ' || true)
  untraced=$(printf '%s\n' "$body" | grep '^- ' | grep -v -E 'Why:[[:space:]]*[^[:space:]]' || true)
  if [ "$total" -eq 0 ]; then
    warn "no constraints yet (fine for a new brain)"
  elif [ -n "$untraced" ]; then
    while IFS= read -r line; do fail "no Why: trace — ${line:0:80}"; done <<<"$untraced"
  else
    ok "$total constraint(s), each traced with Why:"
  fi
  # Exceptions: every real row needs Approved by and Deadline.
  bad=$(section_text "$f" "Exceptions" | awk -F'|' '
    /^\|/ && !/^\|[ \t-]*\|/ && NF >= 6 {
      row++; if (row == 1) next                      # header row
      c=$2; gsub(/[ \t—-]/, "", c); if (c == "") next # placeholder row
      a=$5; d=$6; gsub(/[ \t—-]/, "", a); gsub(/[ \t—-]/, "", d)
      if (a == "" || d == "") print $3
    }')
  if [ -n "$bad" ]; then
    while IFS= read -r c; do fail "exception without approver or deadline:${c}"; done <<<"$bad"
  else
    ok "exceptions are approved and time-bound"
  fi
fi

fi

if want brain/decisions.md; then
echo "Decisions (brain/decisions.md)"
f="brain/decisions.md"
if [ ! -f "$f" ]; then
  fail "missing"
else
  n=$(grep -c '^## ADR-' "$f" || true)
  incomplete=$(awk '
    function flush() { if (id != "" && (!gave || !rej)) print id }
    /^## ADR-/ { flush(); id = $0; gave = 0; rej = 0; next }
    { line = $0; gsub(/<!--.*-->/, "", line) }
    tolower(line) ~ /^- \*?\*?gave up:?\*?\*?:?[ \t]*[^ \t]/ { gave = 1 }
    tolower(line) ~ /^- \*?\*?rejected:?\*?\*?:?[ \t]*[^ \t]/ { rej = 1 }
    END { flush() }
  ' "$f")
  if [ -n "$incomplete" ]; then
    while IFS= read -r id; do fail "${id#\#\# } — needs both 'Gave up:' and 'Rejected:'"; done <<<"$incomplete"
  else
    ok "$n decision(s), each with a cost and a rejected alternative"
  fi
fi

fi

if want brain/lessons.md; then
echo "Lessons (brain/lessons.md)"
f="brain/lessons.md"
if [ ! -f "$f" ]; then
  fail "missing"
else
  n=$(grep -c '^- ' "$f" || true)
  if [ "$n" -gt 60 ]; then warn "$n lessons — consolidate; a brain that is too long stops being read"; else ok "$n lesson(s)"; fi
fi

fi

if want brain/sensitive-paths.txt; then
echo "Sensitive paths (brain/sensitive-paths.txt)"
if [ -f brain/sensitive-paths.txt ]; then
  n=$(grep -c -v -E '^[[:space:]]*(#|$)' brain/sensitive-paths.txt || true)
  ok "$n pattern(s)"
else
  warn "missing — no edits will be routed to a human"
fi
fi

echo
if [ "$problems" -gt 0 ]; then
  echo "brain-check: $problems problem(s), $warnings warning(s)."
  exit 1
fi
echo "brain-check: brain is sound ($warnings warning(s))."
exit 0
