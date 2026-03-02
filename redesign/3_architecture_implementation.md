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
| Phase 2 | 🔄 In Progress | Migrating commands (33/~50 commands migrated) |
| Phase 3 | ⏳ Not Started | Refactoring public interface |
| Phase 4 | ⏳ Not Started | Final cleanup and release |

### Next Task

**Migrate `log_commits` / `full_log_commits`** → `Git::Commands::Log`

#### Workflow

1. **Analyze**: Read the existing implementation in `lib/git/lib.rb` (search for `def
  log_commits` and `def full_log_commits`). Understand all options and edge cases.

2. **Design**: Create command class following the pattern in
   `lib/git/commands/branch/delete.rb`. The interface for `#call` should only include
   options relevant to the command being implemented.

3. **TDD**: Write spec file *before* implementing:
   - Test every option using separate `context` blocks
   - Mock the execution context with `double('ExecutionContext')`
   - Verify argument building matches expected git CLI args
   - Unit tests go in `spec/unit/git/commands/`
   - Optionally add integration tests in `spec/integration/` to verify behavior
     against real git (see CONTRIBUTING.md for integration test guidelines). Only
     add essential integration tests for edge cases and testing that the assumptions
     for git output used in unit tests are correct.

4. **Implement**:
   - Use `Git::Commands::Arguments.define` DSL for argument handling
   - Include comprehensive YARD documentation (see format below)
   - Mark class with `@api private`

   **YARD Documentation Format for `#call` methods:**

   ```ruby
   # Execute the git example command
   #
   # @overload call(operand_arg, *repeatable_args, **options)
   #
   #   @param operand_arg [String] Description of the operand (positional argument)
   #
   #   @param repeatable_args [Array<String>] Description of repeatable arguments
   #
   #   @param options [Hash] command options
   #
   #   @option options [Boolean] :force (nil) Description. Alias: :f
   #
   #   @option options [String] :message (nil) Description
   #
   # @return [String] the command output
   #
   # @raise [Git::FailedError] if the command fails
   #
   def call(*, **)
   ```

   **Important**: Keep empty comment lines between each yard tag

   **Note on Return Types**: Commands return `Git::CommandLineResult` by default.
   If the command output needs to be parsed into structured data, create a Parser
   class (see step 4a below).

