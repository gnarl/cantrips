# Package Management

## Decision Guide

```
Is it a system library or utility (curl, git, build-essential, locales)?
  → apt

Does the distro package lag significantly behind upstream?
  → Use the official installer or download

Does the tool have its own installer/version manager?
  → Use it (rustup, uv, nvm, official Go tarball, etc.)

Is snap suggested by apt or any docs?
  → Never. See below.
```

## Canonical Installers by Tool

| Tool | Method |
|------|--------|
| Go | Download tarball from go.dev/dl, extract to /usr/local/go |
| Rust | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` (rustup) |
| Node | nvm, or official NodeSource apt repo |
| Python packages | uv or pip, never apt python packages for app deps |
| Claude Code | Official install script from claude.ai |
| just, rtk, etc. | Official install scripts from project docs |

## Never Use Snap in Containers

Snap requires the snapd daemon, which does not run in Docker containers. Even if installation appears to succeed, snap packages will fail to execute. Additionally:

- AppArmor profiles conflict with container security
- Snap mounts are not visible across container layers
- Snap updates run as a background daemon that doesn't exist

If apt suggests a snap package, find an alternative:
```bash
# apt may suggest snap for some tools — check first
apt-cache policy <package>   # Look for snap: in output

# Alternatives
apt install <package>        # Try non-snap apt version first
# or use the tool's official installer
```

## Upgrade Safety

- Binaries installed to `/usr/local/` survive apt upgrades
- Tools installed via their own version managers (rustup, nvm) are self-contained
- Document every non-apt install in the Dockerfile so rebuilds are reproducible
- Avoid installing to `/usr/bin/` directly — that's apt's territory
