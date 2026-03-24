# Shell Environments in Linux and Containers

## The Four Shell Types

| Type | Examples | Sources |
|------|----------|---------|
| Login + interactive | SSH session, `bash --login` | /etc/profile, ~/.profile, ~/.bash_profile, ~/.bashrc (if called from .bash_profile) |
| Non-login + interactive | Terminal emulator, `bash` | /etc/bash.bashrc, ~/.bashrc |
| Login + non-interactive | `bash --login -c "cmd"` | /etc/profile, ~/.profile |
| Non-login + non-interactive | Scripts, `docker exec`, agent subshells | **Nothing sourced automatically** |

**Agent and subagent shells are almost always non-login, non-interactive. Nothing is sourced automatically.**

## The .bashrc Interactive Guard

Ubuntu's default `.bashrc` contains this near the top:

```bash
case $- in
    *i*) ;;
      *) return;;
esac
```

This causes `.bashrc` to exit immediately in non-interactive shells. Any PATH or environment setup placed after this guard is **invisible to agents and subagents**.

**Fix:** Move PATH and environment setup above this guard, or remove the guard entirely if the file only contains environment setup (appropriate for purpose-built container environments).

## PATH Setup Rules

- Environment that must work everywhere (including agents): set via `ENV` in Dockerfile or above the interactive guard
- Tool-specific PATH additions (Go, uv, cargo, etc.): add to `/etc/environment` or a drop-in profile script in `/etc/profile.d/toolname.sh`
- Never rely on `.bashrc` alone for PATH in a container used by agents

## /etc/profile.d/ Pattern

For PATH additions that need to work across all users and login shells:

```bash
# /etc/profile.d/go.sh
export PATH="/usr/local/go/bin:$PATH"
```

Files here are sourced automatically for login shells. For non-login non-interactive shells (agent subshells), use Dockerfile `ENV` instead.

## Diagnosing Agent PATH Problems

```bash
# What does the agent's shell actually see?
docker exec <container> env | grep PATH
docker exec <container> which <binary>

# Test non-interactive PATH explicitly
docker exec <container> bash -c 'echo $PATH'

# Test login shell PATH
docker exec <container> bash --login -c 'echo $PATH'
```

If these differ, your PATH setup is in the wrong place.
