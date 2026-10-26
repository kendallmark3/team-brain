#!/usr/bin/env bash
# init.sh — lay down a team brain in a repository. Safe to re-run: never overwrites the team's
# files; refreshes only what the plugin owns (brain/check.sh and the CLAUDE.md import block).
#
# Usage: bash init.sh [repo-root]   (default: current directory)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
scaffold="$here/../scaffold"
root="${1:-$PWD}"
cd "$root"

created=(); kept=(); updated=()

place() { # place <scaffold-rel> <repo-rel>
  local src="$scaffold/$1" dst="$2"
  if [ -e "$dst" ]; then kept+=("$dst"); return; fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  created+=("$dst")
}

place intent/project-intent.md   intent/project-intent.md
place brain/README.md            brain/README.md
place brain/constraints.md       brain/constraints.md
place brain/decisions.md         brain/decisions.md
place brain/lessons.md           brain/lessons.md
place brain/sensitive-paths.txt  brain/sensitive-paths.txt
place .github/workflows/team-brain.yml .github/workflows/team-brain.yml

# The checker is plugin-owned: always refresh it so CI runs the current version.
if [ -f brain/check.sh ] && cmp -s "$here/brain-check.sh" brain/check.sh; then kept+=("brain/check.sh")
else
  [ -f brain/check.sh ] && updated+=("brain/check.sh") || created+=("brain/check.sh")
  cp "$here/brain-check.sh" brain/check.sh
  chmod +x brain/check.sh
fi

# CLAUDE.md: add or refresh the managed import block; leave everything else alone.
block="$scaffold/CLAUDE.team-brain.md"
if [ ! -f CLAUDE.md ]; then
  { echo "# CLAUDE.md"; echo; cat "$block"; } >CLAUDE.md
  created+=("CLAUDE.md")
elif grep -q 'team-brain:begin' CLAUDE.md; then
  tmp="$(mktemp)"
  awk -v blockfile="$block" '
    /team-brain:begin/ { while ((getline l < blockfile) > 0) print l; skip = 1; next }
    /team-brain:end/   { skip = 0; next }
    !skip { print }
  ' CLAUDE.md >"$tmp"
  if cmp -s "$tmp" CLAUDE.md; then kept+=("CLAUDE.md"); rm -f "$tmp"; else mv "$tmp" CLAUDE.md; updated+=("CLAUDE.md (team-brain block)"); fi
else
  { echo; cat "$block"; } >>CLAUDE.md
  updated+=("CLAUDE.md (team-brain block appended)")
fi

# AGENTS.md: other assistants read this. Add a pointer if one exists without it.
if [ ! -f AGENTS.md ]; then
  cp "$scaffold/AGENTS.md" AGENTS.md; created+=("AGENTS.md")
elif ! grep -q 'brain/constraints.md' AGENTS.md; then
  { echo; echo "## Team brain"; echo; echo "Follow the team brain: read intent/project-intent.md, intent/current-feature.md, brain/constraints.md, brain/lessons.md and brain/decisions.md before changing code. Paths in brain/sensitive-paths.txt need human approval. Run \`bash brain/check.sh\`."; } >>AGENTS.md
  updated+=("AGENTS.md (team-brain pointer appended)")
else
  kept+=("AGENTS.md")
fi

report() { local label="$1"; shift; [ "$#" -gt 0 ] && { echo "$label:"; printf '  %s\n' "$@"; }; return 0; }
report "Created" ${created[@]+"${created[@]}"}
report "Updated" ${updated[@]+"${updated[@]}"}
report "Kept (already existed)" ${kept[@]+"${kept[@]}"}
