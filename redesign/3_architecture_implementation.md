# Implementation Plan for Git Gem Redesign (v5.0.0)

This document outlines a step-by-step plan to implement the proposed architectural redesign. The plan is structured to be incremental, ensuring that the gem remains functional and passes its test suite after each major step. This approach minimizes risk and allows for a gradual, controlled migration to the new architecture.

- [Phase 1: Foundation and Scaffolding](#phase-1-foundation-and-scaffolding)
- [Phase 2: The Strangler Fig Pattern - Migrating Commands](#phase-2-the-strangler-fig-pattern---migrating-commands)
- [Phase 3: Refactoring the Public Interface](#phase-3-refactoring-the-public-interface)
- [Phase 4: Final Cleanup and Release Preparation](#phase-4-final-cleanup-and-release-preparation)

## Phase 1: Foundation and Scaffolding

***Goal**: Set up the new file structure and class names without altering existing logic. The gem will be fully functional after this phase.*

1. **Create New Directory Structure**:

   - Create the new directories that will house the refactored components:

     - `lib/git/commands/`

     - `lib/git/repository/` (for the facade modules)

2. **Eliminate Custom Path Classes**:

   - Remove the path wrapper classes entirely and replace them with `Pathname` objects:

     - Delete `Git::Path` (`lib/git/path.rb`)
     - Delete `Git::WorkingDirectory` (`lib/git/working_directory.rb`)
     - Delete `Git::Index` (`lib/git/index.rb`)
     - Delete `Git::Repository` (`lib/git/repository.rb`) - the path class, not the new facade

   - Update `Git::Base` to store paths as `Pathname` objects directly.

   - Update tests to use `Pathname` methods (`.to_s` instead of `.path`).

   - Run the test suite to ensure everything still works as expected.

3. **Introduce New Core Classes (Empty Shells)**:

   - Create the new `Git::ExecutionContext` class in `lib/git/execution_context.rb`. For now, its implementation can be a simple shell or a thin wrapper around the existing `Git::Lib`.

   - Create the new `Git::Repository` class in `lib/git/repository.rb`. This will initially be an empty class.

4. **Set Up RSpec Environment**:

    - Add rspec dependencies to the `Gemfile` as a development dependency.

    - Configure the test setup to allow both TestUnit and RSpec tests to run concurrently.

## Phase 2: The Strangler Fig Pattern - Migrating Commands

***Goal**: Incrementally move the implementation of each git command from `Git::Lib` to a new `Command` class, strangling the old implementation one piece at a time using a Test-Driven Development workflow.*

- **1. Migrate the First Command (`config`)**:

  - **Write Unit Tests First**: Write comprehensive RSpec unit tests for the *proposed* `Git::Commands::Config` class. These tests will fail initially because the class doesn't exist yet. The tests should be fast and mock the `ExecutionContext`.

  - **Create Command Class**: Implement `Git::Commands::Config` to make the tests pass. This class will contain all the logic for building git config arguments and parsing its output. It will accept an `ExecutionContext` instance in its constructor.

  - **Delegate from `Git::Lib`**: Modify the `config_*` methods within the existing `Git::Lib` class. Instead of containing the implementation, they will now instantiate and call the new `Git::Commands::Config` object.

  - **Verify**: Run the full test suite (both TestUnit and RSpec). The existing tests for `g.config` should still pass, but they will now be executing the new, refactored code.

- **2. Incrementally Migrate Remaining Commands:**

  - Repeat the process from the previous step for all other commands, one by one or in logical groups (e.g., all `diff` related commands, then all `log` commands).

  - For each command (`add`, `commit`, `log`, `diff`, `status`, etc.):

    1. Create the corresponding Git::Commands::* class.

    2. Write isolated RSpec unit tests for the new class.

    3. Change the method in Git::Lib to delegate to the new command object.

    4. Run the full test suite to ensure no regressions have been introduced.

## Phase 3: Refactoring the Public Interface

***Goal**: Switch the public-facing classes to use the new architecture directly, breaking the final ties to the old implementation.*

1. **Refactor Factory Methods**:

   - Modify the factory methods in the top-level `Git` module (`.open`, `.clone`, etc.).

   - These methods will now be responsible for creating an instance of `Git::ExecutionContext` and injecting it into the constructor of a `Git::Repository` object.

    The return value of these factories will now be a `Git::Repository` instance, not a `Git::Base` instance.

2. **Implement the Facade**:

   - Populate the `Git::Repository` class with the simple, one-line facade methods that delegate to the `Command` objects. For example:

        ```ruby
        def commit(msg)
          Git::Commands::Commit.new(@execution_context, msg).run
        end
        ```

   - Organize these facade methods into modules as planned (`lib/git/repository/branching.rb`, etc.) and include them in the main `Git::Repository` class.

3. **Deprecate and Alias `Git::Base`**:

   - To maintain a degree of backward compatibility through the transition, make `Git::Base` a deprecated constant that points to `Git::Repository`.

        ```ruby
        Git::Base = ActiveSupport::Deprecation::DeprecatedConstantProxy.new(
          'Git::Base',
          'Git::Repository',
          Git::Deprecation
        )
        ```

   - This ensures that any user code checking `is_a?(Git::Base)` will not immediately break.

## Phase 4: Final Cleanup and Release Preparation

***Goal**: Remove all old code, finalize the test suite, and prepare for the v5.0.0 release.*

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

   - Mark all internal classes (`ExecutionContext`, `Commands`, `*Path`) with `@api private` in the YARD documentation.

   - Update the `README.md` and create a `UPGRADING.md` guide explaining the breaking changes for v5.0.0.
