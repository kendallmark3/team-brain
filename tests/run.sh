#!/usr/bin/env bash
# Tests for every team-brain hook and script. Run from anywhere: bash tests/run.sh
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
failures=0; passes=0
pass() { echo "ok   - $1"; passes=$((passes + 1)); }
flunk() { echo "FAIL - $1"; [ -f "$tmp/out" ] && sed 's/^/       /' "$tmp/out"; failures=$((failures + 1)); }

# ---------- pre-implement.sh (from intent-drive-starter) ----------
pre="$root/hooks/pre-implement.sh"
expect_pre() { local want="$1" label="$2" file="$3" got=0
  bash "$pre" "$file" >"$tmp/out" 2>&1 || got=$?
  if { [ "$want" = pass ] && [ "$got" -eq 0 ]; } || { [ "$want" = fail ] && [ "$got" -ne 0 ]; }; then pass "$label"; else flunk "$label (exit $got)"; fi; }
expect_pre fail "pre: blank feature template is not sufficient" "$root/templates/feature-template.md"
expect_pre fail "pre: missing file fails" "$tmp/nope.md"
printf '# F\n\n## Outcome\nOperators see failed jobs.\n\n## Success / Evidence\nA failed job is visible.\n' >"$tmp/ok.md"
expect_pre pass "pre: outcome and evidence are sufficient" "$tmp/ok.md"
printf '# F\n\n## Outcome\n<!-- what -->\n\n## Success / Evidence\n<!-- how -->\n' >"$tmp/c.md"
expect_pre fail "pre: guidance comments are not content" "$tmp/c.md"

# ---------- hook helpers ----------
run_hook() { # run_hook <script> <project> <json>
  printf '%s' "$3" | CLAUDE_PROJECT_DIR="$2" bash "$root/hooks/$1" >"$tmp/out" 2>&1
}
write_json() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$1"; }
. "$root/hooks/lib.sh"
bash_json() { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(json_str "$1")"; }

# ---------- pre-implement-hook.sh ----------
mkdir -p "$tmp/none" "$tmp/blank/intent" "$tmp/ready/intent"
cp "$root/templates/feature-template.md" "$tmp/blank/intent/current-feature.md"
cp "$tmp/ok.md" "$tmp/ready/intent/current-feature.md"
gate() { local want="$1" label="$2" proj="$3" target="$4" got=0
  run_hook pre-implement-hook.sh "$proj" "$(write_json "$target")" || got=$?
  [ "$got" -eq "$want" ] && pass "$label" || flunk "$label (exit $got, wanted $want)"; }
gate 0 "gate: repo without a feature intent is left alone" "$tmp/none" "$tmp/none/app.py"
gate 2 "gate: blocks code while feature intent is blank" "$tmp/blank" "$tmp/blank/src/app.py"
gate 0 "gate: never blocks Markdown" "$tmp/blank" "$tmp/blank/intent/current-feature.md"
gate 0 "gate: allows code once intent is sufficient" "$tmp/ready" "$tmp/ready/src/app.py"
# Escaped quotes in the JSON must not break path extraction (old sed bug).
got=0; printf '{"tool_input":{"content":"say \\"hi\\" \\"file_path\\": \\"x.md\\"","file_path":"%s"}}' "$tmp/blank/src/app.py" |
  CLAUDE_PROJECT_DIR="$tmp/blank" bash "$root/hooks/pre-implement-hook.sh" >"$tmp/out" 2>&1 || got=$?
[ "$got" -eq 2 ] && pass "gate: escaped quotes in content do not fool path extraction" || flunk "gate: escaped quotes (exit $got)"

# ---------- sensitive-path-guard.sh ----------
mkdir -p "$tmp/brainrepo"
( cd "$tmp/brainrepo" && bash "$root/scripts/init.sh" >/dev/null )
sens() { local want="$1" label="$2" path="$3"
  run_hook sensitive-path-guard.sh "$tmp/brainrepo" "$(write_json "$path")"
  if [ "$want" = ask ]; then grep -q '"permissionDecision":"ask"' "$tmp/out" && pass "$label" || flunk "$label"
  else [ ! -s "$tmp/out" ] && pass "$label" || flunk "$label"; fi; }
sens ask  "sensitive: src/auth/login.ts asks"            "$tmp/brainrepo/src/auth/login.ts"
sens ask  "sensitive: relative migrations path asks"      "db/migrations/001.sql"
sens ask  "sensitive: root .env asks"                     "$tmp/brainrepo/.env"
sens ask  "sensitive: .env.local asks"                    "$tmp/brainrepo/config/.env.local"
sens ask  "sensitive: workflow file asks"                 "$tmp/brainrepo/.github/workflows/ci.yml"
sens none "sensitive: ordinary file is left alone"        "$tmp/brainrepo/src/routes/health.ts"
sens none "sensitive: 'author' does not match auth"       "$tmp/brainrepo/docs/authoring-guide.md"
run_hook sensitive-path-guard.sh "$tmp/none" "$(write_json "$tmp/none/src/auth/x.ts")"
[ ! -s "$tmp/out" ] && pass "sensitive: repo without a brain is left alone" || flunk "sensitive: no brain"
run_hook sensitive-path-guard.sh "$tmp/brainrepo" "$(write_json "$tmp/brainrepo/src/auth/x.ts")"
[ "$(json_get hookSpecificOutput.permissionDecision <"$tmp/out")" = ask ] && pass "sensitive: output is valid JSON" || flunk "sensitive: invalid JSON"

# ---------- command-guard.sh ----------
cmdg() { local want="$1" cmd="$2"
  run_hook command-guard.sh "$tmp/none" "$(bash_json "$cmd")"
  case "$want" in
    ask)  grep -q '"permissionDecision":"ask"'  "$tmp/out" && pass "command $want: $cmd" || flunk "command $want: $cmd" ;;
    deny) grep -q '"permissionDecision":"deny"' "$tmp/out" && pass "command $want: $cmd" || flunk "command $want: $cmd" ;;
    none) [ ! -s "$tmp/out" ] && pass "command $want: $cmd" || flunk "command $want: $cmd" ;;
  esac; }
