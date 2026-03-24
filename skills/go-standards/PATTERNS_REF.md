# Go Design Patterns Reference

External pattern catalog from [tmrts/go-patterns](https://github.com/tmrts/go-patterns). Fetch the specific pattern file when you need implementation guidance. Each file is 1-2KB with a description and complete Go example.

**Base URL:** `https://raw.githubusercontent.com/tmrts/go-patterns/master/`

## Composition & Structure

| When you need to... | Pattern | File |
|---|---|---|
| Compose behavior at runtime | Strategy | `behavioral/strategy.md` |
| Wrap/extend without modifying | Decorator | `structural/decorator.md` |
| Control access or add cross-cutting logic | Proxy | `structural/proxy.md` |
| Configure with many optional parameters | Functional Options | `idiom/functional-options.md` |
| Notify dependents on state changes | Observer | `behavioral/observer.md` |

## Concurrency & Messaging

| When you need to... | Pattern | File |
|---|---|---|
| Limit concurrent work to N goroutines | Bounded Parallelism | `concurrency/bounded_parallelism.md` |
| Fan work out to parallel workers | Parallelism | `concurrency/parallelism.md` |
| Produce values on demand | Generator | `concurrency/generator.md` |
| Aggregate results from multiple sources | Fan-In | `messaging/fan_in.md` |
| Distribute work to multiple consumers | Fan-Out | `messaging/fan_out.md` |
| Decouple producers from consumers | Publish/Subscribe | `messaging/publish_subscribe.md` |

## Creation & Stability

| When you need to... | Pattern | File |
|---|---|---|
| Construct complex objects step by step | Builder | `creational/builder.md` |
| Create objects without specifying exact type | Factory Method | `creational/factory.md` |
| Reuse expensive-to-create objects | Object Pool | `creational/object-pool.md` |
| Ensure exactly one instance | Singleton | `creational/singleton.md` |
| Protect from cascading failures | Circuit Breaker | `stability/circuit-breaker.md` |
| Limit concurrent resource access | Semaphore | `synchronization/semaphore.md` |

## How to Use

1. Identify your design need from the tables above.
2. Fetch the raw file: `https://raw.githubusercontent.com/tmrts/go-patterns/master/<file>`
3. Read the pattern description and Go implementation.
4. Adapt to your specific context — patterns are starting points, not copy-paste templates.

**Note:** Only patterns with actual implementations are listed. The tmrts/go-patterns repo lists 48 patterns but only 18 have content.
