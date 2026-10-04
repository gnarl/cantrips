---
name: project-planning
description: Use when a repo has a PLAN.md, at the start of any session in such a repo, when a task, plan task or phase changes status, when a phase looks finished or the user asks to move to the next phase, when an idea or decision comes up, or when setting up planning for a new or existing project.
---

# Project Planning

## Overview

PLAN.md is the source of truth for project **status**: phases, milestone tasks and the parking lot. Specs are the source of truth for **design**: decisions and their reasoning. This skill tracks progress; it does not decide how work is built or reviewed. Commit, worktree and execution rules live in CLAUDE.md.

## Session Start

1. Read PLAN.md before any other project file.
2. Check for these defects: a task with an empty or unknown Status; more or fewer than one In-progress phase; more than one Next phase; tasks in a Future phase. If any is present, name each one, propose the fix, and ask before doing anything else, including what the user asked for. Other deviations from the Rules: mention them once and carry on. A phase whose tasks differ from the standard milestones is not a deviation.
3. Find the In-progress phase and its In-progress task. If that task is "Execute implementation plan", open the phase's plan file and find its In-progress plan task.
   - Plan file has no `**Status:**` lines: add `**Status:**` directly under every `### Task N:` heading (Completed only where the code or git history shows the task done, otherwise Todo), and tell the user the plan had none.
   - An In-progress plan task plus unstaged or untracked changes in `git status`: those changes are that task's unreviewed work. Review them (`git diff`) as that task's work before anything else, and say in your report that you reviewed them as that task's work and what you kept or changed.
   - No In-progress task: the user's request to continue is the go-ahead for the first Todo task in order (plan task, or PLAN.md task when there is no plan). Set it In-progress.
4. Say which task you are resuming by its ID or number, and finish it. When it is Completed, update its status and apply CLAUDE.md's commit rule: continue with the next Todo task until that rule calls for a commit point or the user asked for only one task, then report and stop. If CLAUDE.md has no commit rule, stop after the one task.
5. Read the spec only as far as the task needs.

## Rules

**Phases**
- Any number Completed, exactly one In-progress, at most one Next, any number Future.
- Future phases have no tasks. Asked to add a task to one: refuse, and offer the Next phase or the parking lot.
- Every phase has exactly one spec by the time it is In-progress. A phase has an implementation plan only when it builds something; a design-only phase shows `Plan: none (design phase)`.
- Next-phase tasks (such as its Write spec) may be worked alongside the In-progress phase.

**Tasks** (PLAN.md tasks are milestones; plan-file tasks are never copied in)
- Standard milestones: design phase = Write spec. Build phase = Write spec, Write plan, Execute implementation plan, SDD final review. Phases you create or draft start with them. A Next phase starts with only Write spec and gains the build milestones once its spec shows it builds something. Phases already in PLAN.md are not checked against this list, and their milestones are not added or renamed, except the Next phase's build milestones.
- Reviews are milestones only when a skill owns them: SDD final review (subagent-driven-development) and the user's spec review (brainstorming). SDD's per-task reviews live inside "Execute implementation plan".
- Statuses: `Todo`, `In-progress`, `Abandoned`, `Completed`. No others.
- Transitions: Todo → In-progress → Completed. Any task not Completed may become Abandoned **with a one-line reason in its Note that the user gave**. No reason given: ask for one; never write one yourself.
- **Completed is final.** Reopening work = add a new task (next free ID, Todo). The old row is untouched.
- "Execute implementation plan" is derived: In-progress while any plan task is Todo or In-progress; Completed when all are Completed or Abandoned.
- Notes are one line. Longer reasoning goes in the spec.

**Plan files**
- Every `### Task N:` heading is followed by `**Status:** <status>`, same four statuses. The plan file outranks the `.superpowers/sdd/` ledger. Save status changes to disk immediately.