cmdg ask  'git push --force origin main'
cmdg ask  'git push -f'
cmdg ask  'git push origin +main'
cmdg none 'git push --force-with-lease origin feature'
cmdg none 'git push origin feature'
cmdg ask  'git reset --hard HEAD~3'
cmdg none 'git reset --soft HEAD~1'
cmdg ask  'git clean -fdx'
cmdg ask  'git branch -D old-feature'
cmdg none 'git branch -d merged-feature'
cmdg deny 'rm -rf /'
cmdg deny 'sudo rm -rf ~'
cmdg deny 'rm -Rf $HOME'
cmdg none 'rm -rf node_modules dist'
cmdg none 'rm -rf ./build'
cmdg ask  'psql -c "DROP TABLE users"'
cmdg ask  'cd db && mysql -e "truncate table sessions"'
cmdg none 'echo "drop table users" > notes.txt'
cmdg none 'git commit -m "docs: explain why we never git push --force"'
cmdg none 'grep -r "rm -rf /" docs/'
cmdg ask  'terraform destroy -auto-approve'
cmdg none 'terraform plan'
cmdg ask  'kubectl delete namespace staging'
cmdg none 'kubectl delete pod web-1'
cmdg ask  'npm test && git push --force'
cmdg none 'ls -la'

# ---------- brain-check.sh ----------
check="$root/scripts/brain-check.sh"
chk() { local want="$1" label="$2" dir="$3" got=0
  bash "$check" "$dir" >"$tmp/out" 2>&1 || got=$?
  [ "$got" -eq "$want" ] && pass "$label" || flunk "$label (exit $got, wanted $want)"; }
chk 2 "check: wrong directory exits 2, not a false green" "$tmp/none"
chk 1 "check: fresh brain fails until Purpose and Owner are written" "$tmp/brainrepo"
grep -q '0 decision(s)' "$tmp/out" && pass "check: template example is not counted as a decision" || flunk "check: template ADR counted"
cp -r "$tmp/brainrepo" "$tmp/good"
cat >"$tmp/good/intent/project-intent.md" <<'EOF'
# Project Intent
## Purpose
Give app teams OTEL observability without learning OTEL.
## Owner
Platform / SRE team
## We do not
Auto-remediate.
EOF
chk 0 "check: purpose and owner are enough to pass" "$tmp/good"
cat >"$tmp/good/brain/constraints.md" <<'EOF'
# Constraints
## Constraints
- Observe only, never remediate. Why: intent "We do not auto-remediate".
- Secrets injected at runtime. Why: security review 2026-03.
## Exceptions
| Date | Constraint | Reason | Approved by | Deadline |
|------|------------|--------|-------------|----------|
| — | — | — | — | — |
EOF
chk 0 "check: traced constraints pass" "$tmp/good"
cp -r "$tmp/good" "$tmp/bad1"
printf '# Constraints\n## Constraints\n- Use Postgres.\n## Exceptions\n' >"$tmp/bad1/brain/constraints.md"
chk 1 "check: constraint without Why: fails" "$tmp/bad1"
cp -r "$tmp/good" "$tmp/bad2"
echo "| 2026-10-26 | Observe only | demo needs restart | | 2026-11-30 |" >>"$tmp/bad2/brain/constraints.md"
chk 1 "check: exception without approver fails" "$tmp/bad2"
cp -r "$tmp/good" "$tmp/ok2"
echo "| 2026-10-26 | Observe only | demo needs restart | Platform lead | 2026-11-30 |" >>"$tmp/ok2/brain/constraints.md"
chk 0 "check: approved, time-bound exception passes" "$tmp/ok2"
cp -r "$tmp/good" "$tmp/bad3"
printf '\n## ADR-001: Use Kafka (2026-10-26)\n- Decision: Kafka for events\n- Gained: replay\n- Rejected: SQS — no replay\n' >>"$tmp/bad3/brain/decisions.md"
chk 1 "check: decision without a cost fails" "$tmp/bad3"
printf -- '- Gave up: ops burden\n' >>"$tmp/bad3/brain/decisions.md"
chk 0 "check: decision with cost and rejected alternative passes" "$tmp/bad3"
bash "$check" "$tmp/bad1" brain/lessons.md >"$tmp/out" 2>&1; got=$?
[ "$got" -eq 0 ] && pass "check: scoped to one file ignores problems elsewhere" || flunk "check: scoped (exit $got)"

