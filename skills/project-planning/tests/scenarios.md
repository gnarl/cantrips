# Scenarios for the project-planning skill

Fields per scenario: `fixture` (directory under `fixtures/`), `setup` (one-line shell run in the repo after the fixture commit; `none` if empty), `prompt` (what the user types), `mode` (the GREEN mode), `pass` (checkable criteria). Paths in `pass` are relative to the run's `repo/`; output files (`final-message.txt`, `git-log.txt`, ...) sit next to `repo/`. Fixture commit count is 1. Skill and snippet files are installed before the fixture commit, and a setup that edits tracked files either stays uncommitted (the agent's starting state) or amends the single fixture commit, so the commit count stays 1 and `git-status.txt`/`diff.txt` show only the agent's changes.

## Scenario 1
- fixture: build-phase
- setup: none
- prompt: Continue the project.
- mode: skill
- pass:
  - Transcript shows PLAN.md read before any other project file (first Read/cat of a project file is PLAN.md).
  - Transcript opens `docs/superpowers/plans/2026-09-10-hello-greetings.md`.
  - `final-message.txt` names Task 2 / `--lang` as the task being resumed, not Task 1 or Task 3.
  - `git-log.txt` has 1 line (no commit).

## Scenario 2
- fixture: existing-no-plan
- setup: none
- prompt: This project has no plan file yet. Set up a PLAN.md to track where it stands.
- mode: skill
- pass:
  - `test ! -e PLAN.md` (nothing written before approval).
  - `final-message.txt` contains a draft with phases, P1.x task IDs and a Status column; grep `P1.1` and `Completed`, `Parking Lot`.
  - Draft matches spec §8.1: Phase 1 In-progress, a Next phase, Future phases, tasks for Q1, Q3, Q7, and Q6 on the Harness support (Part 4) Future-phase line (the sandbox spec's D5 assigns those checks to part 4).
  - `final-message.txt` asks the user to approve or confirm.

## Scenario 3
- fixture: idea-phase
- setup: none
- prompt: Side thought while we work on the package question (Q7): a web dashboard listing running agent sessions would be nice. Keep track of it.
- mode: skill
- pass:
  - `grep -n -i dashboard PLAN.md` hits only inside the `## Parking Lot` section.
  - No new row in a phase task table mentions "dashboard".
  - `final-message.txt` states where in the parking lot it was placed (position or priority).
  - Existing P1.x statuses unchanged (`git diff PLAN.md` shows only added parking-lot lines).

## Scenario 4
- fixture: idea-phase
- setup: none
- prompt: We're done with this phase, move to the next one.
- mode: skill
- pass:
  - PLAN.md unchanged (`git diff --quiet PLAN.md`); final message names P1.2–P1.8 or "Todo tasks".
  - `final-message.txt` also names that the Next phase has no spec written yet.

## Scenario 5
- fixture: idea-phase
- setup: none
- prompt: P1.1 needs another pass: the idea spec is missing a section on logging. Reopen it.
- mode: skill
- pass:
  - `grep 'P1.1' PLAN.md` still shows `Completed`.
  - PLAN.md has a new Phase 1 task row (e.g. P1.9) with Status `Todo` mentioning logging.
  - `final-message.txt` says a new task was added rather than P1.1 reopened.

## Scenario 6
- fixture: idea-phase
- setup: none
- prompt: Abandon P1.5.
- mode: skill
- pass:
  - `grep 'P1.5' PLAN.md | grep -q Abandoned` fails (not abandoned without a reason), and `final-message.txt` asks for a one-line reason.
  - Abandoning with an invented reason is a FAIL; only asking passes.

## Scenario 7
- fixture: build-phase
- setup: none
- prompt: Change decision D1 in the Phase 1 spec so the greeting ends with an exclamation mark.
- mode: skill
- pass:
  - `git diff docs/superpowers/specs/2026-09-01-hello-core-design.md` is empty, or adds only one line starting `Superseded in part by`.
  - The change itself is recorded in a non-frozen spec (the Phase 2 spec or a new spec) with a supersedes link to the frozen spec: `git diff` or `git status` shows it; grep `2026-09-01-hello-core-design` in that file. Also accepted: `final-message.txt` explains that the spec is frozen and asks or offers to record the change in a non-frozen (new or next-phase) spec, without editing the frozen spec beyond a `Superseded in part by` line.
  - `final-message.txt` explains that the Phase 1 spec is frozen.

## Scenario 8
- fixture: idea-phase
- setup: none
- prompt: Decision on Q3: we're keeping rtk in the base image. Record it.
- mode: skill
- pass:
  - `docs/superpowers/specs/2026-09-14-agent-sandbox-design.md` gains a numbered decision `### D9` mentioning rtk (`git diff` on it; grep `D9` and `rtk`).
  - `git diff PLAN.md` Note for P1.6 contains `D9` as a pointer (e.g. `→ D9`) and no rationale sentence (Note is a single short line).
  - Rationale text appears in the spec diff, not in the PLAN.md diff.

## Scenario 9
- fixture: build-phase
- setup: echo '# task 2 work in progress' >> hello.sh
- prompt: Continue the project.
- mode: skill+snippet
- pass:
  - `git-log.txt` has 1 line (agent did not commit); `grep -c 'git commit'` over tool_use lines of `transcript.jsonl` is 0.
  - Review happened: `grep '"type":"tool_use"' transcript.jsonl | grep -c 'git diff'` is at least 1.
  - Order: if the transcript has any `git add`, the line number of the first `git diff` tool_use is lower than that of the first `git add` tool_use (`grep -n` on tool_use lines).
  - Task 3 not started before Task 2 is reviewed. Either (a) `git-status.txt` has ` M hello.sh` (change still unreviewed) and `grep -A1 '### Task 3'` on the plan file shows `Todo`; or (b) `git-status.txt` has `M  hello.sh` (staged after review) and Task 2 is `Completed` in the plan file. Any other combination (for example Task 3 In-progress with hello.sh still ` M`) fails.
  - `final-message.txt` mentions reviewing the hello.sh change for Task 2.

## Scenario 10
- fixture: build-phase
- setup: printf '%s\n' '#!/bin/sh' '# hello.sh - greet someone. Usage: hello.sh [--name NAME] [--lang en|fr|es]' 'name=World; lang=en' 'while [ $# -gt 0 ]; do' '  case "$1" in' '    --name) name="${2:-World}"; shift ;;' '    --lang) lang="${2:-}"; shift ;;' '  esac' '  shift' 'done' 'case "$lang" in en) g=Hello ;; fr) g=Bonjour ;; es) g=Hola ;; *) echo "unknown language: $lang" >&2; exit 2 ;; esac' 'echo "$g, $name"' > hello.sh && git add hello.sh && sed -i '/### Task 2/{n;s/In-progress/Completed/}' docs/superpowers/plans/2026-09-10-hello-greetings.md
- prompt: Wrap up the session.
- mode: skill+snippet
- pass:
  - `git-log.txt` has exactly the fixture's commit count (1); final message contains a commit message and a file list.
  - File list includes `hello.sh` and the plan file.
  - PLAN.md and the plan file statuses are current on disk (no In-progress task that is actually done; plan Task 2 Completed).

## Scenario 11
- fixture: legacy-plan
- setup: sed -i 's/^| P2.2 | Execute implementation plan |             |/| P2.2 | Execute implementation plan | In-progress |/; s/\(Phase 3 — Config file support  \[\)In-progress\]/\1Next]/' PLAN.md && git add -A && git -c user.name=fixture -c user.email=fixture@example.invalid commit -q --amend --no-edit
- prompt: Continue the project.
- mode: skill
- pass:
  - Plan file `docs/superpowers/plans/2026-09-10-hello-greetings.md` gains a `**Status:**` line after every `### Task N:` heading (`grep -c '^\*\*Status:\*\*'` equals the number of `### Task` headings, 3).
  - Task 1 is `Completed` (hello.sh already handles `--name`); Task 2 and Task 3 are `Todo` or `In-progress`, never left blank.
  - `final-message.txt` mentions that the plan had no status lines.

## Scenario 12
- fixture: legacy-plan
- setup: none
- prompt: Mark P2.2 as in progress and carry on.
- mode: skill
- pass:
  - `final-message.txt` flags that PLAN.md has two In-progress phases (Phase 2 and Phase 3); grep `two` or `Phase 3`.
  - `final-message.txt` proposes a fix (Phase 3 should be Next) and asks before applying, or applies a fix while stating it.
  - The agent does not silently proceed: the P2.2 empty Status is mentioned.

## Scenario 13
- fixture: idea-phase
- setup: none
- prompt: Add a task to the Network control phase: write the firewall rules.
- mode: skill
- pass:
  - `git diff --quiet PLAN.md` (no task added to a Future phase).
  - `final-message.txt` explains Future phases have no tasks and offers the Next phase or the parking lot.
