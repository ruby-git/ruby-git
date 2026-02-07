## Testing guidelines for `Git::Commands::*` classes

Each command class has a single `#call` method that builds git CLI arguments using an `Arguments` DSL, executes the command via `execution_context.command`, and returns a `Git::CommandLineResult`. Commands that detect errors raise `Git::FailedError`.

### Unit tests

Unit tests verify that the command builds the correct arguments for every option and operand combination. For each entry in the command's `ARGS` definition (literals, flag options, operands, value options), there should be a unit test that sets a message expectation on `execution_context.command` with the exact expected arguments.

Unit tests should cover:

- The base invocation with no options (verifies all literal flags are passed in the correct order)
- Each positional operand variation (e.g., single value, multiple values)
- Each flag option, including aliases (e.g., `:cached` and its `:staged` alias, or `:force` and its `:f` short alias)
- Flag options combined with operands where meaningful (e.g., an option that modifies how operands are interpreted)
- Value options with each accepted form (e.g., boolean `true` vs a string value like `'lines,cumulative'`)
- Pathspecs or other repeatable/separator-based options, both alone and combined with operands
- Exit code branching logic: verify the command's own success/failure threshold using mocked exit codes. Test every exit code the command treats as success and at least two it treats as failure. For example, if the command raises `FailedError` when `exitstatus >= 2`, test that exit codes 0 and 1 return a result without raising, and that exit codes 2 and 128 raise `FailedError`. This tests the command's branching logic, not git's behavior.

Unit test descriptions should be concise and action-oriented. Avoid appending "and returns CommandLineResult" to every test — that's the universal contract. Use descriptions like "includes the --cached flag", "passes both commits as operands", "combines commit with pathspecs".

### Integration tests

Integration tests are minimal smoke tests that confirm the command executes successfully against a real git repository. They should NOT test git's output format, parsing behavior, or specific content of stdout — those concerns belong in parser specs and facade/end-to-end specs.

Integration tests should only cover:

- A smoke test: calling with valid arguments returns a `CommandLineResult` with expected output (e.g., non-empty for commands that produce output)
- Exit codes from real git: one test per success exit code, exercised through real git invocations that naturally produce each code. For example, for `git diff`: identical refs produce exit code 0 with empty output; differing refs produce exit code ≤1 with non-empty output. This confirms that real git returns the exit codes the command's branching logic expects.
- Error handling: invalid input (e.g., a nonexistent ref) raises `FailedError`

**Do not** write integration tests that assert on git's output format (e.g., matching specific line patterns, status letters, or header syntax). The command's job is to pass the correct arguments to git and return the result — verifying git's formatting behavior is testing git, not the command. If a particular flag needs to be tested (e.g., `-M` for rename detection), verify the flag appears in the arguments via a unit test.

### General guidelines

**Regex patterns** in test assertions should not use Ruby's `/m` modifier unless intentionally matching across newlines. Git output is line-based, so patterns should match within single lines.
