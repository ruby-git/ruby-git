# Extract Command from Lib

Replace a direct `#command` call in `Git::Lib` with a call to a `Git::Commands::*`
class. The git subcommand is determined by the first (or first few) arguments to the
`#command` method call.

## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with a short message
identifying the `Git::Lib` method or `#command` call to migrate. Examples:

```text
Using the Extract Command from Lib prompt, migrate Git::Lib#worktree_add —
it calls command('worktree', 'add', ...).
```

```text
Extract Command from Lib: command('ls-tree', ...)
```

The invocation needs either the `Git::Lib` method name or the git subcommand string
from the `#command` call (or both).

## Related prompts

Run or reference these prompts during the workflow:

- **Scaffold New Command** — generates the `Git::Commands::*` class, unit tests,
  integration tests, and YARD docs (used in Step 4 if the command class does not
  exist yet)
- **Review Command Implementation** — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes
- **Review Cross-Command Consistency** — sibling consistency within a command family
- **Review Backward Compatibility** — preserving `Git::Lib` return-value contracts

## Input

You will be given:

1. A `Git::Lib` method that contains one or more `command(...)` calls to replace
2. The git subcommand name (derived from the first arguments to `#command`)

## Workflow

### Branch setup

All work must be done on a feature branch. **Never commit or push directly to
`main`.**

Before starting, create a new branch:

```bash
git checkout -b <feature-branch-name>
```

All commits in this workflow go on the feature branch. When work is complete,
open a pull request — do not merge or push directly into `main`.

### Step 1 — Identify the `#command` call

1. Locate the `Git::Lib` method that calls `command(...)`.
2. Note:
   - the git subcommand (first argument(s) to `#command`)
   - the options/arguments passed after the subcommand
   - execution options (e.g., `timeout:`, `out:`, `err:`, `env:`)
   - the return value and any post-processing (`.stdout`, parsing, regex matching)
3. Document the method's current **public contract**: signature, return type, and
   return-value format (String, Array, Hash, Boolean, etc.)
4. Run linters and rubocop to confirm a clean baseline:

   ```bash
   bundle exec rubocop
   ```

   Fix any issues before continuing.

### Step 2 — Plan the migration and get approval

Before writing or changing any code, present a migration plan and **wait for
explicit confirmation** from the user. Do not proceed until they approve.

The plan must cover every `#command` call identified above. For each one, state:

| `Git::Lib` method | `#command` call | Target `Git::Commands` class | Class exists? | Notes |
| --- | --- | --- | --- | --- |
| `some_method` | `command('sub', '--flag', arg)` | `Git::Commands::Sub` (new) or existing | ✅ / 🆕 | any mapping decisions |

Also state:

- Which (if any) new `Git::Commands::*` classes need to be created
- How optional or empty arguments will be handled (e.g., nil vs `''` operands)
- Any return-value post-processing that stays in `Git::Lib`

Then ask:

> Does this mapping look correct? Any changes before I start implementing?

**Do not move to Step 3 until the user confirms the plan.**

### Step 3 — Ensure adequate legacy tests

Before making any changes, verify that `tests/units/` has adequate tests for the
`Git::Lib` method being migrated.

1. Search existing legacy tests for coverage of the method:

   ```bash
   grep -rn '<method_name>' tests/units/
   ```

2. If coverage is insufficient, add **minimal new tests** to the legacy test suite
   that exercise the method's current behavior. These tests ensure the refactor does
   not break backward compatibility.
   - Do **not** change existing tests.
   - Follow existing legacy test conventions (`Test::Unit::TestCase`,
     `assert_command_line_eq`, `in_temp_dir`, etc.).
   - Verify new tests pass:

     ```bash
     bundle exec bin/test <test-file-basename>
     ```

   - Run rubocop against the new test file:

     ```bash
     bundle exec rubocop tests/units/<test-file>
     ```

   - Fix any issues before continuing.
3. Commit the new legacy tests:

   ```bash
   git add tests/units/<test-file>
   git commit -m "refactor(test): add legacy tests for <method_name>"
   ```

### Step 4 — Ensure the `Git::Commands::*` class exists

1. Search `lib/git/commands/` for an existing command class that matches the git
   subcommand:

   ```bash
   find lib/git/commands -name '*.rb' | sort
   ```

   Also check the class contents to confirm the existing class covers the same
   subcommand variation (e.g., `branch --show-current` vs. `branch --list`).

2. **If the command class already exists**, skip to Step 5.

