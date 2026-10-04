# hello-cli greetings — Design

## Goal
Let the user choose the greeting language and cover the script with tests.

## Decisions

### D1. Language selection
`--lang <code>` selects the greeting. Supported codes: `en` (default), `fr`, `es`.
Unknown codes exit with status 2 and a message on stderr.

### D2. Tests
Plain shell tests in `test.sh`, no framework.
