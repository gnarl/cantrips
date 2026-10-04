  Personal skills for small, practical spells for everyday work.

  Designed to complement [superpowers](https://github.com/obra/superpowers).

  ## Skills

  | Skill | Description |
  |-------|-------------|
  | **go-standards** | Writing, reviewing, or designing Go code.|
  | **linux-systems** | Managing Linux environments. |
  | **project-planning** | Using a PLAN.md to track project planning.|

  ## Installation

  Clone into your Claude Code skills directory:

  ```bash
  git clone https://github.com/gnarl/cantrips.git /tmp/cantrips \
      && cp -r /tmp/cantrips/skills/* ~/.claude/skills/ \
      && rm -rf /tmp/cantrips 

  Or in a Dockerfile:

  RUN git clone https://github.com/nug/cantrips.git /tmp/cantrips \
      && cp -r /tmp/cantrips/skills/* /home/coder/.claude/skills/ \
      && rm -rf /tmp/cantrips


