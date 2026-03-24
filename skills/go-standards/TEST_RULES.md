# Testing Rules

## 1. Philosophy

- **Real tests only.** Tests hit actual systems (DB, file, API). No mocks, no fakes, no stubs.
- **Zero fabrication.** If it fails in the real world, the test must fail.
- **Standard library only.** Use the built-in `testing` package. No testify, gomega, gocheck.
- **When an external system is genuinely unavailable**, define a small interface and provide two real implementations (e.g., `EmailSender` and `LogSender`). Both do real work. This is not mocking — run the same test suite against both.

## 2. Organization

- **Co-located**: Every `x.go` has `x_test.go` beside it.
- **Same package**: Tests use the same package name (white-box testing), not `package foo_test`.
- **One test file per source file.**

## 3. Naming

- **Format**: `Test[Function][Scenario]` in PascalCase.
- **Descriptive**: The name tells you what is being tested and under what conditions.
- `TestTruncateShortStringUnchanged` — good.
- `TestTruncate` — bad, too vague.
- `Test_truncate_short` — bad, underscores.

## 4. Table-Driven Tests

Default pattern for multiple test cases. Use whenever a function has more than two meaningful cases.

```go
func TestTruncate(t *testing.T) {
    tests := []struct {
        name   string
        input  string
        maxLen int
        want   string
    }{
        {name: "ShortStringUnchanged", input: "Hello", maxLen: 10, want: "Hello"},
        {name: "ExactLengthUnchanged", input: "Hello", maxLen: 5, want: "Hello"},
        {name: "LongStringTruncated", input: "Hello World", maxLen: 8, want: "Hello..."},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Truncate(tt.input, tt.maxLen)
            if got != tt.want {
                t.Errorf("Truncate(%q, %d) = %q, want %q", tt.input, tt.maxLen, got, tt.want)
            }
        })
    }
}
```

## 5. Test Helpers

- **`t.Helper()`** at the start of every test helper. Failures report the caller's line.
- **`t.Cleanup()`** for teardown, not `defer`. Cleanup runs even if the test panics.
- **Helper location**: In the `_test.go` file where used. If shared across packages, place in `internal/testhelper/`.
- **Test constructors**: `newTest[Type](t *testing.T)` — callable with only `*testing.T`. Wire real dependencies. If unavailable, `t.Skip("requires database")`.

```go
func newTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db, err := sql.Open("postgres", os.Getenv("TEST_DATABASE_URL"))
    if err != nil {
        t.Fatalf("connecting to test database: %v", err)
    }
    t.Cleanup(func() { db.Close() })
    return db
}
```

## 6. Error Testing

```go
// Expect an error
func TestFetchUserNotFoundReturnsErrNotFound(t *testing.T) {
    _, err := FetchUser(ctx, "nonexistent-id")
    if !errors.Is(err, ErrNotFound) {
        t.Fatalf("got %v, want ErrNotFound", err)
    }
}

// Expect no error
func TestFetchUserValidIDSucceeds(t *testing.T) {
    user, err := FetchUser(ctx, validID)
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.ID != validID {
        t.Errorf("got ID %s, want %s", user.ID, validID)
    }
}
```

## 7. TestMain for Shared Setup

When all tests in a package need the same expensive setup:

```go
func TestMain(m *testing.M) {
    pool, err := setupTestDB()
    if err != nil {
        fmt.Fprintf(os.Stderr, "test setup failed: %v\n", err)
        os.Exit(1)
    }
    code := m.Run()
    pool.Close()
    os.Exit(code)
}
```

## 8. Useful Test Failures

- **Include got and want**: `t.Errorf("Foo(%d) = %d, want %d", input, got, want)`
- **Include context**: Which input caused the failure, not just "assertion failed"
- **Use `t.Fatalf`** when continuing is pointless (setup failures). Use `t.Errorf` when other cases should still run.

## 9. Prohibited in Tests

- `time.Sleep` for synchronization — use channels, `sync.WaitGroup`, or polling with deadline
- `mock`, `fake`, `stub`, `dummy` in any form
- `t.Skip` to dodge a broken test — only skip when an external resource is genuinely unavailable
- Tests that pass by doing nothing
- Ignoring test output or swallowing errors
