<!-- Paste the section below into your user-level CLAUDE.md (~/.claude/CLAUDE.md); during testing it goes in the repo CLAUDE.md. -->

## Project planning
- If the repo has PLAN.md, it is the source of truth for project status.
  Use the project-planning skill at session start and whenever a task or
  phase status changes.
- brainstorming: each spec belongs to exactly one phase. Record its path
  in PLAN.md. Sub-projects from decomposition become Next or Future phases.
- writing-plans: follow every `### Task N:` heading with `**Status:** Todo`.
  Record the plan path in PLAN.md.
- Plan task status lives in the plan file and outranks the
  .superpowers/sdd ledger.
- Decisions live only in specs; PLAN.md points to them by ID.

## Workflow rules
- Never commit. The user makes all commits. Each time a task completes,
  measure the uncommitted change with `git diff HEAD --shortstat` (new
  files count once `git add -N`'d; copied or generated files such as
  fixtures, vendored files and lockfiles don't). Propose a commit point
  (concise message with enough context for a future agent, plus the
  exact files), then stop until the user has committed, when any is true:
  - the change reaches about 400 changed lines;
  - the next task is unrelated to the uncommitted ones (if the message
    would need "and also", split; when unsure, treat as related);
  - 5 tasks are uncommitted (plan-file tasks while executing a plan,
    otherwise PLAN.md tasks);
  - the session is ending.
  A task that crosses the threshold on its own gets its own commit; if
  earlier uncommitted tasks touch other files, propose them as a separate
  commit first. Never split one task across commits. A plan's commit
  points are upper bounds; after an early commit, the next one covers
  only what remains.
- Never use git worktrees. Work on the current branch.
- Run subagents one at a time unless told otherwise. They exist to keep
  the orchestrator's context small.
- Prefer ending the session and restarting over compaction. Before
  stopping, make sure PLAN.md and plan statuses on disk are current.
- Save all project knowledge, memories included, in repo files.
  Never use ~/.claude memory.

## Executing plans without commits
- The staging area is the review checkpoint. Staged = reviewed and waiting
  for the user's commit. Unstaged = the current task's unreviewed work.
- Before starting a task: set it In-progress in the plan file, and check
  that no unreviewed changes are left from an earlier task.
- New files: the implementer runs `git add -N <file>` so they show up in
  `git diff`. (Untracked files are otherwise invisible to it.)
- Review input is `git diff` (unstaged changes only), not a commit range.
  Do not use scripts/review-package.
- After review passes: `git add` the task's files, set the task Completed
  in the plan file, and record it in the ledger.
- If a plan-execution ruling changes the design, write it into the
  In-progress phase's spec; the ledger is not committed.
- SDD final review input: `git diff <last commit before the plan
  started>` (working tree, staged included), not a MERGE_BASE..HEAD range.
- Skip finishing-a-development-branch. The plan ends at its last commit
  point; then the PLAN.md SDD final review milestone follows.
