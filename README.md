  Personal skills for small, practical spells for everyday work.

  Designed to complement [superpowers](https://github.com/obra/superpowers).

  ## Skills

  | Skill | Triggers on |
  |-------|-------------|
  | **go-standards** | Writing, reviewing, or designing Go code. Zero-tolerance quality gates
  covering naming, error handling, interfaces, composition, testing, and architecture. |
  | **linux-systems** | Container/Linux environments: missing binaries, PATH issues in
  subagent shells, package installation decisions, `/etc` config changes, repetitive shell
  commands. |

  ## Installation

  Clone into your Claude Code skills directory:

  ```bash
  git clone https://github.com/nug/cantrips.git ~/.claude/skills/cantrips

  Or in a Dockerfile:

  RUN git clone https://github.com/nug/cantrips.git /tmp/cantrips \
      && cp -r /tmp/cantrips/skills/* /home/coder/.claude/skills/ \
      && rm -rf /tmp/cantrips

  Structure

  skills/
  ├── go-standards/
  │   ├── SKILL.md
  │   ├── CODE_RULES.md
  │   ├── ARCH_RULES.md
  │   ├── TEST_RULES.md
  │   └── PATTERNS_REF.md
  └── linux-systems/
      ├── SKILL.md
      ├── shell-environments.md
      ├── package-management.md
      ├── system-config.md
      └── build-automation.md
