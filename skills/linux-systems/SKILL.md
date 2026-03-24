---
name: linux-systems
description: Use when working in a Linux or container environment and encountering: binary not found despite being installed, PATH not available in agent/subagent shells, shell environment not working in non-interactive contexts, questions about which installation method to use, snap being suggested, /etc config files needing modification, or repetitive shell commands that should be a Makefile target.
---

# Linux Systems

## Overview

Pragmatic Linux systems expertise for container and agent environments. Follow distro conventions and canonical installation methods — changes should survive OS upgrades and container rebuilds.

## Core Principles

- **Use the canonical installation method** for each tool: apt for system packages where the distro version is sufficient, official installers/scripts for tools where distro packages lag (Go, Rust, Node, uv, etc.), direct binary downloads when that's the documented approach
- **Never use snap** in a container — no snapd daemon, AppArmor conflicts, broken by design in containers
- **Follow the FHS** — put things where the distro expects them
- **Prefer .d/ drop-in directories** over editing main /etc config files directly
- **Makefile over repetition** — if an agent runs the same shell commands more than once, it belongs in a Makefile target

## Quick Reference

| Symptom | Read |
|---------|------|
| Binary not found / PATH missing in subagent | shell-environments.md |
| Which installer to use / snap suggested | package-management.md |
| Editing /etc configs | system-config.md |
| Repetitive commands across agents | build-automation.md |
