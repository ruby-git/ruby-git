## Command Implementation Review for `Git::Commands::*` Classes

### Goal

Verify that the `#call` method and supporting structure of a `Git::Commands::*` class correctly implements the command execution pattern: binding arguments, invoking git, handling exit codes, and raising appropriate errors.

### Input

You will be given one or more command source files from `lib/git/commands/`. Each file defines a class with an `ARGS` constant, `#initialize`, and `#call` method.

### What to Check

#### 1. Method Signature

The `#call` method must use the universal forwarding signature:

```ruby
def call(*, **)
```

**Check:**
- [ ] Uses `(*, **)` — not named parameters, not `(*args, **opts)`, not a custom signature
- [ ] The `Arguments` DSL handles all argument validation — `#call` should not contain argument parsing or validation logic

**Why:** The `ARGS.bind(*, **)` call maps positional and keyword arguments to CLI flags. Named parameters would prevent the DSL from handling overloaded calling conventions.

#### 2. Argument Binding

The first line of `#call` should bind arguments:

```ruby
bound_args = ARGS.bind(*, **)
```

**Check:**
- [ ] Uses `ARGS.bind(*, **)` — forwards all positional and keyword arguments
- [ ] Result is assigned to `bound_args` (consistent variable name across all commands)
- [ ] No manual argument manipulation before or after binding (e.g., no `args << '--flag'` or conditional flag insertion)

**Common mistakes:**
- Adding arguments conditionally outside the DSL — this bypasses the Arguments DSL and makes the ARGS definition incomplete
- Using `ARGS.build` instead of `ARGS.bind` — `build` returns a raw array, `bind` returns a `Bound` object that supports splatting and accessor methods

#### 3. Command Execution

The command must be executed through the execution context:

```ruby
@execution_context.command(*bound_args, raise_on_failure: false)
```

**Check:**
- [ ] Uses `@execution_context.command(...)` — not a direct system call, not `Open3`, not backticks
- [ ] Splats `bound_args` with `*` — ensures the `Bound` object is expanded via `to_ary`
- [ ] Passes `raise_on_failure: false` when the command handles its own exit codes (see section 4)
- [ ] Does NOT pass `raise_on_failure: false` if the default behavior (raise on any non-zero) is correct

#### 4. Exit Code Handling

Different git subcommands have different exit code conventions. The `#call` method must use the correct threshold.

| Convention | Threshold | Subcommands | `raise_on_failure:` |
|------------|-----------|-------------|---------------------|
| 0 = success, 1+ = error | `>= 1` | Most commands (`log`, `commit`, `push`, `checkout`, etc.) | Omit (use default `true`) |
| 0 = no diff, 1 = diff found, 2+ = error | `>= 2` | `diff`, `diff-tree`, `diff-files`, `diff-index` |  `false` |
| 0 = identical, 1 = different, 2+ = error | `>= 2` | `diff` (with `--exit-code`) | `false` |
| 0 = match, 1 = no match, 2+ = error | `>= 2` | `grep` | `false` |

**For commands with non-standard exit codes (threshold >= 2):**

```ruby
@execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
  raise Git::FailedError, result if result.status.exitstatus >= 2
end
```

**Check:**
- [ ] Correct threshold for the git subcommand
- [ ] Uses `.tap` with the threshold check — keeps the return value as the `CommandLineResult`
- [ ] Raises `Git::FailedError` — not a generic `RuntimeError`, not `Git::Error`, not `StandardError`
- [ ] Passes `result` to `FailedError` — enables error inspection
- [ ] Uses `result.status.exitstatus` — not `result.status.success?` (which only checks for 0)
- [ ] Includes a comment explaining the exit code convention

**For commands with standard exit codes (threshold >= 1):**

```ruby
@execution_context.command(*bound_args)
```

**Check:**
- [ ] Does NOT pass `raise_on_failure: false` — lets the default error handling work
- [ ] Does NOT have a manual exit code check — redundant with the default behavior

**Common mistakes:**
- Using `raise_on_failure: false` but forgetting the manual threshold check — silently swallows errors
- Checking `result.status.success?` instead of `exitstatus >= threshold` — wrong for commands where exit code 1 is not an error
- Using the wrong threshold — e.g., `>= 1` for diff commands would raise on normal diffs
- Raising `Git::Error` instead of `Git::FailedError` — wrong error class hierarchy

#### 5. Return Value

**Check:**
- [ ] Returns a `Git::CommandLineResult` — the result of `@execution_context.command(...)`
- [ ] Does NOT parse the output — command classes return raw results; parsing belongs in parsers or facades
- [ ] Does NOT transform, filter, or wrap the result — returns it as-is
- [ ] When using `.tap`, the block does not alter the return value (`.tap` always returns the receiver)

**Common mistakes:**
- Parsing stdout inside `#call` — violates separation of concerns; parsing belongs in `Git::Parsers::*` or facade classes
- Returning a hash, array, or custom object instead of `CommandLineResult`
- Using `.then`/`.yield_self` instead of `.tap` — would change the return value if the block returns something else

#### 6. No Side Effects

**Check:**
- [ ] `#call` does not modify instance state — no `@result = ...` or `@last_output = ...`
- [ ] `#call` does not write to files, logs, or global state
- [ ] `#call` does not cache results — each call executes the command fresh
- [ ] `#call` is safe to call multiple times with different arguments

#### 7. No Conditional Logic

**Check:**
- [ ] No `if`/`unless`/`case` statements — all argument logic should be in the ARGS DSL
- [ ] No conditional flag insertion — e.g., no `args << '--cached' if options[:cached]`
- [ ] No environment variable checks — configuration belongs in the execution context
- [ ] No platform-specific branches — the command class should be platform-agnostic

**The only acceptable conditional** is the exit code threshold check (e.g., `if result.status.exitstatus >= 2`).

**Common mistakes:**
- Adding a conditional to handle a special case that should be an ARGS option instead
- Checking `Gem.win_platform?` in the command — platform differences belong in the execution context

#### 8. Instance Variable Usage

**Check:**
- [ ] Only `@execution_context` is stored as an instance variable
- [ ] Set in `#initialize`, never modified after
- [ ] No other instance variables — the class is stateless beyond its execution context

### Reference Implementation

The canonical `#call` for a command with non-standard exit codes:

```ruby
def call(*, **)
  bound_args = ARGS.bind(*, **)

  # git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error
  @execution_context.command(*bound_args, raise_on_failure: false).tap do |result|
    raise Git::FailedError, result if result.status.exitstatus >= 2
  end
end
```

The canonical `#call` for a command with standard exit codes:

```ruby
def call(*, **)
  bound_args = ARGS.bind(*, **)

  @execution_context.command(*bound_args)
end
```

### Output

For each file, produce:

| Check | Status | Issue |
|-------|--------|-------|
| Method signature | Pass/Fail | Description if fail |
| Argument binding | Pass/Fail | Description if fail |
| Command execution | Pass/Fail | Description if fail |
| Exit code threshold | Pass/Fail | Description if fail |
| Return value | Pass/Fail | Description if fail |
| No side effects | Pass/Fail | Description if fail |
| No conditional logic | Pass/Fail | Description if fail |
| Instance variables | Pass/Fail | Description if fail |

Then provide the corrected `#call` method if any issues were found.
