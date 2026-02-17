# Proposed Redesigned Architecture for the Git Gem

This document outlines a proposal for a major redesign of the git gem, targeted for
version 5.0.0. The goal of this redesign is to modernize the gem's architecture,
making it more robust, maintainable, testable, and easier for new contributors to
understand.

- [1. Motivation](#1-motivation)
- [2. The New Architecture: A Three-Layered Approach](#2-the-new-architecture-a-three-layered-approach)
- [3. Key Design Principles](#3-key-design-principles)
  - [A. Clear Public vs. Private API](#a-clear-public-vs-private-api)
  - [B. Dependency Injection](#b-dependency-injection)
  - [C. Immutable Return Values](#c-immutable-return-values)
  - [D. Eliminate Custom Path Classes](#d-eliminate-custom-path-classes)
- [4. Testing Strategy Overhaul](#4-testing-strategy-overhaul)
- [5. Impact on Users: Breaking Changes for v5.0.0](#5-impact-on-users-breaking-changes-for-v500)

## 1. Motivation

The current architecture, while functional, has several design issues that have
accrued over time, making it difficult to extend and maintain.

- **Unclear Separation of Concerns**: The responsibilities of the `Git`, `Git::Base`,
  and `Git::Lib` classes are "muddy." `Git::Base` acts as both a high-level API and a
  factory, while `Git::Lib` contains a mix of low-level command execution and
  high-level output parsing.

- **Circular Dependency**: A key architectural flaw is the circular dependency
  between `Git::Base` and `Git::Lib`. `Git::Base` creates and depends on `Git::Lib`,
  but `Git::Lib`'s constructor requires an instance of Git::Base to access
  configuration. This tight coupling makes the classes difficult to reason about and
  test in isolation.

- **Undefined Public API**: The boundary between the gem's public API and its
  internal implementation is not clearly defined. This has led some users to rely on
  internal classes like `Git::Lib`, making it difficult to refactor the internals
  without introducing breaking changes.

- **Slow and Brittle Test Suite**: The current tests rely heavily on filesystem
  fixtures and shelling out to the git command line for almost every test case. This
  makes the test suite slow and difficult to maintain, especially on non-UNIX
  platforms.

## 2. The New Architecture: A Three-Layered Approach

The new design is built on a clear separation of concerns, dividing responsibilities
into three distinct layers: a Facade, an Execution Context, and Command Objects.

1. The Facade Layer: Git::Repository

    This is the primary public interface that users will interact with.

    **Renaming**: `Git::Base` will be renamed to `Git::Repository`. This name is more
    descriptive and intuitive.

    **Responsibility**: The facade layer is responsible for:

    1. **Managing the Execution Context**: Holding and providing access to the
       configured execution context for command execution.

    2. **Pre-processing Arguments**: Transforming user-provided arguments to fit the
       command API (e.g., path expansion, Ruby-idiomatic defaults).

    3. **Collecting Data**: Gathering additional information before or after command
       execution that may be needed for building response objects.

    4. **Calling Commands**: Invoking one or more `Git::Commands::*` classes as
       needed to fulfill the user's request.

    5. **Building Rich Response Objects**: Using Parser classes (e.g., `Git::Parsers::Diff`)
       and Result class factory methods (e.g., `BranchDeleteResult.from(...)`) to
       assemble meaningful return values from raw command output.

    **Facade as Orchestration Layer**: The facade layer acts as glue and orchestration
    code. It coordinates the flow between components but contains minimal domain logic
    itself. The actual implementation work is delegated to specialized components:

    - **Commands** → handle argument building and execution, return `CommandLineResult`
    - **Parsers** → transform stdout/stderr into structured data
    - **Result classes** → assemble final objects via factory methods

    This separation means the facade's role is to *wire things together* (which
    component to call, in what order, with what inputs) rather than *implement
    behavior* (how to parse output, which arguments are valid). This keeps each
    component focused, independently testable, and reusable.

    **Scalability**: To prevent this class from growing too large, its methods will
    be organized into logical modules (e.g., `Git::Repository::Branching`,
    `Git::Repository::History`) which are then included in the main class. This keeps
    the core class definition small and the features well-organized. These categories
    will be inspired by (but not slavishly follow) the git command line reference in
    [this page](https://git-scm.com/docs).

2. The Execution Layer: Git::ExecutionContext

    This is the low-level, private engine for running commands.

    **Renaming**: `Git::Lib` will be renamed to `Git::ExecutionContext`.

    **Responsibility**: Its purpose is to provide a configured `command` method for
    executing git commands. This method wraps `Git::CommandLine` with essential
    functionality including default options (normalize, chomp, timeout), option
    validation, and a simplified interface that returns stdout. The execution context
    has no knowledge of any specific git command's arguments or output.

    **Two Context Types**: The execution layer will consist of an abstract base class
    with two concrete implementations:

    - **Git::GlobalContext**: For commands that do not require an existing repository
      (`init`, `clone`, `config --global`, `version`). These commands execute in a
      clean environment with no repository paths set. In the specific case of
      `init`/`clone`, the command itself runs in `GlobalContext`, but on success it
      yields a newly created `Git::Repository` instance backed by a
      `Git::RepositoryContext`.

    - **Git::RepositoryContext**: For repository-bound commands (`add`, `commit`,
      `status`, `log`, etc.). Manages the repository environment (working directory,
      .git path, index file) and provides the ability to override environment
      variables per-command (e.g., unsetting `GIT_INDEX_FILE` for worktree
      mutations).

    The base `ExecutionContext` class provides the common `command` method that wraps
    command execution with defaults, validation, and timeout handling. Subclasses
    implement environment-specific configuration (paths, environment variables) to
    create properly configured command execution contexts.

3. The Command Layer: Git::Commands

    This layer provides a structured interface to individual git commands.

    **New Classes**: For each git operation, a new command class will be created
    within the `Git::Commands` namespace (e.g., `Git::Commands::Commit`,
    `Git::Commands::Diff`).

    **Command Responsibilities**: Each command class is responsible for:

    1. **Defining the Git CLI API**: Using `Arguments.define` to declaratively
       specify the command's accepted arguments. Command parameters should generally
       match the underlying git command's interface to keep this layer thin and
       transparent.

    2. **Binding Arguments**: Exposing bound arguments publicly via the `#bind`
       method, allowing the facade layer to access argument values when needed for
       orchestration or result building.

    3. **Executing the Command**: Running the git command via the execution context
       with any special setup/tweaking for expected results (e.g.,
       `raise_on_failure: false` for partial failures), returning a
       `Git::CommandLineResult`.

    **Note**: Parsing output and building rich response objects is **not** a command
    responsibility. That work belongs in separate Parser classes (e.g., `Git::Parsers::Diff`)
    and Result class factory methods, orchestrated by the Facade layer. See
    [issue #997](https://github.com/ruby-git/ruby-git/issues/997) for the work to
    migrate existing commands that currently parse output.

    **Commands::Base Pattern**: All command classes inherit from `Git::Commands::Base`.
    Implemented in [issue #996](https://github.com/ruby-git/ruby-git/issues/996).

    Simple commands declare `arguments do … end` and provide a YARD shim:

    ```ruby
    class Add < Base
      arguments do
        literal 'add'
        flag_option :all
        flag_option :force
        operand :paths, repeatable: true, default: [], separator: '--'
      end

      # Execute the git add command
      # ...YARD docs...
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
    ```

    Commands with non-zero successful exits declare their accepted range:

    ```ruby
    class Diff::Patch < Base
      arguments do
        literal 'diff'
        literal '--patch'
        # ...
      end

      # git diff exits 1 when differences are found (not an error)
      allow_exit_status 0..1

      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
    ```

    This pattern provides:

    - Declarative argument definition via the class-level `arguments` DSL
    - Behavioral inheritance from `Base` (`#initialize` and `#call`)
    - Unified exit-status handling via `allow_exit_status <Range>` (default `0..0`)
    - Per-command YARD documentation via `def call(...) = super` shim
    - Automatic execution option forwarding (e.g., `timeout:`) via `Bound#execution_options`

    **Method Return Values**:

    - `#call` → Returns `Git::CommandLineResult` (stdout, stderr, status)
    - `#args_definition` → Returns the frozen `Arguments` instance (class-level metadata)

    **No Bind/Call Split**: Arguments are bound as a local variable inside `Base#call`.
    Commands remain stateless beyond `@execution_context` — there is no separate `#bind`
    method. If facade-layer access to bound argument values is needed in the future,
    a `#bind` method can be added as a backward-compatible addition. See the design
    rationale in [issue #996](https://github.com/ruby-git/ruby-git/issues/996).

    **Migration Strategy: Git::Lib as Adapter Layer**

    During the migration to this architecture, `Git::Lib` methods serve as **adapters**
    between the legacy public interface and the new `Git::Commands::*` classes. This
    separation ensures backward compatibility while enabling incremental migration:

    - **Legacy Interface Acceptance**: `Git::Lib` methods continue to accept the
      historical interface—positional arguments, deprecated options, and quirky
      parameter names.

    - **Interface Translation**: The adapter converts legacy patterns to the clean
      `Git::Commands::*` API (e.g., positional `message` → `:message` keyword,
      `:no_gpg_sign => true` → `:gpg_sign => false`).

    - **Deprecation Handling**: Warnings about deprecated options are issued in the
      adapter layer before delegating, ensuring users are informed even if they make
      other errors.

    - **Clean Command Classes**: `Git::Commands::*` classes remain free of legacy
      baggage with a consistent, modern API.

    - **Result Building**: The adapter layer is responsible for transforming
      `CommandLineResult` into rich response objects using Parser classes and Result
      factories. Commands return raw results; adapters build domain objects.

    Once all commands are migrated and deprecation periods end, the adapter logic can
    be simplified or moved to the new facade layer (`Git::Repository`).

    **Arguments DSL**: To standardize argument building across commands, a declarative
    `Git::Commands::Arguments` DSL is provided. This allows each command to define its
    accepted arguments in a clear, self-documenting way:

    ```ruby
    ARGS = Git::Commands::Arguments.define do
      flag_option :force                    # --force when true
      flag_option :all                      # --all when true
      value_option :branch                  # --branch <value>
      value_option :config, repeatable: true  # --config <v1> --config <v2>
      flag_option :single_branch, negatable: true  # --single-branch / --no-single-branch
      custom_option(:depth) { |v| ['--depth', v.to_i] }
      operand :paths, repeatable: true, separator: '--'
    end
    ```

    The DSL supports several option types (`flag_option`, `value_option`, `flag_or_value_option`, `literal`,
    `custom_option`, `execution_option`) and positional arguments, each with various modifiers. See
    [Git::Commands::Arguments](../lib/git/commands/arguments.rb) for full documentation.

    **Interface Convention**: With the `Base` pattern, all commands use
    `def call(...) = super` as a YARD documentation shim. `Base#call` handles
    argument binding and execution automatically; defaults defined in the DSL
    (e.g., `operand :paths, default: []`) are applied during binding, so no manual
    default checking is needed:

    ```ruby
    # All commands: YARD shim delegates to Base#call
    def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    ```

    The facade layer (`Git::Base`, `Git::Lib`) handles translation from the public API
    (which may accept single values or arrays) using `*Array(paths)`.

    **Return Value Convention**: The `#call` method returns `Git::CommandLineResult`
    by default. This is the standard return type for commands, containing stdout,
    stderr, and status information.

    **Important**: Rich objects (`StashInfo`, `BranchInfo`, `BranchDeleteResult`,
    etc.) are built by the **Facade layer** (currently `Git::Lib`, eventually
    `Git::Repository`), not by commands. The facade layer uses:

    - **Parser classes** (e.g., `Git::Parsers::Diff`, `Git::Parsers::Stash`) to transform raw
      stdout/stderr into structured data
    - **Result class factory methods** (e.g., `BranchDeleteResult.from(...)`) to
      assemble final objects from parsed data

    This separation keeps commands focused on execution and the facade responsible
    for building meaningful return values:

    ```ruby
    # Command layer: returns CommandLineResult
    class Git::Commands::Stash::List < Base
      arguments do
        literal 'stash'
        literal 'list'
        # ...
      end

      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end

    # Facade layer: builds rich objects
    def stashes
      result = Git::Commands::Stash::List.new(self).call
      StashListParser.parse(result.stdout).map { |info| Stash.new(self, info) }
    end
    ```

    **Naming Convention for Return Types**: Use the `-Info` suffix for data objects
    representing git entities (e.g., `TagInfo`, `BranchInfo`, `StashInfo`), and use
    `Result` for operation outcomes (e.g., `FsckResult`, `TagDeleteResult`).

    **Handling Complexity**: For commands with multiple behaviors (like git diff), we
    can use specialized subclasses (e.g., Git::Commands::Diff::NameStatus,
    Git::Commands::Diff::Stats) to keep each class focused on a single
    responsibility.

## 3. Key Design Principles

The new architecture will be guided by the following modern design principles.

### A. Clear Public vs. Private API

A primary goal of this redesign is to establish a crisp boundary between the public
API and internal implementation details.

- **Public Interface**: The public API will consist of the `Git` module (for
  factories), the `Git::Repository` class, and the specialized data/query objects it
  returns (e.g., `Git::Log`, `Git::Status`, `Git::Object::Commit`).

- **Private Implementation**: All other components, including `Git::ExecutionContext`
  and all classes within the `Git::Commands` namespace, will be considered internal.
  They will be explicitly marked with the `@api private` YARD tag to discourage
  external use.

### B. Dependency Injection

The circular dependency will be resolved by implementing a clear, one-way dependency
flow.

1. The factory methods (`Git.open`, `Git.clone`) will create and configure an
   instance of the appropriate `Git::ExecutionContext` subclass (`Git::GlobalContext`
   for `init`/`clone`, `Git::RepositoryContext` for `open`/`bare`).

2. This context instance will then be wired into the system in two ways:
   - For commands that run before a repository exists (e.g., `Git::Commands::Init`,
     `Git::Commands::Clone`), the context will be passed directly into the
     constructor of the command object.
   - For repository-scoped commands (e.g., `Git::Commands::Log`,
     `Git::Commands::Status`), the context will be injected once into the
     `Git::Repository` constructor (for `open`/`bare`), and those command objects
     will access the context through the repository instance rather than receiving it
     directly.

This decouples the `Repository` from its execution environment, making the system
more modular and easier to test.

### C. Immutable Return Values

To create a more predictable and robust API, methods will return structured,
immutable data objects instead of raw strings or hashes.

This will be implemented using `Data.define` or simple, frozen `Struct`s.

For example, instead of returning a raw string, `repo.config('user.name')` will
return a `Git::Config::Value` object containing the key, value, scope, and source
path.

**Value Objects vs Domain Objects**: A critical architectural distinction exists
between:

- **Value objects** (e.g., `Git::BranchInfo`): Pure data returned by commands. No
  repository context, no operations, no dependencies. Created by `Data.define`.
  These are the return types of `Git::Commands::*` classes.

- **Domain objects** (e.g., `Git::Branch`): Rich objects with operations that require
  repository context (`@base`). These wrap value objects and provide methods like
  `checkout`, `merge`, `delete`.

Commands return value objects. The facade layer (`Git::Repository`) or collection
classes (`Git::Branches`) convert them to domain objects when needed. This separation
keeps commands pure and testable while domain objects provide the rich API users
expect.

**Note on `Data.define` constraints**: Objects created with `Data.define` are frozen.
This means memoization patterns like `@cached ||= ...` will raise `FrozenError`.
Either accept repeated computation or use a different approach for caching.

### D. Eliminate Custom Path Classes

The existing path wrapper classes (`Git::WorkingDirectory`, `Git::Index`,
`Git::Repository`, and their base class `Git::Path`) provide minimal value over
Ruby's standard library. These classes will be eliminated entirely.

- `Git::Path` -> **Removed**
- `Git::WorkingDirectory` -> **Removed**
- `Git::Index` -> **Removed**
- `Git::Repository` (the path class) -> **Removed**

Instead, the `dir`, `repo`, and `index` accessors on the repository object will
return `Pathname` objects directly. This provides:

- Built-in `readable?` and `writable?` methods (preserving existing API)
- Automatic path expansion and normalization
- Seamless string coercion via `to_s` and `to_path`
- No custom classes to maintain

**Breaking change:** Code using `.path` (e.g., `g.dir.path`) must change to `.to_s`
or use the `Pathname` directly. String interpolation and most other uses will
continue to work unchanged.

## 4. Testing Strategy Overhaul

The test suite will be modernized to be faster, more reliable, and easier to work
with.

- **Migration to RSpec**: The entire test suite will be migrated from TestUnit to
  RSpec to leverage its modern tooling and expressive DSL.

- **Layered Testing**: A three-layered testing strategy will be adopted:

  1. **Unit Tests**: The majority of tests will be fast, isolated unit tests for the
     `Command` classes, using mock `ExecutionContexts`.

  2. **Integration Tests**: A small number of integration tests will verify that
     `ExecutionContext` correctly interacts with the system's `git` binary.

  3. **Feature Tests**: A minimal set of high-level tests will ensure the public
     facade on `Git::Repository` works end-to-end.

- **Reduced Filesystem Dependency**: This new structure will dramatically reduce the
  suite's reliance on slow and brittle filesystem fixtures.

## 5. Impact on Users: Breaking Changes for v5.0.0

This redesign is a significant undertaking and will be released as version 5.0.0. It
includes several breaking changes that users will need to be aware of when upgrading.

- **`Git::Lib` is Removed**: Any code directly referencing `Git::Lib` will break.

- **g.lib Accessor is Removed**: The `.lib` accessor on repository objects will be
  removed.

- **Internal Methods Relocated**: Methods that were previously accessible via g.lib
  will now be private implementation details of the new command classes and will not
  be directly reachable.

Users should only rely on the newly defined public interface.
