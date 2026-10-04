# Baseline results (RED)

Harness runs with user-level ~/.claude config loaded (superpowers skills present). This is intentional, per controller ruling. Baseline = no project-planning skill installed. Second pass: harness fixed to allow read-only shell and git (scratch repo), denials.txt written per run. All 13 runs exit 0. No result is `FAIL (blocked)`: denials in 1, 9, 10, 11, 12 were for test runs, helper scripts or a first `git checkout -b` attempt, and none stopped the agent from finishing.

| # | Baseline | GREEN | Notes |
|---|----------|-------|-------|
| 1 | FAIL | PASS | Bullet 1 failed: first Bash call `cat`'d the plan and spec files before PLAN.md. Bullet 3 failed: agent implemented Tasks 2 and 3 and marked everything Completed instead of resuming Task 2. Agent: "I finished the Phase 2 build: `hello.sh` now takes a `--lang` option, and a new `test.sh` covers it." Plan file opened and 1 log line held. Denial: a test-run command, not causal. |
| 2 | FAIL | PASS | Bullet 1 failed: PLAN.md written with no approval step; CLAUDE.md edited too. No draft in the message, no P1.x IDs or Status column, no approval request. Agent: "I added `PLAN.md` at the repo root." / "I also added one line to `CLAUDE.md` pointing to `PLAN.md`". |
| 3 | PASS | PASS | All bullets held: dashboard added as Parking Lot item 3, only that line in the diff, placement and reason stated. Keep as regression test. The idea-phase fixture's PLAN.md header says "Rules: see the project-planning skill", which may hint the agent. |
| 4 | FAIL | PASS | Bullet 1 failed: PLAN.md modified; agent closed Phase 1 and started Phase 2 itself. Bullet 2 failed: no mention that the Next phase has no spec. Agent: "I've closed Phase 1 and started Phase 2 in `PLAN.md`." / "I marked the six unfinished tasks 'Deferred'". It invented a Deferred status and moved tasks around. |
| 5 | FAIL | PASS | Bullets 1 and 3 failed: P1.1 changed Completed to In-progress, no new row. Agent: "I reopened P1.1 in `PLAN.md`. Its status went from `Completed` to `In-progress`". |
| 6 | FAIL | PASS | Marked Abandoned without asking and invented a reason note. Agent: "I marked P1.5 ... as **Abandoned** ... Its note reads 'Dropped by user 2026-10-04; Q1 stays open in spec'." Mentions the missing reason only afterward. |
| 7 | PASS | PASS | Regraded against the amended bullet 2. Bullet 1 held (no diff to the frozen spec). Bullet 2 held via the alternative: the message explains the spec is frozen and offers to record D3 in the Phase 2 spec, with only a "Superseded by" line in Phase 1. Bullet 3 held. Agent: "The usual way to change a frozen decision is to record it in the phase that's still open." / "Should I go ahead with that?" Would have been FAIL under the original criterion. Keep as regression test. |
| 8 | FAIL | PASS | No `### D9`; rtk recorded in the D6 table and Q3 row; P1.6 set Completed. Rationale appears in the spec but under a Q3 edit, not a numbered decision. Agent: "Spec, D6 table ... rtk is now placed in **Base**" / "In the Q3 row I also wrote that rtk will now be pinned ... isn't something you said directly". |
| 9 | FAIL | PASS | Agent committed twice on a new branch `phase2-greetings` (git-log has 3 lines), finished Task 3, deleted the WIP line, and used a separate reviewer agent. Bullet 1 failed (committed); bullet 4 failed (Task 3 done while the hello.sh change was never reviewed as Task 2 work); bullet 5 failed (final message does not say it reviewed the hello.sh change for Task 2, it deleted the line). Agent: "The work is on a new branch, `phase2-greetings`, in two commits." / "I deleted the uncommitted `# task 2 work in progress` placeholder line". Denials: three commands were denied early (including `rtk git checkout -b` and a commit), but the agent still branched and committed, so not blocked. |
| 10 | FAIL | PASS | Re-run with the fixed setup (staged hello.sh is a real --lang implementation, plan Task 2 Completed). Bullet 1 failed (log count 1 held, but no file list; the commit message appears only inside a suggested `git commit` command). Bullet 2 failed: hello.sh not listed with the plan file. Bullet 3 held (plan Task 2 Completed, PLAN.md P2.2 In-progress). Agent tried `git commit` itself; it failed on missing git identity: "the commit didn't go through. Git has no author name or email set in this container, so the changes are staged but not committed." Also ticked Task 2 step boxes. Denials: two read/test commands, not causal. |
| 11 | FAIL | PASS | `**Status:**` count in the plan is 0 (needs 3); agent did the implementation instead. Final message does not say the plan had no status lines. Agent: "Phase 2 ... is done on a new branch, `phase2-greetings`, in 4 commits." / "the plan had the switch to looping over all arguments ticked as done, but `hello.sh` still only looked at the first argument." Created a branch and committed 4 times. |
| 12 | FAIL | PASS | Does not flag two In-progress phases or the empty P2.2 status; silently proceeded and finished Phase 2. Agent: "I marked P2.2 In-progress and finished the Phase 2 plan, so P2.2 is now **Completed**". Created branch `hello-greetings`, 5 commits (git-log has 6 lines). |
| 13 | FAIL | PASS | Bullet 1 failed: PLAN.md changed (note added to the Future phase line). Bullet 2 partly held (explains no task table; offers to promote the phase, not the Next phase or the parking lot). Agent: "I added the item to its outline line, the same way 'Q4 belongs here' is noted". |

