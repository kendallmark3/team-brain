#!/usr/bin/env bash
# Shared helpers for team-brain hooks. Sourced, not run.
# Hooks fail open: if a helper cannot do its job, the hook exits 0 and gets out of the way.
# A broken guard must never stop a developer from working.

# json_get <dotted.path>  — reads JSON on stdin, prints the string value or nothing.
# Tries jq, then python3, then node (all handle escaped quotes), then a sed best effort.
json_get() {
  local path="$1" input
  input="$(cat)"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg p "$path" 'getpath($p | split(".")) // empty | tostring' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -I -c '
import json, sys
try:
    v = json.load(sys.stdin)
    for k in sys.argv[1].split("."):
        v = v.get(k) if isinstance(v, dict) else None
    if v is not None:
        sys.stdout.write(v if isinstance(v, str) else json.dumps(v))
except Exception:
    pass
' "$path"
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$input" | node -e '
let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{let v=JSON.parse(s);
for(const k of process.argv[1].split("."))v=(v&&typeof v==="object")?v[k]:undefined;
if(v!==undefined&&v!==null)process.stdout.write(typeof v==="string"?v:JSON.stringify(v))}catch(e){}})' "$path"
  else
    # Last resort, no JSON parser installed: match the final key as a simple string value.
    local key="${path##*.}"
    printf '%s' "$input" | sed -nE 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | head -n 1
  fi
}

# json_str <text> — prints text as a JSON string literal.
json_str() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"
  printf '"%s"' "$s"
}

# project_dir — the repository Claude Code is working in.
project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

# rel_path <abs-or-rel> — path relative to the project, without a leading ./
rel_path() {
  local p="$1" root
  root="$(project_dir)"
  case "$p" in
    "$root"/*) p="${p#"$root"/}" ;;
  esac
  p="${p#./}"
  printf '%s' "$p"
}

# ask <reason> — PreToolUse decision that hands the call to the human.
ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":%s}}\n' "$(json_str "$1")"
  exit 0
}

# deny <reason> — PreToolUse decision that refuses the call; Claude sees the reason.
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' "$(json_str "$1")"
  exit 0
}