3. **If the command class does not exist**, scaffold it using the
   **Scaffold New Command** prompt. This produces:

   - `lib/git/commands/<command>.rb` (or `lib/git/commands/<family>/<action>.rb`)
   - `spec/unit/git/commands/<command>_spec.rb`
   - `spec/integration/git/commands/<command>_spec.rb`

4. Verify the new command class:

   ```bash
   bundle exec rspec spec/unit/git/commands/<command>_spec.rb
   bundle exec rspec spec/integration/git/commands/<command>_spec.rb
   bundle exec rubocop lib/git/commands/<command>.rb
   bundle exec yard
   ```

   Fix any issues before continuing.

5. Commit the new command class and its tests:

   ```bash
   git add lib/git/commands/<command>*.rb spec/
   git commit -m "refactor(command): add Git::Commands::<Command> class"
   ```

### Step 5 — Update `Git::Lib` to delegate to the command class

1. Replace the `command(...)` call with a call to the `Git::Commands::*` class:

   ```ruby
   # Before
   def some_method(args)
     command('some-command', '--flag', args).stdout
   end

   # After
   def some_method(args)
     Git::Commands::SomeCommand.new(self).call(args, flag: true).stdout
   end
   ```

2. Preserve the method's **exact return value contract** — apply any parsing or
   transformation after `.stdout` / `.stderr` / `.status` to match the original
   return type.

3. Add the appropriate `require_relative` at the top of `lib/git/lib.rb` if not
   already present.

4. Verify:

   ```bash
   bundle exec bin/test <legacy-test-file-basename>
   bundle exec rspec
   bundle exec rubocop
   bundle exec yard
   ```

   Fix any issues before continuing.

5. Commit the `Git::Lib` change:

   ```bash
   git add lib/git/lib.rb
   git commit -m "refactor(lib): delegate <method_name> to Git::Commands::<Command>"
   ```

## Commit discipline

Keep changes in **exactly three distinct commits** (each optional if no changes were
needed for that step):

1. `refactor(test): add legacy tests for <method_name>` — new tests in
   `tests/units/`
2. `refactor(command): add Git::Commands::<Command> class` — new command class,
   unit specs, and integration specs
3. `refactor(lib): delegate <method_name> to Git::Commands::<Command>` — `Git::Lib`
   changes only

If further changes are needed after these commits are created:

- Amend the change to the **appropriate commit** (e.g., a command class fix goes
  into the `refactor(command)` commit).
- Rebase the later commits on top:

  ```bash
  git rebase -i <base-commit>
  ```

- After rebasing, verify all quality gates still pass:

  ```bash
  bundle exec rspec && bundle exec rake test && bundle exec rubocop && bundle exec yard
  ```

## Create a pull request

Once all commits are clean and quality gates pass, create a PR for the branch.

If changes are made after the PR is created:

- Amend the change to the appropriate commit.
- Rebase later commits on top.
- Force-push the branch:

  ```bash
  git push --force-with-lease
  ```

## Quality gates (run at every step)

```bash
bundle exec rspec
bundle exec rake test
bundle exec rubocop
bundle exec yard
```

All four must pass before committing at each step. If errors are found, fix them
before continuing.

## Common patterns

### Simple delegation (stdout passthrough)

```ruby
# Before
def symbolic_ref(branch_name)
  command('symbolic-ref', 'HEAD', "refs/heads/#{branch_name}")
end

# After
def symbolic_ref(branch_name)
  Git::Commands::SymbolicRef.new(self).call(branch_name).stdout
end
```

### Delegation with post-processing

```ruby
# Before
def cat_file_type(object)
  command('cat-file', '-t', object).stdout
end

# After
def cat_file_type(object)
  Git::Commands::CatFile::Type.new(self).call(object).stdout
end
```

### Delegation with parsed return value

```ruby
# Before
def worktree_list
  worktrees = {}
  command('worktree', 'list', '--porcelain').stdout.split("\n").each do |w|
    # ... parsing ...
  end
  worktrees
end

# After
def worktree_list
  result = Git::Commands::Worktree::List.new(self).call
  worktrees = {}
  result.stdout.split("\n").each do |w|
    # ... parsing stays in Git::Lib ...
  end
  worktrees
end
```

## What stays in `Git::Lib`

- Output parsing and transformation (until a parser class is created)
- Return-value adaptation to preserve backward compatibility
- Deprecation shims (e.g., option renames)
- Method signatures and public API surface

## What moves to `Git::Commands::*`

- Argument building and CLI flag generation
- `#command` invocation
- Exit-status handling via `allow_exit_status`