**Specs and decisions**
- A decision is recorded only in a spec, as the next numbered decision (`### D9. <title>` plus its rationale) in the spec of the phase it belongs to: normally the In-progress phase, or the Next phase's spec when it concerns the Next phase's design. PLAN.md gets only a pointer: the producing task's Note is exactly `→ D9`, with no summary of the decision.
- A spec whose first line is `Frozen — Phase N completed <date>` is never edited, with one exception: one added line `Superseded in part by <path>`. A change to a frozen decision goes in the In-progress or Next phase's spec with a supersedes link; ask before writing it.

**Parking lot**
- An idea outside the In-progress phase goes in the parking lot, ordered by your judgment of priority. Tell the user the position. An item moved into a phase is removed from the parking lot.

## Setup

- **New project:** copy `plan-template.md` (next to this file) to PLAN.md. Rename P1.1 to "Write idea spec"; the Next phase keeps only Write spec; remove placeholder lines that don't apply; the parking lot starts empty.
- **Existing project:** draft PLAN.md from the repo's specs, plans and git log. Show the full draft in your reply and **write nothing** until the user approves it. Do not edit CLAUDE.md. Build the draft this way:
  - A spec file that exists means its Write spec task is Completed. A "Draft" status inside the spec describes the design, not the milestone.
  - A phase with no plan file is a design phase (`Plan: none (design phase)`) and gets no build milestones.
  - An open question becomes a task in the In-progress phase. Exceptions: one the spec's text explicitly assigns to a later part or phase ("belongs to Part 3", "handle in Part 4") goes with that phase (Next phase spec scope or Future outline line); one the spec marks as an idea or measurement for later goes to the parking lot. Your own inference about where a question fits is not an explicit assignment: keep it a task.
  - The spec's own next steps or ordering decide the Next phase. Its other components become Future phases.

## Updates

No approval needed: status changes, Notes, parking-lot additions, and adding a task the user asked for (including a reopen task). Change a task's status only when you start or finish that task's work in this session, or the user tells you to. Exceptions: backfilling missing plan Status lines (Session Start 3) and Setup drafts. A task mentioned in passing ("while we work on Q7") keeps its status. New phases, phase transitions and moving tasks between phases need the user.

## Phase Transition

Needs the user's approval. Never transition on your own initiative.

1. **Precondition:** every task in the In-progress phase is Completed or Abandoned, and the Next phase's spec is written. If not, change nothing: name each open task by ID and say whether the Next spec is missing, then stop.
2. Mark the phase Completed and add its `Outcome:` line.
3. Freeze its spec (first line `Frozen — Phase N completed <date>`).
4. Promote Next to In-progress; if its spec shows it builds something, add any missing build milestones.
5. Propose candidates for the new Next phase from Future Phases and the top of the parking lot. The user chooses.

## Red Flags

| Thought | Rule |
|---|---|
| "Let me look at the plan and spec first" | PLAN.md first, always. |
| "Continue the project, so I'll finish the whole plan" | Resume the In-progress task; go further only as CLAUDE.md's commit rule allows (Session Start 4). |
| "I'll just write PLAN.md, it's what they asked for" | Show the draft; write after approval. |
| "I'll close the phase and mark the leftovers Deferred" | No Deferred status. Change nothing; name the open tasks. |
| "Reopen P1.1: set it back to In-progress" | Completed is final. Add a new task. |
| "I'll mark it Abandoned with a sensible reason" | Ask the user for the reason. |
| "I'll record the decision in the table and the Q row" | New `### D<n>` in the spec; Note `→ D<n>`. |
| "I'll clean up this WIP line and move on to Task 3" | It's the In-progress task's work. Review it first. |
| "The plan has no status lines; I'll just do the work" | Add Status lines first; say the plan had none. |
| "PLAN.md looks off, but I'll carry on" | Listed defects: name, propose the fix, ask. |
| "I'll add a note to the Future phase line" | Refuse; offer Next phase or parking lot. |
| "This edit to the frozen spec is small" | Only a `Superseded in part by` line. |
| "This phase is missing standard milestones, I must fix that first" | Not a defect. Carry on. |
| "They mentioned working on Q7, so I'll set it In-progress" | Status changes when the work starts or finishes, or the user says so. |
| "The spec says Draft, so Write spec is still In-progress" | The spec exists, so Write spec is Completed. |