4a. **Create Parser Classes** (when output needs transformation):

   If the command produces output that needs to be parsed into structured data,
   create a Parser class or module in `lib/git/parsers/` following existing patterns.
   For example, see `Git::Parsers::Diff` which uses nested classes for different
   output formats:

   ```ruby
   # lib/git/parsers/diff.rb (existing pattern)
   module Git
     module Parsers
       module Diff
         # Nested parser for --numstat format
         class Numstat
           def self.parse(output)
             output.lines.map { |line| parse_line(line) }
           end
         end

         # Nested parser for --raw format
         class Raw
           def self.parse(output)
             # Parse into DiffFileRawInfo value objects
           end
         end
       end
     end
   end
   ```

   Parser classes/modules should:
   - Be stateless (class methods or module methods)
   - Return value objects (e.g., `DiffFileNumstatInfo`, `BranchInfo`)
   - Be independently testable
   - Live outside the Commands namespace (they're reusable utilities)

5. **Delegate**: Update related methods in `Git::Lib` to delegate to the new class(es).
   Here is an example pattern for facade methods in `Git::Lib`:

   ```ruby
   # Example pattern (aspirational - specific classes/methods may vary)
   def branch_new(branch_name, options = {})
     result = Git::Commands::Branch::Create.new(self).call(branch_name, **options)
     # Facade builds rich return value from CommandLineResult
     # Using a Result factory method or Parser class
     result.stdout  # Or parse into a value object as needed
   end

   def branch_delete(branch_name, options = {})
     result = Git::Commands::Branch::Delete.new(self).call(branch_name, **options)
     # Facade parses output into result object using existing parser
     Git::BranchDeleteResult.parse(result.stdout)
   end
   ```

   Note: `Git::Lib` methods may accept an options hash for backward compatibility,
   but they must convert it to keyword arguments when calling the command class
   using `**options`.

   Note: `Git::Lib` methods must remain backward compatible. The facade layer is
   responsible for building rich response objects from `CommandLineResult` using
   Parser classes and Result factories.

6. **Verify**:
  - `bundle exec rspec spec/unit/git/commands/log_spec.rb` — new tests pass
   - `bundle exec rspec` — all RSpec tests pass
   - `bundle exec rake test` — legacy TestUnit tests pass
   - `bundle exec rubocop` — no lint errors
   - `bundle exec yard` — no yardoc errors

   To run a single legacy test: `bundle exec bin/test test_<name>` (e.g., `bundle
   exec bin/test test_branch`)

7. **Update Checklist**: Move the command from "Commands To Migrate" to "Migrated
   Commands" table in this document, and update the "Next Task" section to point to
   the next command in the list.

#### Reference Files

- Pattern to follow: `lib/git/commands/commit.rb` + `spec/unit/git/commands/commit_spec.rb`
- Namespace example: `lib/git/commands/checkout/branch.rb`
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
anonymous repeatable arguments for both positional and keyword arguments:

```ruby
# ✅ Preferred: anonymous forwarding with ARGS.bind
# Note: defaults defined in the DSL (e.g., `positional :paths, default: ['.']`)
# are applied automatically by ARGS.bind
def call(*, **)
  @execution_context.command('add', *ARGS.bind(*, **))
end

# ✅ Acceptable: assign bound_args when you need to access argument values
def call(*, **)
  bound_args = ARGS.bind(*, **)
  output = @execution_context.command('diff', *bound_args).stdout
  Parsers::Diff.parse(output, include_dirstat: !bound_args.dirstat.nil?)
end

# ❌ Incorrect: options hash parameter
def call(paths = '.', options = {})
  @execution_context.command('add', *ARGS.bind(*Array(paths), **options))
end
```

This convention provides:

- **Better IDE support**: Editors can autocomplete and validate keyword arguments
- **Clearer method signatures**: The `#call` signature documents available options
- **Centralized validation**: `ARGS.bind` enforces allowed options and raises errors for unknown or invalid keywords
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
   negatable_flag_or_inline_value_option :track
   # track: nil     → (omitted)
   # track: true    → --track
   # track: false   → --no-track
   # track: 'inherit' → --track=inherit

   # ❌ Avoid: separate definitions require conflict management
   flag_option :track
   flag_option :no_track
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

8. **Arguments are rendered in definition order**

   The Arguments DSL outputs arguments in the exact order they are defined,
   regardless of type. This allows precise control over argument positioning,
   which is important for commands like `git checkout` where `--` must appear
   between options and pathspecs:

   ```ruby
   # Arguments render in definition order
   ARGS = Arguments.define do
     flag_option :force
     operand :tree_ish
     literal '--'
     operand :paths, repeatable: true
   end
   # build('HEAD', 'file.txt', force: true) => ['--force', 'HEAD', '--', 'file.txt']

   # Common pattern: static flags first for subcommands like branch --delete
   ARGS = Arguments.define do
     literal '--delete'
     flag_option %i[force f], args: '--force'
     operand :branch_names, repeatable: true, required: true
   end
   # build('feature', force: true) => ['--delete', '--force', 'feature']
   ```

9. **Use `%i[long short]` array syntax for flag aliases**

   When defining flags with short aliases, use the `%i[]` symbol array syntax with
   the long (canonical) name first. This provides a clean, consistent pattern:

   ```ruby
   flag_option %i[force f], args: '--force'      # force: true OR f: true
   flag_option %i[remotes r], args: '--remotes'  # remotes: true OR r: true
   flag_option %i[quiet q], args: '--quiet'      # quiet: true OR q: true
   ```

   The first symbol becomes the primary name used in documentation and error
   messages; subsequent symbols are aliases.

10. **Consider repeatable support in adapter methods when command supports it**

    When a command class supports repeatable positional arguments (e.g., deleting
    multiple branches), consider whether the `Git::Lib` adapter should expose this
    capability:

    ```ruby
    # Command class supports multiple branches
    def call(*, **)  # repeatable positional
      @execution_context.command('branch', *ARGS.bind(*, **))
    end

    # ❌ Adapter only accepts single branch
    def branch_delete(branch, options = {})
      Git::Commands::Branch::Delete.new(self).call(branch, **options)
    end

    # ✅ Adapter exposes repeatable capability
    def branch_delete(*branches, **options)
      options = { force: true }.merge(options)
      Git::Commands::Branch::Delete.new(self).call(*branches, **options)
    end
    ```

    This allows callers to delete multiple branches efficiently in one git command.

11. **Use `def call(*, **)` when Arguments DSL handles all validation**

    When using the Arguments DSL with patterns where optional positionals precede
    required ones (matching Ruby's parameter binding semantics), prefer the
    catch-all signature `def call(*, **)` and let `ARGS.bind(*, **)` handle
    all validation:

    ```ruby
    # git branch -m [<old-branch>] <new-branch>
    ARGS = Arguments.define do
      literal '--move'
      flag_option :force
      operand :old_branch                  # optional (no required: true)
      operand :new_branch, required: true  # required
    end.freeze

    # ✅ Preferred: let ARGS.bind handle validation
    def call(*, **)
      @execution_context.command('branch', *ARGS.bind(*, **))
    end

    # ❌ Avoid: explicit params trigger RuboCop Style/OptionalArguments
    def call(old_branch = nil, new_branch, **)
      # ...
    end
    ```

    The Arguments DSL with Ruby-like positional allocation correctly fills
    required parameters before optional ones, so `move.call('new-name')` works
    as expected.

12. **Arguments DSL supports Ruby-like positional parameter allocation**

    The `PositionalAllocator` in the Arguments DSL follows Ruby's method parameter
    binding semantics. When optional positionals precede required ones, values are
    allocated to required parameters first:

    ```ruby
    # Ruby method: def foo(a = 'default', b); end
    # foo('value') → a='default', b='value' (required b filled first)

    # Arguments DSL equivalent:
    operand :old_branch                  # optional
    operand :new_branch, required: true  # required

    # Single value: ARGS.bind('new-name')
    # → old_branch=nil, new_branch='new-name'

    # Two values: ARGS.bind('old-name', 'new-name')
    # → old_branch='old-name', new_branch='new-name'
    ```

    This enables command interfaces that match git CLI patterns like
    `git branch -m [<old-branch>] <new-branch>` without awkward workarounds.

13. **Commands layer maps option semantics, not argument ergonomics**

    The Commands layer should strictly mirror git CLI semantics. When git uses
    `--option=value` syntax, the Commands class should use a keyword argument—even
    if a positional would feel more natural in Ruby:

    ```ruby
    # Git CLI: git branch --set-upstream-to=<upstream> [<branch>]
    # ↑ <upstream> is the VALUE of --set-upstream-to option, not a positional

    # ✅ Commands layer: strict CLI mapping
    class SetUpstream
      ARGS = Arguments.define do
        value_option :set_upstream_to, inline: true  # keyword, not positional
        operand :branch_name
      end

      def call(*, **)
        @execution_context.command('branch', *ARGS.bind(*, **))
      end
    end

    # ✅ Higher-layer facade: ergonomic Ruby API (Phase 3)
    # This wrapper belongs in Git::Repository or Git::Branch, NOT in Git::Lib.
    # Git::Lib only adapts methods that existed in v4.3.0.
    def branch_set_upstream(upstream, branch_name = nil)
      SetUpstream.new(@execution_context).call(branch_name, set_upstream_to: upstream)
    end
    ```

    This separation keeps Commands classes predictable (they mirror git 1:1) while
    allowing higher layers to provide intuitive Ruby interfaces. Ergonomic
    transformations—like reordering arguments or converting keywords to
    positionals—belong in higher layers (`Git::Repository`, `Git::Base`, `Git::Branch`),
    not in `Git::Lib` (which only adapts pre-existing methods for backward compatibility).

14. **Use `allow_nil: true` for positional arguments that can be intentionally omitted**

    Some git commands have positional arguments that are semantically present but
    should not appear in the command line. For example, `git checkout -- file.txt`
    restores from the index (no tree-ish), while `git checkout HEAD -- file.txt`
    restores from a commit.

    Use `allow_nil: true` to mark a positional that can accept `nil` as a valid
    "present but empty" value:

    ```ruby
    ARGS = Arguments.define do
      operand :tree_ish, required: true, allow_nil: true
      operand :paths, repeatable: true, separator: '--'
    end

    # Restore from index (tree_ish intentionally nil)
    ARGS.bind(nil, 'file.txt')
    # → ['--', 'file.txt']

    # Restore from commit
    ARGS.bind('HEAD', 'file.txt')
    # → ['HEAD', '--', 'file.txt']
    ```

    Without `allow_nil: true`, passing `nil` would either skip the positional slot
    (causing argument misalignment) or raise a validation error for required
    arguments.

15. **Namespace commands by mode, not just by operation**

    When a git command has fundamentally different modes (not just different
    operations on the same concept), use nested namespaces that reflect the mode:

    ```ruby
    # ✅ Different modes of git checkout → separate namespaces
    Git::Commands::Checkout::Branch  # branch switching, creation
    Git::Commands::Checkout::Files   # file restoration from tree-ish/index

    # ✅ Different operations on same concept → flat namespace with operation suffix
    Git::Commands::Branch::Create
    Git::Commands::Branch::Delete
    Git::Commands::Branch::Move
    ```

    The distinction: `Checkout::Branch` and `Checkout::Files` accept fundamentally
    different arguments and have different semantics. `Branch::Create` and
    `Branch::Delete` operate on the same conceptual entity (a branch) with the same
    core argument (branch name).

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

- Simple command: `lib/git/commands/add.rb` + `spec/unit/git/commands/add_spec.rb`
- Command with output parsing: `lib/git/commands/fsck.rb` +
  `spec/unit/git/commands/fsck_spec.rb`
- Command with complex options: `lib/git/commands/clone.rb` +
  `spec/unit/git/commands/clone_spec.rb`

#### ✅ Migrated Commands

| Git::Lib Method | Command Class | Spec | Git Command |
| --------------- | ------------- | ---- | ----------- |
| `add` | `Git::Commands::Add` | `spec/unit/git/commands/add_spec.rb` | `git add` |
| `clone` | `Git::Commands::Clone` | `spec/unit/git/commands/clone_spec.rb` | `git clone` |
| `commit` | `Git::Commands::Commit` | `spec/unit/git/commands/commit_spec.rb` | `git commit` |
| `fsck` | `Git::Commands::Fsck` | `spec/unit/git/commands/fsck_spec.rb` | `git fsck` |
| `init` | `Git::Commands::Init` | `spec/unit/git/commands/init_spec.rb` | `git init` |
| `mv` | `Git::Commands::Mv` | `spec/unit/git/commands/mv_spec.rb` | `git mv` |
| `reset` | `Git::Commands::Reset` | `spec/unit/git/commands/reset_spec.rb` | `git reset` |
| `rm` | `Git::Commands::Rm` | `spec/unit/git/commands/rm_spec.rb` | `git rm` |
| `clean` | `Git::Commands::Clean` | `spec/unit/git/commands/clean_spec.rb` | `git clean` |
| `branches_all` | `Git::Commands::Branch::List` | `spec/unit/git/commands/branch/list_spec.rb` | `git branch --list` |
| `branch_new` | `Git::Commands::Branch::Create` | `spec/unit/git/commands/branch/create_spec.rb` | `git branch <name>` |
| `branch_delete` | `Git::Commands::Branch::Delete` | `spec/unit/git/commands/branch/delete_spec.rb` | `git branch --delete` |
| N/A (new) | `Git::Commands::Branch::Move` | `spec/unit/git/commands/branch/move_spec.rb` | `git branch --move` |
| `diff_full` | `Git::Commands::Diff::Patch` | `spec/unit/git/commands/diff/patch_spec.rb` | `git diff` (patch format) |
| `diff_stats` | `Git::Commands::Diff::Numstat` | `spec/unit/git/commands/diff/numstat_spec.rb` | `git diff --numstat` |
| `diff_path_status` / `diff_index` | `Git::Commands::Diff::Raw` | `spec/unit/git/commands/diff/raw_spec.rb` | `git diff --raw` |
| `stashes_list` | `Git::Commands::Stash::List` | `spec/unit/git/commands/stash/list_spec.rb` | `git stash list` |
| `stash_save` | `Git::Commands::Stash::Push` | `spec/unit/git/commands/stash/push_spec.rb` | `git stash push` |
| `stash_pop` | `Git::Commands::Stash::Pop` | `spec/unit/git/commands/stash/pop_spec.rb` | `git stash pop` |
| `stash_apply` | `Git::Commands::Stash::Apply` | `spec/unit/git/commands/stash/apply_spec.rb` | `git stash apply` |
| `stash_drop` | `Git::Commands::Stash::Drop` | `spec/unit/git/commands/stash/drop_spec.rb` | `git stash drop` |
| `stash_clear` | `Git::Commands::Stash::Clear` | `spec/unit/git/commands/stash/clear_spec.rb` | `git stash clear` |
| `checkout` / `checkout_file` | `Git::Commands::Checkout::Branch` / `Git::Commands::Checkout::Files` | `spec/unit/git/commands/checkout/branch_spec.rb` / `spec/unit/git/commands/checkout/files_spec.rb` | `git checkout` (branch) / `git checkout` (files) |
| `merge` | `Git::Commands::Merge::Start` | `spec/unit/git/commands/merge/start_spec.rb` | `git merge` |
| N/A (new) | `Git::Commands::Merge::Abort` | `spec/unit/git/commands/merge/abort_spec.rb` | `git merge --abort` |
| N/A (new) | `Git::Commands::Merge::Continue` | `spec/unit/git/commands/merge/continue_spec.rb` | `git merge --continue` |
| N/A (new) | `Git::Commands::Merge::Quit` | `spec/unit/git/commands/merge/quit_spec.rb` | `git merge --quit` |
| N/A (new) | `Git::Commands::Stash::Create` | `spec/unit/git/commands/stash/create_spec.rb` | `git stash create` |
| N/A (new) | `Git::Commands::Stash::Store` | `spec/unit/git/commands/stash/store_spec.rb` | `git stash store` |
| N/A (new) | `Git::Commands::Stash::Branch` | `spec/unit/git/commands/stash/branch_spec.rb` | `git stash branch` |
| N/A (new) | `Git::Commands::Stash::ShowNumstat` | `spec/unit/git/commands/stash/show_numstat_spec.rb` | `git stash show --numstat` |
| N/A (new) | `Git::Commands::Stash::ShowPatch` | `spec/unit/git/commands/stash/show_patch_spec.rb` | `git stash show --patch` |
| N/A (new) | `Git::Commands::Stash::ShowRaw` | `spec/unit/git/commands/stash/show_raw_spec.rb` | `git stash show --raw` |

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
- [x] N/A (new) → `Git::Commands::Branch::Move` — `git branch --move`
- [x] `checkout` / `checkout_file` → `Git::Commands::Checkout::Branch` / `Git::Commands::Checkout::Files` — `git checkout`
- [x] `merge` → `Git::Commands::Merge::Start` — `git merge`
- [x] N/A (new) → `Git::Commands::Merge::Abort` / `Git::Commands::Merge::Continue` / `Git::Commands::Merge::Quit` — `git merge --abort/--continue/--quit`
- [x] `tag` → `Git::Commands::Tag::*` — `git tag` (implemented as `List`, `Create`, `Delete`, and `Verify`)
- [x] `stash_*` → `Git::Commands::Stash::*` — `git stash` (List, Push, Pop, Apply, Drop, Clear, Create, Store, Branch, ShowNumstat, ShowPatch, ShowRaw)

**Inspection & Comparison:**

- [ ] `log_commits` / `full_log_commits` → `Git::Commands::Log` — `git log`
- [x] `diff_full` / `diff_stats` / `diff_path_status` / `diff_index` →
  `Git::Commands::Diff::*` — `git diff` (implemented as `Patch`, `Numstat`, and `Raw`)
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
- [x] `cat_file_*` → `Git::Commands::CatFile::*` — `git cat-file` (implemented as `ObjectContent` and `ObjectMeta`)
- [ ] `read_tree` → `Git::Commands::ReadTree` — `git read-tree`
- [ ] `commit_tree` → `Git::Commands::CommitTree` — `git commit-tree`
- [ ] `update_ref` → `Git::Commands::UpdateRef` — `git update-ref`
- [x] `checkout_index` → `Git::Commands::CheckoutIndex` — `git checkout-index`
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
