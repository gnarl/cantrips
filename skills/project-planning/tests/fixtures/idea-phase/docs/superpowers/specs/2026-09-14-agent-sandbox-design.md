# Agent Sandbox — Architecture Design (Draft)

- **Status:** Draft. Brainstorming is still in progress, and some decisions are open (see [Open Questions](#9-open-questions)).
- **Date:** 2026-09-14
- **Replaces:** [claude-container](https://github.com/gnarl/claude-container) (CCR)
- **Location:** Written in `container-research`. Move or link it once the replacement project repo exists.

---

## 1. Purpose

Run AI coding agents (Claude Code, and later [pi](https://pi.dev) and [fx](https://github.com/vercel-labs/fx)) on an M1 MacBook Pro so that:

1. An agent **cannot break out** of its sandbox and compromise the Mac.
2. An agent in one workspace **cannot share information** with an agent in another workspace.

These goals should cost as little usability as possible. The design also has to fit the user's workflow (see [§6](#6-agent-workflow-constraints)).

## 2. Threat Model

| # | Threat | In scope |
|---|---|---|
| T1 | Agent escapes its container or VM and reaches the macOS host (files, credentials, shell configuration) | Yes |
| T2 | Agent in workspace A reads or writes data of, or talks to, the agent in workspace B | Yes |
| T3 | Stolen model credential, used from inside or outside the sandbox | Yes |
| T4 | Supply-chain compromise of something installed into the image | Yes |
| T5 | Malicious instructions planted in files that persist across sessions (planning docs, `.claude/`, git hooks) | Yes, mitigated partly by process rather than enforcement |
| T6 | An adversarial agent leaking data through any allowed network destination | **Only partly preventable** (see below) |
| T7 | Leakage of identity data: Mac username and paths, git author identity, SSH keys, `gh` or other tokens, account emails, hostnames | Yes, **top priority** |

**Priorities (user, 2026-09-14):**
1. The agent must not be able to access files outside the bound workspace (T1).
2. Credentials and identity data must be protected (T3, T7).
3. Network restrictions (T6) matter, but they cost the most usability. How they are implemented will be discussed in detail later, not designed yet.

**Accepted limit:** as long as the agent can reach the internet at all, even just the model API, a determined agent can leak data. The achievable goal is: no direct channel between workspaces, no shared credentials, and outbound network access limited to an auditable allowlist.

## 3. Findings: Current Setup (CCR on Colima)

Checked from inside a running CCR container on 2026-09-14, and by reading the CCR source.

| Finding | Evidence | Threat |
|---|---|---|
| Agent can become root in the container | `sudo -n true` succeeds (NOPASSWD sudoers); `NoNewPrivs: 0`; default Docker capabilities | T1 |
| Container root is the same user as VM root | `/proc/self/uid_map` = `0 0 4294967295` (no user namespace remapping) | T1 |
| All containers share one VM kernel | Single Colima VM; kernel `6.8.0-64-generic` (built June 2025) | T1, T2 |
| The VM can see the whole macOS home folder | `/workspace` is a subfolder (`/projects/ai/container-research`) of one virtiofs share (`lima-…`), consistent with Colima's default `~` mount | T1 |
| Containers can reach each other over the network | Shared bridge `172.17.0.0/16`; `172.17.0.2` answered while this container was `172.17.0.3` | T2 |
| VM SSH server and the Mac host are reachable from the container | `172.17.0.1:22` open; `host.lima.internal` → `192.168.5.2` | T1 |
| Unrestricted outbound network access | HTTPS to example.com → 200 | T2, T6 |
| Every container logs into the same Claude account | `~/.claude/.credentials.json` per container; login flow requested `user:inference user:sessions:claude_code user:mcp_servers user:file_upload org:create_api_key` | T2, T3 |
| Unpinned installs at build time | `curl \| bash` for Claude Code, uv, rtk, just; `git clone` at latest commit for superpowers and cantrips | T4 |
| Rebuilding is tedious | stop → delete → rebuild image → create; login state lost | Usability |

**Breakout path today:** `sudo` → kernel exploit → VM root → every workspace, plus read/write access to the Mac home folder through the share.

## 4. Decomposition

The project splits into four parts. Parts 2–4 depend on part 1.

1. **Isolation runtime and lifecycle** — this spec
2. **Network control** — outbound allowlist proxy, no path between workspaces
3. **Credentials** — per-workspace API keys, added to requests outside the VM
4. **Harness support** — running Claude Code, pi and fx in the sandbox; context and model defaults

Parts 2–4 get their own specs. **Order of work:** part 3 (credentials and identity) comes before part 2 (network), which is deferred because of its usability trade-offs. The credential-injecting proxy in D7 depends on part 2, so part 3 must name the minimum network piece it needs.

## 5. Decisions

### D1. Runtime: Apple `container`, driven directly from Go

- **Decision:** Use [Apple `container`](https://github.com/apple/container) (macOS 26.6.2 on the host). The Go orchestrator calls the `container` CLI directly. Do **not** use [socktainer](https://socktainer.github.io).
- **Why:**
  - Every container runs in its own lightweight VM, so there's no kernel shared between workspaces (T1, T2).
  - Only folders mounted explicitly are shared with that VM.
- **Alternatives rejected:**
  - *Colima profile per workspace:* a full VM per workspace with fixed RAM, slower startup, and a per-profile mount setting that silently breaks isolation if misconfigured.
  - *Hardened single Colima VM:* still one shared kernel, so it fails T2.
  - *Abstracting both runtimes:* more to build, and no expected need to switch.
- **Why no socktainer:**
  - No interactive exec, which interactive agent terminals require.
  - Adds a pre-1.0 translation layer.
  - Its socket controls every container, so mounting it anywhere defeats T2.
  - Docker compatibility isn't needed for a tool we write ourselves.
- **Costs accepted:**
  - Apple `container` is pre-1.0 and its CLI may change. Mitigation: isolate all runtime calls in one small Go package.
  - VMs don't return freed memory to the host. Mitigation: stop containers often (D2).
  - No Docker ecosystem tools (compose, testcontainers) inside the sandbox.

### D2. Lifecycle: disposable containers, state outside

- **Decision:** a container is disposable. Stopping one removes it; starting one creates it from the current image.
- **Why:**
  - The user stops containers often, since VM memory only grows until the container stops.
  - The user wants supply-chain updates applied when returning to a workspace, without the manual rebuild steps.
  - Sessions can already be stopped at any time ([§6](#6-agent-workflow-constraints)).

Where state lives:

| Location | Contents | Survives `down` | Survives rebuild |
|---|---|---|---|
| Base image | OS, agent programs, default config, hooks, skills | — | Replaced |
| Per-workspace image layer | System packages declared for that workspace (D4) | — | Rebuilt |
| `/workspace` bind mount | Project repo, including planning and status docs | Yes | Yes |
| Per-workspace state volume | **Credentials only** (possibly nothing once D7 is implemented) | Yes | Yes |
| Container filesystem | Anything changed at runtime | No | No |

Commands (names are placeholders):

- `up <ws>`: create if missing, recreate if its image is stale, then start
- `down <ws>` / `down --idle` / `down --all`: stop and remove, freeing memory
- `update`: resolve and bump pinned versions, rebuild images, mark workspaces stale (D5)
- `shell <ws>` / `run <ws> <harness>`: attach a shell or start an agent
- `pkg add <ws> <package>`: add a system package for that workspace (D4)

**Only credentials persist, and settings, hooks and skills are built into the image,** so an agent can't plant a persistent hook or instruction in the state volume (T5).

### D3. No root inside the container

- **Decision:** no passwordless sudo and no root user for the agent.
- **Why:**
  - Runtime installs as root bypass pinning and review (D5).
  - Root can undo any network control enforced inside the VM (part 2).
  - Root exposes more of the VM kernel to attack.
- **History:** at first I judged sudo acceptable, since each workspace has its own VM (D1). That reversed once pinned, reviewable versions (D5) and in-VM enforcement risks came up.
- **Unaffected:** project dependencies (`uv add`, `go get`, `npm install`) need no root and are tracked by lockfiles in git. User-level tools (`~/.local/bin`) need no root but are lost on `down`.

### D4. System packages: per-workspace list on the Mac

- **Decision:** system packages go in a per-workspace list stored on the Mac, **outside `/workspace`**, in the tool's config folder. Keeping that folder in git is recommended. `pkg add` updates the list, builds a per-workspace layer, and the next `up` uses it.
- **apt pinning:** use `snapshot.ubuntu.com` at a fixed timestamp for the base image and workspace layers. `update` moves the timestamp forward and shows the package version differences.
- **How the agent asks:** it stops and asks the user (an instruction in the image's `CLAUDE.md` / `AGENTS.md`). An in-container request queue was considered and deferred.
- **Why outside `/workspace`:** if the list lived in the workspace, the agent could edit it and choose what goes into its own next image.

### D5. Supply chain: pinned versions, checksums, and `update` bumps them

- **Decision:** every image input is recorded in a lock file:

| Component | Pinned as | Verified by |
|---|---|---|
| Base OS image | `ubuntu:24.04@sha256:…` | Registry digest |
| apt packages | Snapshot timestamp | Signed apt repository metadata |
| Downloaded binaries | Version plus per-architecture URL | sha256 |
| Agent programs | Exact version | sha256 or npm lockfile |
| Skill repositories | Commit SHA | The commit hash itself |

- The base image definition and lock file live in the project's git repo, so every update is a reviewable commit.
- `update` does four things:
  1. Queries each source for newer versions.
  2. Shows `old → new` with links to release notes.
  3. Rewrites the lock file after approval.
  4. Rebuilds the image and marks workspaces stale.
- **Built-in self-updaters are turned off** in the image (for example Claude Code's auto-updater), because they would bypass the pins. Each harness's setting is checked in part 4.
- **Known limit:** a checksum proves you got the bytes you approved, not that they are safe. Protection against a compromised release comes from D6 (smaller image), provenance checks where available, and the release-age policy (open question Q1).

### D6. Minimal base image

- **Decision (user's primary supply-chain control):** reduce what the base image installs, so there's less to attack and less to pin and audit.

| In the current CCR image | Proposed placement |
|---|---|
| ubuntu, git, ca-certificates | Base |
| sudo | Removed (D3) |
| build-essential, Go, uv/Python, just | Per-workspace layer, only where needed |
| Claude Code, pi, fx | Harness layer, only the harness that workspace uses |
| rtk | Undecided (Q3) |
| superpowers, cantrips skills | Pinned commits |

- **Known limit:** the harness itself runs with credentials and full workspace access in every session. It's the single most damaging component if compromised, so pinning and the release policy matter most there.

### D7. Model credentials: API keys per Console workspace

- **Decision:** use Anthropic API keys, one Claude Console workspace per sandbox workspace, instead of a shared subscription login.
- **Why:**
  - **Terms:** subscription login is "designed to support ordinary use of Claude Code and other native Anthropic applications." Third-party harnesses (pi, fx) must use API keys ([source](https://code.claude.com/docs/en/legal-and-compliance)).
  - **Isolation (T2):** Console workspaces isolate files, batches, skills and prompt caches. Subscription accounts share cloud sessions, Remote Control, artifacts and claude.ai connectors across every container.
  - **Limiting damage (T3):** each workspace gets its own monthly spend limit and rate limits, and its key can be revoked alone. Up to 100 workspaces per organization.
  - **Key stays outside the VM:** the part 2 proxy can add the key to outgoing requests, so the key never enters the container. This is designed in part 3; it depends on pointing each harness at the proxy (for example Claude Code's `ANTHROPIC_BASE_URL`, still to be verified).
- **Cost trade-off:** API usage is billed per token (Opus 5: $5 input / $0.50 cache read / $25 output per MTok). A rough Opus 5 agent turn under 200k context with caching costs about $0.10, so a heavy day of 200–300 turns is roughly $20–30. That is an illustration, not a forecast. See Q2.
- **Fallback if API cost for Claude Code is too high:** keep the subscription for Claude Code only (permitted), and use API keys for everything else. This knowingly gives up workspace isolation for Claude Code.

### D8. Claude Code auto-memory: turned off by a locked setting, with project memory in the repo

- **Problem:**
  - Claude Code's auto-memory is on by default. It writes `~/.claude/projects/<project>/memory/MEMORY.md` plus topic files, and loads up to 200 lines / 25KB of `MEMORY.md` into every session.
  - Under D2 that folder is discarded on `down`. The agent believes it has saved something that silently disappears, while project knowledge belongs in the repo ([§6](#6-agent-workflow-constraints)).
  - Auto-memory also loads context the user never reviews, which works against the 200k context discipline and against git review (T5).
- **Decision:** turn auto-memory off in **managed settings**, which the agent can't change, and send all project memory to repo files through instructions.
  1. **Enforced:** the image installs `/etc/claude-code/managed-settings.json`, owned by root and read-only:
     ```json
     {
       "autoMemoryEnabled": false,
       "env": { "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1" }
     }
     ```
     Managed settings take precedence over user and project settings. Because the agent has no root (D3), it can't change this file. An agent-writable `~/.claude/settings.json` would be weaker: it could be flipped back, even though the change would only last until `down`.
  2. **Instruction:** the image's user-level `CLAUDE.md` says to save project knowledge (decisions, status, plans, preferences) as files under `/workspace` (for example `docs/`), never under `~/.claude`.
  3. **Optional enforcement, deferred:** a managed `PreToolUse` hook that blocks Write/Edit to `~/.claude/**`. It can't stop writes made through Bash, so it's a backstop only; add it if (1) and (2) turn out not to be enough.
- **Alternative considered:** point `autoMemoryDirectory` at a folder inside `/workspace`, so auto-memory persists and shows up in git. Rejected for now: it duplicates the user's explicit repo-docs workflow, and Claude Code decides on its own what to save. It remains an option if the user wants Claude-curated notes alongside the docs.
- **To verify in part 4:**
  - Whether subagent memory (the `memory` field in subagent definitions) is covered by the same switch.
  - Which other `~/.claude` writes are lost on `down` (session transcripts, which only break `--resume`, and todos or plans) and whether any of them matter.
  - pi and fx equivalents.

## 6. Agent Workflow Constraints

These come from how the user works, and the design must preserve them.

- Agents continuously write project planning, goals, status, phases, deliverables and tasks into **repo files**. At the end of a session the user asks the agent to save anything relevant. Superpowers skills support this.
- Any session can stop at any time, and new sessions start cold from repo files.
- Agent context is kept **under ~200k tokens**, even with a 1M window available, for quality and cost.
- All projects use git, and git history is how changes, planning docs included, get reviewed.
- **A judge agent, enabled by a judge skill,** will review specs, designs, code changes and git commits. The sandbox must be able to run it; how it gets into the image is decided with the skill layer (D6) and harness support (part 4).
- **This spec is the source of truth** for the project's design. Conversation history and earlier advice that conflict with it are superseded.

Consequences:

- Container-local and harness-private memory (for example Claude Code auto-memory under `~/.claude/projects/`) is not needed and is turned off in the sandbox (D8).
- Context limits and default models belong to part 4.
- **Risk (T5):** planning docs load into every future session, which makes them the easiest place to plant malicious instructions that persist. Mitigation is by process: review changes to planning docs in git before committing.

## 7. Target Architecture (Part 1)

```
macOS 26 host
├── orchestrator (Go CLI)
│   ├── runtime/      the only package that calls the `container` CLI
│   ├── lock/         lock file parsing, version resolvers, checksum verification
│   ├── image/        base image, harness layer, per-workspace layer builds
│   └── workspace/    workspace registry, lifecycle (up/down/update), staleness detection
├── ~/.config/<tool>/            (git repo recommended)
│   └── workspaces/<ws>.toml     mount path, harness, system packages
└── per workspace: one Apple `container` VM
    ├── /workspace   ← bind mount of the project folder only
    ├── state volume ← credentials only
    └── agent runs as a non-root user; no sudo
```

## 8. Later Parts (Placeholders, Not Designed Yet)

- **Part 2 — Network control:**
  - Outbound allowlist proxy enforced **outside the VM**.
  - Each container on its own network (`container network create`); no path between containers.
  - Separate network rules for image builds and for agent sessions.
- **Part 3 — Credentials:** proxy adds the API key to requests; per-workspace Console workspace, spend limits and rate limits; account-wide Claude features turned off in containers.
- **Part 4 — Harness support:**
  - A common way to run Claude Code, pi and fx.
  - Model and context defaults.
  - Self-updaters and auto-memory turned off.
  - Project-level config risks (`.claude/settings.json`, hooks).

## 9. Open Questions

| # | Question | Current positions |
|---|---|---|
| Q1 | **Release-age policy for `update`** | *Assistant:* only offer releases older than N days (default 7); pinned versions flagged in OSV (including known-malicious reports) override it immediately, in whichever direction is safe; `update --now <component>` for manual overrides. Reason: most hijacked-maintainer releases (ua-parser-js, nx, chalk/debug, Shai-Hulud) were pulled within hours to days. *User:* skeptical that delays help, since the fix for a compromised version is often the newest version; wants a smaller image as the main control. Not resolved. |
| Q2 | **API cost vs. subscription for Claude Code** | Measure first: total token usage from existing Claude Code transcripts, or run one workspace on an API key with a low spend limit for a week. |
| Q3 | **Keep rtk?** | It rewrites the output of every agent shell command and is installed from its `master` branch. Keep only if its token savings justify that risk. |
| Q4 | **Persistence risk in the workspace** | `.claude/settings.json`, hooks, git hooks, `.envrc` inside `/workspace` persist and can run code. Needs handling in part 4. |
| Q5 | **Project name and repo** | Replacement for CCR not yet created; this spec lives in `container-research` for now. |
| Q7 | **Usability of per-workspace package management** | *User concern:* installing, upgrading and managing packages per workspace (D4, D5, D6) may be too much friction. Ideas not yet evaluated: reusable toolchain profiles (`go`, `python`, `node`) shared across workspaces instead of package-by-package lists; one command that adds, rebuilds and restarts; `update` applying to all workspaces at once; measuring layer build time on real projects. Must be resolved before the D4 design is final. |
| Q8 | **Identity data inside the container (T7)** | List and remove identity sources: git `user.name`/`user.email` (commits made inside the container), SSH agent or keys, `gh` tokens, the host path and username showing through mount paths or tool output, hostname. Decide what git identity agents commit under. Belongs to part 3. |
| Q6 | **Harness self-updater and memory settings** | Claude Code auto-memory is settled (D8). Still to verify: the Claude Code auto-updater setting, subagent memory coverage, and pi and fx equivalents. |

## 10. Risks and Constraints Summary

- Apple `container` is pre-1.0 and supports macOS 26 only; its CLI may change.
- VM memory isn't returned until the container stops.
- An adversarial agent can still leak data through any allowed network destination (T6).
- Planning docs and project config in `/workspace` can carry planted instructions across sessions (T5); mitigated by git review.
- A compromised harness release is the most damaging single supply-chain event.

## 11. Status and Next Session

**Session 1 (2026-09-14):**
- Covered the threat model, runtime choice, lifecycle, package and supply-chain approach, credentials choice and auto-memory handling.
- The user likes the spec format.

**Next session, in order:**
1. User reviews this spec (and/or has the judge agent review it) and requests changes.
2. Resolve Q7 (package management usability). It may reshape D4 and D6.
3. Settle Q1 (release-age policy) and Q3 (rtk).
4. Part 3: credentials and identity protection (T3, T7, Q8), including the minimum proxy needed to keep the API key out of the VM.
5. Q2: measure API cost vs. subscription.
6. Later: part 2 network design, as a dedicated discussion of implementation and usability trade-offs.

## 12. Sources

- apple/container: [README](https://github.com/apple/container), [technical overview](https://github.com/apple/container/blob/main/docs/technical-overview.md)
- socktainer: [site](https://socktainer.github.io), [GitHub](https://github.com/socktainer/socktainer)
- [Claude Code legal and compliance](https://code.claude.com/docs/en/legal-and-compliance)
- [Claude Code memory (auto memory settings)](https://code.claude.com/docs/en/memory)
- [Claude API pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Console workspaces](https://platform.claude.com/docs/en/manage-claude/workspaces)
- [claude-container (CCR)](https://github.com/gnarl/claude-container)
