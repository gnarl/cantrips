---
name: go-standards
description: Go development standards with zero-tolerance quality gates. Use when writing, reviewing, or designing Go code. Covers naming, error handling, interfaces, composition, testing, architecture, and design patterns.
---

# Go Development Standards

**Zero-Tolerance | Composition Over Inheritance | Real Tests Only**

These rules are non-negotiable. Violations are failures.

## Golden Rules

1. **Real tests, no mocks.** Tests hit actual systems. No mocks, fakes, or stubs. If an external system is unavailable, use two real implementations behind an interface — both do real work.
2. **Accept interfaces, return structs.** Define interfaces at the consumer, not the implementer. Keep them small: 1-2 methods. Return concrete types.
3. **Design for zero values.** Types should be usable without explicit initialization. The zero value of a struct should be valid and useful.
4. **Errors are values. Handle every one.** Return errors explicitly. Check immediately. Wrap with context using `%w`. Never discard with `_`. No panic for expected conditions.
5. **No premature abstraction.** Do not create an interface until you have two consumers. Three similar lines are better than a premature helper. YAGNI.
6. **Composition via embedding and fields.** Go has no inheritance. Compose behavior through struct embedding and interface fields. Be aware that embedding in public structs leaks methods.
7. **Zero warnings.** `gofmt`, `go vet`, and `golangci-lint` must be clean. No exceptions.
8. **Small interfaces at the consumer.** The consumer defines what it needs. The implementer satisfies it implicitly. This is Go's core composition mechanism.

## Quick Reference

| When you are... | Read |
|---|---|
| Writing or reviewing Go code | CODE_RULES.md |
| Designing package structure or project layout | ARCH_RULES.md |
| Writing or reviewing tests | TEST_RULES.md |
| Choosing design patterns for a Go system | PATTERNS_REF.md |

## Quality Gate Commands

Before any commit, all must pass:

- `gofmt -l .` — must produce no output
- `go vet ./...` — must be clean
- `golangci-lint run ./...` — must be clean
- `go test ./... -count=1` — must pass with zero failures

**IF YOU VIOLATE THESE RULES, YOU HAVE FAILED.**
