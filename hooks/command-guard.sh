#!/usr/bin/env bash
# PreToolUse (Bash): commands that destroy shared state go to the human; catastrophic ones are refused.
# Only the command word that actually runs counts, so `echo "git push --force"` or a commit
# message mentioning "drop table" is not flagged.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"

input="$(cat)"
cmd="$(printf '%s' "$input" | json_get tool_input.command)"
[ -n "$cmd" ] || exit 0

# Remove quoted strings, then split into segments on ; && || | and newlines.
stripped="$(printf '%s' "$cmd" | sed -E "s/'[^']*'/ /g; s/\"([^\"\\\\]|\\\\.)*\"/ /g")"
# Pure bash splitting: BSD sed (macOS) does not turn \n into a newline.
nl=$'\n'
segments="${stripped//&&/$nl}"; segments="${segments//||/$nl}"
segments="${segments//;/$nl}"; segments="${segments//|/$nl}"

while IFS= read -r seg; do
  # Drop leading whitespace, sudo, env assignments and `command`/`exec` wrappers.
  seg="$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//; s/^(sudo|command|exec|env)[[:space:]]+//; s/^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)+//')"
  [ -n "$seg" ] || continue
  word="${seg%%[[:space:]]*}"
  word="${word##*/}"
  padded=" $seg "

  case "$word" in
    rm)
      shopt -s nocasematch
      if [[ "$padded" =~ [[:space:]]-[a-z]*r[a-z]*f|[[:space:]]-[a-z]*f[a-z]*r|--recursive ]] &&
         [[ "$padded" =~ [[:space:]](/|/\*|~|~/|\$HOME|\$HOME/|\$\{HOME\})[[:space:]] ]]; then
        deny "Team brain: refusing recursive delete of a root or home directory: $cmd"
      fi
      shopt -u nocasematch
      ;;
    git)
      if [[ "$padded" =~ [[:space:]]push[[:space:]] ]] &&
         [[ "$padded" =~ [[:space:]](--force|-f|--mirror)[[:space:]] || "$padded" =~ [[:space:]]\+[^[:space:]]+[[:space:]] ]]; then
        ask "Team brain: force push rewrites shared history. Prefer --force-with-lease. Approve only if the team expects it: $cmd"
      fi
      if [[ "$padded" =~ [[:space:]]reset[[:space:]].*--hard ]]; then
        ask "Team brain: git reset --hard discards uncommitted work: $cmd"
      fi
      if [[ "$padded" =~ [[:space:]]clean[[:space:]].*-[a-z]*f ]]; then
        ask "Team brain: git clean -f deletes untracked files permanently: $cmd"
      fi
      if [[ "$padded" =~ [[:space:]]branch[[:space:]].*(-D|--delete[[:space:]]+--force) ]]; then
        ask "Team brain: force-deleting a branch can lose unmerged work: $cmd"
      fi
      ;;
    psql|mysql|mariadb|sqlite3|mongosh|mongo|sqlcmd|cqlsh)
      shopt -s nocasematch
      if [[ "$cmd" =~ (drop|truncate)[[:space:]]+(table|database|schema|collection|keyspace) || "$cmd" =~ dropDatabase|\.drop\(\) ]]; then
        ask "Team brain: destructive database statement. Data integrity is a sensitive area: $cmd"
      fi
      shopt -u nocasematch
      ;;
    terraform|tofu|pulumi)
      if [[ "$padded" =~ [[:space:]]destroy[[:space:]] ]]; then
        ask "Team brain: infrastructure destroy: $cmd"
      fi
      ;;
    kubectl)
      if [[ "$padded" =~ [[:space:]]delete[[:space:]] ]] &&
         [[ "$padded" =~ [[:space:]](namespace|ns|--all|-A|--all-namespaces)[[:space:]] ]]; then
        ask "Team brain: broad Kubernetes delete: $cmd"
      fi
      ;;
  esac
done <<<"$segments"
exit 0
