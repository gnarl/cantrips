# Build Automation with Make

## When to Use a Makefile

Use a Makefile when:
- The same shell command sequence is run more than once
- Multiple agents or subagents need to perform the same operations
- A task has dependencies that should only run when inputs change
- You want a single documented entry point for common operations

Do not use a Makefile for one-off commands or things that only ever run during
a single agent session.

## Basic Structure for Agent Environments

```makefile
.PHONY: install build test lint clean

# Default target
all: build

install:
	apt-get update && apt-get install -y --no-install-recommends $(PACKAGES)

build:
	go build ./...

test:
	go test ./...

lint:
	golangci-lint run

clean:
	rm -rf bin/
```

## Key Rules

- Always declare non-file targets as `.PHONY`
- Use tabs (not spaces) for recipe indentation — Make requires it
- Keep targets single-purpose and composable
- Document targets with `##` comments for self-documenting help:

```makefile
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'

install: ## Install system dependencies
	apt-get update && apt-get install -y $(PACKAGES)

build: ## Build the project
	go build ./...
```

## Agent-Specific Patterns

When orchestrating agents that repeat operations, expose them as Make targets so
any agent can run `make <target>` without needing to reconstruct the command:

```makefile
setup-env: ## Configure shell environment for non-interactive shells
	cp config/.bashrc /home/coder/.bashrc
	cp config/profile.d/* /etc/profile.d/

add-to-path: ## Add /usr/local/go/bin to PATH for all shells
	echo 'export PATH="/usr/local/go/bin:$$PATH"' > /etc/profile.d/go.sh
```

## Debugging Make

```bash
make -n <target>    # Dry run — show commands without executing
make -d <target>    # Debug — show dependency resolution
make -j4 <target>   # Run up to 4 targets in parallel
```
