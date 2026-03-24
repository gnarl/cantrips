# Architecture Rules

## 1. Project Layout

- **`go.mod` at repo root** unless working in a monorepo. No `src/` wrapper directory.
- **`cmd/`**: Entry points. Each subdirectory is one binary containing a single `main.go`. Thin: parse flags, wire dependencies, call into packages, handle errors.
- **`internal/`**: Private packages. Not importable by external modules. Use for shared code between `cmd/` binaries that should not be part of the public API.
- **Domain packages** at the top level or under a grouping directory. `auth/`, `storage/`, `text/` — not `pkg/` unless the project is a library intended for external consumption.

## 2. Package Organization

- **Group by domain**, not by layer. `auth/`, `billing/`, `storage/` — not `models/`, `services/`, `controllers/`.
- **Forbidden package names**: `utils/`, `helpers/`, `common/`, `misc/`, `models/`, `services/`, `controllers/`. These are horizontal layers. Go packages are vertical slices.
- **One concept per package.** If a package does two unrelated things, split it.
- **Minimal external dependencies.** Prefer standard library. Add external modules only when they provide substantial value.
- **Pin versions**: Always use specific versions in `go.mod`, never floating tags. Run `go mod tidy` after adding/removing imports.

## 3. File Organization

- **One concept per file.** Each file focuses on a single type or closely related group of functions.
- **File names**: Lowercase, underscores for word separation. `http_client.go`, `truncate.go`.
- **Co-located tests**: Every `x.go` has `x_test.go` beside it in the same directory.
- **Package docs**: Add `doc.go` with a package comment when a package needs an overview.

## 4. Dependency Direction

- Domain packages depend on standard library and external modules only.
- Domain packages may depend on each other but must not form cycles.
- `internal/` depends on domain packages and standard library.
- `cmd/` depends on everything. This is where wiring happens.
- **No upward dependencies**: Domain packages never import from `cmd/` or `internal/`.

## 5. When to Split vs. Merge Packages

**Split when:**
- A package has two unrelated responsibilities
- Two packages form a dependency cycle (extract the shared concept)
- A package exceeds ~15-20 files

**Keep together when:**
- Types are always used together
- Splitting would create packages with only 1-2 files
- The "shared" concept is only used by one consumer (inline it)

## 6. Separation of Concerns

- **Stateless first.** Prefer pure functions that take parameters and return values.
- **When state is needed**, use structs with unexported fields and constructor functions.
- **File/function size signals**: File > ~200-300 lines or function > ~25 lines → refactor. A function with a loop should primarily loop and call a named helper.
