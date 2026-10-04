# hello-greetings Implementation Plan

**Spec:** docs/superpowers/specs/2026-09-10-hello-greetings-design.md

### Task 1: Refactor argument parsing
**Status:** Completed

- [x] **Step 1:** Move argument parsing into a loop handling `--name`
- [x] **Step 2:** Verify `hello.sh --name Ada` prints `Hello, Ada`

### Task 2: Add --lang option
**Status:** In-progress

- [ ] **Step 1:** Add `--lang en|fr|es` per spec D1
- [ ] **Step 2:** Unknown code exits 2 with a message on stderr
- [ ] **Step 3:** Verify `hello.sh --lang fr --name Ada` prints `Bonjour, Ada`

### Task 3: Add test.sh
**Status:** Todo

- [ ] **Step 1:** Write `test.sh` covering default, `--name` and each `--lang`
- [ ] **Step 2:** Run `sh test.sh` and confirm it passes
