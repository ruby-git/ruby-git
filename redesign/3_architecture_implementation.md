# Implementation Plan for Git Gem Redesign (v5.0.0)

This document outlines a step-by-step plan to implement the proposed architectural
redesign. The plan is structured to be incremental, ensuring that the gem remains
functional and passes its test suite after each major step. This approach minimizes
risk and allows for a gradual, controlled migration to the new architecture.

- [Progress Tracker](#progress-tracker)
  - [Next Task](#next-task)
    - [Workflow](#workflow)
    - [Reference Files](#reference-files)
- [Phase 1: Foundation and Scaffolding](#phase-1-foundation-and-scaffolding)
- [Phase 2: The Strangler Fig Pattern - Migrating Commands](#phase-2-the-strangler-fig-pattern---migrating-commands)
  - [Command Migration Checklist](#command-migration-checklist)
    - [✅ Migrated Commands](#-migrated-commands)
    - [⏳ Commands To Migrate](#-commands-to-migrate)
- [Phase 3: Refactoring the Public Interface](#phase-3-refactoring-the-public-interface)
- [Phase 4: Final Cleanup and Release Preparation](#phase-4-final-cleanup-and-release-preparation)

## Progress Tracker

| Phase | Status | Description |
| ----- | ------ | ----------- |
| Phase 1 | ✅ Complete | Foundation and scaffolding |
| Phase 2 | 🔄 In Progress | Migrating commands (12/~50 commands migrated) |
| Phase 3 | ⏳ Not Started | Refactoring public interface |
| Phase 4 | ⏳ Not Started | Final cleanup and release |

### Next Task

**Migrate the `checkout` command** → `Git::Commands::Checkout`

#### Workflow

1. **Analyze**: Read the existing implementation in `lib/git/lib.rb` (search for `def
   checkout`). Understand all options and edge cases.

2. **Design**: Create command class following the pattern in
   `lib/git/commands/branch/delete.rb`. The interface for `#call` should only include
   options relevant to the command being implemented.

3. **TDD**: Write spec file *before* implementing:
   - Test every option using separate `context` blocks
   - Mock the execution context with `double('ExecutionContext')`
   - Verify argument building matches expected git CLI args

4. **Implement**:
   - Use `Git::Commands::Arguments.define` DSL for argument handling
   - Include comprehensive YARD documentation with `@param`, `@option`, and `@return`
     tags
   - Mark class with `@api private`

5. **Delegate**: Update `Git::Lib#branch_new` and `Git::Lib#branch_delete` to delegate to the new class:

   ```ruby
   def branch_new(branch_name, options = {})
     Git::Commands::Branch.new(self).call(branch_name, **options)
   end

   def branch_delete(branch_name, options = {})
     Git::Commands::Branch.new(self).call(branch_name, delete: true, **options)
   end
   ```

   Note: `Git::Lib` methods may accept an options hash for backward compatibility,
   but they must convert it to keyword arguments when calling the command class
   using `**options`.

6. **Verify**:
   - `bundle exec rspec spec/git/commands/branch_spec.rb` — new tests pass
   - `bundle exec rspec` — all RSpec tests pass
   - `bundle exec rake test` — legacy TestUnit tests pass
   - `bundle exec rubocop` — no lint errors
   - `bundle exec yard` — no yardoc errors

   To run a single legacy test: `bundle exec bin/test test_<name>` (e.g., `bundle
   exec bin/test test_branch`)

7. **Update Checklist**: Move `branch` from "Commands To Migrate" to "Migrated
   Commands" table in this document, and update the "Next Task" section to point to
   the next command in the list.

#### Reference Files

- Pattern to follow: `lib/git/commands/add.rb` + `spec/git/commands/add_spec.rb`
- Output parsing example: `lib/git/commands/fsck.rb`
- Complex options example: `lib/git/commands/clone.rb`
- Contributing guide: `CONTRIBUTING.md` (see "Wrapping a git command")

## Phase 1: Foundation and Scaffolding

***Goal**: Set up the new file structure and class names without altering existing
logic. The gem will be fully functional after this phase.*

1. **Create New Directory Structure**

   - `lib/git/commands/` ✅
   - `lib/git/repository/` (for the facade modules) - to be populated in Phase 3

2. **Eliminate Custom Path Classes**

   Path wrapper classes removed and replaced with `Pathname` objects:

   - `Git::Path` ✅
   - `Git::WorkingDirectory` ✅
   - `Git::Index` ✅
   - `Git::Repository` (the path class) ✅

   `Git::Base` now stores paths as `Pathname` objects directly via
   `@working_directory`, `@repository`, and `@index` instance variables.

3. **Introduce New Core Classes (Empty Shells)**

   - `Git::ExecutionContext` in `lib/git/execution_context.rb` ✅
     - Currently a thin wrapper around `Git::Lib` using `method_missing` delegation
     - `GlobalContext` and `RepositoryContext` subclasses will be added in Phase 3

   - `Git::Repository` in `lib/git/repository.rb` ✅
     - Currently an empty shell, to be populated in Phase 3

   - `Git::Commands::Arguments` DSL in `lib/git/commands/arguments.rb` ✅
     - Provides declarative argument definition for command classes

4. **Set Up RSpec Environment**

    RSpec configured and working alongside TestUnit. Specs live in `spec/` and can be
    run with `bundle exec rspec`. ✅

## Phase 2: The Strangler Fig Pattern - Migrating Commands

***Goal**: Incrementally move the implementation of each git command from `Git::Lib`
to a new `Command` class, strangling the old implementation one piece at a time using
a Test-Driven Development workflow.*

**Important Note**: During this phase, `Git::Lib` acts as a stand-in for the
`ExecutionContext` hierarchy:

- `Git::Lib.new(nil, logger)` effectively acts like `GlobalContext` (no repository
  paths set)
- `Git::Lib.new(base, logger)` effectively acts like `RepositoryContext` (repository
  paths set)

All new `Git::Commands::*` classes should accept any object that responds to
`command` (duck typing), not a specific context class. This allows them to work with
`Git::Lib` during migration and the proper context classes in Phase 3.

The `command` method provides important functionality including default options
(normalize, chomp, timeout), option validation, and a simplified interface that
returns just stdout. Commands should call `@execution_context.command('subcommand',
*args, **opts)` rather than working with `CommandLine` instances directly.

**Key Architectural Insight: Git::Lib as the Adapter Layer**

A fundamental principle of this migration is that `Git::Lib` methods serve as
**adapters** between the legacy public interface and the new `Git::Commands::*`
classes. This separation of concerns provides several benefits:

1. **Legacy Interface Acceptance**: `Git::Lib` methods continue to accept the
   historical interface—positional arguments, deprecated options, and quirky
   parameter names that users have come to rely on.

2. **Interface Translation**: The adapter converts legacy patterns to the clean
   `Git::Commands::*` API. For example:
   - Positional `message` argument → `:message` keyword
   - `:no_gpg_sign => true` → `:gpg_sign => false`
   - Options hash → keyword arguments via `**options`

3. **Deprecation Handling**: Warnings about deprecated options are issued in the
   adapter layer, *before* delegating to the command class. This ensures users are
   informed even if they're making other errors.

4. **Clean Command Classes**: `Git::Commands::*` classes remain free of legacy
   baggage. They have a consistent, modern API that:
   - Uses keyword arguments with sensible defaults
   - Matches the underlying git command's interface closely
   - Is easier to test in isolation
   - Could potentially be used directly by advanced users

Example adapter pattern:

```ruby
# Git::Lib#commit - the adapter layer
def commit(message, opts = {})
  # Legacy: positional message → keyword argument
  opts = opts.merge(message: message) if message

  # Legacy: :no_gpg_sign → :gpg_sign => false (with deprecation warning)
  if opts[:no_gpg_sign]
    Git::Deprecation.warn(':no_gpg_sign option is deprecated...')
    raise ArgumentError, '...' if opts.key?(:gpg_sign)
    opts.delete(:no_gpg_sign)
    opts[:gpg_sign] = false
  end

  # Delegate to clean interface
  Git::Commands::Commit.new(self).call(**opts)
end
```

This pattern makes future cleanup straightforward—once deprecation periods end, the
adapter logic can be simplified or removed entirely.

**Parameter Design Principle**: Command class `#call` method parameters should
generally match the underlying git command's interface. This keeps the Commands layer
thin and transparent—directly mapping to git documentation. The public facade API
(Git.*, Git::Repository#*) can add convenience features like:

- Path expansion or normalization
- Ruby-idiomatic defaults
- Parameter validation specific to the Ruby context
- Combining multiple git operations into one public method

Keep Command parameters matching git closely for simplicity, maintainability, and
easier testing. Allow the public API to diverge when it adds real value, but without
obscuring what's actually happening underneath.

**Method Signature Convention**: The `#call` signature SHOULD, if possible, use
anonymous variadic arguments for both positional and keyword arguments:

```ruby
# ✅ Preferred: anonymous forwarding when just passing to ARGS.build
# Note: defaults defined in the DSL (e.g., `positional :paths, default: ['.']`)
# are applied automatically by ARGS.build
def call(*, **)
  args = ARGS.build(*, **)
  @execution_context.command('add', *args)
end

# ✅ Acceptable: explicit positional args when command needs to manipulate them
def call(repository_url, directory = nil, **options)
  directory ||= derive_directory_from(repository_url)
  args = ARGS.build(repository_url, directory, **options)
  @execution_context.command('clone', *args)
end

# ❌ Incorrect: options hash parameter
def call(paths = '.', options = {})
  args = ARGS.build(*Array(paths), **options)
  @execution_context.command('add', *args)
end
```

This convention provides:

- **Better IDE support**: Editors can autocomplete and validate keyword arguments
- **Clearer method signatures**: The `#call` signature documents available options
- **Centralized validation**: `ARGS.build` enforces allowed options and raises errors for unknown or invalid keywords
- **Consistency**: All command classes follow the same pattern

The facade layer (`Git::Lib`, `Git::Base`) may accept either keyword arguments or an
options hash for backward compatibility, but must use `**options` when delegating to
command classes.

**Architectural Insights from Command Migrations**

The following insights were discovered during command migrations and should guide
future work:

1. **`Data.define` creates frozen objects—no memoization allowed**

   Ruby's `Data.define` creates immutable, frozen objects. This means patterns like
   `@cached ||= expensive_computation` will raise `FrozenError`. When using
   `Data.define` for value objects, either:
   - Accept repeated computation (preferred for simple operations)
   - Move caching outside the value object
   - Use a regular class with `freeze` called explicitly after initialization

2. **Parsing logic duplication is unavoidable when one path needs repository context**

   Value objects like `BranchInfo` cannot create domain objects like `Remote` because
   they lack repository context. This leads to seemingly duplicate parsing:

   ```ruby
   # Value object (pure, no context)
   BranchInfo#short_name  # → returns String

   # Domain object (has @base context)
   Branch#parse_name      # → returns [Remote, String]
   ```

   This is **intentional duplication**, not a code smell. Eliminating it would couple
   the value object to the repository, defeating its purpose.

3. **The command's return type shapes the entire downstream architecture**

   When a command returns primitive types (`Array<Array>`), all consumers need magic
   index knowledge. Changing to value objects (`Array<BranchInfo>`) ripples through
   every consumer. Plan return types carefully—they define contracts across the
   system.

4. **Constructor polymorphism enables gradual deprecation**

   When changing a constructor's expected argument type, accept both old and new
   types with a deprecation warning for the legacy path:

   ```ruby
   def initialize(base, branch_info_or_name)
     if branch_info_or_name.is_a?(Git::BranchInfo)
       initialize_from_branch_info(branch_info_or_name)
     else
       Git::Deprecation.warn('...')
       initialize_from_name(branch_info_or_name)
     end
   end
   ```

   This allows migrating internal code first while external users continue working.

5. **The boundary between "pure data" and "contextualized operations" is the most
   important architectural decision**

   Commands should return pure value objects (no repository context needed).
   Domain objects wrap those value objects and add operations requiring context.
   This single decision determines where parsing lives, what types flow where, and
   how the system layers together.

6. **Use `negatable_flag_or_inline_value` for tri-state options with optional values**

   When a git option supports `--flag`, `--no-flag`, AND `--flag=value` forms (like
   `--track`/`--no-track`/`--track=inherit`), use the `negatable_flag_or_inline_value`
   DSL type instead of defining separate options with conflict declarations:

   ```ruby
   # ✅ Preferred: single definition handles all forms
   negatable_flag_or_inline_value :track
   # track: nil     → (omitted)
   # track: true    → --track
   # track: false   → --no-track
   # track: 'inherit' → --track=inherit

   # ❌ Avoid: separate definitions require conflict management
   flag :track
   flag :no_track
   conflicts :track, :no_track
   ```

7. **Adapter methods should forward all positional arguments, not just options**

   **BUT ONLY IF BACKWARD COMPATIBILITY IS MAINTAINED**

   When `Git::Lib` methods delegate to command classes, ensure the method signature
   supports ALL positional arguments the command class accepts:

   ```ruby
   # ❌ Wrong: loses start_point positional argument
   def branch_new(branch, options = {})
     Git::Commands::Branch::Create.new(self).call(branch, **options)
   end

   # ✅ Correct: forwards all positional arguments
   def branch_new(branch, start_point = nil, options = {})
     Git::Commands::Branch::Create.new(self).call(branch, start_point = nil, **options)
   end
   ```

   Review the command class's `#call` signature when writing the adapter to ensure
   no arguments are lost in translation.

8. **Static flags are always output first—define them first for readability**

   The Arguments DSL outputs arguments in this order: static flags → dynamic flags
   (in definition order) → positionals. For readability, define `static` flags first
   to match the actual output order:

   ```ruby
   # ✅ Preferred: static first matches output order
   ARGS = Arguments.define do
     static '--delete'                    # Always first in output
     flag %i[force f], args: '--force'
     flag %i[remotes r], args: '--remotes'
     positional :branch_names, variadic: true, required: true
   end

   # ❌ Less clear: static at end is misleading
   ARGS = Arguments.define do
     flag %i[force f], args: '--force'
     static '--delete'                    # Still output first, but confusing
     positional :branch_names, variadic: true, required: true
   end
   ```

9. **Use `%i[long short]` array syntax for flag aliases**

   When defining flags with short aliases, use the `%i[]` symbol array syntax with
   the long (canonical) name first. This provides a clean, consistent pattern:

   ```ruby
   flag %i[force f], args: '--force'      # force: true OR f: true
   flag %i[remotes r], args: '--remotes'  # remotes: true OR r: true
   flag %i[quiet q], args: '--quiet'      # quiet: true OR q: true
   ```

   The first symbol becomes the primary name used in documentation and error
   messages; subsequent symbols are aliases.

10. **Consider variadic support in adapter methods when command supports it**

    When a command class supports variadic positional arguments (e.g., deleting
    multiple branches), consider whether the `Git::Lib` adapter should expose this
    capability:

    ```ruby
    # Command class supports multiple branches
    def call(*, **)  # variadic positional
      args = ARGS.build(*, **)
      @execution_context.command('branch', *args)
    end

    # ❌ Adapter only accepts single branch
    def branch_delete(branch, options = {})
      Git::Commands::Branch::Delete.new(self).call(branch, **options)
    end

    # ✅ Adapter exposes variadic capability
    def branch_delete(*branches, **options)
      options = { force: true }.merge(options)
      Git::Commands::Branch::Delete.new(self).call(*branches, **options)
    end
    ```

    This allows callers to delete multiple branches efficiently in one git command.

- **1. Migrate the First Command (`add`)**:

  - **Write Unit Tests First**: Write comprehensive RSpec unit tests for the
    *proposed* `Git::Commands::Add` class. These tests will fail initially because
    the class doesn't exist yet. The tests should be fast and mock an object with a
    `command` method that returns stdout strings.

  - **Create Command Class**: Implement `Git::Commands::Add` to make the tests pass.
    This class will contain all the logic for building git add arguments and parsing
    its output. It will accept an execution context (any object responding to
    `command`) in its constructor and call `@execution_context.command('add', *args,
    **opts)` to execute commands.

  - **Delegate from `Git::Lib`**: Modify the `add` method within the existing
    `Git::Lib` class. Instead of containing the implementation, it will now
    instantiate and call the new `Git::Commands::Add` object, passing `self` as the
    context.

  - **Verify**: Run the full test suite (both TestUnit and RSpec). The existing tests
    for `g.add` should still pass, but they will now be executing the new, refactored
    code.

- **2. Incrementally Migrate Remaining Commands:**

  - Repeat the process from the previous step for all other commands, one by one or
    in logical groups (e.g., all `diff` related commands, then all `log` commands).

  - For each command (`add`, `commit`, `log`, `diff`, `status`, etc.):

    1. Create the corresponding Git::Commands::* class.

    2. Write isolated RSpec unit tests for the new class.

    3. Change the method in Git::Lib to delegate to the new command object.

    4. Run the full test suite to ensure no regressions have been introduced.

### Command Migration Checklist

The following tracks the migration status of commands from `Git::Lib` to
`Git::Commands::*` classes.

**Reference implementations** (use these as templates):

- Simple command: `lib/git/commands/add.rb` + `spec/git/commands/add_spec.rb`
- Command with output parsing: `lib/git/commands/fsck.rb` +
  `spec/git/commands/fsck_spec.rb`
- Command with complex options: `lib/git/commands/clone.rb` +
  `spec/git/commands/clone_spec.rb`

#### ✅ Migrated Commands

| Git::Lib Method | Command Class | Spec | Git Command |
| --------------- | ------------- | ---- | ----------- |
| `add` | `Git::Commands::Add` | `spec/git/commands/add_spec.rb` | `git add` |
| `clone` | `Git::Commands::Clone` | `spec/git/commands/clone_spec.rb` | `git clone` |
| `commit` | `Git::Commands::Commit` | `spec/git/commands/commit_spec.rb` | `git commit` |
| `fsck` | `Git::Commands::Fsck` | `spec/git/commands/fsck_spec.rb` | `git fsck` |
| `init` | `Git::Commands::Init` | `spec/git/commands/init_spec.rb` | `git init` |
| `mv` | `Git::Commands::Mv` | `spec/git/commands/mv_spec.rb` | `git mv` |
| `reset` | `Git::Commands::Reset` | `spec/git/commands/reset_spec.rb` | `git reset` |
| `rm` | `Git::Commands::Rm` | `spec/git/commands/rm_spec.rb` | `git rm` |
| `clean` | `Git::Commands::Clean` | `spec/git/commands/clean_spec.rb` | `git clean` |
| `branches_all` | `Git::Commands::Branch::List` | `spec/git/commands/branch/list_spec.rb` | `git branch --list` |
| `branch_new` | `Git::Commands::Branch::Create` | `spec/git/commands/branch/create_spec.rb` | `git branch <name>` |
| `branch_delete` | `Git::Commands::Branch::Delete` | `spec/git/commands/branch/delete_spec.rb` | `git branch --delete` |

#### ⏳ Commands To Migrate

Commands are listed in recommended migration order within each group. Migrate in
order: Basic Snapshotting → Branching & Merging → etc.

**Basic Snapshotting**:

- [x] `rm` → `Git::Commands::Rm` — `git rm`
- [x] `mv` → `Git::Commands::Mv` — `git mv`
- [x] `commit` → `Git::Commands::Commit` — `git commit`
- [x] `reset` → `Git::Commands::Reset` — `git reset`
- [x] `clean` → `Git::Commands::Clean` — `git clean`

**Branching & Merging:**

- [x] `branches_all` → `Git::Commands::Branch::List` — `git branch --list` (returns `BranchInfo` value objects)
- [x] `branch_new` → `Git::Commands::Branch::Create` — `git branch <name> [start-point]`
- [x] `branch_delete` → `Git::Commands::Branch::Delete` — `git branch --delete`
- [ ] `checkout` / `checkout_file` → `Git::Commands::Checkout` — `git checkout`
- [ ] `merge` / `merge_base` → `Git::Commands::Merge` — `git merge`
- [ ] `tag` → `Git::Commands::Tag` — `git tag`
- [ ] `stash_save` / `stash_apply` → `Git::Commands::Stash` — `git stash`

**Inspection & Comparison:**

- [ ] `log_commits` / `full_log_commits` → `Git::Commands::Log` — `git log`
- [ ] `diff_full` / `diff_stats` / `diff_path_status` / `diff_index` →
  `Git::Commands::Diff` — `git diff`
- [ ] `show` → `Git::Commands::Show` — `git show`
- [ ] `describe` → `Git::Commands::Describe` — `git describe`
- [ ] `grep` → `Git::Commands::Grep` — `git grep`
- [ ] `ls_files` → `Git::Commands::LsFiles` — `git ls-files`
- [ ] `ls_tree` / `full_tree` / `tree_depth` → `Git::Commands::LsTree` — `git
  ls-tree`

**Sharing & Updating:**

- [ ] `fetch` → `Git::Commands::Fetch` — `git fetch`
- [ ] `pull` → `Git::Commands::Pull` — `git pull`
- [ ] `push` → `Git::Commands::Push` — `git push`
- [ ] `remote_add` / `remote_remove` / `remote_set_url` / `remote_set_branches` →
  `Git::Commands::Remote` — `git remote`
- [ ] `ls_remote` → `Git::Commands::LsRemote` — `git ls-remote`

**Patching:**

- [ ] `apply` / `apply_mail` → `Git::Commands::Apply` — `git apply` / `git am`
- [ ] `revert` → `Git::Commands::Revert` — `git revert`

**Plumbing:**

- [ ] `rev_parse` → `Git::Commands::RevParse` — `git rev-parse`
- [ ] `name_rev` → `Git::Commands::NameRev` — `git name-rev`
- [ ] `cat_file_*` → `Git::Commands::CatFile` — `git cat-file`
- [ ] `read_tree` → `Git::Commands::ReadTree` — `git read-tree`
- [ ] `commit_tree` → `Git::Commands::CommitTree` — `git commit-tree`
- [ ] `update_ref` → `Git::Commands::UpdateRef` — `git update-ref`
- [ ] `checkout_index` → `Git::Commands::CheckoutIndex` — `git checkout-index`
- [ ] `archive` → `Git::Commands::Archive` — `git archive`

**Setup & Config:**

- [ ] `config_get` / `config_set` / `global_config_*` / `config_list` →
  `Git::Commands::Config` — `git config`

**Other:**

- [ ] `worktree_add` / `worktree_remove` → `Git::Commands::Worktree` — `git worktree`
- [ ] `branch_contains` → (part of `Git::Commands::Branch`)
- [ ] `change_head_branch` → `Git::Commands::SymbolicRef` — `git symbolic-ref`
- [ ] `repository_default_branch` → (part of `Git::Commands::LsRemote`)

## Phase 3: Refactoring the Public Interface

***Goal**: Switch the public-facing classes to use the new architecture directly,
breaking the final ties to the old implementation.*

1. **Refactor Factory Methods**:

   - Modify the factory methods in the top-level `Git` module (`.open`, `.clone`,
     etc.).

   - These methods will now be responsible for creating an instance of the
     appropriate `Git::ExecutionContext` subclass and injecting it:
     - `Git.init` and `Git.clone`: Use `Git::GlobalContext` to run the command, then
       open the repository
     - `Git.open` and `Git.bare`: Create `Git::RepositoryContext` and inject it into
       `Git::Repository`

    The return value of these factories will now be a `Git::Repository` instance, not
    a `Git::Base` instance.

2. **Implement the Facade**:

   - Populate the `Git::Repository` class with the simple, one-line facade methods
     that delegate to the `Command` objects. For example:

        ```ruby
        def commit(msg)
          Git::Commands::Commit.new(@execution_context, msg).run
        end
        ```

   - Organize these facade methods into modules as planned
     (`lib/git/repository/branching.rb`, etc.) and include them in the main
     `Git::Repository` class.

3. **Deprecate and Alias `Git::Base`**:

   - To maintain a degree of backward compatibility through the transition, make
     `Git::Base` a deprecated constant that points to `Git::Repository`.

        ```ruby
        Git::Base = ActiveSupport::Deprecation::DeprecatedConstantProxy.new(
          'Git::Base',
          'Git::Repository',
          Git::Deprecation
        )
        ```

   - This ensures that any user code checking `is_a?(Git::Base)` will not immediately
     break.

## Phase 4: Final Cleanup and Release Preparation

***Goal**: Remove all old code, finalize the test suite, and prepare for the v5.0.0
release.*

1. **Remove Old Code**:

   - Delete the `Git::Lib` class entirely.

   - Delete the `Git::Base` class file and remove the deprecation proxy.

   - Remove any other dead code that was part of the old implementation.

2. **Finalize Test Suite**:

   - Convert any remaining, relevant TestUnit tests to RSpec.

   - Remove the `test-unit` dependency from the `Gemfile`.

   - Ensure the RSpec suite has comprehensive coverage for the new architecture.

3. **Update Documentation**:

   - Thoroughly document the new public API (`Git`, `Git::Repository`, etc.).

   - Mark all internal classes (`ExecutionContext`, `Commands`, `*Path`) with `@api
     private` in the YARD documentation.

   - Update the `README.md` and create a `UPGRADING.md` guide explaining the breaking
     changes for v5.0.0.