# ---------- brain-validate.sh (PostToolUse) ----------
got=0; run_hook brain-validate.sh "$tmp/bad1" "$(write_json "$tmp/bad1/brain/constraints.md")" || got=$?
[ "$got" -eq 2 ] && grep -q 'Why:' "$tmp/out" && pass "validate: broken constraint edit is fed back to Claude" || flunk "validate: feedback (exit $got)"
got=0; run_hook brain-validate.sh "$tmp/bad1" "$(write_json "$tmp/bad1/src/app.ts")" || got=$?
[ "$got" -eq 0 ] && pass "validate: non-brain edits are ignored" || flunk "validate: non-brain (exit $got)"
got=0; run_hook brain-validate.sh "$tmp/good" "$(write_json "$tmp/good/brain/lessons.md")" || got=$?
[ "$got" -eq 0 ] && pass "validate: sound brain edit passes" || flunk "validate: sound (exit $got)"

# ---------- session-start.sh ----------
run_hook session-start.sh "$tmp/none" '{}'
[ ! -s "$tmp/out" ] && pass "session: silent in repos without a brain" || flunk "session: should be silent"
run_hook session-start.sh "$tmp/good" '{}'
grep -q 'Team brain active' "$tmp/out" && grep -q '2 constraints' "$tmp/out" && grep -q 'Sensitive paths' "$tmp/out" \
  && pass "session: announces brain with counts and sensitive paths" || flunk "session: content"

# ---------- init.sh ----------
mkdir -p "$tmp/existing"
printf '# My rules\nUse tabs.\n' >"$tmp/existing/CLAUDE.md"
printf '# Agents\nBe nice.\n' >"$tmp/existing/AGENTS.md"
( cd "$tmp/existing" && bash "$root/scripts/init.sh" >"$tmp/out" 2>&1 ) && pass "init: runs in a repo with existing files" || flunk "init: run"
grep -q 'Use tabs.' "$tmp/existing/CLAUDE.md" && grep -q 'team-brain:begin' "$tmp/existing/CLAUDE.md" && pass "init: keeps CLAUDE.md content and appends block" || flunk "init: CLAUDE.md"
grep -q 'Be nice.' "$tmp/existing/AGENTS.md" && grep -q 'brain/constraints.md' "$tmp/existing/AGENTS.md" && pass "init: keeps AGENTS.md and adds pointer" || flunk "init: AGENTS.md"
[ ! -e "$tmp/existing/intent/current-feature.md" ] && pass "init: does not gate the repo with a blank feature file" || flunk "init: created current-feature.md"
echo "- Keep me. (test)" >>"$tmp/existing/brain/lessons.md"
cp "$tmp/existing/CLAUDE.md" "$tmp/claude.before"
( cd "$tmp/existing" && bash "$root/scripts/init.sh" >"$tmp/out" 2>&1 )
grep -q 'Keep me.' "$tmp/existing/brain/lessons.md" && pass "init: re-run never overwrites the team's files" || flunk "init: overwrote lessons"
cmp -s "$tmp/claude.before" "$tmp/existing/CLAUDE.md" && pass "init: re-run is idempotent for CLAUDE.md" || flunk "init: CLAUDE.md changed on re-run"
[ "$(grep -c 'team-brain:begin' "$tmp/existing/CLAUDE.md")" -eq 1 ] && pass "init: exactly one managed block" || flunk "init: duplicate blocks"
[ -x "$tmp/existing/brain/check.sh" ] && pass "init: vendors executable brain/check.sh for CI" || flunk "init: check.sh"

echo
echo "$passes passed, $failures failed"
[ "$failures" -eq 0 ]