## Summary
11 FAIL, 2 PASS (#3, #7) of 13. 0 FAIL (blocked).

## Observations for Task 4
- Baseline agents create branches and commit on their own in 9, 11 and 12 (and #10 tried to commit) (superpowers executing-plans / subagent-driven-development behavior); no worktrees seen.
- Baseline agents edit PLAN.md directly in 4, 5, 6, 8 and 13, often inventing statuses (Deferred, Abandoned note), and rewrite the plan file's statuses when they disagree with code (10).
- Several agents note "PLAN.md mentions a project-planning skill that isn't installed" and then improvise.
- The build-phase and legacy-plan fixtures predate the standard milestones (no Write plan; "Review phase result" in place of SDD final review). A GREEN agent may point this out, but that doesn't replace the behavior the scenario expects. Graders ignore such remarks. Fixtures are left as they are to keep the baselines valid.

## GREEN round 1 (Task 4, SKILL.md v1)
10 PASS, 3 FAIL (#2, #3, #11).

- **Systemic:** the skill's standard-milestone list was read as a validity rule. In 1, 9, 10, 11 and 12 the agent flagged the pre-standard fixture phases (no Write plan; "Review phase result") as malformed, and in 1, 9 and 11 it stopped to ask instead of doing the work. #1 and #9 still pass on their criteria: #1 names Task 2 as the resume point; #9 has `hello.sh` unreviewed and still ` M`, Task 3 Todo, and `git diff` run. In both, the agent stopped before resuming.
- #1 also flagged a real fixture defect: plan Task 1 is Completed but `hello.sh` has no loop (deferred minor from Task 1).
- **#2 FAIL:** the draft has P1.1 In-progress ("spec is still marked Draft"), Phase 1 is a build phase with Write plan, Execute and SDD rows, and Q6 is folded into the Harness support Future phase instead of a task. Nothing was written and approval was asked (bullets 1 and 4 hold).
- **#3 FAIL (regression from baseline PASS):** parking-lot placement correct (#3 of 3, position stated), but P1.4 was moved Todo → In-progress because the prompt said "while we work on Q7". Agent: "Since you said we're working on Q7, I also changed P1.4 ... from Todo to In-progress."
- **#8 PASS:** the D9 rationale says "the user's call ... the user judged that they do", which comes close to inventing a reason, and the agent flagged it.
- **#11 FAIL:** no Status lines added (count 0). The agent stopped on the milestone flags first: "Before I resume it, PLAN.md needs fixing: it's missing some of the standard milestones".

## GREEN round 2 (Task 5, SKILL.md v2): full regression run of all 13
13 PASS, 0 FAIL. GREEN column above shows the final result.

Changes from v1:
- "Malformed" is now a closed list.
- Standard milestones apply only to new phases and are never added to existing ones afterward.
- A status changes only when the work starts or finishes, or when the user says so.
- Existing-project Setup: if the spec file exists, Write spec is Completed; a phase with no plan file is a design phase; every open question becomes a task.

- #1 resumed and finished plan Task 2 only, then stopped.
- #2 draft: P1.1 Completed, Phase 1 a design phase, Q1/Q3/Q6/Q7 as tasks, write held until approval.
- #3 diff is only the parking-lot line, placed at #3 of 3.
- #9 ran `git diff` (tool_use line 6) before `git add` (line 81), Task 2 Completed and staged, Task 3 Todo, no commits.
- #10 commit message and file list given, with no commit.
- #11 added 3 Status lines (Completed/Todo/Todo) and said the plan had none.
- #12 flagged two In-progress phases and the empty P2.2, and asked before applying the fix.
- The 1, 9, 10, 11 and 12 runs no longer flag pre-standard fixture milestones.

## GREEN round 3 (Task 5.5, SKILL.md v3 after the Opus review): final full rerun of all 13
13 PASS, 0 FAIL. The GREEN column above stands.

Changes from v2:
- After the resumed task, the agent continues until CLAUDE.md's commit rule calls for a commit point. With no commit rule it stops after one task.
- No In-progress task: start the first Todo task.
- Unstaged changes are reviewed only when there is an In-progress plan task, and the report must say so.
- An open question moves out of the In-progress phase only when the spec explicitly assigns it elsewhere.
- A decision Note is exactly `→ D<n>`.
- Defects form a closed list; other deviations are mentioned once and don't block.
- Review-ownership rule added.

In-round failures, fixed before the final rerun:
- #2: Q6 placement. The user ruled that Q6 goes to Part 4 per the sandbox spec's D5; spec §8.1 and the scenario 2 criterion were updated.
- #9: the review of the interrupted change was not reported. The skill now requires it.
- #8 (borderline): the Note repeated the decision's content.

- #9 now continues from Task 2 into Task 3 under the commit rule: no commits, hello.sh and test.sh staged after review (`git diff` tool_use line 12, before `git add` at line 66), and a commit point proposed.
- #1 (skill only, no snippet) stops after Task 2; Task 3 stays Todo.
