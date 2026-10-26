#!/usr/bin/env bash
# PreToolUse (Edit/Write): edits to paths the team marked sensitive in brain/sensitive-paths.txt
# go to the human for approval. AI may recommend; a human approves.
#
# Patterns are shell globs matched against the path relative to the repo root.
# In these patterns '*' also crosses '/', so '*auth*' matches 'src/auth/login.ts'.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"

input="$(cat)"
root="$(project_dir)"
list="$root/brain/sensitive-paths.txt"
[ -f "$list" ] || exit 0

target="$(printf '%s' "$input" | json_get tool_input.file_path)"
[ -n "$target" ] || target="$(printf '%s' "$input" | json_get tool_input.notebook_path)"
[ -n "$target" ] || exit 0
rel="$(rel_path "$target")"

while IFS= read -r pattern || [ -n "$pattern" ]; do
  pattern="${pattern%%#*}"
  pattern="$(printf '%s' "$pattern" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$pattern" ] || continue
  # shellcheck disable=SC2053
  if [[ "$rel" == $pattern ]]; then
    ask "Team brain: '$rel' matches sensitive pattern '$pattern' (brain/sensitive-paths.txt). State the risk and what could break before approving."
  fi
done <"$list"
exit 0
