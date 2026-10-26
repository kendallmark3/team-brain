#!/usr/bin/env bash
# PreToolUse (Edit/Write): from intent-drive-starter. Blocks code edits while the current
# feature intent is not sufficient (see pre-implement.sh).
# Leaves projects without intent/current-feature.md alone, and never blocks Markdown.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"

input="$(cat)"
project="$(project_dir)"
intent="$project/intent/current-feature.md"
[ -f "$intent" ] || exit 0

target="$(printf '%s' "$input" | json_get tool_input.file_path)"
[ -n "$target" ] || target="$(printf '%s' "$input" | json_get tool_input.notebook_path)"
[ -n "$target" ] || exit 0
case "$target" in
  *.md|*.MD|*.markdown|*.txt) exit 0 ;;
esac

if ! out="$(bash "$here/pre-implement.sh" "$intent" 2>&1)"; then
  echo "$out" >&2
  echo "Write the intent first (Markdown files are not blocked), then continue." >&2
  exit 2
fi
exit 0
