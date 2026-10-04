Frozen — Phase 1 completed 2026-09-01

# hello-cli core — Design

## Decisions

### D1. Greeting format
The greeting is `Hello, <name>` with no trailing punctuation.

### D2. Language
POSIX sh only; no bashisms, so it runs on any system.

### D3. Default name
When no name is given, the name is `World`.
