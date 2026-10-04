# Plan: hello-cli

Source of truth for project status. Design lives in specs; this file says
where the project is. Rules: see the project-planning skill.

## Phases

### Phase 1 — Core greeter  [Completed]
- **Spec:** docs/superpowers/specs/2026-09-01-hello-core-design.md
- **Plan:** docs/superpowers/plans/2026-09-01-hello-core.md
- **Outcome:** hello.sh prints a greeting with an optional --name flag.

| ID   | Task                        | Status    | Note |
|------|-----------------------------|-----------|------|
| P1.1 | Write spec                  | Completed |      |
| P1.2 | Execute implementation plan | Completed |      |

### Phase 2 — Greeting languages and tests  [In-progress]
- **Spec:** docs/superpowers/specs/2026-09-10-hello-greetings-design.md
- **Plan:** docs/superpowers/plans/2026-09-10-hello-greetings.md

| ID   | Task                        | Status      | Note                   |
|------|-----------------------------|-------------|------------------------|
| P2.1 | Write spec                  | Completed   | → D1, D2               |
| P2.2 | Execute implementation plan |             | Derived from plan file |
| P2.3 | Review phase result         | Todo        |                        |

### Phase 3 — Config file support  [In-progress]
- **Spec:** not yet written
- **Plan:** not yet written

| ID   | Task       | Status | Note |
|------|------------|--------|------|
| P3.1 | Write spec | Todo   |      |

## Future Phases (outline only — no tasks)
- **Packaging** — install script and man page

## Parking Lot (highest priority first)
1. Colored output when stdout is a terminal.
2. Read the name from the USER environment variable by default.
