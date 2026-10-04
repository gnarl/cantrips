#!/bin/sh
# hello.sh - greet someone. Usage: hello.sh [--name NAME]
name="World"
if [ "${1:-}" = "--name" ]; then
  name="${2:-World}"
fi
echo "Hello, $name"
