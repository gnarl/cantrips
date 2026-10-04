#!/usr/bin/env bash
# Usage: run-scenario.sh <number> <baseline|skill|snippet|skill+snippet>
set -euo pipefail

SCRATCH="${SCRATCH:-/tmp/claude-501/-workspace/d2b9ca02-1b4a-4117-ac29-e12caca6683b/scratchpad}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$HERE")"
SCENARIOS="$HERE/scenarios.md"

if [ $# -ne 2 ]; then
  echo "usage: $0 <number> <baseline|skill|snippet|skill+snippet>" >&2
  exit 64
fi
num="$1"
mode="$2"
case "$mode" in baseline|skill|snippet|skill+snippet) ;; *) echo "bad mode: $mode" >&2; exit 64 ;; esac
command -v jq >/dev/null || { echo "jq is required" >&2; exit 69; }
case "$num" in ''|*[!0-9]*) echo "bad scenario number: $num" >&2; exit 64 ;; esac

# field <name>: value of "- <name>: ..." inside "## Scenario <num>"
field() {
  awk -v n="$num" -v f="$1" '
    /^## Scenario / { insec = ($3 == n); next }
    insec && index($0, "- " f ": ") == 1 { print substr($0, length(f) + 5); exit }
  ' "$SCENARIOS"
}

fixture="$(field fixture)"
setup="$(field setup)"
prompt="$(field prompt)"
[ -n "$fixture" ] && [ -n "$prompt" ] || { echo "scenario $num not found in $SCENARIOS" >&2; exit 65; }
[ -d "$HERE/fixtures/$fixture" ] || { echo "missing fixture: $fixture" >&2; exit 65; }

case "$mode" in
  skill|skill+snippet)
    [ -f "$SKILL_DIR/SKILL.md" ] || { echo "missing $SKILL_DIR/SKILL.md (needed for mode $mode)" >&2; exit 66; } ;;
esac
case "$mode" in
  snippet|skill+snippet)
    [ -f "$SKILL_DIR/claude-md-snippet.md" ] || { echo "missing $SKILL_DIR/claude-md-snippet.md (needed for mode $mode)" >&2; exit 66; } ;;
esac

run="$SCRATCH/runs/$num-$mode"
mkdir -p "$SCRATCH/runs"
rm -rf "$run"
mkdir -p "$run"
repo="$run/repo"
cp -R "$HERE/fixtures/$fixture" "$repo"

git_fx() { git -c user.name=fixture -c user.email=fixture@example.invalid "$@"; }

cd "$repo"
git init -q
case "$mode" in
  skill|skill+snippet)
    mkdir -p .claude/skills/project-planning
    (cd "$SKILL_DIR" && tar --exclude=./tests -cf - .) | tar -xf - -C .claude/skills/project-planning
    ;;
esac
case "$mode" in
  snippet|skill+snippet)
    printf '\n' >> CLAUDE.md
    cat "$SKILL_DIR/claude-md-snippet.md" >> CLAUDE.md
    ;;
esac

# Single fixture commit (includes skill/snippet) so outputs show only the agent's changes.
git_fx add -A
git_fx commit -q -m "Fixture: $fixture ($mode)"
if [ -n "$setup" ] && [ "$setup" != "none" ]; then
  bash -c "set -e; $setup"
fi

rc=0
timeout 900 claude -p "$prompt" --output-format stream-json --verbose \
  --permission-mode acceptEdits \
  --allowedTools "Bash(git:*)" "Bash(find:*)" "Bash(cat:*)" "Bash(ls:*)" "Bash(head:*)" "Bash(tail:*)" "Bash(grep:*)" "Bash(wc:*)" "Bash(sed:*)" "Bash(diff:*)" "Bash(sort:*)" \
  "Bash(rtk git:*)" "Bash(rtk find:*)" "Bash(rtk cat:*)" "Bash(rtk ls:*)" "Bash(rtk head:*)" "Bash(rtk tail:*)" "Bash(rtk grep:*)" "Bash(rtk wc:*)" "Bash(rtk sed:*)" "Bash(rtk diff:*)" "Bash(rtk sort:*)" \
  "Bash(rtk read:*)" "Bash(rtk tree:*)" "Bash(rtk smart:*)" "Bash(rtk rg:*)" "Bash(rtk log:*)" "Bash(rtk json:*)" "Bash(rtk recall:*)" \
  "Bash(sh test.sh:*)" "Bash(sh hello.sh:*)" "Bash(bash hello.sh:*)" "Bash(./hello.sh:*)" "Bash(./test.sh:*)" \
  < /dev/null > "$run/transcript.jsonl" 2> "$run/stderr.txt" || rc=$?
echo "$rc" > "$run/exit-code.txt"

# final message: the "result" event of the stream (needs jq)
grep '"type":"result"' "$run/transcript.jsonl" | tail -1 | jq -r '.result // empty' > "$run/final-message.txt" 2>/dev/null || true
# denied tool calls from the result event (empty file if none)
grep '"type":"result"' "$run/transcript.jsonl" | tail -1 | jq -c '.permission_denials[]?' > "$run/denials.txt" 2>/dev/null || true
[ "$rc" -eq 0 ] || echo "claude exited with status $rc" >> "$run/final-message.txt"

git status --short > "$run/git-status.txt" || true   # real staging state, captured before add -N
git log --oneline > "$run/git-log.txt" || true
git add -N . 2>/dev/null || true   # scratch repo only: make new files visible in diff
{ git diff HEAD || true; } > "$run/diff.txt"
echo "run $num-$mode done (exit $rc): $run"
