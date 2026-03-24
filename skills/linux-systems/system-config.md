# System Configuration Files

## Core Rule: Prefer Drop-in Directories Over Editing Main Files

Most modern Linux services support `.d/` drop-in directories. Use them instead of
editing the main config file directly — your changes survive package upgrades that
would otherwise overwrite the main file.

| Service | Main file | Drop-in directory |
|---------|-----------|-------------------|
| sudoers | /etc/sudoers | /etc/sudoers.d/ |
| sysctl | /etc/sysctl.conf | /etc/sysctl.d/ |
| PAM | /etc/pam.conf | /etc/pam.d/ |
| apt sources | /etc/apt/sources.list | /etc/apt/sources.list.d/ |
| profile/PATH | /etc/profile | /etc/profile.d/ |
| logrotate | /etc/logrotate.conf | /etc/logrotate.d/ |
| cron | /etc/crontab | /etc/cron.d/ |

## Drop-in File Rules

- Name files descriptively: `/etc/sudoers.d/coder`, `/etc/profile.d/go.sh`
- sudoers drop-ins must have mode `0440` and pass `visudo -c`
- profile.d scripts must be valid POSIX sh (not bash-specific) for broad compatibility
- Use numeric prefixes when load order matters: `50-myapp.conf`

## Editing Main Config Files Safely

When you must edit a main config file directly:

1. **Check if a .d/ directory exists first** — prefer it
2. **Make changes idempotent** — use a guard so re-running doesn't duplicate entries:
```bash
grep -q 'my setting' /etc/config || echo 'my setting' >> /etc/config
```
3. **In Dockerfiles, use RUN with sed/echo** — never hand-edit files in a container image
4. **Validate before applying** — most services have a check mode:
```bash
visudo -c -f /etc/sudoers.d/myfile
nginx -t
sshd -t
```

## Container-Specific Notes

- Changes to /etc in a running container are lost on rebuild — put them in the Dockerfile
- Use `COPY --chown` to place config files rather than `RUN echo ... >>` where possible — easier to review and diff
- Never modify /etc/passwd or /etc/shadow directly — use `useradd`, `usermod`, `passwd`
