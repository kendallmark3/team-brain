#!/usr/bin/env bash
# PostToolUse (Edit/Write): after Claude edits the brain itself, run brain-check and hand any
# problems straight back to Claude (exit 2 → stderr is shown to Claude) so it fixes them now.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"

input="$(cat)"
root="$(project_dir)"
[ -d "$root/brain" ] || exit 0

target="$(printf '%s' "$input" | json_get tool_input.file_path)"
rel="$(rel_path "$target")"
case "$rel" in
  brain/*.md|intent/project-intent.md) ;;
  *) exit 0 ;;
esac

out="$(bash "$here/../scripts/brain-check.sh" "$root" "$rel" 2>&1)"
code=$?
if [ "$code" -eq 1 ]; then
  printf '%s\n' "$out" | grep -E '✗' >&2
  echo "Team brain: fix the problems above in the brain files before moving on." >&2
  exit 2
fi
exit 0
