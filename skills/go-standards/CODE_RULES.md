# Code Rules

## 1. Naming

- **Exported**: `PascalCase` for types, functions, methods, constants, interfaces.
- **Unexported**: `camelCase` for fields, local variables, helper functions.
- **Acronyms**: All caps: `HTTP`, `URL`, `ID`, `JSON`, `SQL`. Not `Http`, `Url`, `Id`.
- **Packages**: Lowercase, single word, no underscores, no plural. `text` not `texts`.
- **Interfaces**: Single-method interfaces named method + "er" (`Reader`, `Writer`). Multi-method interfaces use a descriptive noun.
- **Receivers**: Short, 1-2 letter, consistent across all methods of a type. `s` for `Service`, `c` for `Client`. Never `this` or `self`.
- **Constructors**: `New[Type]()`. Example: `NewService(logger Logger) *Service`.
- **No getters with "Get"**: `user.Name()` not `user.GetName()`. Setters use `Set` prefix.
- **No stutter**: `http.Server` not `http.HTTPServer`. The package name is already context.

## 2. Immutability & Value Semantics

- **Unexported fields by default.** Expose via methods, not public fields.
- **Constructor functions** for types with invariants. `New[Type]()` returns a valid instance.
- **Value receivers** for methods that do not mutate. Pointer receivers only when mutation is needed or the struct is large.
- **Copy safety**: Return copies of internal slices/maps, not the reference.
- **Constants**: Use `const` for compile-time values. Group related constants in a `const` block.

## 3. Error Handling

- **Return errors explicitly.** Every function that can fail returns `error` as the last value.
- **Check immediately.** Never discard errors with `_`.
- **Wrap with context.** `fmt.Errorf("fetching user %s: %w", id, err)`.
- **`%w` vs `%v`**: Use `%w` when callers should be able to unwrap with `errors.Is`/`errors.As`. Use `%v` when the error is an implementation detail you do not want callers to depend on.
- **Sentinel errors**: `var ErrNotFound = errors.New("not found")` for specific conditions callers check.
- **Error types**: Implement the `error` interface when callers need structured details.
- **No panic** for expected error conditions. Reserve for truly unrecoverable corruption.
- **No log-and-return**: Either log the error OR return it. Never both.
- **No in-band errors**: Do not return `-1` or `""` to signal failure. Use the error return.

## 4. Interfaces & Composition

- **Define interfaces at the consumer**, not the implementer.
- **Small interfaces**: 1-2 methods. Go interfaces are satisfied implicitly.
- **Accept interfaces, return concrete types.**
- **No premature interfaces**: Do not create an interface until you have two consumers.
- **Compile-time verification**: Verify interface compliance at build time:
  ```go
  var _ io.Reader = (*MyReader)(nil)
  ```
- **Embedding pitfall**: Embedding a type in a public struct exposes all its methods as part of your API. Embed in unexported structs, or use a named field instead.

## 5. Function Design

- **Small**: ~25 lines max. If you are scrolling, refactor.
- **Single responsibility**: Each function does one thing.
- **Accept the narrowest interface** that works. Return concrete types.
- **Named returns**: Only for very short functions where it aids godoc clarity. No naked returns in functions longer than ~5 lines.
- **Context**: Functions that do I/O or may block accept `context.Context` as the first parameter.
- **Functional options** for many optional parameters:
  ```go
  type Option func(*Config)
  func WithTimeout(d time.Duration) Option {
      return func(c *Config) { c.timeout = d }
  }
  func NewClient(opts ...Option) *Client { ... }
  ```
- **Option struct** when you have 3+ required fields and few optional ones. Functional options are for APIs where most config is optional.

## 6. Concurrency

- **No premature goroutines.** Do not add concurrency until profiling shows it is needed.
- **Structured concurrency**: Every goroutine has a clear owner, shutdown path, and error propagation.
- **`errgroup`**: Use `golang.org/x/sync/errgroup` for coordinating goroutine groups.
- **Channels for communication, mutexes for state.** Use the right tool.
- **Channel size**: Prefer unbuffered (0) or 1. Larger buffers mask design problems.
- **Context cancellation**: All long-running goroutines respect `context.Context` cancellation.
- **Goroutine ownership**: The function that starts a goroutine is responsible for ensuring it stops. Document the shutdown mechanism.
- **Pre-allocate** slices with `make([]T, 0, cap)` and maps with `make(map[K]V, cap)` when size is known.

## 7. Documentation

- **Go doc comments on ALL exported types, functions, methods, constants.**
- **Start with the name**: `// Truncate shortens a string to maxLen.`
- **Explain WHY**, not WHAT. The code shows what; the comment explains the reason.
- **Package docs**: Add `doc.go` with a package comment when a package needs an overview.
- **No stutter**: `// Truncate` not `// text.Truncate` inside package `text`.

## 8. Prohibited Patterns (Zero Tolerance)

- `interface{}` / `any` when a specific type or generic constraint works
- `init()` functions — wire dependencies explicitly in `main`
- Global mutable state (package-level `var` mutated at runtime)
- `panic()` for expected error conditions
- Naked returns in functions longer than ~5 lines
- Discarding errors: `result, _ := something()`
- `time.Sleep` in tests for synchronization
- Horizontal-layer package names: `utils/`, `helpers/`, `common/`, `models/`, `services/`
- Mutable exported fields on structs
- `log.Fatal` / `os.Exit` outside of `main()`
