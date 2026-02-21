# GitHub Copilot Instructions for ruby-git

## Project Overview

ruby-git is a Ruby gem that provides a Ruby interface to Git repositories.

The git gem wraps system calls to the `git` command line and provides an API to:

- Create, read, and manipulate Git repositories
- Work with branches, commits, tags, and remotes
- Inspect repository history and objects
- Perform Git operations like merge, clone, fetch, push, etc.
- Handle complex interactions including branching, merging, and patch generation

**Current Status:** Stable project supporting Ruby 3.2.0+ minimum and Git 2.28.0+.
Compatible with MRI Ruby 3.2+ on Mac, Linux, and Windows.

## AI Use Cases

This document guides AI agents in handling the following types of tasks. Each
category includes a link to the workflow that should be followed.

### Issue Triage & Investigation

**→ Use [Development Workflow](#development-workflow) (Phase 0: TRIAGE only -- do not proceed to implementation)**

- **"Diagnose issue #999"** - Investigate reported issues, identify root causes, and
  report findings without implementing changes
- **"Is issue #999 a bug or feature request?"** - Analyze and categorize issues
- **"Check if issue #999 is a duplicate"** - Search for similar existing issues
- **"Respond to issue #999"** - Answer questions or provide clarification on issues

### Bug Fixes

**→ Use [Development Workflow](#development-workflow) (Phases 0-3: TRIAGE → PREPARE → EXECUTE → FINALIZE)**

- **"Fix issue #999"** - Implement a fix for a reported bug following the full TDD
  workflow (diagnose → implement → test → PR)
- **"Fix the timeout handling in Git::CommandLine"** - Address specific bugs in the
  codebase

### Feature Implementation

**→ Use [Development Workflow](#development-workflow) (Phases 0-3: TRIAGE → PREPARE → EXECUTE → FINALIZE)**

- **"Implement issue #999"** - Build new features requested in issues
- **"Add support for git worktree commands"** - Implement specific functionality
- **"Implement the feature requested in issue #999 and create a PR"** - Full
  implementation workflow ending with PR creation

### Code Improvements

**→ Use [Development Workflow](#development-workflow) (Phases 1-3: PREPARE → EXECUTE → FINALIZE)**

- **"Refactor the Git::Branch class to reduce duplication"** - Improve code quality
  without changing behavior
- **"Add missing YARD documentation to Git::Base methods"** - Enhance documentation
- **"Add tests for Git::Remote#fetch"** - Improve test coverage

### Architectural Redesign Tasks

**→ Use [Architectural Redesign Workflow](#architectural-redesign-workflow)**

- **"Do the next task in the redesign"** - Migrate the next command per the implementation plan
- **"Migrate the commit command"** - Migrate a specific command to the new architecture
- **"Continue the architectural redesign"** - Pick up where the last migration left off

See `redesign/3_architecture_implementation.md` for the current progress tracker and next task details.

### Pull Request Review

**→ Use [Pull Request Review Workflow](#pull-request-review-workflow)**

- **"Review PR #999"** - Review a pull request, analyze changes against project
  standards, and post review comments
- **"Review PR #999 and approve if it looks good"** - Perform review with potential
  approval
- **"Check if PR #999 follows our coding standards"** - Focused review on specific
  criteria

### Maintenance Tasks

**→ Use [Development Workflow](#development-workflow) (Phases 1-3: PREPARE → EXECUTE → FINALIZE)**

- **"Update Ruby version support"** - Modify compatibility requirements
- **"Fix rubocop violations in lib/git/base.rb"** - Address linting issues
- **"Run the test suite and fix any failures"** - Ensure code quality

### Dependency Management

**→ Use [Dependency Management Workflow](#dependency-management-workflow)**

- **"Update all gem dependencies"** - Update dependencies to latest versions
- **"Check for outdated dependencies"** - List gems that have newer versions available
- **"Fix security vulnerabilities in dependencies"** - Address CVEs and security issues
- **"Update \<gem-name\> to version X.Y.Z"** - Update a specific dependency

### Test Debugging & Maintenance

**→ Use [Test Debugging & Maintenance Workflow](#test-debugging--maintenance-workflow)**

- **"Why is test_branch failing?"** - Debug consistently failing tests
- **"Fix flaky test in test_remote.rb"** - Address intermittent test failures
- **"Debug intermittent test failure"** - Investigate non-deterministic test behavior
- **"Improve test coverage for Git::Base#add"** - Add missing tests for existing code

### CI/CD Troubleshooting

**→ Use [CI/CD Troubleshooting Workflow](#cicd-troubleshooting-workflow)**

- **"Why is CI failing on PR #999?"** - Diagnose CI/CD failures and report root causes
- **"Fix the failing GitHub Actions build"** - Investigate and resolve CI failures
- **"Debug test failures in CI for PR #999"** - Identify why tests pass locally but fail in CI
- **"Check CI status for this branch"** - View current build status

### Code Review & Analysis

**→ No specific workflow required (use standard code analysis techniques)**

- **"Review the changes in this file"** - Analyze code quality and suggest
  improvements
- **"Explain how Git::CommandLine handles timeouts"** - Provide code explanations
- **"What would break if we change this method signature?"** - Impact analysis

### Merge Conflict Resolution

**→ Use [Merge Conflict Resolution Workflow](#merge-conflict-resolution-workflow)**

- **"Resolve merge conflicts in PR #999"** - Help resolve conflicts in a pull request
- **"Help merge feature branch into main"** - Assist with branch merging and conflict
  resolution
- **"Show merge conflicts between branches"** - Identify conflicting changes before
  merging

### Code Archaeology & History Analysis

**→ Use [Code Archaeology & History Analysis Workflow](#code-archaeology--history-analysis-workflow)**

- **"When was this bug introduced?"** - Use git bisect to find the commit that
  introduced a bug
- **"Find all callers of Git::Base#checkout"** - Search codebase for method usage
- **"Show the history of this method"** - Track changes to specific code over time
- **"Who last changed this file?"** - Use git blame to identify recent contributors
- **"What changed in this file between v1.0 and v2.0?"** - Compare file history
  across versions

### Release Management

**→ Use [Release Management Workflow](#release-management-workflow)**

- **"Prepare a new release"** - Guide through version bump, changelog, and release
  process
- **"Generate release notes from recent PRs"** - Compile changes since last release
- **"What PRs are included in this release?"** - List merged PRs between versions
- **"Tag and publish a release"** - Create git tags and publish gem
- **"Check release readiness"** - Verify all checks pass before release

### Breaking Change Analysis

**→ Use [Breaking Change Analysis Workflow](#breaking-change-analysis-workflow)**

- **"What would break if we remove this method?"** - Assess impact of deprecation
- **"Find all usages of deprecated API"** - Search for code using deprecated features
- **"Assess impact of changing this interface"** - Analyze downstream effects of API
  changes
- **"List all public API methods"** - Enumerate the public interface for audit

### Documentation Tasks

**→ Use [Documentation Workflow](#documentation-workflow)**

- **"Generate missing YARD documentation"** - Add documentation to undocumented
  methods
- **"Update README examples to match current API"** - Keep examples current
- **"Fix documentation errors"** - Correct inaccurate or outdated documentation
- **"Document this class/method"** - Add comprehensive YARD documentation
- **"Check documentation coverage"** - Identify undocumented public methods

## Architecture & Module Organization

The codebase is structured to separate high-level API interactions from low-level
command execution, ensuring maintainability and testability. ruby-git follows a
modular architecture:

- **Git::Base** - Main interface for repository operations (most major actions)
- **Git::Lib** - Low-level Git command execution via system calls
- **Git::Commands** - Command-specific argument building and output parsing (new architecture)
- **Git::CommandLine** - Handles Git command construction and execution with timeout
  support
- **Git Objects** - Repository objects (Commit, Tree, Blob, Tag) via `Git::Object`
- **Git::Status** - Working directory status (tracked/untracked/modified files)
- **Git::Diff** - Diff operations returning file-level patches and statistics
- **Git::Log** - Enumerable query builder for commit history
- **Git::Branch/Branches** - Branch management (local and remote)
- **Git::Remote** - Remote repository references
- **Git::Worktree/Worktrees** - Git worktree support
- **Git::Stash/Stashes** - Stash management

Key directories:

- `lib/git/` - Core library code
- `lib/git/commands/` - Command classes for the new architecture
- `tests/units/` - Legacy Test::Unit suite
- `spec/unit/` - RSpec unit tests (mocked execution context)
- `spec/integration/` - RSpec integration tests (real git repositories)
- `spec/support/` - Shared test contexts and helpers
- `doc/` - YARD-generated documentation
- `pkg/` - Built gem packages
- `redesign/` - Architecture redesign documentation

## Coding Standards

High-quality code is essential for the long-term maintenance of this library. Adhere
to the following standards to ensure consistency, readability, and reliability across
the codebase.

### Ruby Style

To ensure code consistency and leverage modern Ruby features, adhere to the following
style guidelines:

- Use `frozen_string_literal: true` at the top of all Ruby files
- Follow Ruby community style guide (Rubocop-compatible)
- Require Ruby 3.2.0+ features and idioms
- Use keyword arguments for methods with multiple parameters
- Prefer `private` over `private :method_name` for method visibility
- Use pattern matching for complex conditional logic where appropriate

### Code Organization

To maintain a clean, modular, and navigable codebase, structure your code according
to these principles:

- Keep classes focused and single-responsibility
- Use modules for mixins and namespace organization
- Place related classes in the same file only if they're tightly coupled
- One public class per file as a general rule
- Core library code organized in `lib/git/` directory

### Naming Conventions

Follow these naming conventions to ensure code readability and consistency with the
existing codebase and idiomatic Ruby:

- Classes/Modules: PascalCase (e.g., `Git::Base`, `Git::Branch`, `Git::CommandLine`)
- Methods/variables: snake_case (e.g., `current_branch`, `ls_files`, `commit_all`)
- Constants: UPPER_SNAKE_CASE (e.g., `VERSION`)
- Predicate methods: end with `?` (e.g., `bare?`, `success?`, `exist?`)
- Dangerous methods: end with `!` if they modify in place
- Instance variables: `@variable_name`
- Avoid class variables; prefer class instance variables or constants

## Design Philosophy

For detailed guidelines on wrapping git commands, see the following sections in
[CONTRIBUTING.md](../CONTRIBUTING.md):

- **[Design philosophy](../CONTRIBUTING.md#design-philosophy)** — Core principles
- **[Wrapping a git command](../CONTRIBUTING.md#wrapping-a-git-command)** —
  Implementation guide including method placement, naming, parameters, and output
  processing

The summary below outlines key principles. **For authoritative and complete
guidelines, always refer to CONTRIBUTING.md.**

**Note:** As of v2.x, this design philosophy is aspirational. Future versions may
include interface changes to fully align with these principles.

The git gem is designed as a lightweight wrapper around the `git` command-line tool,
providing a simple and intuitive Ruby interface for programmatically interacting with
Git.

### Principle of Least Surprise

The design should prioritize predictability and familiarity for users already
accustomed to the Git command line:

- Do not introduce unnecessary abstraction layers
- Do not modify Git's core functionality
- Maintain close alignment with the existing `git` command-line interface
- Avoid extensions or alterations that could lead to unexpected behaviors
- Allow users to leverage their existing knowledge of Git

### Direct Mapping to Git Commands

To maintain clarity and ease of use, the API should mirror the underlying Git
commands as closely as possible:

- Git commands are implemented within the `Git::Base` class
- Each method should directly correspond to a `git` command
- Example: `git add` → `Git::Base#add`, `git ls-files` → `Git::Base#ls_files`
- When a single Git command serves multiple distinct purposes, use the command name
  as a prefix followed by a descriptive suffix
  - Example: `#ls_files_untracked`, `#ls_files_staged`
- Introduce aliases to provide more user-friendly method names where appropriate

### Parameter Naming

Adopt a naming strategy that reinforces the connection to the Git CLI:

- Parameters are named after their corresponding long command-line options
- Ensures familiarity for developers already accustomed to Git
- Note: Not all Git command options are supported

### Output Processing

To provide a rich and idiomatic Ruby experience, process raw Git output into
structured objects when the output is important to the user:

- Translate Git command output into Ruby objects for easier programmatic use
- Ruby objects often include methods that allow for further Git operations
- Provide additional functionality while staying true to underlying Git behavior

### User Documentation

Comprehensive documentation is essential for a public library. Follow these
guidelines:

- Use YARD syntax for all public methods
- Include `@param`, `@return`, `@raise`, `@example` tags
- Use `@overload` with explicit keyword parameters when methods use anonymous keyword forwarding (`**`), and use individual `@param` tags for each keyword (not `@option`)
- Document edge cases, platform differences, and security considerations
- Keep method documentation up-to-date with implementation
- Add `@api private` for internal-only methods
- Document Git version requirements and compatibility

Example:

```ruby
# Opens a Git repository
#
# @param [String, Pathname] path The path to the working directory or .git directory
# @param [Hash] options The options for this command (see list of valid options below)
# @option options [Logger] :log A logger to use for Git operations
# @option options [Numeric] :timeout Maximum seconds to wait for Git commands (0 for no timeout)
# @return [Git::Base] an object that can execute git commands in the context of the repository
# @raise [ArgumentError] if path is not a valid Git repository
# @example Open a repository
#   git = Git.open('/path/to/repo')
#   puts git.log.first.message
# @api public
def self.open(path, options = {})
  # implementation
end
```

### Testing Philosophy

The project uses RSpec for all new tests, with tests organized into unit and
integration categories:

**Unit Tests** (`spec/unit/`): Test individual classes and methods with mocked
execution context. Unit tests verify that:
- The gem builds correct git command arguments
- Command output is properly parsed into Ruby objects
- Edge cases and error conditions are handled correctly
- All code paths and options are exercised

**Integration Tests** (`spec/integration/`): Test the gem's behavior against real git
repositories. Integration tests verify that:
- Mocked assumptions in unit tests match actual git behavior
- The gem correctly handles real git output formats
- Command options produce expected git behavior in practice
- Edge cases (unicode, special characters, etc.) work with real git

**Purpose of Integration Tests**: Integration tests validate the gem's interaction
with git, not git's functionality. They answer: "Does our mocked execution context
accurately represent what git actually does?" Integration tests should be minimal and
purposeful, focusing on key behaviors that unit tests cannot verify.

See [CONTRIBUTING.md](../CONTRIBUTING.md#rspec-best-practices) for detailed testing
guidelines including test organization, best practices, and examples.

## Key Technical Details

This section outlines the critical technical mechanisms that power the gem.
Understanding these details is important for implementing new features or debugging
complex issues.

### Git Command Execution

All Git commands are executed through the `Git::CommandLine` class which:

- Constructs Git commands with proper argument escaping
- Handles environment variables and working directory context
- Manages command execution with timeout support
- Captures stdout, stderr, and exit status
- Raises appropriate errors on command failures

### Major Classes and Their Responsibilities

Understanding the core classes is crucial for navigating the codebase and ensuring
logic is placed correctly. The following list outlines the primary classes and their
specific responsibilities:

1. **Git::Base**: The main repository interface
   - Entry point for most Git operations
   - Delegates to `Git::Lib` for low-level operations
   - Manages working directory, index, and repository references
   - Returns domain objects (Branch, Status, Diff, Log, etc.)

2. **Git::Lib**: Low-level command execution (Facade/Adapter layer during migration)
   - Executes Git commands via `Git::CommandLine`
   - Delegates to `Git::Commands::*` classes for command execution
   - **Builds rich response objects** from `CommandLineResult` using Parser classes
   - Responsible for pre-processing arguments and orchestrating command calls
   - Being incrementally migrated; will eventually become `Git::Repository`

3. **Git::Commands::*** (New Architecture): Command-specific logic
   - Each command class inherits from `Git::Commands::Base`
   - Declares arguments via the `arguments do … end` DSL (class-level)
   - `Base` provides default `#initialize` and `#call`; simple commands write `def call(...) = super`
   - `Base#call` binds arguments, calls `execution_context.command`, and validates exit status
   - Optional `allow_exit_status <Range>` for commands where non-zero exit is not an error
   - `#call` returns `Git::CommandLineResult` by default (not rich objects)
   - Located in `lib/git/commands/`
   - Unit tested with RSpec in `spec/unit/git/commands/`

   **Layer Responsibilities Summary**:
   - **Commands**: Define git CLI API, bind arguments, execute command → return `CommandLineResult`
   - **Parsers**: Transform stdout/stderr to structured data (e.g., `Git::Parsers::Diff`, `Git::Parsers::Stash`)
   - **Facade (Git::Lib)**: Pre-process args, call commands, build rich objects using Parsers

4. **Git::CommandLine**: Command execution layer
   - Builds Git command arrays with proper escaping
   - Manages subprocess execution with timeout support
   - Handles timeout and error conditions
   - Returns `Git::CommandLineResult` with output and status

4. **Git Objects** (Commit, Tree, Blob, Tag)
   - Immutable representations of Git objects
   - Lazy-loaded from repository
   - Methods for inspecting object properties and relationships

5. **Git::Status**: Working directory status
   - Enumerable collection of `Git::Status::StatusFile`
   - Tracks added, changed, deleted, and untracked files
   - Similar to `git status` command output

6. **Git::Diff**: Diff operations
   - Enumerable collection of `Git::Diff::DiffFile`
   - Per-file patches and statistics
   - Total insertion/deletion statistics

7. **Git::Log**: Commit history query builder
   - Chainable methods for building log queries
   - Enumerable returning `Git::Object::Commit` objects
   - Supports filtering by path, date range, author, etc.

### Path Handling

ruby-git handles three types of paths:

- **Working directory paths**: Relative to repository working directory
- **Git directory paths**: The `.git` directory location
- **Object paths**: Paths within Git tree objects

Paths are stored as `Pathname` objects on `Git::Base` (`@working_directory`, `@repository`, `@index`). The `Git::EscapedPath` class handles paths with special characters when needed.

### Error Hierarchy

Proper error handling is essential for robust applications. The gem defines a
specific hierarchy of exception classes to allow callers to rescue specific failure
modes. All custom exceptions inherit from `Git::Error`:

- `Git::FailedError`: Git command exited with non-zero status
- `Git::SignaledError`: Git command was killed by a signal
- `Git::TimeoutError`: Git command exceeded timeout (subclass of SignaledError)
- `ArgumentError`: Invalid arguments passed to methods

All Git command errors include the command, output, and status for debugging.

## Project Configuration

The following configuration values define the project's environment and operational
parameters. Use these settings to ensure your development environment matches the
project's requirements.

- **Language:** Ruby
- **Refactoring Strategy:** Maintain close alignment with git CLI commands, use
  descriptive method names, avoid over-abstraction, favor Ruby idioms while keeping
  git concepts clear

> **INSTRUCTIONS FOR AI:** Read these configuration values and use them strictly for
> the phases below. Do not guess commands.

- **Setup Project:** `bin/setup`
- **Run All Tests:** `bundle exec rake test_all`
- **Run Unit Tests (TestUnit only):** `bundle exec rake test`
- **Run RSpec Tests (unit + integration):** `bundle exec rake spec`
- **Run RSpec Unit Tests Only:** `bundle exec rake spec:unit`
- **Run RSpec Integration Tests Only:** `bundle exec rake spec:integration`
- **Run A Specific TestUnit Test:** `bundle exec bin/test <test_file_name_without_extension>`
  (e.g., `bundle exec bin/test test_branch`)
- **Run A Specific RSpec Test:** `bundle exec rspec <spec_file_path>`
  (e.g., `bundle exec rspec spec/unit/git/commands/add_spec.rb`)
- **Run Linters:** `bundle exec rake rubocop yard`
- **Run Continuous Integration Workflow:** `bundle exec rake default`

## Development Workflow

You are an expert and practical software engineer following a strict Test-Driven
Development (TDD) workflow.

**This project strictly follows Test Driven Development (TDD) practices. All
production code MUST be written using the TDD process described below.**

### Workflow Overview

When assigned a task involving a GitHub issue, follow this workflow:

1. **Phase 0: TRIAGE** - Understand the issue and determine if action is needed
2. **Phase 1: PREPARE** - Set up the environment and plan the implementation
3. **Phase 2: EXECUTE** - Implement the solution using TDD
4. **Phase 3: FINALIZE** - Squash commits and create the PR

**Note:** Not all issues require implementation. Phase 0 may result in requesting
clarification, confirming the issue is a duplicate, or determining no changes are
needed.

### Core TDD Principles

Adhere to the following fundamental principles to ensure high code quality and test
coverage:

- **Never Write Production Code without a Failing Test**
- **Bug Fixes Start with Tests:** Before fixing any bug, write a failing test that
  demonstrates the bug and fails in the expected way. Only then fix the code to make
  the test pass.
- **Tests Drive Design:** Let the test dictate the API and architecture. If the test
  is hard to write, the design is likely wrong. When this happens, stop and suggest
  one or more design alternatives. Offer to stash any current changes and work on the
  design improvements first before continuing with the original task.
- **Write Tests Incrementally:** Build tests in small steps, writing just enough to
  get the next expected failure. For example, first write a test that references a
  class that doesn't exist (fails), then define the empty class (passes), then extend
  the test to call a method (fails), then define the method (passes), etc.
- **Tests Should Be Atomic:** Each test should verify exactly one logical behavior,
  making failures easy to diagnose and understand.
- **Prefer the Simplest Solution:** Choose the simplest implementation that could
  possibly work, even if it seems naive. Complexity should only be added when driven
  by actual requirements in tests.
- **No Implementation in Advance:** Only write the code strictly needed to pass the
  current test.

### Phase 0: TRIAGE

The purpose of this phase is to understand what the issue is asking for, investigate
the current state of the codebase, and determine whether implementation is needed.

**Use this phase when the user references a GitHub issue number** (e.g., "Fix issue
\#999", "Implement \#999", "Diagnose issue \#999").

1. **Fetch the Issue:** Use `gh issue view #999` to read the full issue content,
   including description, comments, and labels.

2. **Understand the Request:** Analyze what is being asked:
   - Is this a bug report? Feature request? Question? Documentation issue?
   - Is the issue clear and actionable, or does it need clarification?
   - Are there reproduction steps or examples provided?

3. **Search for Context:** Investigate the codebase to understand the area affected:
   - Use `grep_search` or `semantic_search` to find relevant code
   - Read related test files to understand existing behavior
   - Check if similar functionality already exists
   - Look for related issues or PRs that might be relevant

4. **Reproduce (if applicable):** For bug reports:
   - Try to reproduce the issue based on the provided steps
   - Run existing tests to see if they catch the issue
   - Verify the issue still exists in the current codebase

5. **Determine Next Steps and Report Findings:**

   **Option A: Issue needs clarification**
   - Comment on the issue using `gh issue comment #999 --body "..."`
   - Ask specific questions about reproduction steps, expected behavior, or use case
   - **STOP here** - wait for user/reporter response before proceeding

   **Option B: Issue is not actionable (duplicate, won't-fix, already resolved)**
   - Comment on the issue explaining your findings
   - Suggest closing the issue or linking to related issues
   - **STOP here** - no implementation needed

   **Option C: Issue is clear and actionable**
   - Comment on the issue confirming you understand the request and plan to implement
   - Summarize your understanding and proposed approach
   - **Proceed to Phase 1: PREPARE** to begin implementation

   **Option D: User asked only to diagnose (not implement)**
   - Comment on the issue with your diagnostic findings
   - Explain what you discovered (root cause, affected code, potential solutions)
   - **STOP here** - wait for confirmation to proceed with implementation

**GitHub CLI Commands for Phase 0:**

- View issue: `gh issue view #999`
- View with comments: `gh issue view #999 --comments`
- Comment on issue: `gh issue comment #999 --body "Your comment here"`
- Search issues: `gh issue list --search "keyword"`

### Phase 1: PREPARE

The purpose of this phase is to ensure the project environment is ready, establish a
clean baseline, and create a clear implementation plan before writing any code.

**Only proceed to this phase if Phase 0 determined that implementation is needed.**

1. **Check Uncommitted Changes:** If there are any uncommitted changes in the
   project, ask the user what to do with them before continuing: include them in the
   current implementation plan, ignore them, or stash them before continuing.
2. **Create Feature Branch:** Create a new branch from `origin/main` using the naming
   convention `<type>/<short-description>` (e.g., `fix/issue-999`).
3. **Verify Project Setup:** Run the `Setup Project` command to ensure that the
   project is ready for development.
4. **Verify Clean Baseline:** Ensure that all existing tests and linters pass by
   running the `Run Continuous Integration Workflow` command.
5. **Analyze and Plan:** Understand the requirements, identify edge cases and
   potential challenges, and break the work into small, isolated tasks. Consider what
   tests will be needed and in what order they should be written.
6. **Consider Refactoring:** Look for ways to make the implementation of the feature
   or bug fix easier by performing one or more refactorings. If any are found,
   suggest them to the user. If the user confirms the refactoring, do the refactoring
   in a separate TDD process. Only once the refactoring is completed should the
   current feature or bug fix be worked on.
7. **Review Implementation Guidelines:** When implementing or modifying git command
   wrappers, read the [Wrapping a git command](../CONTRIBUTING.md#wrapping-a-git-command)
   section in CONTRIBUTING.md before proceeding. This ensures consistent API design
   for method placement, naming, parameters, and output processing. **Pay special
   attention to the Note annotations (blockquoted sections starting with `> **Note:**`)
   which provide critical guidance about the architectural transition and what to do
   at each step.**

### Phase 2: EXECUTE

The purpose of this phase is to implement each planned task using strict TDD cycles,
ensuring every line of production code is driven by a failing test.

Execute each task by repeating the following cycle of steps until all tasks are
complete:

1. **RED-GREEN:** Write failing tests and implement code to make them pass
2. **REFACTOR:** Improve code quality and design without changing behavior
3. **VERIFY:** Confirm the task is complete and code meets quality standards
4. **COMMIT:** Create a commit for the completed task
5. **REPLAN:** Review the implementation plan, then return to step 1 for the next
   task

When all tasks are complete, proceed to [Phase 3: FINALIZE](#phase-3-finalize).

#### RED-GREEN Step

1. **RED Substep**

   The purpose of this substep is to write a failing test that you hypothesize will
   pass with the next incremental bit of task implementation.

   - **Write the Test:** Write a single, focused, failing test or extend an existing
     test for the current task.
   - **Keep It Minimal:** Only write enough of a test to get an expected, failing
     result (the test should fail for the *right* reason).
   - **Execute and Analyze:** Run the `Run A Specific Test` command and analyze the
     output.
   - **Confirm Expected Failure:** Confirm it fails with an expected error (e.g.,
     assertion failure or missing definition).
   - **Validate:** If the test passes without implementation, the test is invalid or
     the logic already exists. When that happens, revise or skip.

2. **GREEN Substep**

   The purpose of this substep is to write just enough production code to make the
   failing test(s) pass.

   - **Write Minimal Code:** Write the minimum amount of code required to make the
     test pass.
   - **Use Simple Solutions:** It is acceptable to use hardcoded values or "quick and
     dirty" logic here just to get to green, even if this means intentionally writing
     clearly suboptimal code that you will improve during the REFACTOR step.
   - **No Premature Optimization:** Do NOT optimize, clean up, or improve code style
     during GREEN—that work belongs in the REFACTOR step.
   - **Execute and Verify:** Run the `Run A Specific Test` command
     - **If the test passes**, proceed to the REFACTOR step
     - **If the test fails**, read the FULL error output including the stack trace.
       Identify the exact failing line and assertion before modifying any code. Fix
       only what the error indicates, then re-run. Repeat until the test passes.
   - **Rollback on Repeated Failure:** If the test cannot be made to pass within 3
     attempts, revert all changes from this RED-GREEN cycle, report the issue to the
     user, and ask for guidance before proceeding.
   - **Stay Focused:** Do not implement future features or optimizations yet.

#### REFACTOR Step

The purpose of this step is to improve code quality and design without changing
behavior, ensuring the codebase remains clean and maintainable.

**You must consider refactoring before starting the next task.** Remove duplication,
improve variable names, and apply design patterns. Skip this step only if the code is
already clean and simple—avoid over-engineering.

- **Generalize the Implementation:** Ensure the code solves the general case, not
  just the specific test case. Replace hardcoded values used to pass the test with
  actual logic.
- **Limit Scope:** Do not perform refactorings that affect files outside the
  immediate scope of the current task. If a broader refactor is needed, add it to the
  task list during the REPLAN step as a separate task.
- **Execute All Tests:** Run the `Run All Tests` command and verify they still pass.
- **Verify Test Independence:** Verify tests can run independently in any order.
- **Confirm Improvement:** Ensure the refactoring made the code clearer, simpler, or
  more maintainable.

#### VERIFY Step

The purpose of this step is to confirm that the current task is fully complete before
moving to the next task.

- **Confirm Implementation Complete:** Verify all functionality for the task is
  implemented.
- **Run All Tests:** Run the `Run All Tests` command to ensure all tests pass.
- **Run Linters:** Run the `Run Linters` command to verify code style and
  documentation standards.
- **Check Code Quality:** Confirm the code is clean and well-factored.
- **STOP on Unexpected Failure:** If any test unexpectedly fails during VERIFY, STOP
  immediately and report the failure to the user. Do not attempt to fix the failure
  without first explaining what went wrong and getting confirmation to proceed.

#### COMMIT Step

The purpose of this step is to create a checkpoint after successfully completing a
task, providing a safe rollback point.

- **Create Commit:** Commit all changes from this task using the appropriate
  conventional commit type (see [Per-Task Commits](#per-task-commits) for guidance).
- **Keep Commits Atomic:** Each commit should represent one completed task with all
  tests passing and linters clean.

#### REPLAN Step

The purpose of this step is to review progress and adjust the implementation plan
based on what was learned during the current task.

- **Review Implementation Plan:** Assess whether the remaining tasks are still valid
  and appropriately scoped based on what was learned.
- **Identify New Tasks:** If the implementation revealed new requirements, edge
  cases, or necessary refactorings, add them to the task list.
- **Reprioritize if Needed:** Adjust task order if dependencies or priorities have
  changed.
- **Report Progress:** Briefly summarize what was completed and what remains.
  **ALWAYS** print the updated task list with status (e.g., `[x] Task 1`, `[ ] Task
  2`).
- **Continue or Complete:** If tasks remain, return to RED-GREEN for the next task.
  If all tasks are complete, proceed to [Phase 3: FINALIZE](#phase-3-finalize).

### Phase 3: FINALIZE

The purpose of this phase is to consolidate all task commits into a single, clean
commit and complete the feature or bug fix.

1. **Run Final Verification:** Run the `Run Continuous Integration Workflow` command
   one final time to ensure everything passes.
2. **Safety Check:** Run `git log --oneline HEAD~N..HEAD` (where N is the number of
   task commits) to list the commits included in the squash. Verify these are
   strictly the commits generated during the current session. If unexpected commits
   appear, STOP and ask the user for the correct value of N.
3. **Capture Commit Messages:** Run `git log --format="- %s" HEAD~N..HEAD` to capture
   individual commit messages for inclusion in the final commit body.
4. **Draft the Squash Message:** Prepare a commit message with:
   - **Subject:** A single line summarizing the entire feature or fix (e.g.,
     `feat(branch): add Branch#create method`)
   - **Body:** A summary of what was implemented, the captured commit messages from
     step 2, key decisions made, and any relevant context. Wrap lines at 100
     characters.
5. **Propose the Squash:** Present the drafted message and the commands to squash to
   the user:
   - `git reset --soft HEAD~N` (where N is the number of task commits)
   - `git commit -m "<drafted message>"`
6. **Wait for Confirmation:** Do NOT execute the squash until the user reviews the
   commits and confirms. The user may want to adjust the message or keep some commits
   separate.
7. **Execute on Confirmation:** Once confirmed, run `git reset --soft HEAD~N` to
   unstage the task commits while preserving all changes, then commit with the
   approved message.
8. **Handle Commit Hook Failure:** If the commit fails due to a `commit-msg` hook
   rejection (e.g., commitlint error):
   - Read the error message carefully to identify the formatting issue.
   - Fix the commit message to comply with the project's commit conventions.
   - Retry the commit. The changes remain staged after a hook failure, so only the
     `git commit` command needs to be re-run.
   - If the commit fails 3 times, STOP and report the issue to the user with the
     exact error message.

## Pull Request Review Workflow

When asked to review a pull request (e.g., "Review PR #999"), follow this workflow to
analyze the changes, provide feedback, and optionally post the review to GitHub.

### Step 1: Fetch the PR

1. **Read PR Details:** Use `gh pr view #999` to get title, description, author, and
   status.
2. **Get Changed Files:** Use `gh pr diff #999` to see the complete diff.
3. **Check PR Status:** Note if it's a draft, has merge conflicts, or has existing
   reviews.

### Step 2: Review Against Project Standards

Evaluate the PR against these criteria:

**Code Quality:** Ruby style (Rubocop-compliant), `frozen_string_literal: true`, proper naming (snake_case/PascalCase), single-responsibility, no duplication, Ruby 3.2+ idioms.

**Testing:** Changes covered by atomic Test::Unit tests, well-named, passing CI. Test modifications require justification.

**Documentation:** YARD docs on public methods with `@param`, `@return`, `@raise`, `@example`. README updated for user-facing changes. Platform differences and security documented.

**Architecture:** Correct layer placement (Base/Lib/CommandLine), principle of least surprise, direct Git command mapping, proper error hierarchy.

**Commits:** Conventional Commits format, lowercase subjects under 100 chars, no trailing period. Breaking changes use `!` and `BREAKING CHANGE:` footer.

**Compatibility:** Backward compatible (or marked breaking), Ruby 3.2+, Git 2.28.0+, cross-platform (Windows/macOS/Linux).

**Security:** No command injection, proper escaping via Git::CommandLine, input validation, resource cleanup.

### Step 3: Present Review Findings

Present your findings to the user in this format:

```text
## PR Review: #999 - [PR Title]

**Author:** [username]
**Status:** [open/draft/has conflicts/etc.]

### Summary
[Brief description of what the PR does]

### Recommendation
- **Review Type:** [APPROVE / COMMENT / REQUEST CHANGES]
- **Rationale:** [Why this recommendation]

### General Comments

[Overall feedback on the PR - architecture decisions, approach, etc.]

### Line-Specific Comments

[file.rb:123]
[Specific feedback about this line or section]

[file.rb:456-460]
[Feedback about this range of lines]

### Checklist Results

**Passing:**
- Uses proper Ruby style
- Tests included
- ...

**Issues Found:**
- Missing YARD documentation on `SomeClass#method`
- Commit message "Fixed bug" doesn't follow conventional commits
- ...

---

**Here is the review. Do you have any questions or want additional changes, OR should I go ahead and post this review on the PR?**
```

### Step 4: Get User Approval

Wait for the user to respond. They may:

- **Approve posting:** Proceed to Step 5
- **Request changes to review:** Modify your findings and re-present
- **Ask questions:** Answer and clarify before proceeding
- **Decide not to post:** End the workflow

Do NOT post the review without explicit user confirmation.

### Step 5: Post the Review

Once the user confirms, post the review using the GitHub CLI:

**For reviews with line-specific comments:**

1. Create the review: `gh pr review #999 --comment` (or `--approve` or
   `--request-changes`)
2. Add the general comment as the review body using `-b "comment text"`
3. For line-specific comments, you may need to use the GitHub API or instruct the
   user to add them manually in the GitHub UI

**For reviews with only general comments:**

```bash
gh pr review #999 --approve -b "Your general comment here"
# or
gh pr review #999 --comment -b "Your general comment here"
# or
gh pr review #999 --request-changes -b "Your general comment here"
```

**Note:** The `gh` CLI has limitations with line-specific comments. If the review
includes line-specific comments, inform the user of this limitation and either:

- Post only the general comment via CLI and provide the line comments for manual
  posting
- Provide the full review text for the user to post manually
- Use the GitHub API if line-specific commenting is critical

### Step 6: Confirm Completion

After posting, confirm with the user:

```text
Review posted successfully to PR #999.
View at: [PR URL from gh pr view output]
```

## CI/CD Troubleshooting Workflow

When asked to diagnose or fix CI/CD failures (e.g., "Why is CI failing on PR #999?",
"Fix the failing build"), follow this workflow to identify the root cause and
optionally implement fixes.

### Step 1: Identify the Failure

1. **Get CI Status:**
   - For PRs: `gh pr checks #999`
   - For branches: `gh run list --branch <branch-name> --limit 5`
   - Note which jobs passed and which failed

2. **Categorize the Failure Type:**
   - **Test failures** - Unit tests, integration tests failing
   - **Linter failures** - Rubocop, YARD documentation issues
   - **Build failures** - Dependency installation, compilation errors
   - **Timeout failures** - Jobs exceeding time limits
   - **Platform-specific failures** - Failing on specific Ruby version or OS

3. **Identify Specific Failing Steps:**
   - Note the exact job name and step that failed
   - Record the Ruby version, OS, and other environment details

### Step 2: Fetch Relevant Logs

**CRITICAL: CI logs can be massive (100K+ lines) and exceed token limits.**

1. **Get the Run ID:**

   ```bash
   gh run list --branch <branch> --limit 1 --json databaseId --jq '.[0].databaseId'
   ```

2. **Fetch Failed Job Logs Only:**

   ```bash
   gh run view <run-id> --log-failed
   ```

   This limits output to only failed jobs, making it manageable.

3. **Extract Key Error Information:**

   - For test failures: Look for stack traces, assertion errors, specific test names
   - For linter failures: Extract file names, line numbers, and violation types
   - For build failures: Find dependency errors or missing packages
   - Use `grep` to filter logs if still too large:

     ```bash
     gh run view <run-id> --log-failed | grep -A 10 -B 5 "Error\|FAILED\|Failure"
     ```

4. **Avoid Full Log Downloads:**

   - Do NOT use `--log` without `--log-failed` unless specifically requested
   - If logs are still too large, focus on the most recent or critical failure

### Step 3: Diagnose Root Cause

Based on the failure type, investigate:

**For Test Failures:**

- Check if the test exists and what it's testing
- Look for recent changes that might have broken the test
- Consider environment differences (local vs. CI)
- Check for flaky tests (intermittent failures)

**For Linter Failures:**

- Run linters locally: `bundle exec rake rubocop yard`
- Identify specific violations from the log
- Check if violations are in files related to recent changes

**For Build Failures:**

- Check dependency versions in `Gemfile` and `git.gemspec`
- Look for platform-specific dependency issues
- Verify Ruby version compatibility

**For Timeout Failures:**

- Identify which test or step is timing out
- Check for infinite loops or performance regressions
- Consider if it's a resource limitation in CI environment

### Step 4: Reproduce Locally (if applicable)

**For PR Failures:**

1. Fetch the PR branch:

   ```bash
   gh pr checkout #999
   ```

2. Run the failing tests locally:

   ```bash
   bundle exec bin/test <test-name>
   ```

3. Run linters:

   ```bash
   bundle exec rake rubocop yard
   ```

**For Branch Failures:**

1. Checkout the branch.
2. Run full CI workflow:

   ```bash
   bundle exec rake default
   ```

### Step 5: Report Findings or Fix

Determine the appropriate action based on the user's request:

#### Option A: Diagnostic Report ("Why is CI failing?")

Present findings to the user:

````markdown
## CI Failure Diagnosis: <Branch/PR>

**Status:** <X of Y jobs failed>

### Failed Jobs
1. **<Job Name>** (<Ruby version>, <OS>)
   - **Step:** <failing step name>
   - **Failure Type:** <test/linter/build/timeout>

### Root Cause
<Explanation of what's causing the failure>

### Error Details
```
<Relevant error messages and stack traces>
```

### Recommendations
- <Specific fix suggestion 1>
- <Specific fix suggestion 2>

**Would you like me to implement a fix, or do you need more information?**
````

**STOP here** unless the user asks you to proceed with fixes.

#### Option B: Implement Fix ("Fix the failing build")

Proceed based on failure type:

- **Test Failures:** Use the full TDD workflow (Phase 1-3) to fix the failing tests
- **Linter Failures:** Fix violations directly, commit with appropriate message
  (e.g., `style: fix rubocop violations in lib/git/base.rb`)
- **Build Failures:** Update dependencies or configuration as needed
- **Timeout Failures:** Investigate performance issues, may require user guidance

**For PR Failures on Someone Else's PR:**

- You may not have push access to their branch
- Present the fix and ask user to either:
  - Push to the PR branch (if they have access)
  - Comment on the PR with suggested changes
  - Create a new PR with fixes

### Step 6: Verify Fix

After implementing fixes:

1. **Run Affected Tests Locally:**

   ```bash
   bundle exec bin/test <test-name>
   ```

2. **Run Full CI Suite:**

   ```bash
   bundle exec rake default
   ```

3. **Push and Monitor:**

   - Push the fixes
   - Monitor CI to confirm the fix worked:

     ```bash
     gh run watch
     ```

4. **Confirm Resolution:**

   ```text
   Fix implemented and pushed. Monitoring CI run...
   CI Status: <link to run>
   ```

### Special Troubleshooting Considerations

**Platform-Specific Failures:**

- If tests pass on macOS but fail on Linux/Windows, document the difference
- Check for path separator issues (`/` vs. `\`)
- Look for encoding differences
- Consider file system case sensitivity

**Flaky Tests:**

- If a test fails intermittently, note this in your diagnosis
- Run the test multiple times locally to confirm flakiness
- Suggest fixes for race conditions or timing issues

**Permission Issues:**

- If you can't push to a PR branch, clearly communicate this limitation
- Provide the exact commands or changes needed for the user to apply

**Token Limit Management:**

- Always use `--log-failed` to limit output
- If logs are still too large, use `grep` to extract errors
- Focus on the first failure if multiple failures exist
- Consider running tests locally instead of relying on full CI logs

## Test Debugging & Maintenance Workflow

When asked to debug tests or improve test coverage (e.g., "Why is test_branch
failing?", "Fix flaky test", "Improve test coverage"), follow this workflow to
identify problems, determine root causes, and apply appropriate fixes.

### Understanding Test Failure Types

**Consistent Failures:**

- Test fails every time it runs
- Usually indicates a real bug or broken test
- Easier to debug than flaky tests

**Flaky/Intermittent Failures:**

- Test passes sometimes, fails other times
- Often indicates:
  - Race conditions
  - Timing dependencies
  - Shared state between tests
  - Non-deterministic behavior (random data, time-based logic)
  - External dependencies (filesystem, network)
  - Test execution order dependencies

**Test Coverage Gaps:**

- Existing code lacks sufficient test coverage
- Not a failure, but maintenance task
- Use TDD workflow to add tests

### Step 1: Run and Observe the Test

1. **Run the Failing Test:**

   ```bash
   bundle exec bin/test <test_file_name>
   ```

   Capture the full output including stack trace.

2. **Run Specific Test Method (if needed):**

   ```bash
   bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_method_name
   ```

3. **For Suspected Flaky Tests, Run Multiple Times:**

   ```bash
   # Run 20 times, stop on first failure
   for i in {1..20}; do
     echo "Run $i"
     bundle exec bin/test test_branch || break
   done
   ```

   If it fails inconsistently, it's flaky.

4. **Check Test Isolation:**

   ```bash
   # Run test file in isolation
   bundle exec bin/test test_branch

   # Run full suite to see if other tests affect it
   bundle exec bin/test
   ```

### Step 2: Understand the Test

1. **Read the Test Code:**

   - What behavior is being tested?
   - What is the expected outcome?
   - What setup/teardown occurs?
   - Are there any mocks or stubs?

2. **Understand the Error:**

   - Read the full error message and stack trace
   - Identify the exact line that failed
   - Understand expected vs. actual values
   - Check if it's an assertion failure or exception

3. **Review Related Tests:**

   - Do similar tests pass?
   - Are there patterns in what works vs. what doesn't?

### Step 3: Investigate Root Cause

**For Consistent Failures:**

1. **Check Recent Changes:**

   - Use `git log` to see recent commits to test file or related production code
   - Use `git blame` on the failing test to see when it was last modified

2. **Look for Broken Assumptions:**

   - Has the API changed?
   - Are test fixtures or data still valid?
   - Are external dependencies (git version, Ruby version) compatible?

3. **Check Test Setup/Teardown:**

   - Is setup creating the necessary preconditions?
   - Is teardown cleaning up properly?
   - Use test helpers (`clone_working_repo`, `create_temp_repo`, etc.)

4. **Environment Issues:**

   - Platform differences (paths, line endings, permissions)
   - Missing dependencies or configuration
   - Git configuration on the system

**For Flaky Tests:**

1. **Look for Race Conditions:**

   - Multiple threads or processes
   - File system operations without proper synchronization
   - Async operations without proper waiting

2. **Check for Timing Dependencies:**

   - Tests that depend on execution speed
   - Sleep statements or timeouts
   - Time-based logic (dates, timestamps)

3. **Identify Shared State:**

   - Global variables or class variables
   - Shared file system resources
   - Tests affecting each other through side effects

4. **Look for Non-Determinism:**

   - Random data generation
   - Hash ordering (though Ruby 1.9+ maintains insertion order)
   - Iteration over sets without guaranteed order
   - Time-dependent logic (Time.now, Date.today)

5. **Check Test Execution Order:**

   - Does the test only pass when run after certain other tests?
   - Does it fail when run in isolation?
   - Use `--seed` option to reproduce specific execution order

### Step 4: Report Findings

Present your diagnostic findings to the user:

````markdown
## Test Failure Diagnosis: <test_name>

**Failure Type:** [Consistent / Flaky / Coverage Gap]
**Test File:** <path/to/test_file.rb>
**Test Method:** <test_method_name>

### Error
```
<error message and relevant stack trace>
```

### Root Cause
<Explanation of why the test is failing>

### Affected Code
- Test code: <relevant test code>
- Production code: <relevant production code if applicable>

### Recommended Fix
<Specific recommendation based on scenario below>

**Would you like me to implement this fix?**
````

**STOP here** unless the user asks you to proceed with the fix.

### Step 5: Determine Fix Strategy and Execute

Based on the root cause, choose the appropriate fix strategy:

#### Scenario A: Production Code Bug (Test Caught a Real Bug)

- **Strategy:** Fix production code using TDD workflow
- **Process:**
  1. The failing test already exists (RED step done)
  2. **Proceed to Phase 1: PREPARE** of the TDD workflow
  3. Fix the production code (GREEN step)
  4. Refactor if needed
  5. Continue through Phase 2-3 as normal
- **Commit:** `fix(component): <description>` with test changes if needed

#### Scenario B: Test Needs Updating (Intentional API Change)

- **Strategy:** Update test to match new expected behavior
- **CRITICAL:** Get user confirmation before modifying test!
- **Process:**
  1. Explain what changed and why test expectations are now different
  2. Ask if this is a breaking change
  3. Wait for user approval
  4. Update test assertions or setup
  5. Verify test passes
  6. Run full test suite
- **Commit:** `test(component): update test for <change>`

#### Scenario C: Flaky Test (Non-Determinism)

- **Strategy:** Make test deterministic
- **Process:**
  1. Identify source of non-determinism
  2. Fix the test to be deterministic:
     - Stub time-dependent code (freeze time in tests)
     - Use fixed seed for random data
     - Add proper synchronization for async operations
     - Isolate tests from each other (proper setup/teardown)
     - Remove timing dependencies
  3. Run test 20+ times to verify fix
  4. Run full test suite
- **Commit:** `test(component): fix flaky test in <test_name>`
- **If production code has race condition:** Also fix that using TDD workflow

#### Scenario D: Missing Test Coverage

- **Strategy:** Add tests using TDD workflow
- **Process:**
  1. **Proceed to Phase 1: PREPARE** of the TDD workflow
  2. Write tests for uncovered code (RED step)
  3. If tests pass → good! Code works, test documents behavior
  4. If tests fail → found a bug, proceed with GREEN step
  5. Continue through normal TDD cycle
- **Commit:** `test(component): add tests for <feature>`

#### Scenario E: Test Refactoring/Cleanup

- **Strategy:** Improve test quality without changing behavior
- **Process:**
  1. Keep test green while refactoring
  2. Improve readability, reduce duplication
  3. Extract test helpers if needed
  4. Run test after each change to ensure still passing
  5. Run full test suite
- **Commit:** `refactor(test): improve test clarity in <test_name>`

#### Scenario F: Environment/Setup Issue

- **Strategy:** Fix environment, not code
- **Process:**
  1. Document the environment requirement
  2. Update README or test setup if needed
  3. May need to run `bin/setup` or install dependencies
  4. No code commit needed unless documenting requirement

### Step 6: Verify Test Fix

After implementing the fix:

1. **Run the Specific Test:**

   ```bash
   bundle exec bin/test <test_file>
   ```

2. **For Flaky Test Fixes, Run Many Times:**

   ```bash
   for i in {1..50}; do
     echo "Run $i"
     bundle exec bin/test test_branch || break
   done
   ```

   Should pass all 50 times.

3. **Verify Test Isolation:**

   ```bash
   # Run test alone
   bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_method

   # Run full suite
   bundle exec bin/test
   ```

4. **Run Full Test Suite:**

   ```bash
   bundle exec rake default
   ```

5. **Confirm Fix:**

   ```text
   Test fix verified:
   - Test passes consistently (ran 50 times for flaky test)
   - Test passes in isolation
   - Full test suite passes
   - No regressions introduced
   ```

### Special Considerations

**Test Isolation:**

- Each test should be independent
- Setup should create fresh state
- Teardown should clean up completely
- Use `clone_working_repo` or `create_temp_repo` from test helpers
- Don't rely on test execution order

**Platform-Specific Tests:**

- Some tests may behave differently on Windows vs. Unix
- Check for path separator issues (`/` vs. `\\`)
- File permissions work differently across platforms
- Line endings (CRLF vs. LF) can affect tests

**CI vs. Local:**

- CI may have different environment (different Ruby version, Git version, OS)
- CI runs tests in different order
- CI may have stricter resource limits
- Use CI/CD Troubleshooting Workflow if failing only in CI

**Test Data Management:**

- Test fixtures are in `tests/files/`
- Use test helpers to create temporary repos
- Clean up temporary files in teardown
- Don't commit generated test data

**Mocking and Stubbing:**

- Project uses Mocha for mocking
- Be careful with stubs - they can hide real issues
- Verify mocks are being called as expected
- Clean up stubs in teardown

**Test Naming:**

- Test names should describe behavior: `test_creates_new_branch`
- Not implementation: `test_branch_method`
- Good names make failures self-documenting

### Integration with TDD Workflow

Test debugging transitions to TDD workflow in these cases:

1. **Production Code Bug Found:**
   - Failing test = RED step already done
   - **→ Proceed to Phase 1: PREPARE**
   - Fix bug using GREEN step
   - Continue through Phase 2-3

2. **Missing Test Coverage:**
   - **→ Proceed to Phase 1: PREPARE**
   - Write new tests using TDD cycle
   - RED → GREEN → REFACTOR for each test

3. **Flaky Test Reveals Race Condition in Production Code:**
   - Fix test first to make deterministic
   - Then **→ Proceed to Phase 1: PREPARE** to fix production code
   - Write additional test for the race condition
   - Fix using TDD workflow

**Do NOT use TDD workflow for:**

- Updating tests after intentional API changes (direct test update)
- Fixing flaky tests (test maintenance)
- Refactoring tests (test cleanup)
- Environment issues (no code changes)

## Dependency Management Workflow

### Project-Specific Rules

- **All dependencies go in `git.gemspec`** (both runtime and development) - enforced by Rubocop
- **`Gemfile` should remain minimal/empty** - do not add dependencies here
- **`Gemfile.lock` is NOT committed** - this is a gem/library project

### Update Process

1. **Assess:** Run `bundle outdated` and `bundle audit check --update` (if available)
2. **Update:** Edit `git.gemspec` if constraints need changing, then run `bundle update`
3. **Test:** Run `bundle exec rake default` - must pass on all Ruby versions (3.2, 3.3, 3.4)
4. **Commit:** Use conventional commit format:
   - Security: `fix(deps): update <gem> to fix CVE-XXXX-XXXX`
   - Regular: `chore(deps): update dependencies`
   - Breaking: `chore(deps)!: update <gem>` with `BREAKING CHANGE:` footer

### Key Considerations

- Security vulnerabilities are highest priority - address immediately
- For gem projects, version constraints in gemspec must be carefully chosen since users resolve dependencies independently
- Breaking changes in dependencies may require code changes (use TDD workflow)
- Test with both minimum supported versions and latest versions when possible
- If tests fail, isolate by updating gems one at a time or use binary search

### Commit Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/). A
commit hook enforces the format. See [Git Commit
Conventions](#git-commit-conventions) for the full format and allowed types.

#### Per-Task Commits

In the COMMIT step, create a commit for the completed task following these
guidelines:

- **Use Appropriate Types:**
  - `test:` for adding or modifying tests (RED step)
  - `feat:` for new **user-facing** functionality (triggers MINOR version bump)
  - `fix:` for bug fixes (GREEN step for bugs)
  - `refactor:` for code improvements without behavior change
  - `chore:` for internal tooling or maintenance
- **Use Scope When Relevant:** Include a scope to indicate the affected component
  (e.g., `feat(branch):`, `test(remote):`).
- **Write Clear Subjects:** Use imperative mood, lowercase, no period (e.g.,
  `feat(branch): add create method`).

### Additional Guidelines

These guidelines supplement the TDD process:

- **Justify Test Modifications:** If an existing test needs to be modified, STOP and
  report to the user before making the change. Explain which test needs modification,
  why the expected behavior is changing, and whether this represents a breaking
  change. Wait for user confirmation before proceeding.
- **Unrelated Test Failures:** If you need to modify a test file that is not related
  to the current task to make the build pass, STOP and report to the user. This
  usually indicates a deeper regression, environment issue, or flawed assumption. Do
  not attempt to fix unrelated tests without user guidance.
- **Handle Discovered Complexity:** If the implementation reveals a complex logic
  gap, add it to your task list but finish the current cycle first.
- **Test Names Describe Behavior:** Name tests to clearly describe what behavior they
  verify (e.g., `test_creates_new_branch` not `test_branch`).
- **Ask for Clarification:** Stop and ask for clarification if requirements or
  expectations are ambiguous.

### Example TDD Cycle

Each task follows this cycle: **RED → GREEN → REFACTOR → VERIFY → COMMIT → REPLAN**

**RED:** Write a failing test that describes the desired behavior.

```ruby
def test_creates_new_branch
  @git.branch('feature').create
  assert @git.branches.local.map(&:name).include?('feature')
end
# Run: bundle exec bin/test test_branch → fails with NoMethodError
```

**GREEN:** Write minimal code to make the test pass.

```ruby
def create
  @base.lib.branch_new(@name)
end
# Run: bundle exec bin/test test_branch → passes
```

**REFACTOR:** Improve code quality without changing behavior, then run all tests.

**VERIFY:** Run `bundle exec rake default` to confirm tests and linters pass.

**COMMIT:** `git commit -m "feat(branch): add Branch#create method"`

**REPLAN:** Report progress, update task list, proceed to next task or FINALIZE.

**FINALIZE (after all tasks):** Propose squash commit with captured messages, wait
for user confirmation, then execute.

## Merge Conflict Resolution Workflow

This workflow guides resolving merge conflicts in pull requests or when merging
branches locally.

### Step 1: Identify Conflicts

Before resolving conflicts, understand what needs to be merged:

1. **For PR conflicts:**

   - View PR details and check out the PR branch using `gh pr checkout`
   - Attempt to merge `main` with `--no-commit` to see conflicts

2. **For local branch merging:** Fetch origin, then attempt merge with
   `--no-commit` to see conflicts.

3. **List conflicted files** using `git diff --name-only --diff-filter=U`.

### Step 2: Understand the Conflicting Changes

For each conflicted file:

1. **View the conflict markers** in the file.
2. **Understand both sides:** Compare what each branch changed relative to the
   common ancestor using `git diff` with the appropriate refs (HEAD, MERGE_HEAD,
   and the stage numbers `:1:`, `:2:`, `:3:` for base/ours/theirs).
3. **Check the history** of the conflicting sections if needed.

### Step 3: Resolve Conflicts

Choose the appropriate resolution strategy:

- **Accept one side entirely:** Use `git checkout --ours <file>` or
  `git checkout --theirs <file>`
- **Manual resolution:** Edit the file to resolve conflict markers
  (`<<<<<<<`, `=======`, `>>>>>>>`), then stage with `git add`
- **Interactive merge tool:** Use `git mergetool <file>`

### Step 4: Verify Resolution

After resolving all conflicts:

1. **Check for remaining conflicts:** `git diff --check`
2. **Run the test suite:** `bundle exec bin/test`
3. **Run linters:** `bundle exec rake rubocop`
4. **Review the final diff:** `git diff --staged`

### Step 5: Complete the Merge

Commit the merge with a message listing the resolved conflict files.

1. **Push the changes:**

   ```bash
   git push
   ```

2. **For PRs, verify CI passes:**

   ```bash
   gh pr checks #999
   ```

## Code Archaeology & History Analysis Workflow

This workflow helps investigate code history to understand when bugs were introduced,
track changes to specific code, and find usages of methods or classes.

### Understanding History Analysis Tools

ruby-git provides several approaches to code archaeology:

- **git blame**: See who last modified each line
- **git log**: Track commit history for files or code
- **git bisect**: Binary search to find the commit that introduced a bug
- **grep/semantic search**: Find usages of methods and classes

### Finding When a Bug Was Introduced (git bisect)

When you need to find which commit introduced a bug:

1. **Start bisect session:**

   ```bash
   # Start bisect
   git bisect start

   # Mark current commit as bad (has the bug)
   git bisect bad

   # Mark a known good commit (before the bug existed)
   git bisect good <commit-sha>
   ```

2. **Test each commit:**

   For each commit git checks out:

   ```bash
   # Run relevant tests
   bundle exec bin/test <test_name>

   # Mark as good or bad
   git bisect good  # if bug is NOT present
   git bisect bad   # if bug IS present
   ```

3. **Automated bisect with test script:**

   ```bash
   # Create test script that exits 0 for good, non-zero for bad
   git bisect run bundle exec ruby -I lib:tests tests/units/test_specific.rb -n test_method
   ```

4. **Complete bisect:**

   ```bash
   # View the result
   git bisect log

   # Reset to original state
   git bisect reset
   ```

### Tracing Method History

To see how a specific method has changed over time:

1. **View file history with changes:**

   ```bash
   # Show commits that touched a specific file
   git log --oneline -p -- lib/git/base.rb

   # Search for commits that changed specific text
   git log -p -S "def checkout" -- lib/git/base.rb

   # Show commits that changed a specific function (if supported)
   git log -p -L :checkout:lib/git/base.rb
   ```

2. **View the history of a specific line range:**

   ```bash
   git log -p -L 100,150:lib/git/base.rb
   ```

3. **Find when a method was added:**

   ```bash
   git log --diff-filter=A -p -S "def method_name"
   ```

### Finding Code Usages

To find all callers or usages of a method:

1. **Use grep_search for exact matches:**

   ```bash
   # Find method calls
   grep -rn "\.checkout" lib/ tests/

   # Find class references
   grep -rn "Git::Base" lib/ tests/
   ```

2. **Use semantic_search for broader context:**

   Use the AI's semantic_search capability to find related code patterns.

3. **Find test coverage for a method:**

   ```bash
   grep -rn "def test.*checkout" tests/
   ```

### Blame Analysis

To understand who changed specific code and why:

1. **Basic blame:**

   ```bash
   git blame lib/git/base.rb
   ```

2. **Blame with commit messages:**

   ```bash
   git blame -c lib/git/base.rb
   ```

3. **Ignore whitespace changes:**

   ```bash
   git blame -w lib/git/base.rb
   ```

4. **Find the original author (ignore moves/copies):**

   ```bash
   git blame -M -C lib/git/base.rb
   ```

5. **Blame specific lines:**

   ```bash
   git blame -L 100,150 lib/git/base.rb
   ```

## Release Management Workflow

This workflow guides preparing and publishing new releases of the ruby-git gem.

### Understanding the Release Process

ruby-git uses [release-please](https://github.com/googleapis/release-please) for
automated release management. Key files:

- `release-please-config.json` - Release configuration
- `lib/git/version.rb` - Version constant
- `CHANGELOG.md` - Release history

### Step 1: Pre-Release Checks

Before preparing a release:

1. **Ensure all CI checks pass:**

   ```bash
   bundle exec rake default
   ```

2. **Review unreleased changes:**

   ```bash
   # List commits since last tag
   git log $(git describe --tags --abbrev=0)..HEAD --oneline

   # List PRs merged since last release
   gh pr list --state merged --base main --search "merged:>$(git log -1 --format=%cs $(git describe --tags --abbrev=0))"
   ```

3. **Check for any outstanding issues:**

   ```bash
   gh issue list --label "bug" --state open
   gh issue list --label "breaking-change" --state open
   ```

4. **Verify documentation is current:**

   ```bash
   bundle exec yard doc
   bundle exec yard stats --list-undoc
   ```

### Step 2: Version Bump

Determine the appropriate version bump based on changes:

- **Patch** (x.y.Z): Bug fixes, documentation, non-breaking changes
- **Minor** (x.Y.0): New features, backward-compatible additions
- **Major** (X.0.0): Breaking changes

Update version in `lib/git/version.rb`:

```ruby
module Git
  VERSION = 'X.Y.Z'
end
```

### Step 3: Update Changelog

1. **Generate release notes from PRs:**

   ```bash
   # List merged PRs since last release
   gh pr list --state merged --base main --json number,title,labels,mergedAt \
     --search "merged:>$(git log -1 --format=%cs $(git describe --tags --abbrev=0))" \
     | jq -r '.[] | "- \(.title) (#\(.number))"'
   ```

2. **Organize by category in CHANGELOG.md:**

   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD

   ### Added
   - New feature description (#PR)

   ### Changed
   - Changed behavior description (#PR)

   ### Fixed
   - Bug fix description (#PR)

   ### Deprecated
   - Deprecated feature description (#PR)

   ### Removed
   - Removed feature description (#PR)

   ### Security
   - Security fix description (#PR)
   ```

### Step 4: Create Release

1. **Commit version bump and changelog:**

   ```bash
   git add lib/git/version.rb CHANGELOG.md
   git commit -m "chore: release X.Y.Z"
   ```

2. **Create and push tag:**

   ```bash
   git tag -a vX.Y.Z -m "Release X.Y.Z"
   git push origin main --tags
   ```

3. **Build and publish gem:**

   ```bash
   bundle exec rake build
   gem push pkg/git-X.Y.Z.gem
   ```

4. **Create GitHub release:**

   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z" --notes-file RELEASE_NOTES.md
   ```

### Step 5: Post-Release Tasks

1. **Verify gem is available:**

   ```bash
   gem info git --remote
   ```

2. **Announce release (if applicable):**
   - Update any external documentation
   - Notify downstream dependencies

3. **Close related milestone (if used):**

   ```bash
   gh api repos/{owner}/{repo}/milestones --jq '.[] | select(.title=="vX.Y.Z")'
   ```

### Release Commands Reference

```bash
# View recent tags
git tag -l --sort=-v:refname | head -10

# Compare with previous release
git diff v1.0.0..v1.1.0

# List commits since tag
git log v1.0.0..HEAD --oneline

# View tag details
git show v1.0.0

# Delete tag (if needed)
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z

# Build gem locally
bundle exec rake build

# Install gem locally for testing
gem install pkg/git-X.Y.Z.gem
```

## Breaking Change Analysis Workflow

This workflow helps assess the impact of API changes before implementation to
understand what code would break and plan appropriate migration paths.

### Understanding Breaking Changes

A breaking change is any modification that requires users to update their code:

- Removing or renaming public methods/classes
- Changing method signatures (required parameters)
- Changing return types or values
- Changing exception types
- Modifying default behavior

### Step 1: Identify the Change Scope

1. **Determine what is changing:**

   - Which class(es) are affected?
   - Which method(s) are affected?
   - Is this a public or private API?

2. **Check API visibility:**

   ```bash
   # Search for @api tags in documentation
   grep -n "@api public" lib/git/*.rb
   grep -n "@api private" lib/git/*.rb
   ```

3. **Review current documentation:**

   ```bash
   bundle exec yard doc
   open doc/index.html
   ```

### Step 2: Find All Usages

1. **Search within the gem:**

   ```bash
   # Find internal usages
   grep -rn "method_name" lib/
   grep -rn "ClassName" lib/
   ```

2. **Search in tests:**

   ```bash
   grep -rn "method_name" tests/
   ```

3. **Use semantic search for broader patterns:**

   Use the AI's semantic_search to find related usages that might not match exact
   patterns.

4. **Check external usage (if applicable):**

   ```bash
   # Search GitHub for usage of this gem's API
   gh search code "Git::Base#method_name language:ruby"
   ```

### Step 3: Assess Impact

Create an impact assessment:

1. **Internal impact:**
   - Number of files affected within the gem
   - Test changes required
   - Documentation updates needed

2. **External impact:**
   - Likely number of external users affected
   - Severity (compile error vs. runtime error vs. behavior change)
   - Ease of migration

3. **Document findings:**

   ```markdown
   ## Breaking Change Impact Assessment

   ### Change Description
   [What is being changed]

   ### Affected API
   - Class: `Git::Base`
   - Method: `#checkout`
   - Current signature: `def checkout(branch, opts = {})`
   - Proposed signature: `def checkout(branch, create: false)`

   ### Internal Impact
   - Files affected: X
   - Tests to update: Y

   ### External Impact
   - Severity: [High/Medium/Low]
   - Migration difficulty: [Easy/Medium/Hard]

   ### Migration Path
   [How users should update their code]
   ```

### Step 4: Plan Migration Path

1. **Deprecation approach (preferred for non-urgent changes):**

   ```ruby
   def old_method(*args)
     warn "[DEPRECATION] `old_method` is deprecated. Use `new_method` instead."
     new_method(*args)
   end
   ```

2. **Version-based migration:**
   - v2.x: Deprecate with warning
   - v3.0: Remove deprecated API

3. **Document migration in CHANGELOG:**

   ```markdown
   ### Deprecated
   - `Git::Base#old_method` is deprecated, use `Git::Base#new_method` instead
   ```

### Step 5: Document the Change

1. **Update YARD documentation:**

   ```ruby
   # @deprecated Use {#new_method} instead. Will be removed in v3.0.
   def old_method
   end
   ```

2. **Add to CHANGELOG.md:**

   ````markdown
   ### Breaking Changes
   - `Git::Base#checkout` signature changed: `opts` hash replaced with keyword
     arguments

   ### Migration Guide

   Before:

   ```ruby
   git.checkout('branch', { create: true })
   ```

   After:

   ```ruby
   git.checkout('branch', create: true)
   ```
   ````

3. **Update README if applicable**

## Architectural Redesign Workflow

This workflow guides implementing tasks for the v5.0.0 architectural redesign. The
redesign is migrating command logic from `Git::Lib` to dedicated `Git::Commands::*`
classes using a "Strangler Fig" pattern.

**Always start by reading the current task in
`redesign/3_architecture_implementation.md`.**

### Step 1: Read the Next Task

1. Open `redesign/3_architecture_implementation.md`
2. Find the "Next Task" section under "Progress Tracker"
3. Review the specific command to migrate and the workflow steps provided

### Step 2: Analyze the Existing Implementation

1. **Find the current implementation in `Git::Lib`:**

   ```bash
   # Search for the method definition
   grep -n "def <command_name>" lib/git/lib.rb
   ```

2. **Understand all options and edge cases** by reading:
   - The method in `lib/git/lib.rb`
   - Any related methods in `lib/git/base.rb`
   - Existing tests in `tests/units/`

### Step 3: Write Tests First (TDD)

1. **Create the spec file:** `spec/unit/git/commands/<command>_spec.rb`

2. **Follow the testing pattern from existing specs:**

   ```ruby
   # frozen_string_literal: true

   require 'spec_helper'

   RSpec.describe Git::Commands::<CommandName> do
     let(:execution_context) { double('ExecutionContext') }
     let(:command) { described_class.new(execution_context) }

     describe '#call' do
       context 'with default arguments' do
         it 'executes the expected git command' do
           expected_result = command_result
           expect_command('<git-subcommand>').and_return(expected_result)

           result = command.call

           expect(result).to eq(expected_result)
         end
       end

       # Add context blocks for each option...
     end
   end
   ```

   Note: `Base#call` always passes `raise_on_failure: false` (it validates
   exit status itself). The `command_result` helper is defined in the spec
   support files and returns a `Git::CommandLineResult` double.

3. **Test every option** defined in the original `Git::Lib` method

### Step 4: Implement the Command Class

1. **Create the command file:** `lib/git/commands/<command>.rb`

2. **Follow the pattern from existing commands:**

   ```ruby
   # frozen_string_literal: true

   require 'git/commands/base'

   module Git
     module Commands
       # Implements the `git <command>` command
       #
       # @api private
       class <CommandName> < Base
         arguments do
           literal '<git-subcommand>'
           # Define arguments using the DSL
           # For repeatable operand:
           operand :paths, repeatable: true
         end

         # Optionally, declare non-error exit codes:
         # allow_exit_status 0..1

         # Execute the git <command> command
         #
         # @overload call(*paths, **options)
         #   @param paths [Array<String>] ...
         #   @param options [Hash] command options
         #   @option options [Boolean] :force (nil) ...
         #
         # @return [Git::CommandLineResult] the result of the command
         #
         def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
       end
     end
   end
   ```

   **How `Base` works**: `Base` provides default `#initialize` (accepts an
   `execution_context`) and `#call` (binds arguments via the DSL, calls
   `execution_context.command`, validates exit status). Simple commands only need
   `arguments do … end` and `def call(...) = super`. That `def call(...) = super`
   definition exists primarily as the YARD documentation anchor so each command
   can have its own `@overload` docs; because it merely forwards to `Base#call`,
   RuboCop would normally flag it as a useless method, so we add
   `# rubocop:disable Lint/UselessMethodDefinition` to prevent it being "fixed"
   and inadvertently removing the per-command documentation hook.

   **Method Signature Convention:**
   - Most commands use `def call(...) = super`, which forwards all arguments
     to `Base#call` for binding, execution, and exit-status validation
   - Override `call` only when the command needs to inspect argument values or
     post-process output before returning
   - Defaults defined in the DSL (e.g., `operand :paths, default: ['.']`) are
     applied automatically during binding

   **DSL Operand Shape Convention:**

   When a command has two optional argument groups separated by `--` in git's
   SYNOPSIS (e.g., `[<tree-ish>] [--] [<pathspec>...]`), the post-`--` group is
   *independently reachable* — callers must be able to supply it without supplying
   the first group. Represent such commands with a plain `operand` for the first
   group and a `value_option … as_operand: true, separator: '--'` for the second:

   ```ruby
   arguments do
     literal 'diff'
     operand :tree_ish                                             # positional
     value_option :pathspec, as_operand: true, separator: '--',   # keyword
                  repeatable: true
   end
   # cmd.call                               → git diff
   # cmd.call('HEAD~3')                     → git diff HEAD~3
   # cmd.call(pathspec: ['file.rb'])        → git diff -- file.rb
   # cmd.call('HEAD~3', pathspec: ['f.rb']) → git diff HEAD~3 -- f.rb
   ```

   When the SYNOPSIS shows pure nesting (`[<commit1> [<commit2>]]`) with no `--`,
   the second operand is only meaningful when the first is present. Two plain
   `operand` entries with left-to-right binding are correct:

   ```ruby
   arguments do
     literal 'diff'
     operand :commit1   # optional
     operand :commit2   # optional — only meaningful when commit1 is also given
   end
   # cmd.call                    → git diff
   # cmd.call('HEAD~3')          → git diff HEAD~3
   # cmd.call('HEAD~3', 'HEAD')  → git diff HEAD~3 HEAD
   ```

   **Return Value Convention:**
   - `#call` **SHOULD** return `Git::CommandLineResult` by default
   - Rich objects (e.g., `StashInfo`, `BranchInfo`, `BranchDeleteResult`) are built
     by the **Facade layer** (`Git::Lib`), not by commands
   - Commands simply execute and return the raw result; parsing and object building
     is handled by Parser classes and Result factories in the facade

   **When to Create Parser Classes:**
   - Create a Parser class when command output needs to be transformed into
     structured data (e.g., `Git::Parsers::Diff`, `Git::Parsers::Stash`)
   - Parsers are stateless (class methods), return value objects, and live in
     `lib/git/parsers/` namespace
   - Inline parsing is acceptable for trivial output (e.g., single line, simple split)

3. **Run the spec to verify:** `bundle exec rspec spec/unit/git/commands/<command>_spec.rb`

### Step 5: Delegate from Git::Lib

1. **Update the method in `lib/git/lib.rb`:**

   ```ruby
   # Git::Lib may accept an options hash for backward compatibility
   def <command_name>(paths = '.', options = {})
     # Execute command - returns CommandLineResult
     result = Git::Commands::<CommandName>.new(self).call(*Array(paths), **options)

     # Facade builds rich response object if needed
     # Option A: Use Parser class for complex output
     <CommandName>Parser.parse(result.stdout)

     # Option B: Use Result factory method
     <CommandName>Result.from(result)

     # Option C: Return raw result for simple commands
     result
   end
   ```

   **Key Principle**: The facade layer (`Git::Lib`) is responsible for:
   - Calling the command (which returns `CommandLineResult`)
   - Building rich response objects using Parser classes or Result factories
   - Maintaining backward compatibility with the legacy interface

2. **Add the require statement** at the top of `lib/git/lib.rb`:

   ```ruby
   require_relative 'commands/<command>'
   ```

### Step 6: Verify All Tests Pass

```bash
# Run the new RSpec tests
bundle exec rspec spec/unit/git/commands/<command>_spec.rb

# Run all RSpec tests
bundle exec rspec

# Run legacy TestUnit tests
bundle exec rake test

# Run linter
bundle exec rubocop
```

### Step 7: Update the Checklist

1. Move the command from "Commands To Migrate" to "Migrated Commands" in
   `redesign/3_architecture_implementation.md`

2. Update the "Next Task" section to point to the next command

3. Update the progress count in the Progress Tracker table

## Documentation Workflow

This workflow guides creating and maintaining documentation for the ruby-git gem.

### Understanding Documentation Standards

ruby-git uses YARD for API documentation:

- All public methods must have YARD documentation
- Use standard YARD tags: `@param`, `@return`, `@raise`, `@example`
- Include code examples for non-trivial methods
- Document edge cases and platform differences

### Step 1: Identify Documentation Gaps

1. **Check documentation coverage:**

   ```bash
   bundle exec yard stats --list-undoc
   ```

2. **Find methods without documentation:**

   ```bash
   bundle exec yard doc --no-output --no-cache 2>&1 | grep "Undocumented"
   ```

3. **Review specific files:**

   ```bash
   # Check documentation for a specific class
   bundle exec yard doc lib/git/base.rb --no-output
   ```

### Step 2: Write Documentation

Follow the YARD documentation template:

```ruby
# Short description of what the method does
#
# Longer description with more details about behavior,
# edge cases, or important notes.
#
# @param name [Type] Description of parameter
# @param options [Hash] Options hash description
# @option options [Type] :key Description of option
#
# @return [Type] Description of return value
# @return [nil] When no result is found
#
# @raise [ArgumentError] When invalid arguments provided
# @raise [Git::Error] When git command fails
#
# @example Basic usage
#   git = Git.open('/path/to/repo')
#   result = git.method_name('arg')
#
# @example With options
#   git.method_name('arg', option: true)
#
# @see #related_method
# @see Git::RelatedClass
#
# @since 2.0.0
# @api public
def method_name(name, options = {})
end
```

### Step 3: Verify Documentation

1. **Generate and review docs:**

   ```bash
   bundle exec yard doc
   open doc/index.html
   ```

2. **Check for warnings:**

   ```bash
   bundle exec yard doc 2>&1 | grep -i "warn"
   ```

3. **Verify examples work:**

   Run code examples in a console to ensure they're correct:

   ```bash
   bundle exec bin/console
   ```

4. **Check cross-references:**

   Verify all `@see` references point to valid targets.

### Step 4: Update Related Documentation

1. **README.md updates:**
   - Ensure examples match current API
   - Update feature descriptions
   - Check installation instructions

2. **CHANGELOG.md entries:**
   - Document API changes
   - Note deprecations

3. **Inline comments:**
   - Update implementation comments if behavior changed
   - Remove outdated TODO comments

### Documentation Commands Reference

```bash
# Generate documentation
bundle exec yard doc

# Generate and serve locally
bundle exec yard server --reload

# Check documentation coverage
bundle exec yard stats

# List undocumented objects
bundle exec yard stats --list-undoc

# Generate docs for specific file
bundle exec yard doc lib/git/base.rb

# Check for YARD syntax errors
bundle exec yard doc --no-output 2>&1

# View documentation for specific class
bundle exec yard ri Git::Base
```

## Testing Requirements

### Test Framework

- **RSpec** (`spec/`): **Use for all new code.**
  - Required for `Git::Commands::*` classes (new architecture)
  - Preferred for bug fixes and new features
  - Uses standard RSpec syntax (`describe`, `it`, `let`)

- **Test::Unit** (`tests/units/`): **Legacy support only.**
  - Do not add new Test::Unit tests unless modifying existing legacy files
  - Main test helper: `tests/test_helper.rb`
  - Uses Mocha for mocking

### RSpec Testing Standards

Follow these guidelines for all RSpec tests:

- **Method Isolation**: Use a separate `describe '#method_name'` block for each public method being tested.
- **Context Isolation**: Use separate `context` blocks for different scenarios (state, inputs, configurations).

**For Git::Commands options:**

When implementing a command using the `Git::Commands::Arguments` DSL, you **MUST** include comprehensive tests for every option defined:

- **Structure**: use a separate `context` block for each option (e.g., `context 'with :force option'`) to keep tests organized and readable.
- **Valid Values**: Test each supported value type in its context (e.g., boolean `true/false`, string `'value'`, array `['a', 'b']`).
- **Invalid Values**: Test that invalid values raise appropriate errors or are handled correctly.
- **Argument Building**: Verify that the generated git command arguments match the expected CLI flags.
- **Edge Cases**: Test nil values, empty strings/arrays, and special characters.
- **Constraint Validation**: If the command uses `conflicts`, `forbid_values`, `requires_one_of`, `requires`, or `allowed_values` DSL declarations, include a `context 'input validation'` block that tests each constraint raises `ArgumentError` as expected (too many conflicting args present; forbidden exact-value tuple matched; none of the required group present; value outside the allowed set).

### Coverage Target

Maintain **high code coverage** through TDD practice.

### Test Organization

```ruby
require_relative '../test_helper'

class TestGitOpen < Test::Unit::TestCase
  def setup
    @repo = clone_working_repo
  end

  def test_opens_existing_repository
    git = Git.open(@repo)
    assert_kind_of Git::Base, git
  end

  def test_raises_on_invalid_path
    assert_raises(ArgumentError) do
      Git.open('/nonexistent/path')
    end
  end
end
```

### Critical Test Cases

- Repository operations (open, init, clone)
- Branch operations (create, checkout, delete, merge)
- Commit operations (add, commit, reset)
- Remote operations (fetch, pull, push)
- Status and diff operations
- Log queries with various filters
- Timeout handling for long-running operations
- Error conditions (invalid repos, failed commands, timeouts)
- Cross-platform compatibility (Mac, Linux, Windows)
- Path handling with special characters and Unicode
- Encoding issues with different character sets
- Git version compatibility (minimum 2.28.0)

### Test Helpers

The `Test::Unit::TestCase` base class provides:

- `clone_working_repo`: Creates a temporary clone of test repository
- `create_temp_repo`: Creates a temporary repository for testing
- `with_temp_dir`: Provides a temporary directory for tests
- `git_teardown`: Automatically cleans up temporary files
- Test fixtures in `tests/files/`

### Running Tests

```bash
# Run all tests
bundle exec bin/test

# Run specific test file using bin/test (preferred method)
bundle exec bin/test test_base

# Run multiple test files
bundle exec bin/test test_object test_archive

# Run specific test by name
bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_opens_existing_repository

# Run tests in Docker (tests against multiple Ruby versions)
bin/test-in-docker

# View coverage report
open coverage/index.html
```

## Ruby and Git Version Compatibility

### Current Support

- Minimum Ruby: 3.2.0
- Minimum Git: 2.28.0 or greater
- Actively tested on: MRI Ruby 3.2, 3.4, and 4.0
- Platforms: Mac, Linux, Windows
- CI tests on multiple Ruby versions and platforms

### Dependencies

- `activesupport` (>= 5.0) - For utilities and deprecation handling
- `addressable` (~> 2.8) - For URI parsing
- `process_executer` (~> 4.0) - For subprocess execution with timeout
- `rchardet` (~> 1.9) - For character encoding detection

### Platform Considerations

**Cross-Platform Compatibility:**

- Git command execution works on all platforms
- Handle Windows path separators and drive letters appropriately
- Test Git operations on all platforms
- Be aware of platform-specific Git behavior (e.g., line endings, permissions)
- Windows has different path handling and file system behavior

**Git Version Compatibility:**

- Minimum Git version is 2.28.0
- Test with different Git versions when using newer features
- Gracefully handle missing Git features on older versions
- Document Git version requirements for specific features

**Encoding Handling:**

- Handle different default encodings across platforms
- Use `rchardet` for automatic encoding detection
- Test with UTF-8 and other encodings
- Binary vs. text mode differences on Windows

## Configuration & Settings

### Gemspec Configuration

Located in `git.gemspec`:

- Runtime dependencies: activesupport, addressable, process_executer, rchardet
- Development dependencies: test-unit, mocha, rake, rubocop, yard, etc.
- `required_ruby_version >= 3.2.0`
- Git requirement: `git 2.28.0 or greater`

### Rake Configuration

Located in `Rakefile`:

- Default task runs Test::Unit tests
- Rubocop for linting
- YARD for documentation generation
- Tasks defined in `tasks/` directory

## Error Handling

- Raise specific exception classes from `Git::Error` hierarchy
- Always include relevant context (command, status, output) in exceptions
- Provide helpful error messages that guide users to solutions
- Handle platform-specific errors gracefully
- Document all error conditions in method YARD docs
- Never swallow exceptions silently
- Use `ArgumentError` for invalid method arguments

**Error Design Principles:**

- Inherit from `Git::Error` for all gem-specific errors
- `Git::FailedError`: Command failed (non-zero exit)
- `Git::SignaledError`: Command killed by signal
- `Git::TimeoutError`: Command exceeded timeout (subclass of SignaledError)
- Include structured data (command, output, status) for debugging
- Make errors programmatically inspectable
- Distinguish between user errors and runtime errors

## Performance Considerations

### Git Commands

- Commands execute with configurable timeout (global or per-command)
- Clean up resources properly
- Handle large repository operations efficiently
- Subprocess execution is handled internally by `Git::CommandLine`

### Memory Management

- Lazy-load Git objects when possible
- Stream large outputs rather than buffering everything
- Be mindful of memory usage with large diffs and logs
- Clean up temporary files and resources

### Repository Operations

- Minimize Git command executions
- Cache Git objects when appropriate
- Use batch operations where possible
- Consider performance implications of deep history traversal

## Documentation

The purpose of this section is to define the standards for maintaining project
documentation.

- Update README.md examples when API changes
- Use inline YARD comments for comprehensive API documentation
- Generate docs with `bundle exec yard doc`
- Ensure examples in documentation actually work
- Document platform-specific behavior
- Document Git version requirements for features
- Include security considerations (e.g., shell injection risks with certain
  operations)

## Key Documents

Always consult these before implementing features:

- **README.md** - Project overview, usage examples, and getting started
- **CHANGELOG.md** - Version history including identification breaking changes
  managed by the release GitHub Actions workflow
- **LICENSE** - MIT License
- **CONTRIBUTING.md** - Contribution guidelines
- **MAINTAINERS.md** - Maintainer information
- **redesign/** - Architecture redesign documentation
- [The full YARD documentation page](https://rubydoc.info/gems/git/)

## Code Quality Checklist

Before committing, ensure:

**Testing:**

- [ ] **TDD process followed** - Tests written before implementation
- [ ] All tests pass (`bundle exec bin/test`)
- [ ] No Ruby warnings when running tests

**Code Style:**

- [ ] Code follows Ruby style conventions (Rubocop)
- [ ] YARD documentation for public methods

**Compatibility:**

- [ ] Backward compatibility maintained (unless breaking change)
- [ ] Cross-platform compatibility considered (Windows, macOS, Linux)
- [ ] Git version compatibility (minimum 2.28.0)

**Documentation & Safety:**

- [ ] Security considerations addressed (command injection, etc.)
- [ ] Resource cleanup (file handles, temporary files)

## Git Commit Conventions

**CRITICAL:** All commits **MUST** adhere to the [Conventional Commits
standard](https://www.conventionalcommits.org/en/v1.0.0/). Commits not adhering to
this standard will cause the CI build to fail. PRs will not be merged if they include
non-conventional commits.

### Conventional Commit Format

The simplest format: `type: description`

**Valid types** (see [.commitlintrc.yml](../.commitlintrc.yml) for full list):

- `feat:` - New user facing functionality
- `fix:` - Bug fixes
- `docs:` - Documentation only
- `test:` - Adding/updating tests
- `refactor:` - Code restructuring without changing behavior
- `chore:` - Chores and maintenance (e.g., tooling, dependency bumps)
- `perf:` - Performance improvements
- `build:` - Build system or external dependency changes
- `ci:` - Continuous integration configuration and scripts
- `style:` - Code style and formatting only (no functional changes)
- `revert:` - Revert a previous commit

**Description rules:**

1. Must NOT start with an upper case letter
2. Must be no more than 100 characters
3. Must NOT end with punctuation

**Examples:**

- `feat: add the --merges option to Git::Lib.log`
- `fix: exception thrown by Git::Lib.log when repo has no commits`
- `docs: add conventional commit announcement to README.md`

**Breaking changes** must include an exclamation mark before the colon AND a
`BREAKING CHANGE: <description>` footer where the `<description>` indicates what was
broken:

- `feat!: removed Git::Base.commit_force`

Example with footer:

```text
feat(branch)!: rename create to make

Implement the new Branch#make method with improved validation.

BREAKING CHANGE: Branch#create renamed to Branch#make
```

**Full format:**

```text
type[optional scope][!]: description

[optional body]

[optional footer(s)]
```

**Version incrementing:**

- Breaking change → **major** version increment
- New feature → **minor** version increment
- Neither → **patch** version increment

**Pre-commit hook:** Run `bin/setup` in the project root to install a git pre-commit
hook that validates conventional commit messages before pushing to GitHub.

This project uses [release-please](https://github.com/googleapis/release-please) for
automated releases based on conventional commits.

## Pull Request Guidelines

**Branch Strategy:**

This project maintains two active branches:

- **`main`**: Active development for the next major version (v5.0.0+). May contain
  breaking changes.
- **`4.x`**: Maintenance branch for the v4.x release series. Bug fixes and
  backward-compatible improvements only.

**Important:** Never commit directly to `main` or `4.x`. All changes must be
submitted via pull requests from feature branches. This ensures proper code review,
CI validation, and maintains a clean commit history.

**For new features and breaking changes (target `main`):**

1. Ensure local main is up-to-date: `git fetch origin main`
2. Create a new branch from origin/main: `git checkout -b feature/your-feature
   origin/main`
3. Make your changes following TDD
4. Ensure all tests pass and code quality checks pass
5. Push the branch and create a PR targeting `main`

**For bug fixes (target `main`, maintainers backport to `4.x` if applicable):**

1. Ensure local main is up-to-date: `git fetch origin main`
2. Create a new branch from origin/main: `git checkout -b fix/your-fix origin/main`
3. Make your changes following TDD
4. Push the branch and create a PR targeting `main`

**For security fixes or 4.x-only changes (target `4.x`):**

1. Ensure local 4.x is up-to-date: `git fetch origin 4.x`
2. Create a new branch from origin/4.x: `git checkout -b fix/your-fix origin/4.x`
3. Make your changes following TDD
4. Push the branch and create a PR targeting `4.x`

**When Submitting Existing Changes:**

- Ensure changes are on a feature branch (not `main` or `4.x`), following the naming
  convention `<type>/<short-description>`
- If changes are on the wrong branch, offer to create a new branch from the
  appropriate base branch (`origin/main` or `origin/4.x`) and relocate the user's
  existing work (commits or uncommitted changes) onto that new branch, choosing an
  appropriate Git approach (for example, cherry-pick, rebase, or recommitting) based
  on the situation

**PR Creation Automation:**

When asked to create the PR, use the GitHub CLI: `gh pr create --title "feat(scope):
description" --body "..."`

- Read `.github/pull_request_template.md` to structure the body
- Ensure the body covers the "PR Description Should Include" points below
- Assign the user as the assignee if possible

**PR Description Should Include:**

- What problem does this solve?
- What approach was taken?
- Any breaking changes?
- Testing performed (manual and automated)
- Platform-specific considerations
- Related issues/PRs

**Review Checklist:**

- All commits follow Conventional Commits standard (CI will fail otherwise)
- Tests demonstrate the change works
- All tests pass (`bundle exec rake default`)
- Documentation updated (YARD comments for public methods)
- CHANGELOG.md will be automatically updated by release-please
- No breaking changes without major version bump or exclamation mark in commit
- At least one approval from a project maintainer required before merge

## AI Prompt: Create Comprehensive PR

Use this at the end of implementation to prepare for PR submission:

**"I've completed the implementation. Please perform a comprehensive PR readiness review."**

### 1. Run Final Validation

Execute and report results for:
- `bundle exec rake test_all` - all RSpec and Test::Unit tests must pass
- `bundle exec rake rubocop yard` - zero violations required
- Check test output for any Ruby warnings

### 2. Verify Testing Quality

**Unit Tests (Critical):**
- [ ] **100% coverage of all changed code** - every branch, edge case, error condition
- [ ] All external dependencies properly mocked (execution_context, git commands)
- [ ] Each test verifies one specific behavior
- [ ] Comprehensive coverage: success paths, failures, edge cases, error handling
- [ ] Test both public API and private methods where complexity exists

**Integration Tests (Essential Only):**
- [ ] **Minimal and purposeful** - only test what unit tests cannot verify
- [ ] Each test validates one specific git interaction pattern
- [ ] Tests verify mocked assumptions match real git behavior
- [ ] No redundancy - don't duplicate what unit tests already cover
- [ ] Follow CONTRIBUTING.md guidelines: test gem's interaction with git, not git itself

### 3. Review Code Quality

- [ ] YARD documentation complete for all public methods/classes
- [ ] Include `@api public` or `@api private` tags appropriately
- [ ] Usage examples in YARD docs show common patterns
- [ ] No breaking changes (or properly marked with `!` in commits)
- [ ] Cross-platform compatible on all supported OSes; any platform-specific logic is properly guarded and tested
- [ ] No security issues (command injection, path traversal, etc.)
- [ ] Uses Arguments DSL for building git commands

### 4. Verify Against Git Documentation

- [ ] Read https://git-scm.com/docs/git-[command] for the implemented command
- [ ] Confirm all documented options are considered
- [ ] All edge cases from git documentation are tested
- [ ] Error handling matches git's actual behavior
- [ ] Exit codes handled correctly (especially partial failures)

### 5. Check Commit Quality

- [ ] All commits follow Conventional Commits format: `type: description`
- [ ] Description is lowercase, no ending period, under 100 chars
- [ ] Valid types: feat, fix, docs, test, refactor, chore, perf, build, ci, style, revert
- [ ] Breaking changes marked with `!` and include `BREAKING CHANGE:` footer
- [ ] Each commit is atomic and has a clear purpose

### 6. Review Documentation

- [ ] Architecture docs updated if new patterns introduced (redesign/*.md)
- [ ] README.md updated if public API changed
- [ ] Examples are clear and demonstrate common use cases
- [ ] All `@param`, `@return`, `@raise` tags are accurate

### 7. Generate PR Summary

Provide a comprehensive report with:

**Implementation Summary:**
- What was implemented and why
- Key design decisions made
- Any trade-offs or limitations

**Test Coverage:**
- Unit tests: X examples covering Y scenarios
- Integration tests: Z examples validating specific git interactions
- Coverage: 100% of changed lines (or explain gaps)
- Edge cases tested: [list critical ones]

**Quality Verification:**
- ✅ Items that passed all checks
- ⚠️ Items that need attention (if any)
- Reference to relevant documentation verified

**Suggested PR Materials:**
- PR Title: `type: clear description of change`
- PR Description draft including:
  - Summary of changes
  - Why this change is needed
  - Test coverage details
  - Breaking changes (if any)
  - Checklist from .github/pull_request_template.md

**Next Steps:**
- Any remaining items to address before PR submission
- Confirmation that all checklist items are complete
- Make sure to create a feature branch for the PR -- never push directly to main or 4.x

## PR Special Considerations

### Security

- **Command Injection**: When using single-string commands, be aware of shell
  injection risks. Use `Git::CommandLine` for proper argument escaping.
- **Input Validation**: Validate and sanitize user-supplied paths and arguments
  before passing to commands.
- **File Permissions**: Be careful with file descriptors and permissions
- **Resource Limits**: Consider timeout and resource consumption
- **Git Hooks**: Consider risks associated with Git hook execution
- Document security implications in YARD comments

## Current Priorities

Based on project status and maintenance needs:

### Stability and Compatibility

1. Maintain Ruby 3.2+ compatibility
2. Keep cross-platform support (Mac, Linux, Windows)
3. Support Git 2.28.0+ versions
4. Ensure backward compatibility within major versions

### Code Quality

1. Maintain high test coverage
2. Follow TDD strictly for all changes
3. Keep Rubocop violations at zero
4. Comprehensive YARD documentation

### Feature Enhancements

Consider these only after TDD test is written:

- Improved worktree support
- Enhanced Git LFS integration
- Better handling of large repositories
- Performance optimizations for common operations
- Additional Git operations as needed

### Documentation Priorities

Focus on these specific documentation improvements to enhance developer experience
and project maintainability:

- Keep README.md examples current and comprehensive
- Add more real-world examples
- Document common pitfalls and gotchas
- Platform-specific behavior documentation
- Complete architecture redesign documentation in `redesign/`

## Useful Commands

See [Project Configuration](#project-configuration) for primary development commands.

**Additional commands:**

- Run specific test method: `bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_method_name`
- Run tests in Docker: `bin/test-in-docker`
- Run with different Git: `GIT_PATH=/path/to/git/bin-wrappers bin/test`
- Generate docs: `bundle exec yard doc`
- Serve docs locally: `bundle exec yard server --reload`
- Build gem: `bundle exec rake build`
- Auto-fix style: `bundle exec rubocop -a`

## Getting Help

- Review README.md for usage examples and architecture
- Check CHANGELOG.md for version history and breaking changes
- Read inline YARD documentation in source code
- Browse full API docs on [the full YARD documentation
  page](https://rubydoc.info/gems/git/)
- Look at existing tests for testing patterns
- Check CI configuration in `.github/workflows/` for supported platforms
- Review architecture redesign docs in `redesign/` directory

## Important Implementation Notes

### When Working with Git Commands

- Always use `Git::CommandLine` for command execution
- Handle command output encoding properly
- Consider timeout implications for long-running operations
- Test with various Git versions (minimum 2.28.0)
- Properly escape arguments and paths
- Handle Git error messages and exit codes

### When Working with Paths

- Paths are stored as `Pathname` objects (not custom wrapper classes)
- Use `Git::EscapedPath` for paths with special characters
- Handle Windows path separators appropriately
- Test with Unicode filenames
- Consider relative vs. absolute paths

### When Working with Repository Objects

- Lazy-load objects when possible
- Cache objects appropriately
- Handle missing or invalid objects gracefully
- Test with various object types (commits, trees, blobs, tags)
- Consider performance with large repositories

### When Working with Encoding

- Use `rchardet` for encoding detection
- Handle different platform encodings
- Test with UTF-8, ASCII, and other encodings
- Be aware of Git's encoding configuration
- Handle binary files appropriately

### When Working with Timeouts

- Use global timeout configuration or per-command overrides
- Handle `Git::TimeoutError` appropriately
- Test timeout behavior with long-running operations
- Document timeout implications in YARD comments
- Timeout support is built into the command execution layer
