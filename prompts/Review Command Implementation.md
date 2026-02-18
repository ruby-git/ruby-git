## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with one or more
command source files to review. Examples:

```text
Using the Review Command Implementation prompt, review
lib/git/commands/branch/delete.rb.
```

```text
Review Command Implementation: lib/git/commands/diff/patch.rb
lib/git/commands/diff/numstat.rb
```

The invocation needs the command file(s) to review.

---

## Review Command Implementation

Verify a command class follows the current `Git::Commands::Base` architecture and
contains no duplicated execution behavior.

### Related prompts

- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes
- **Review Cross-Command Consistency** — sibling consistency within a command family

### Input

You will be given one or more command source files from `lib/git/commands/`.

### Architecture Contract (Current)

For migrated commands, the expected structure is:

```ruby
require 'git/commands/base'

class SomeCommand < Base
  arguments do
    ...
  end

  # optional for non-zero successful exits
  # reason comment
  allow_exit_status 0..1

  # YARD docs for this command's call signature
  def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
end
```

Shared behavior lives in `Base`:

- binds arguments
- calls `@execution_context.command(*args, **args.execution_options, raise_on_failure: false)`
- raises `Git::FailedError` unless exit status is in allowed range (`0..0` default)

### What to Check

#### 1. Class shape

- [ ] Class inherits from `Base`
- [ ] Requires `git/commands/base` (not `git/commands/arguments`)
- [ ] Has exactly one `arguments do` declaration
- [ ] Does not define command-specific `initialize` that only assigns
      `@execution_context`

#### 2. `#call` implementation

- [ ] Uses `def call(...) = super # rubocop:disable Lint/UselessMethodDefinition` as YARD documentation shim
- [ ] Contains no custom bind/execute/exit-status logic in migrated commands
- [ ] Does not parse output in command class

#### 3. Exit-status configuration

- [ ] Commands with non-zero successful exits declare `allow_exit_status <range>`
- [ ] Declaration includes a short rationale comment explaining git semantics
- [ ] Range values match expected command behavior

#### 4. Arguments DSL quality

- [ ] DSL entries accurately describe subcommand interface
- [ ] Option aliases and modifiers are used correctly
- [ ] Ordering produces expected CLI argument order

#### 5. Internal compatibility contract

This is the canonical location for the internal compatibility contract. Other
prompts reference this section rather than duplicating it.

Ensure refactors preserve these contract expectations:

- [ ] constructor shape remains `initialize(execution_context)` (inherited from `Base`)
- [ ] command entrypoint remains `call(*, **)` at runtime (via `Base#call`)
- [ ] argument-definition metadata remains available via `args_definition`

If an intentional deviation exists, require migration notes/changelog documentation.

#### 6. Phased rollout / rollback requirements

This is the canonical location for phased rollout requirements. Other prompts
reference this section rather than duplicating the full checklist.

For migration PRs, verify process constraints:

- [ ] changes are on a feature branch — **never commit or push directly to `main`**
- [ ] migration slice is scoped (pilot or one family), not all commands at once
- [ ] each slice is independently revertible
- [ ] refactor-only changes are not mixed with unrelated behavior changes
- [ ] quality gates pass for the slice (`bundle exec rspec`, `bundle exec rake test`,
      `bundle exec rubocop`, `bundle exec yard`)

### Common Failures

- lingering `ARGS = Arguments.define` constant and custom `#call`
- command-specific duplicated exit-status checks instead of `allow_exit_status`
- missing rationale comment for `allow_exit_status`
- missing YARD shim method (`def call(...) = super`)
- migration PR scope too broad (not phased)

### Output

For each file, produce:

| Check | Status | Issue |
|---|---|---|
| Base inheritance | Pass/Fail | ... |
| arguments DSL | Pass/Fail | ... |
| call shim | Pass/Fail | ... |
| allow_exit_status usage | Pass/Fail | ... |
| output parsing absent | Pass/Fail | ... |
| compatibility contract | Pass/Fail | ... |

Then list required fixes and indicate whether the migration slice is safe to merge
under phased-rollout rules.
